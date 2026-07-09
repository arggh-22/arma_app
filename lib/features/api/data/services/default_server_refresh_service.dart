import 'package:arma_proxy_vpn_client/features/api/data/datasources/default_server_cache_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_cache_model.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_cache_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_keys_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef DefaultServerKeysFetcher = Future<List<DefaultServerKey>> Function();

class DefaultServerRefreshResult {
  const DefaultServerRefreshResult({
    required this.fetchedAt,
    required this.keys,
  });

  final DateTime fetchedAt;
  final List<DefaultServerKey> keys;
}

class DefaultServerRefreshService {
  DefaultServerRefreshService({
    required DefaultServerKeysFetcher fetchKeys,
    required DefaultServerCacheDatasource cacheDatasource,
    required SettingsLocalDatasource settingsDatasource,
    DateTime Function()? now,
  }) : _fetchKeys = fetchKeys,
       _cacheDatasource = cacheDatasource,
       _settingsDatasource = settingsDatasource,
       _now = now ?? DateTime.now;

  final DefaultServerKeysFetcher _fetchKeys;
  final DefaultServerCacheDatasource _cacheDatasource;
  final SettingsLocalDatasource _settingsDatasource;
  final DateTime Function() _now;

  Future<DefaultServerRefreshResult> refreshNow() async {
    final fetchedAt = _now().toUtc();
    final fetchedKeys = await _fetchKeys();
    final prunedKeys = _pruneExpiredKeys(fetchedKeys, reference: fetchedAt);

    await _cacheDatasource.write(
      DefaultServerCacheModel(fetchedAt: fetchedAt, keys: prunedKeys),
    );
    await _settingsDatasource.setDefaultServerAutoUpdateLastSuccessAt(
      fetchedAt,
    );

    return DefaultServerRefreshResult(fetchedAt: fetchedAt, keys: prunedKeys);
  }

  List<DefaultServerKey> _pruneExpiredKeys(
    List<DefaultServerKey> keys, {
    required DateTime reference,
  }) {
    return keys
        .where((key) => key.expireDate.toUtc().isAfter(reference))
        .toList(growable: false);
  }
}

final defaultServerRefreshServiceProvider =
    Provider<DefaultServerRefreshService>((ref) {
      final cacheDatasource = ref.watch(defaultServerCacheDatasourceProvider);
      final prefs = ref.watch(sharedPreferencesProvider);
      final settingsDatasource = SettingsLocalDatasource(prefs);

      return DefaultServerRefreshService(
        fetchKeys: () => ref.refresh(defaultServerKeysProvider.future),
        cacheDatasource: cacheDatasource,
        settingsDatasource: settingsDatasource,
      );
    });
