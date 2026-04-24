import 'dart:ui';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

part 'locale_provider.g.dart';

/// Riverpod notifier for locale/language persistence.
///
/// Reads initial value from SharedPreferences on build,
/// and writes back when the user changes the language.
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  late SettingsLocalDatasource _datasource;

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _datasource = SettingsLocalDatasource(prefs);
    final localeCode = _datasource.getLocale();
    return Locale(localeCode);
  }

  /// Updates the locale and persists the choice.
  Future<void> setLocale(Locale locale) async {
    await _datasource.setLocale(locale.languageCode);
    state = locale;
  }
}

/// Supported locales for the app.
const supportedLocales = [
  Locale('en'),
  Locale('fa'),
  Locale('ru'),
  Locale('zh'),
  Locale('hy'),
];

/// Display names for the language selector UI.
const localeDisplayNames = <String, String>{
  'en': 'English',
  'fa': 'فارسی',
  'ru': 'Русский',
  'zh': '中文',
  'hy': 'Հայերեն',
};
