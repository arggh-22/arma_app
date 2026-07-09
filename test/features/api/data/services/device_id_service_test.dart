import 'dart:async';
import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/auth_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/services/device_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  group('DeviceIdService', () {
    late Directory hiveDir;
    late Box<dynamic> authBox;
    late AuthLocalDatasource datasource;
    late Map<String, String> secureStorage;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('device_id_service_');
      Hive.init(hiveDir.path);
      secureStorage = <String, String>{};
      authBox = await AuthLocalDatasource.openEncryptedBox(
        hiveDir: hiveDir,
        readSecret: (key) async => secureStorage[key],
        writeSecret: (key, value) async => secureStorage[key] = value,
      );
      datasource = AuthLocalDatasource(authBox);
    });

    tearDown(() async {
      if (authBox.isOpen) {
        await authBox.close();
      }
      Hive.close();
      if (await hiveDir.exists()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('returns stored device id when it matches stable platform id', () async {
      await datasource.writeDeviceId('stable-id-123');
      var platformCalls = 0;

      final service = DeviceIdService(
        datasource,
        platformDeviceIdReader: () async {
          platformCalls++;
          return 'stable-id-123';
        },
      );

      final resolved = await service.resolveDeviceId();

      expect(resolved, 'stable-id-123');
      expect(platformCalls, 1);
    });

    test('stores and returns Android ID when no persisted value exists', () async {
      var platformCalls = 0;
      final service = DeviceIdService(
        datasource,
        platformDeviceIdReader: () async {
          platformCalls++;
          return 'android-id-123';
        },
      );

      final first = await service.resolveDeviceId();
      final second = await service.resolveDeviceId();

      expect(first, 'android-id-123');
      expect(second, 'android-id-123');
      expect(platformCalls, 2);
    });

    test('stores generated UUID fallback when platform id is unavailable', () async {
      var platformCalls = 0;
      var uuidCalls = 0;
      final service = DeviceIdService(
        datasource,
        platformDeviceIdReader: () async {
          platformCalls++;
          return null;
        },
        uuidGenerator: () {
          uuidCalls++;
          return 'uuid-fallback-001';
        },
      );

      final first = await service.resolveDeviceId();
      final second = await service.resolveDeviceId();

      expect(first, 'uuid-fallback-001');
      expect(second, 'uuid-fallback-001');
      expect(platformCalls, 2);
      expect(uuidCalls, 1);
    });

    test('migrates legacy stored id to stable Android id when available', () async {
      await datasource.writeDeviceId('legacy-build-id');
      var platformCalls = 0;
      var uuidCalls = 0;

      final service = DeviceIdService(
        datasource,
        platformDeviceIdReader: () async {
          platformCalls++;
          return 'stable-android-id';
        },
        uuidGenerator: () {
          uuidCalls++;
          return 'uuid-fallback-should-not-run';
        },
      );

      final resolved = await service.resolveDeviceId();
      final persisted = datasource.readDeviceId();

      expect(resolved, 'stable-android-id');
      expect(persisted, 'stable-android-id');
      expect(platformCalls, 1);
      expect(uuidCalls, 0);
    });

    test('does not print plaintext identifiers while resolving device id', () async {
      final printed = <String>[];
      final service = DeviceIdService(
        datasource,
        platformDeviceIdReader: () async => 'android-id-redacted',
      );

      await runZoned(
        () async {
          await service.resolveDeviceId();
        },
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );

      expect(printed, isEmpty);
    });
  });
}
