import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/default_server_auto_update_interval.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsLocalDatasource auto-update interval', () {
    test('defaults to disabled when storage is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final datasource = SettingsLocalDatasource(prefs);

      expect(
        datasource.getDefaultServerAutoUpdateInterval(),
        DefaultServerAutoUpdateInterval.disabled,
      );
    });

    test('falls back to disabled when stored value is invalid', () async {
      SharedPreferences.setMockInitialValues({
        'default_server_auto_update_interval': 'unexpected',
      });
      final prefs = await SharedPreferences.getInstance();
      final datasource = SettingsLocalDatasource(prefs);

      expect(
        datasource.getDefaultServerAutoUpdateInterval(),
        DefaultServerAutoUpdateInterval.disabled,
      );
    });

    test('round-trips all interval options', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final datasource = SettingsLocalDatasource(prefs);

      for (final interval in DefaultServerAutoUpdateInterval.values) {
        await datasource.setDefaultServerAutoUpdateInterval(interval);
        expect(datasource.getDefaultServerAutoUpdateInterval(), interval);
      }
    });

    test('stores and reads last successful refresh timestamp', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final datasource = SettingsLocalDatasource(prefs);
      final timestamp = DateTime.utc(2026, 5, 24, 12, 15, 30);

      expect(datasource.getDefaultServerAutoUpdateLastSuccessAt(), isNull);

      await datasource.setDefaultServerAutoUpdateLastSuccessAt(timestamp);
      expect(datasource.getDefaultServerAutoUpdateLastSuccessAt(), timestamp);

      await datasource.setDefaultServerAutoUpdateLastSuccessAt(null);
      expect(datasource.getDefaultServerAutoUpdateLastSuccessAt(), isNull);
    });
  });
}
