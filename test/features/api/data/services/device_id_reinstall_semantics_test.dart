import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/auth_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/services/device_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  group('DeviceIdService reinstall/update semantics', () {
    test(
      'fresh reinstall simulation keeps same HWID when stable platform id is unchanged',
      () async {
        final firstInstall = await _openDatasource();
        final secondInstall = await _openDatasource();

        final firstService = DeviceIdService(
          firstInstall.datasource,
          platformDeviceIdReader: () async => 'stable-platform-id',
        );
        final secondService = DeviceIdService(
          secondInstall.datasource,
          platformDeviceIdReader: () async => 'stable-platform-id',
        );

        final firstDeviceId = await firstService.resolveDeviceId();
        final secondDeviceId = await secondService.resolveDeviceId();

        expect(firstDeviceId, 'stable-platform-id');
        expect(secondDeviceId, 'stable-platform-id');
        expect(secondDeviceId, firstDeviceId);

        await firstInstall.dispose();
        await secondInstall.dispose();
      },
    );

    test('app update simulation preserves existing stored HWID', () async {
      final env = await _openDatasource();
      await env.datasource.writeDeviceId('existing-device-id');

      var uuidCalls = 0;
      final service = DeviceIdService(
        env.datasource,
        platformDeviceIdReader: () async => null,
        uuidGenerator: () {
          uuidCalls++;
          return 'uuid-should-not-be-used';
        },
      );

      final resolved = await service.resolveDeviceId();

      expect(resolved, 'existing-device-id');
      expect(env.datasource.readDeviceId(), 'existing-device-id');
      expect(uuidCalls, 0);

      await env.dispose();
    });

    test('platform-id unavailable path persists deterministic UUID fallback', () async {
      final env = await _openDatasource();

      var platformCalls = 0;
      var nextUuid = 'uuid-fallback-fixed';
      final service = DeviceIdService(
        env.datasource,
        platformDeviceIdReader: () async {
          platformCalls++;
          return null;
        },
        uuidGenerator: () => nextUuid,
      );

      final first = await service.resolveDeviceId();
      nextUuid = 'uuid-fallback-changed';
      final second = await service.resolveDeviceId();

      expect(first, 'uuid-fallback-fixed');
      expect(second, 'uuid-fallback-fixed');
      expect(env.datasource.readDeviceId(), 'uuid-fallback-fixed');
      expect(platformCalls, 2);

      await env.dispose();
    });
  });
}

Future<_TestEnv> _openDatasource() async {
  final hiveDir = await Directory.systemTemp.createTemp(
    'device_id_reinstall_semantics_',
  );
  Hive.init(hiveDir.path);
  final secureStorage = <String, String>{};
  final authBox = await AuthLocalDatasource.openEncryptedBox(
    hiveDir: hiveDir,
    readSecret: (key) async => secureStorage[key],
    writeSecret: (key, value) async => secureStorage[key] = value,
  );
  return _TestEnv(
    hiveDir: hiveDir,
    authBox: authBox,
    datasource: AuthLocalDatasource(authBox),
  );
}

class _TestEnv {
  _TestEnv({
    required this.hiveDir,
    required this.authBox,
    required this.datasource,
  });

  final Directory hiveDir;
  final Box<dynamic> authBox;
  final AuthLocalDatasource datasource;

  Future<void> dispose() async {
    if (authBox.isOpen) {
      await authBox.close();
    }
    Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  }
}
