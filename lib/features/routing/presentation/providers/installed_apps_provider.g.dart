// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_apps_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the list of installed user apps from Android PackageManager.
///
/// Returns sorted by app name. Uses [VpnPlatformService.getInstalledApps]
/// which calls native via MethodChannel.

@ProviderFor(installedApps)
final installedAppsProvider = InstalledAppsProvider._();

/// Fetches the list of installed user apps from Android PackageManager.
///
/// Returns sorted by app name. Uses [VpnPlatformService.getInstalledApps]
/// which calls native via MethodChannel.

final class InstalledAppsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InstalledApp>>,
          List<InstalledApp>,
          FutureOr<List<InstalledApp>>
        >
    with
        $FutureModifier<List<InstalledApp>>,
        $FutureProvider<List<InstalledApp>> {
  /// Fetches the list of installed user apps from Android PackageManager.
  ///
  /// Returns sorted by app name. Uses [VpnPlatformService.getInstalledApps]
  /// which calls native via MethodChannel.
  InstalledAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installedAppsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installedAppsHash();

  @$internal
  @override
  $FutureProviderElement<List<InstalledApp>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InstalledApp>> create(Ref ref) {
    return installedApps(ref);
  }
}

String _$installedAppsHash() => r'02e37efee5003a0207a61439c4da71599cb51413';
