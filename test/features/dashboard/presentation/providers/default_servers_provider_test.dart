import 'dart:async';
import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/datasources/default_server_cache_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_cache_model.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_cache_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_keys_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  group('defaultServersProvider', () {
    late Directory hiveDir;
    late Box<dynamic> cacheBox;
    late DefaultServerCacheDatasource cacheDatasource;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp(
        'default_servers_provider_test_',
      );
      Hive.init(hiveDir.path);
      cacheBox = await Hive.openBox<dynamic>(DefaultServerCacheDatasource.boxName);
      cacheDatasource = DefaultServerCacheDatasource(cacheBox);
    });

    tearDown(() async {
      if (cacheBox.isOpen) {
        await cacheBox.close();
      }
      Hive.close();
      if (await hiveDir.exists()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('loads live API data and preserves API-02 fields', () async {
      final apiKeys = [_sampleKey()];
      final container = ProviderContainer(
        overrides: [
          defaultServerKeysProvider.overrideWith((ref) async => apiKeys),
          defaultServerCacheDatasourceProvider.overrideWithValue(cacheDatasource),
        ],
      );
      addTearDown(container.dispose);

      container.read(defaultServersProvider);
      await _settle();
      final state = container.read(defaultServersProvider);

      expect(state.items, hasLength(1));
      expect(state.isOfflineData, isFalse);
      expect(state.lastFailureType, isNull);
      expect(state.items.first.subscriptionUrl, apiKeys.first.subscriptionUrl);
      expect(state.items.first.expireDate, apiKeys.first.expireDate);

      final cached = await cacheDatasource.read();
      expect(cached, isNotNull);
      expect(cached!.keys.first.subscriptionUrl, apiKeys.first.subscriptionUrl);
      expect(cached.keys.first.expireDate, apiKeys.first.expireDate);
    });

    test('falls back to cache and marks state as offline data', () async {
      final cachedKey = _sampleKey(id: 99, name: 'Cached');
      await cacheDatasource.write(
        DefaultServerCacheModel(
          fetchedAt: DateTime.utc(2026, 1, 1),
          keys: [cachedKey],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          defaultServerKeysProvider.overrideWith(
            (ref) async => throw const ApiClientException(
              type: ApiClientErrorType.network,
              message: 'offline',
            ),
          ),
          defaultServerCacheDatasourceProvider.overrideWithValue(cacheDatasource),
        ],
      );
      addTearDown(container.dispose);

      container.read(defaultServersProvider);
      await _settle();
      final state = container.read(defaultServersProvider);

      expect(state.items, hasLength(1));
      expect(state.items.first.id, 'default-api-99');
      expect(state.items.first.subscriptionUrl, cachedKey.subscriptionUrl);
      expect(state.items.first.expireDate, cachedKey.expireDate);
      expect(state.isOfflineData, isTrue);
      expect(state.lastFailureType, isNotNull);
    });

    test('refresh keeps visible items while request is in progress', () async {
      final refreshCompleter = Completer<List<DefaultServerKey>>();
      var call = 0;
      final container = ProviderContainer(
        overrides: [
          defaultServerKeysProvider.overrideWith((ref) async {
            call++;
            if (call == 1) {
              return [_sampleKey(id: 1)];
            }
            return refreshCompleter.future;
          }),
          defaultServerCacheDatasourceProvider.overrideWithValue(cacheDatasource),
        ],
      );
      addTearDown(container.dispose);

      container.read(defaultServersProvider);
      await _settle();
      expect(container.read(defaultServersProvider).items, hasLength(1));

      final refreshFuture = container
          .read(defaultServersProvider.notifier)
          .refresh();
      final refreshingState = container.read(defaultServersProvider);
      expect(refreshingState.items, hasLength(1));
      expect(refreshingState.isRefreshing, isTrue);

      refreshCompleter.complete([_sampleKey(id: 2)]);
      await refreshFuture;

      final refreshed = container.read(defaultServersProvider);
      expect(refreshed.items.first.id, 'default-api-2');
      expect(refreshed.isRefreshing, isFalse);
    });

    test('surfaces unauthorized after silent retry exhaustion', () async {
      final container = ProviderContainer(
        overrides: [
          defaultServerKeysProvider.overrideWith(
            (ref) async => throw const ApiClientException(
              type: ApiClientErrorType.unauthorized,
              message: 'unauthorized',
            ),
          ),
          defaultServerCacheDatasourceProvider.overrideWithValue(cacheDatasource),
        ],
      );
      addTearDown(container.dispose);

      container.read(defaultServersProvider);
      await _settle();
      final state = container.read(defaultServersProvider);

      expect(state.items, isEmpty);
      expect(state.isOfflineData, isFalse);
      expect(state.lastFailureType, isNotNull);
    });

    test('maps API client failure types explicitly', () {
      expect(
        mapDefaultServersFailureType(
          const ApiClientException(
            type: ApiClientErrorType.timeout,
            message: 'timeout',
          ),
        ),
        DefaultServersFailureType.timeout,
      );
      expect(
        mapDefaultServersFailureType(
          const ApiClientException(
            type: ApiClientErrorType.network,
            message: 'offline',
          ),
        ),
        DefaultServersFailureType.offline,
      );
      expect(
        mapDefaultServersFailureType(
          const ApiClientException(
            type: ApiClientErrorType.unauthorized,
            message: 'unauthorized',
          ),
        ),
        DefaultServersFailureType.unauthorized,
      );
    });

    test('queues bounded exponential retries for offline refresh failures', () async {
      final observedDelays = <Duration>[];
      var call = 0;
      final container = ProviderContainer(
        overrides: [
          defaultServerKeysProvider.overrideWith((ref) async {
            call++;
            if (call == 1) {
              return [_sampleKey(id: 1)];
            }
            throw const ApiClientException(
              type: ApiClientErrorType.network,
              message: 'offline',
            );
          }),
          defaultServerCacheDatasourceProvider.overrideWithValue(cacheDatasource),
          defaultServersRetryDelayProvider.overrideWithValue((duration) async {
            observedDelays.add(duration);
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(defaultServersProvider);
      await _settle();

      await container.read(defaultServersProvider.notifier).refresh();
      await _settle();

      final state = container.read(defaultServersProvider);
      expect(observedDelays, const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
      ]);
      expect(state.hasPendingRetry, isFalse);
      expect(state.retryAttempt, 3);
      expect(state.lastFailureType, DefaultServersFailureType.offline);
    });
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

DefaultServerKey _sampleKey({int id = 42, String name = 'Default 42'}) {
  return DefaultServerKey(
    id: id,
    name: name,
    keyBody: 'vless://uuid@server.com:443?type=tcp&security=tls#$name',
    subscriptionUrl: 'https://example.com/sub/$id',
    expireDate: DateTime.utc(2026, 12, 1),
    isActive: true,
    status: 'active',
    usedTraffic: 1024,
    dataLimit: 4096,
  );
}
