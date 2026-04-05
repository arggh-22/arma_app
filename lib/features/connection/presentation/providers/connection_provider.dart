import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
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
  Future<void> connect(ServerConfig server) async {
    print('[ConnectionNotifier] connect(${server.name}) — current state: $state');
    if (state is Connecting || state is Connected) return;

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
        state = Connected(serverName: serverName, connectedAt: DateTime.now());
      case 'disconnected':
        _durationTimer?.cancel();
        state = Disconnected(event['message'] as String?);
      case 'error':
        _durationTimer?.cancel();
        state =
            Disconnected(event['message'] as String? ?? 'Connection error');
    }
  }

}
