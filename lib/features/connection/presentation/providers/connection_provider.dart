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
    _eventSubscription = _platformService.vpnEvents
        .where((e) => e['type'] == 'status')
        .listen(_handleStatusEvent);

    ref.onDispose(() {
      _eventSubscription?.cancel();
      _durationTimer?.cancel();
    });

    return const Disconnected();
  }

  /// Connect to the given [server].
  ///
  /// Flow:
  /// 1. Request VPN permission (shows system dialog on first use)
  /// 2. Build Xray JSON config from ServerConfig (D-02: all config logic in Dart)
  /// 3. Start VPN via MethodChannel
  /// 4. Connected state set by EventChannel callback from native
  Future<void> connect(ServerConfig server) async {
    if (state is Connecting || state is Connected) return;

    state = Connecting(server.name);

    // 1. Request VPN permission if needed
    final hasPermission = await _platformService.requestVpnPermission();
    if (!hasPermission) {
      state = const Disconnected('VPN permission denied');
      return;
    }

    // 2. Build Xray JSON config (D-02: all config logic in Dart)
    final configJson = XrayConfigBuilder.build(server);

    // 3. Start VPN via platform channel
    try {
      final started = await _platformService.startVpn(configJson, server.name);
      if (!started) {
        state = const Disconnected('Failed to start VPN');
      }
      // Connected state will be set by EventChannel callback
    } catch (e) {
      state = Disconnected('Error: $e');
    }
  }

  /// Disconnect from the current VPN connection.
  ///
  /// Can be called from Connecting or Connected states.
  /// Disconnected state set by EventChannel callback from native.
  Future<void> disconnect() async {
    if (state is Disconnected || state is Disconnecting) return;
    state = const Disconnecting();
    try {
      await _platformService.stopVpn();
      // Disconnected state will be set by EventChannel callback
    } catch (e) {
      state = const Disconnected();
    }
  }

  /// Handle status events from the native VPN process via EventChannel.
  void _handleStatusEvent(Map<String, dynamic> event) {
    final status = event['state'] as String?;
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
