import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';

part 'installed_apps_provider.g.dart';

/// Represents an installed Android app fetched from PackageManager.
class InstalledApp {
  final String packageName;
  final String appName;
  final bool isSystem;

  /// Base64-encoded PNG icon, may be empty.
  final String iconBase64;

  const InstalledApp({
    required this.packageName,
    required this.appName,
    this.isSystem = false,
    this.iconBase64 = '',
  });
}

/// Fetches the list of installed user apps from Android PackageManager.
///
/// Returns sorted by app name. Uses [VpnPlatformService.getInstalledApps]
/// which calls native via MethodChannel.
@riverpod
Future<List<InstalledApp>> installedApps(Ref ref) async {
  final service = VpnPlatformService();
  final rawApps = await service.getInstalledApps();
  final apps = rawApps
      .map(
        (m) => InstalledApp(
          packageName: m['packageName'] as String? ?? '',
          appName: m['appName'] as String? ?? '',
          isSystem: m['isSystem'] as bool? ?? false,
          iconBase64: m['icon'] as String? ?? '',
        ),
      )
      .toList();
  // Sort alphabetically by app name for consistent ordering
  apps.sort(
    (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
  );
  return apps;
}
