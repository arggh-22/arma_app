import 'dart:async';
import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/datasources/default_server_cache_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_cache_model.dart';
import 'package:arma_proxy_vpn_client/features/api/data/services/default_server_refresh_service.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_cache_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_keys_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('defaultServersProvider', () {
    late Directory hiveDir;
    late Box<dynamic> cacheBox;
    late DefaultServerCacheDatasource cacheDatasource;
    late SettingsLocalDatasource settingsDatasource;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp(
        'default_servers_provider_test_',
      );
      Hive.init(hiveDir.path);
      cacheBox = await Hive.openBox<dynamic>(DefaultServerCacheDatasource.boxName);
      cacheDatasource = DefaultServerCacheDatasource(cacheBox);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      settingsDatasource = SettingsLocalDatasource(prefs);
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
          defaultServerRefreshServiceProvider.overrideWithValue(
            _service(
              cacheDatasource: cacheDatasource,
              settingsDatasource: settingsDatasource,
              fetchKeys: () async => apiKeys,
            ),
          ),
          defaultServerKeysProvider.overrideWith((ref) => _legacyPathGuard()),
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

    test('expands rows from each key subscription_url response', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.write(
          'vless://uuid-a@one.example:443?type=tcp&security=tls#Zone A\n'
          'vless://uuid-b@two.example:443?type=tcp&security=tls#Zone B',
        );
        await request.response.close();
      });

      final subUrl =
          'http://${server.address.address}:${server.port}/subscription';
      final key = _sampleKey(
        id: 501,
        name: 'Key 501',
        keyBody: 'vless://uuid-fallback@fallback.example:443?type=tcp#Fallback',
        subscriptionUrl: subUrl,
      );
      final container = ProviderContainer(
        overrides: [
          defaultServerRefreshServiceProvider.overrideWithValue(
            _service(
              cacheDatasource: cacheDatasource,
              settingsDatasource: settingsDatasource,
              fetchKeys: () async => [key],
            ),
          ),
          defaultServerKeysProvider.overrideWith((ref) => _legacyPathGuard()),
          defaultServerCacheDatasourceProvider.overrideWithValue(cacheDatasource),
        ],
      );
      addTearDown(container.dispose);

      container.read(defaultServersProvider);
      await _settle();
      final state = container.read(defaultServersProvider);

      expect(state.items, hasLength(2));
      expect(state.items.map((item) => item.id), ['default-api-501-1', 'default-api-501-2']);
      expect(state.items.map((item) => item.name), ['Zone A', 'Zone B']);
      expect(
        state.items.map((item) => item.subscriptionUrl).toSet(),
        {subUrl},
      );
    });

    test('falls back to keyBody mapping when one subscription_url fetch fails', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.write(
          'vless://uuid-a@one.example:443?type=tcp&security=tls#Primary A\n'
          'vless://uuid-b@two.example:443?type=tcp&security=tls#Primary B',
        );
        await request.response.close();
      });

      final successUrl = 'http://${server.address.address}:${server.port}/ok';
      final keys = [
        _sampleKey(
          id: 601,
          name: 'Key 601',
          keyBody: 'vless://uuid-fallback@fallback.example:443?type=tcp#Fallback 601',
          subscriptionUrl: 'http://127.0.0.1:1/unreachable',
        ),
        _sampleKey(
          id: 602,
          name: 'Key 602',
          keyBody: 'vless://uuid-unused@unused.example:443?type=tcp#Unused',
          subscriptionUrl: successUrl,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          defaultServerRefreshServiceProvider.overrideWithValue(
            _service(
              cacheDatasource: cacheDatasource,
              settingsDatasource: settingsDatasource,
              fetchKeys: () async => keys,
            ),
          ),
          defaultServerKeysProvider.overrideWith((ref) => _legacyPathGuard()),
          defaultServerCacheDatasourceProvider.overrideWithValue(cacheDatasource),
        ],
      );
      addTearDown(container.dispose);

      container.read(defaultServersProvider);
      await _settle();
      final state = container.read(defaultServersProvider);

      expect(state.items, hasLength(3));
      expect(state.items.first.id, 'default-api-601');
      expect(state.items.first.name, 'Key 601');
      expect(state.items.skip(1).map((item) => item.id), [
        'default-api-602-1',
        'default-api-602-2',
      ]);
      expect(state.lastFailureType, isNull);
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
          defaultServerRefreshServiceProvider.overrideWithValue(
            _service(
              cacheDatasource: cacheDatasource,
              settingsDatasource: settingsDatasource,
              fetchKeys: () async => throw const ApiClientException(
                type: ApiClientErrorType.network,
                message: 'offline',
              ),
            ),
          ),
          defaultServerKeysProvider.overrideWith((ref) => _legacyPathGuard()),
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
          defaultServerRefreshServiceProvider.overrideWithValue(
            _service(
              cacheDatasource: cacheDatasource,
              settingsDatasource: settingsDatasource,
              fetchKeys: () async {
                call++;
                if (call == 1) {
                  return [_sampleKey(id: 1)];
                }
                return refreshCompleter.future;
              },
            ),
          ),
          defaultServerKeysProvider.overrideWith((ref) => _legacyPathGuard()),
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
          defaultServerRefreshServiceProvider.overrideWithValue(
            _service(
              cacheDatasource: cacheDatasource,
              settingsDatasource: settingsDatasource,
              fetchKeys: () async => throw const ApiClientException(
                type: ApiClientErrorType.unauthorized,
                message: 'unauthorized',
              ),
            ),
          ),
          defaultServerKeysProvider.overrideWith((ref) => _legacyPathGuard()),
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
          defaultServerRefreshServiceProvider.overrideWithValue(
            _service(
              cacheDatasource: cacheDatasource,
              settingsDatasource: settingsDatasource,
              fetchKeys: () async {
                call++;
                if (call == 1) {
                  return [_sampleKey(id: 1)];
                }
                throw const ApiClientException(
                  type: ApiClientErrorType.network,
                  message: 'offline',
                );
              },
            ),
          ),
          defaultServerKeysProvider.overrideWith((ref) => _legacyPathGuard()),
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
      expect(state.lastFailureType, isNotNull);
    });
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

DefaultServerKey _sampleKey({
  int id = 42,
  String name = 'Default 42',
  String? keyBody,
  String? subscriptionUrl,
}) {
  return DefaultServerKey(
    id: id,
    name: name,
    keyBody: keyBody ?? 'vless://uuid@server.com:443?type=tcp&security=tls#$name',
    subscriptionUrl: subscriptionUrl ?? 'https://example.com/sub/$id',
    expireDate: DateTime.utc(2026, 12, 1),
    isActive: true,
    status: 'active',
    usedTraffic: 1024,
    dataLimit: 4096,
  );
}

Future<List<DefaultServerKey>> _legacyPathGuard() async {
  throw StateError('defaultServerKeysProvider should not be called directly');
}

DefaultServerRefreshService _service({
  required DefaultServerCacheDatasource cacheDatasource,
  required SettingsLocalDatasource settingsDatasource,
  required Future<List<DefaultServerKey>> Function() fetchKeys,
}) {
  return DefaultServerRefreshService(
    fetchKeys: fetchKeys,
    cacheDatasource: cacheDatasource,
    settingsDatasource: settingsDatasource,
  );
}
