import 'package:flutter/services.dart';

/// Dart-side wrapper around the native VPN platform channels.
///
/// Encapsulates MethodChannel commands and EventChannel streaming.
/// Channel names MUST match Kotlin MainActivity:
///   - MethodChannel: "com.arma.vpn/method"
///   - EventChannel:  "com.arma.vpn/vpn_status"
class VpnPlatformService {
  static const _methodChannel = MethodChannel('com.arma.vpn/method');
  static const _eventChannel = EventChannel('com.arma.vpn/vpn_status');

  /// Cached broadcast stream — MUST be shared across all subscribers.
  /// Creating multiple receiveBroadcastStream() calls on the same EventChannel
  /// causes the second to overwrite the native handler, killing the first.
  static Stream<Map<String, dynamic>>? _sharedEventStream;

  /// Start the VPN with a complete Xray JSON config and server display name.
  Future<bool> startVpn(String configJson, String serverName) async {
    print('[VpnPlatformService] startVpn(configJson.length=${configJson.length}, serverName=$serverName)');
    final result = await _methodChannel.invokeMethod<bool>(
          'startVpn',
          {'config': configJson, 'serverName': serverName},
        ) ??
        false;
    print('[VpnPlatformService] startVpn result: $result');
    return result;
  }

  /// Stop the currently active VPN connection.
  Future<bool> stopVpn() async {
    print('[VpnPlatformService] stopVpn()');
    final result = await _methodChannel.invokeMethod<bool>('stopVpn') ?? false;
    print('[VpnPlatformService] stopVpn result: $result');
    return result;
  }

  /// Check whether the VPN service is currently running.
  Future<bool> get isRunning async {
    final result = await _methodChannel.invokeMethod<bool>('isRunning') ?? false;
    print('[VpnPlatformService] isRunning: $result');
    return result;
  }

  /// Request VPN permission from the Android system.
  Future<bool> requestVpnPermission() async {
    print('[VpnPlatformService] requestVpnPermission()');
    final result = await _methodChannel.invokeMethod<bool>('requestVpnPermission') ?? false;
    print('[VpnPlatformService] requestVpnPermission result: $result');
    return result;
  }

  /// Stream of VPN events from native (status changes + traffic stats).
  Stream<Map<String, dynamic>> get vpnEvents {
    _sharedEventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          final mapped = Map<String, dynamic>.from(event as Map);
          // Log all events EXCEPT frequent traffic stats
          if (mapped['type'] != 'stats') {
            print('[VpnPlatformService] EVENT: $mapped');
          }
          return mapped;
        })
        .asBroadcastStream();
    return _sharedEventStream!;
  }
}
