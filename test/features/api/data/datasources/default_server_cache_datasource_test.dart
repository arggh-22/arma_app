import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/default_server_cache_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_cache_model.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  group('DefaultServerCacheDatasource', () {
    late Directory hiveDir;
    late Box<dynamic> box;
    late DefaultServerCacheDatasource datasource;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('default_server_cache_test_');
      Hive.init(hiveDir.path);
      box = await Hive.openBox<dynamic>(DefaultServerCacheDatasource.boxName);
      datasource = DefaultServerCacheDatasource(box);
    });

    tearDown(() async {
      if (box.isOpen) {
        await box.close();
      }
      Hive.close();
      if (await hiveDir.exists()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('returns null when cache has never been written', () async {
      final cache = await datasource.read();

      expect(cache, isNull);
    });

    test('writes and restores a cache snapshot', () async {
      final expected = DefaultServerCacheModel(
        fetchedAt: DateTime.utc(2026, 5, 24, 15),
        keys: [
          DefaultServerKey(
            id: 1,
            name: 'Default #1',
            keyBody: 'vless://node',
            subscriptionUrl: 'https://example.com/sub/1',
            expireDate: DateTime.utc(2026, 6, 30),
            isActive: true,
            status: 'active',
            usedTraffic: 123,
            dataLimit: 456,
          ),
        ],
      );

      await datasource.write(expected);
      final restored = await datasource.read();

      expect(restored, isNotNull);
      expect(restored!.fetchedAt, expected.fetchedAt);
      expect(restored.keys.single.subscriptionUrl, 'https://example.com/sub/1');
      expect(restored.keys.single.expireDate, DateTime.utc(2026, 6, 30));
    });

    test('returns null when stored payload is corrupted', () async {
      await box.put(DefaultServerCacheDatasource.storageKey, 'not-json');

      final restored = await datasource.read();

      expect(restored, isNull);
    });
  });
}
