import 'package:flutter/foundation.dart';
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

  /// Measure latency to a server by sending an HTTP request through a temporary Xray instance.
  /// Returns delay in milliseconds, or -1 on failure.
  /// [configJson] must be a complete Xray JSON config (use XrayConfigBuilder.build()).
  /// [testUrl] defaults to Google's generate_204 endpoint (~0 bytes response body).
  Future<int> measureDelay(
    String configJson, {
    String testUrl = 'https://www.google.com/generate_204',
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<Object>('measureDelay', {
        'config': configJson,
        'url': testUrl,
      });
      // Go returns Long → platform channel may deliver as int or num
      if (result is int) return result;
      if (result is num) return result.toInt();
      return -1;
    } on PlatformException catch (e) {
      debugPrint('[VpnPlatformService] measureDelay error: ${e.message}');
      return -1;
    } catch (_) {
      return -1;
    }
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

  /// Configure per-app proxy routing on the native side.
  ///
  /// When [mode] is non-null, the VPN service will apply per-app routing:
  /// - "blacklist": all apps proxied except [selectedApps]
  /// - "whitelist": only [selectedApps] are proxied
  ///
  /// When [mode] is null, per-app routing is disabled (all apps proxied).
  /// Stub implementation — full native integration added in Plan 03.
  Future<void> setPerAppConfig({
    required String? mode,
    required List<String> selectedApps,
  }) async {
    debugPrint(
      '[VpnPlatformService] setPerAppConfig(mode=$mode, apps=${selectedApps.length})',
    );
    // TODO(plan-03): Forward to native via MethodChannel
  }
}
