import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';

part 'theme_provider.g.dart';

/// Riverpod notifier for theme mode persistence.
///
/// Reads initial value from SharedPreferences on build,
/// and writes back when the user changes the theme.
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  late SettingsLocalDatasource _datasource;

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _datasource = SettingsLocalDatasource(prefs);
    final modeIndex = _datasource.getThemeMode();
    return ThemeMode.values[modeIndex];
  }

  /// Updates the theme mode and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    await _datasource.setThemeMode(mode.index);
    state = mode;
  }
}

/// Provider for the SharedPreferences instance.
///
/// Must be overridden in main.dart with the actual instance
/// loaded before app startup.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(
    'Must be overridden with actual SharedPreferences instance',
  );
}
