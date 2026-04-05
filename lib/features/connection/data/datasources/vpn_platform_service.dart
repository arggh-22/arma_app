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

  /// Start the VPN with a complete Xray JSON config and server display name.
  Future<bool> startVpn(String configJson, String serverName) async {
    return await _methodChannel.invokeMethod<bool>(
          'startVpn',
          {'config': configJson, 'serverName': serverName},
        ) ??
        false;
  }

  /// Stop the currently active VPN connection.
  Future<bool> stopVpn() async {
    return await _methodChannel.invokeMethod<bool>('stopVpn') ?? false;
  }

  /// Check whether the VPN service is currently running.
  Future<bool> get isRunning async {
    return await _methodChannel.invokeMethod<bool>('isRunning') ?? false;
  }

  /// Request VPN permission from the Android system.
  ///
  /// Returns true if permission was granted (or was already granted).
  /// Returns false if the user denied the permission dialog.
  Future<bool> requestVpnPermission() async {
    return await _methodChannel.invokeMethod<bool>('requestVpnPermission') ??
        false;
  }

  /// Stream of VPN events from native (status changes + traffic stats).
  ///
  /// Each event is a Map with "type" key:
  ///   - {"type": "status", "state": "connecting"|"connected"|"disconnected"|"error", "message": "..."}
  ///   - {"type": "stats", "uplink": int, "downlink": int}
  Stream<Map<String, dynamic>> get vpnEvents {
    return _eventChannel.receiveBroadcastStream().map(
          (event) => Map<String, dynamic>.from(event as Map),
        );
  }
}
