import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/traffic_stats_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/routing/data/datasources/routing_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/routing/data/models/domain_rule_model.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/best_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/vpn_settings.dart';
import 'package:arma_proxy_vpn_client/xray/xray_config_builder.dart';

part 'connection_provider.g.dart';

/// Riverpod notifier managing the VPN connection state machine.
///
/// State transitions:
///   Disconnected → Connecting → Connected → Disconnecting → Disconnected
///   Connecting → Disconnected (on error or permission denied)
///
/// Uses [VpnPlatformService] for native MethodChannel/EventChannel communication
/// and [XrayConfigBuilder] to generate Xray JSON config from [ServerConfig] (D-02).
///
/// Lifecycle-aware: re-syncs state when app returns to foreground.
///
/// keepAlive: true — connection state persists across widget rebuilds.
@Riverpod(keepAlive: true)
class ConnectionNotifier extends _$ConnectionNotifier
    with WidgetsBindingObserver {
  final VpnPlatformService _platformService = VpnPlatformService();
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  Timer? _durationTimer;
  Timer? _stateTimeoutTimer;
  int _fallbackAttempts = 0;
  static const _maxFallbackAttempts = 3;
  static const _connectingTimeout = Duration(seconds: 30);
  static const _disconnectingTimeout = Duration(seconds: 10);
  static const _reachabilityTimeout = Duration(seconds: 8);

  @override
  ConnectionStatus build() {
    debugPrint('[ConnectionNotifier] build() — subscribing to vpnEvents');
    _eventSubscription = _platformService.vpnEvents
        .where((e) => e['type'] == 'status')
        .listen(_handleStatusEvent);

    WidgetsBinding.instance.addObserver(this);

    _syncInitialState();

    ref.onDispose(() {
      debugPrint('[ConnectionNotifier] dispose() — cleaning up');
      _eventSubscription?.cancel();
      _durationTimer?.cancel();
      _stateTimeoutTimer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });

    return const Disconnected();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[ConnectionNotifier] App resumed — re-syncing VPN state');
      resyncState();
    }
  }

  /// Re-sync Dart state with actual native VPN state.
  /// Called on app resume and can be called manually.
  Future<void> resyncState() async {
    try {
      final running = await _platformService.isRunning;
      debugPrint('[ConnectionNotifier] resyncState: isRunning=$running, currentState=$state');
      if (running && state is! Connected) {
        final serverName =
            state is Connecting ? (state as Connecting).serverName : 'Active';
        state = Connected(serverName: serverName, connectedAt: DateTime.now());
        _cancelStateTimeout();
      } else if (!running && state is! Disconnected) {
        state = const Disconnected();
        _cancelStateTimeout();
      }
    } catch (e) {
      debugPrint('[ConnectionNotifier] resyncState error: $e');
    }
  }

  Future<void> _syncInitialState() async {
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final running = await _platformService.isRunning;
      debugPrint('[ConnectionNotifier] _syncInitialState: isRunning=$running, currentState=$state');
      if (running && state is Disconnected) {
        state = Connected(serverName: 'Active', connectedAt: DateTime.now());
      }
    } catch (e) {
      debugPrint('[ConnectionNotifier] _syncInitialState error: $e');
    }
  }

  /// Connect to the given [server].
  Future<void> connect(ServerConfig server, {bool isManual = true}) async {
    debugPrint('[ConnectionNotifier] connect(${server.name}) — current state: $state');

    // Switching servers / reconnecting: tear down any existing (or pending)
    // session and WAIT until the native side reports it is fully stopped
    // before starting the new one. The native service processes stop/start/
    // isRunning on one sequential handler, so polling isRunning until false
    // guarantees the previous xray-core + TUN are gone. Without this wait the
    // new startVpn raced the old teardown, leaving the service "connected"
    // with no traffic (old tunnel torn down after the new one came up, or the
    // reachability probe running through the still-up old TUN).
    if (state is! Disconnected) {
      debugPrint(
        '[ConnectionNotifier] Reconnect: stopping current session first',
      );
      await disconnect();
      await _awaitNativeStopped();
    }

    if (isManual) _fallbackAttempts = 0;

    state = Connecting(server.name);
    _startStateTimeout(_connectingTimeout);

    final hasPermission = await _platformService.requestVpnPermission();
    debugPrint('[ConnectionNotifier] VPN permission: $hasPermission');
    if (!hasPermission) {
      state = const Disconnected('VPN permission denied');
      _cancelStateTimeout();
      return;
    }

    // Pre-flight reachability check. Runs before the TUN is up, so this socket
    // goes over the normal network and accurately tests whether the proxy
    // endpoint is dialable. Catches dead/stale endpoints (e.g. a wrong IP in
    // the key) instead of starting Xray and sitting on a fake "Connected" while
    // every dial silently hangs. Xray dials this same address:port directly, so
    // if we can't even open TCP here, the tunnel cannot work either.
    final reachable = await _isServerReachable(server);
    debugPrint('[ConnectionNotifier] reachability ${server.address}:${server.port} '
        '= $reachable');
    if (!reachable) {
      state = Disconnected(
        'Server unreachable (${server.address}:${server.port})',
      );
      _cancelStateTimeout();
      return;
    }

    // Read current Phase 4 settings from persistence
    final prefs = await SharedPreferences.getInstance();
    final settingsDatasource = SettingsLocalDatasource(prefs);
    final rulesBox = Hive.box<DomainRuleModel>('domain_rules');
    final routingDatasource = RoutingLocalDatasource(rulesBox);
    final vpnSettings = VpnSettings.fromDatasource(
      settingsDatasource,
      routingDatasource.getAllRules(),
    );

    // Desktop runs xray in proxy mode (SOCKS/HTTP inbounds + system proxy);
    // Android/iOS use the TUN inbound driven by the native tunnel.
    final configJson = (Platform.isLinux || Platform.isWindows)
        ? XrayConfigBuilder.buildForProxy(server, settings: vpnSettings)
        : XrayConfigBuilder.build(server, settings: vpnSettings);

    // Pass per-app proxy config to native side (Plan 03 adds setPerAppConfig)
    try {
      if (vpnSettings.perAppEnabled && vpnSettings.selectedApps.isNotEmpty) {
        await _platformService.setPerAppConfig(
          mode: vpnSettings.perAppMode,
          selectedApps: vpnSettings.selectedApps,
        );
      } else {
        await _platformService.setPerAppConfig(
          mode: null,
          selectedApps: [],
        );
      }
    } catch (e) {
      debugPrint('[ConnectionNotifier] setPerAppConfig not available: $e');
    }

    try {
      debugPrint('[ConnectionNotifier] Calling startVpn...');
      final started = await _platformService.startVpn(configJson, server.name);
      debugPrint('[ConnectionNotifier] startVpn returned: $started');
      if (!started) {
        state = const Disconnected('Failed to start VPN');
        _cancelStateTimeout();
      }
    } catch (e) {
      debugPrint('[ConnectionNotifier] startVpn ERROR: $e');
      state = Disconnected('Error: $e');
      _cancelStateTimeout();
    }
  }

  /// Attempt a bare TCP connection to the proxy endpoint to verify it is
  /// reachable before bringing up the tunnel.
  ///
  /// Returns `true` if a TCP connection opens within [_reachabilityTimeout],
  /// `false` on any failure (connection refused, timeout, DNS failure). A
  /// connect-then-close is harmless to the server (indistinguishable from an
  /// aborted connection) and is the minimum any VLESS/REALITY/XHTTP server
  /// must accept, so a failure here is a reliable "won't work" signal.
  Future<bool> _isServerReachable(ServerConfig server) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        server.address,
        server.port,
        timeout: _reachabilityTimeout,
      );
      return true;
    } catch (e) {
      debugPrint('[ConnectionNotifier] reachability check failed: $e');
      return false;
    } finally {
      socket?.destroy();
    }
  }

  /// Disconnect from the current VPN connection.
  Future<void> disconnect() async {
    debugPrint('[ConnectionNotifier] disconnect() — current state: $state');
    if (state is Disconnected) return;

    state = const Disconnecting();
    _startStateTimeout(_disconnectingTimeout);

    try {
      await _platformService.stopVpn();
      debugPrint('[ConnectionNotifier] stopVpn called');
    } catch (e) {
      debugPrint('[ConnectionNotifier] stopVpn ERROR: $e');
      state = const Disconnected();
      _cancelStateTimeout();
    }
  }

  /// Polls the native side until it reports the tunnel is fully stopped (or a
  /// timeout elapses). Because native stop/isRunning share one sequential
  /// message handler, an `isRunning == false` reply is only produced after the
  /// preceding `stopVpn` has fully torn down xray-core and closed the TUN — so
  /// this is a reliable "safe to start the next server" barrier.
  Future<void> _awaitNativeStopped({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        if (!await _platformService.isRunning) return;
      } catch (_) {
        // Treat an errored query as "assume stopped" rather than hang forever.
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    debugPrint(
      '[ConnectionNotifier] _awaitNativeStopped: timed out waiting for stop',
    );
  }

  /// Start a timeout that auto-resets state if it stays in a transitional
  /// state (Connecting/Disconnecting) for too long.
  void _startStateTimeout(Duration timeout) {
    _cancelStateTimeout();
    _stateTimeoutTimer = Timer(timeout, () {
      debugPrint('[ConnectionNotifier] State timeout — checking actual state');
      resyncState();
    });
  }

  void _cancelStateTimeout() {
    _stateTimeoutTimer?.cancel();
    _stateTimeoutTimer = null;
  }

  /// Handle status events from the native VPN process via EventChannel.
  void _handleStatusEvent(Map<String, dynamic> event) {
    final status = event['state'] as String?;
    debugPrint('[ConnectionNotifier] _handleStatusEvent: status=$status, current=$state');
    _cancelStateTimeout();
    switch (status) {
      case 'connecting':
        if (state is! Connecting) {
          state = const Connecting('...');
          _startStateTimeout(_connectingTimeout);
        }
      case 'connected':
        final serverName =
            state is Connecting ? (state as Connecting).serverName : 'Active';
        _fallbackAttempts = 0;
        state = Connected(serverName: serverName, connectedAt: DateTime.now());
      case 'disconnected':
        ref.read(trafficStatsProvider.notifier).reset();
        _durationTimer?.cancel();
        state = Disconnected(event['message'] as String?);
      case 'error':
        ref.read(trafficStatsProvider.notifier).reset();
        _durationTimer?.cancel();
        state =
            Disconnected(event['message'] as String? ?? 'Connection error');
        _attemptAutoFallback();
    }
  }

  /// D-17: When selected server fails, automatically try the next best server.
  Future<void> _attemptAutoFallback() async {
    if (_fallbackAttempts >= _maxFallbackAttempts) {
      debugPrint(
        '[ConnectionNotifier] Auto-fallback limit reached ($_maxFallbackAttempts)',
      );
      return;
    }
    _fallbackAttempts++;

    try {
      final servers = await ref.read(serverListProvider.future);
      final latencyMap = ref.read(latencyProvider);
      if (latencyMap.isEmpty) return;

      final activeServer = ref.read(activeServerProvider);
      final nextBest = selectBestServer(
        servers,
        latencyMap,
        excludeServerId: activeServer?.id,
      );

      if (nextBest != null) {
        debugPrint(
          '[ConnectionNotifier] Auto-fallback to: ${nextBest.name} '
          '(attempt $_fallbackAttempts/$_maxFallbackAttempts)',
        );
        ref.read(activeServerProvider.notifier).selectServer(nextBest);
        await Future.delayed(const Duration(seconds: 2));
        await connect(nextBest, isManual: false);
      }
    } catch (e) {
      debugPrint('[ConnectionNotifier] Auto-fallback error: $e');
    }
  }

}
