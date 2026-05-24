import 'dart:io';

import 'package:arma_proxy_vpn_client/core/storage/app_hive_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  group('bootstrapAppHiveStorage', () {
    late Directory hiveDir;
    late Box<dynamic> shadowBox;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp(
        'app_hive_bootstrap_test_',
      );
      Hive.init(hiveDir.path);
      shadowBox = await Hive.openBox<dynamic>('bootstrap-test-shadow');
    });

    tearDown(() async {
      if (shadowBox.isOpen) {
        await shadowBox.close();
      }
      Hive.close();
      if (await hiveDir.exists()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('opens required Hive boxes including default_server_cache', () async {
      final openedTypedBoxes = <String>[];
      var openedDefaultCache = false;

      await bootstrapAppHiveStorage(
        hiveDir: hiveDir,
        openBoxSafe: <T>(name, directory) async {
          openedTypedBoxes.add(name);
        },
        openDefaultServerCacheBox: () async {
          openedDefaultCache = true;
          return shadowBox;
        },
        openEncryptedAuthBox: ({required hiveDir}) async {},
      );

      expect(
        openedTypedBoxes,
        equals(const ['configs', 'subscriptions', 'domain_rules']),
      );
      expect(openedDefaultCache, isTrue);
    });

    test('opens encrypted auth storage during bootstrap', () async {
      var authBootstrapCalls = 0;

      await bootstrapAppHiveStorage(
        hiveDir: hiveDir,
        openBoxSafe: <T>(name, directory) async {},
        openDefaultServerCacheBox: () async => shadowBox,
        openEncryptedAuthBox: ({required hiveDir}) async {
          authBootstrapCalls++;
        },
      );

      expect(authBootstrapCalls, 1);
    });
  });
}
