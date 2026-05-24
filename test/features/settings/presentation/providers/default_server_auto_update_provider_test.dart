import 'package:arma_proxy_vpn_client/features/settings/domain/entities/default_server_auto_update_interval.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/default_server_auto_update_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('defaultServerAutoUpdateProvider', () {
    test('loads persisted interval during initialization', () async {
      SharedPreferences.setMockInitialValues({
        'default_server_auto_update_interval': '24h',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(defaultServerAutoUpdateProvider),
        DefaultServerAutoUpdateInterval.every24Hours,
      );
    });

    test('defaults to disabled for fresh preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(defaultServerAutoUpdateProvider),
        DefaultServerAutoUpdateInterval.disabled,
      );
    });

    test('setInterval updates provider state and persists selection', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(defaultServerAutoUpdateProvider.notifier)
          .setInterval(DefaultServerAutoUpdateInterval.every12Hours);

      expect(
        container.read(defaultServerAutoUpdateProvider),
        DefaultServerAutoUpdateInterval.every12Hours,
      );
      expect(
        prefs.getString('default_server_auto_update_interval'),
        '12h',
      );
    });
  });
}
