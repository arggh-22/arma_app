import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/best_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
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
/// keepAlive: true — connection state persists across widget rebuilds.
@Riverpod(keepAlive: true)
class ConnectionNotifier extends _$ConnectionNotifier {
  final VpnPlatformService _platformService = VpnPlatformService();
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  Timer? _durationTimer;
  int _fallbackAttempts = 0;
  static const _maxFallbackAttempts = 3;

  @override
  ConnectionStatus build() {
    print('[ConnectionNotifier] build() — subscribing to vpnEvents');
    _eventSubscription = _platformService.vpnEvents
        .where((e) => e['type'] == 'status')
        .listen(_handleStatusEvent);

    // Sync initial state — the VPN might be running from a previous app session.
    // The EventChannel.onListen replays lastKnownStatus, but as a belt-and-suspenders
    // approach, also query isRunning after a short delay.
    _syncInitialState();

    ref.onDispose(() {
      print('[ConnectionNotifier] dispose() — cleaning up');
      _eventSubscription?.cancel();
      _durationTimer?.cancel();
    });

    return const Disconnected();
  }

  Future<void> _syncInitialState() async {
    // Give time for service binding + EventChannel status replay
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final running = await _platformService.isRunning;
      print('[ConnectionNotifier] _syncInitialState: isRunning=$running, currentState=$state');
      if (running && state is Disconnected) {
        state = Connected(serverName: 'Active', connectedAt: DateTime.now());
      }
    } catch (e) {
      print('[ConnectionNotifier] _syncInitialState error: $e');
    }
  }

  /// Connect to the given [server].
  ///
  /// Set [isManual] to false when called from auto-fallback to preserve
  /// the fallback attempt counter.
  Future<void> connect(ServerConfig server, {bool isManual = true}) async {
    print('[ConnectionNotifier] connect(${server.name}) — current state: $state');
    if (state is Connecting || state is Connected) return;

    // Reset fallback counter only on user-initiated connect
    if (isManual) _fallbackAttempts = 0;

    state = Connecting(server.name);

    final hasPermission = await _platformService.requestVpnPermission();
    print('[ConnectionNotifier] VPN permission: $hasPermission');
    if (!hasPermission) {
      state = const Disconnected('VPN permission denied');
      return;
    }

    final configJson = XrayConfigBuilder.build(server);
    print('[ConnectionNotifier] === FULL XRAY CONFIG ===');
    print(configJson);
    print('[ConnectionNotifier] === END CONFIG ===');

    try {
      print('[ConnectionNotifier] Calling startVpn...');
      final started = await _platformService.startVpn(configJson, server.name);
      print('[ConnectionNotifier] startVpn returned: $started');
      if (!started) {
        state = const Disconnected('Failed to start VPN');
      }
    } catch (e) {
      print('[ConnectionNotifier] startVpn ERROR: $e');
      state = Disconnected('Error: $e');
    }
  }

  /// Disconnect from the current VPN connection.
  Future<void> disconnect() async {
    print('[ConnectionNotifier] disconnect() — current state: $state');
    if (state is Disconnected || state is Disconnecting) return;
    state = const Disconnecting();
    try {
      await _platformService.stopVpn();
      print('[ConnectionNotifier] stopVpn called');
    } catch (e) {
      print('[ConnectionNotifier] stopVpn ERROR: $e');
      state = const Disconnected();
    }
  }

  /// Handle status events from the native VPN process via EventChannel.
  void _handleStatusEvent(Map<String, dynamic> event) {
    final status = event['state'] as String?;
    print('[ConnectionNotifier] _handleStatusEvent: status=$status, current=$state');
    switch (status) {
      case 'connecting':
        if (state is! Connecting) {
          state = const Connecting('...');
        }
      case 'connected':
        final serverName =
            state is Connecting ? (state as Connecting).serverName : 'Active';
        _fallbackAttempts = 0; // Reset on successful connection
        state = Connected(serverName: serverName, connectedAt: DateTime.now());
      case 'disconnected':
        _durationTimer?.cancel();
        state = Disconnected(event['message'] as String?);
      case 'error':
        _durationTimer?.cancel();
        state =
            Disconnected(event['message'] as String? ?? 'Connection error');
        // D-17: Auto-fallback — try next best server on connection failure
        _attemptAutoFallback();
    }
  }

  /// D-17: When selected server fails, automatically try the next best server.
  /// Bounded to [_maxFallbackAttempts] consecutive failures to prevent infinite loops.
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
      if (latencyMap.isEmpty) return; // No latency data — can't auto-select

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
        // Small delay before retry to avoid rapid reconnection loops
        await Future.delayed(const Duration(seconds: 2));
        await connect(nextBest, isManual: false);
      }
    } catch (e) {
      debugPrint('[ConnectionNotifier] Auto-fallback error: $e');
    }
  }

}
