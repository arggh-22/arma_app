import 'package:package_info_plus/package_info_plus.dart';

/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// App display name and version.
  ///
  /// These are NOT hardcoded — [init] populates them from the platform package
  /// metadata, which Flutter derives from `pubspec.yaml` (the `version` field,
  /// e.g. `1.0.4+3` → version `1.0.4`) and the native app label (`appName`).
  /// pubspec.yaml is the single source of truth; bump the version there only.
  ///
  /// The literals below are fallbacks used only if [init] has not run yet
  /// (e.g. in unit tests that don't bootstrap the platform channel).
  static String appName = 'Arma VPN';
  static String appVersion = '1.0.4';

  static const maxServerNameLength = 50;
  static const snackBarDurationShort = Duration(seconds: 3);
  static const snackBarDurationDefault = Duration(seconds: 4);
  static const snackBarDurationLong = Duration(seconds: 6);

  /// Loads [appName] and [appVersion] from the platform package metadata.
  /// Call once during app startup, before `runApp`.
  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.appName.isNotEmpty) appName = info.appName;
      if (info.version.isNotEmpty) appVersion = info.version;
    } catch (_) {
      // Keep the fallback literals if platform metadata is unavailable.
    }
  }
}
