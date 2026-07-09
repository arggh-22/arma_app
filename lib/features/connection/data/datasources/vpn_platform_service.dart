import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:arma_proxy_vpn_client/features/connection/data/datasources/desktop/desktop_xray_manager.dart';

/// Dart-side wrapper around the native VPN platform channels.
///
/// Encapsulates MethodChannel commands and EventChannel streaming.
/// Channel names MUST match Kotlin MainActivity:
///   - MethodChannel: "com.arma.vpn/method"
///   - EventChannel:  "com.arma.vpn/vpn_status"
///
/// On desktop (Linux/Windows) there is no native channel handler, so calls are
/// delegated to [DesktopXrayManager] (proxy mode) instead. The API surface is
/// identical, keeping callers platform-agnostic.
class VpnPlatformService {
  static const _methodChannel = MethodChannel('com.arma.vpn/method');
  static const _eventChannel = EventChannel('com.arma.vpn/vpn_status');

  /// Whether to route through the desktop proxy-mode core instead of the
  /// native Android channels.
  bool get _isDesktop => DesktopXrayManager.isSupported;

  /// Cached broadcast stream — MUST be shared across all subscribers.
  /// Creating multiple receiveBroadcastStream() calls on the same EventChannel
  /// causes the second to overwrite the native handler, killing the first.
  static Stream<Map<String, dynamic>>? _sharedEventStream;

  /// Start the VPN with a complete Xray JSON config and server display name.
  Future<bool> startVpn(String configJson, String serverName) async {
    debugPrint(
      '[VpnPlatformService] startVpn(configJson.length=${configJson.length}, serverName=$serverName)',
    );
    if (_isDesktop) {
      return DesktopXrayManager.instance.start(configJson, serverName);
    }
    final result =
        await _methodChannel.invokeMethod<bool>('startVpn', {
          'config': configJson,
          'serverName': serverName,
        }) ??
        false;
    debugPrint('[VpnPlatformService] startVpn result: $result');
    return result;
  }

  /// Stop the currently active VPN connection.
  Future<bool> stopVpn() async {
    debugPrint('[VpnPlatformService] stopVpn()');
    if (_isDesktop) {
      return DesktopXrayManager.instance.stop();
    }
    final result = await _methodChannel.invokeMethod<bool>('stopVpn') ?? false;
    debugPrint('[VpnPlatformService] stopVpn result: $result');
    return result;
  }

  /// Check whether the VPN service is currently running.
  Future<bool> get isRunning async {
    if (_isDesktop) {
      return DesktopXrayManager.instance.isRunning;
    }
    final result =
        await _methodChannel.invokeMethod<bool>('isRunning') ?? false;
    debugPrint('[VpnPlatformService] isRunning: $result');
    return result;
  }

  /// Request VPN permission from the Android system.
  /// Desktop proxy mode needs no OS permission → always granted.
  Future<bool> requestVpnPermission() async {
    debugPrint('[VpnPlatformService] requestVpnPermission()');
    if (_isDesktop) return true;
    final result =
        await _methodChannel.invokeMethod<bool>('requestVpnPermission') ??
        false;
    debugPrint('[VpnPlatformService] requestVpnPermission result: $result');
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
    // Desktop measures real through-proxy latency by running a short-lived
    // xray with a local HTTP-proxy inbound (equivalent to Android's native
    // MeasureDelay). This is what makes the HTTP server test work on desktop.
    if (_isDesktop) {
      return DesktopXrayManager.instance.measureDelay(configJson, testUrl);
    }
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
    // Desktop has no native EventChannel handler — surface the proxy-mode
    // manager's status events instead (same {type,state,message} shape).
    if (_isDesktop) {
      return DesktopXrayManager.instance.events;
    }
    _sharedEventStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      final mapped = Map<String, dynamic>.from(event as Map);
      // Log all events EXCEPT frequent traffic stats
      if (mapped['type'] != 'stats') {
        debugPrint('[VpnPlatformService] EVENT: $mapped');
      }
      return mapped;
    }).asBroadcastStream();
    return _sharedEventStream!;
  }

  /// Get list of installed user apps from Android PackageManager.
  /// Returns list of maps: {packageName: String, appName: String, icon: String (base64 PNG)}.
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final result = await _methodChannel.invokeListMethod<Map>(
        'getInstalledApps',
      );
      return result?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    } on PlatformException catch (e) {
      debugPrint('[VpnPlatformService] getInstalledApps error: ${e.message}');
      return [];
    }
  }

  /// Configure per-app proxy routing on the native side.
  ///
  /// When [mode] is non-null, the VPN service will apply per-app routing:
  /// - "blacklist": all apps proxied except [selectedApps]
  /// - "whitelist": only [selectedApps] are proxied
  ///
  /// When [mode] is null, per-app routing is disabled (all apps proxied).
  Future<void> setPerAppConfig({
    required String? mode,
    required List<String> selectedApps,
  }) async {
    try {
      await _methodChannel.invokeMethod('setPerAppConfig', {
        'mode': mode,
        'selectedApps': selectedApps,
      });
    } on PlatformException catch (e) {
      debugPrint('[VpnPlatformService] setPerAppConfig error: ${e.message}');
    }
  }

  /// Toggle detailed foreground notification content (server + traffic stats).
  Future<void> setNotificationDetailsEnabled(bool enabled) async {
    try {
      await _methodChannel.invokeMethod('setNotificationDetailsEnabled', {
        'enabled': enabled,
      });
    } on MissingPluginException {
      debugPrint(
        '[VpnPlatformService] setNotificationDetailsEnabled not available on this build',
      );
    } on PlatformException catch (e) {
      debugPrint(
        '[VpnPlatformService] setNotificationDetailsEnabled error: ${e.message}',
      );
    }
  }

  /// Request notification permission from the Android system (Android 13+).
  /// Returns true if permission is granted (or already granted on older Android).
  Future<bool> requestNotificationPermission() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('requestNotificationPermission');
      return result ?? false;
    } on MissingPluginException {
      debugPrint(
        '[VpnPlatformService] requestNotificationPermission not available on this build',
      );
      return true;
    } on PlatformException catch (e) {
      debugPrint(
        '[VpnPlatformService] requestNotificationPermission error: ${e.message}',
      );
      return false;
    }
  }

  /// Get Xray-core version string from the native runtime.
  /// Returns the version or empty string on error.
  Future<String> getXrayVersion() async {
    if (_isDesktop) return DesktopXrayManager.instance.version();
    try {
      final result =
          await _methodChannel.invokeMethod<String>('getXrayVersion');
      return result ?? 'Unknown';
    } on MissingPluginException {
      debugPrint('[VpnPlatformService] getXrayVersion not available on this build');
      return 'Unknown';
    } on PlatformException catch (e) {
      debugPrint('[VpnPlatformService] getXrayVersion error: ${e.message}');
      return 'Unknown';
    }
  }
}
