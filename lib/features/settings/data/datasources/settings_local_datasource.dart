import 'package:shared_preferences/shared_preferences.dart';

/// Local data source for user preferences backed by SharedPreferences.
///
/// Stores theme mode, locale, and active server selection.
/// All values are lightweight (int/string) — no sensitive data.
class SettingsLocalDatasource {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _activeServerKey = 'active_server_id';

  final SharedPreferences _prefs;

  SettingsLocalDatasource(this._prefs);

  /// Returns theme mode index: 0=system, 1=light, 2=dark.
  int getThemeMode() => _prefs.getInt(_themeKey) ?? 0;

  /// Persists theme mode index.
  Future<void> setThemeMode(int mode) => _prefs.setInt(_themeKey, mode);

  /// Returns stored locale code (defaults to 'en').
  String getLocale() => _prefs.getString(_localeKey) ?? 'en';

  /// Persists locale code (e.g., 'fa', 'ru', 'zh').
  Future<void> setLocale(String locale) =>
      _prefs.setString(_localeKey, locale);

  /// Returns the active server ID, or null if none selected.
  String? getActiveServerId() => _prefs.getString(_activeServerKey);

  /// Persists or clears the active server ID.
  Future<void> setActiveServerId(String? id) async {
    if (id == null) {
      await _prefs.remove(_activeServerKey);
    } else {
      await _prefs.setString(_activeServerKey, id);
    }
  }
}
