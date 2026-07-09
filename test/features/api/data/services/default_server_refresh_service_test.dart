import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/datasources/default_server_cache_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/services/default_server_refresh_service.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DefaultServerRefreshService', () {
    late Directory hiveDir;
    late Box<dynamic> cacheBox;
    late DefaultServerCacheDatasource cacheDatasource;
    late SettingsLocalDatasource settingsDatasource;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp(
        'default_server_refresh_',
      );
      Hive.init(hiveDir.path);
      cacheBox = await Hive.openBox<dynamic>(
        DefaultServerCacheDatasource.boxName,
      );
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

    test(
      'refreshNow prunes expired keys before cache write and records sync timestamp',
      () async {
        final now = DateTime.utc(2026, 5, 24, 12);
        final service = DefaultServerRefreshService(
          fetchKeys: () async => [
            _sampleKey(
              id: 1,
              expireDate: now.subtract(const Duration(days: 1)),
            ),
            _sampleKey(id: 2, expireDate: now.add(const Duration(days: 1))),
          ],
          cacheDatasource: cacheDatasource,
          settingsDatasource: settingsDatasource,
          now: () => now,
        );

        final result = await service.refreshNow();

        expect(result.keys.map((key) => key.id), [2]);

        final cache = await cacheDatasource.read();
        expect(cache, isNotNull);
        expect(cache!.fetchedAt, now);
        expect(cache.keys.map((key) => key.id), [2]);
        expect(
          settingsDatasource.getDefaultServerAutoUpdateLastSuccessAt(),
          now,
        );
      },
    );

    test(
      'refreshNow surfaces unauthorized failure without local retries',
      () async {
        var calls = 0;
        final now = DateTime.utc(2026, 5, 24, 12);
        final service = DefaultServerRefreshService(
          fetchKeys: () async {
            calls++;
            throw const ApiClientException(
              type: ApiClientErrorType.unauthorized,
              message: 'Unauthorized request',
              statusCode: 401,
            );
          },
          cacheDatasource: cacheDatasource,
          settingsDatasource: settingsDatasource,
          now: () => now,
        );

        await expectLater(
          service.refreshNow(),
          throwsA(
            isA<ApiClientException>().having(
              (error) => error.type,
              'type',
              ApiClientErrorType.unauthorized,
            ),
          ),
        );
        expect(calls, 1);
        expect(await cacheDatasource.read(), isNull);
        expect(
          settingsDatasource.getDefaultServerAutoUpdateLastSuccessAt(),
          isNull,
        );
      },
    );
  });
}

DefaultServerKey _sampleKey({required int id, required DateTime expireDate}) {
  return DefaultServerKey(
    id: id,
    name: 'Server $id',
    keyBody: 'vless://uuid@server.com:443?type=tcp&security=tls#Server$id',
    subscriptionUrl: 'https://example.com/sub/$id',
    expireDate: expireDate,
    isActive: true,
    status: 'active',
    usedTraffic: 100,
    dataLimit: 1000,
  );
}
