import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/auth_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/datasources/default_server_cache_datasource.dart';
import 'package:arma_proxy_vpn_client/features/routing/data/models/domain_rule_model.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/server_config_model.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/subscription_model.dart';
import 'package:arma_proxy_vpn_client/hive_registrar.g.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';

typedef OpenBoxSafe = Future<void> Function<T>(String name, Directory hiveDir);
typedef OpenDefaultServerCacheBox = Future<Box<dynamic>> Function();
typedef OpenEncryptedAuthBox =
    Future<void> Function({required Directory hiveDir});

/// Opens a Hive box, clearing on-disk files if the data is incompatible
/// with the current schema (e.g. after a field type change).
Future<void> openHiveBoxSafe<T>(String name, Directory hiveDir) async {
  try {
    await Hive.openBox<T>(name);
  } catch (_) {
    if (Hive.isBoxOpen(name)) {
      await Hive.box(name).close();
    }
    for (final ext in ['.hive', '.lock']) {
      final file = File('${hiveDir.path}/$name$ext');
      if (await file.exists()) {
        await file.delete();
      }
    }
    await Hive.openBox<T>(name);
  }
}

Future<void> bootstrapAppHiveStorage({
  required Directory hiveDir,
  OpenBoxSafe openBoxSafe = openHiveBoxSafe,
  OpenDefaultServerCacheBox openDefaultServerCacheBox =
      _openDefaultServerCacheBox,
  required OpenEncryptedAuthBox openEncryptedAuthBox,
}) async {
  await openBoxSafe<ServerConfigModel>('configs', hiveDir);
  await openBoxSafe<SubscriptionModel>('subscriptions', hiveDir);
  await openBoxSafe<DomainRuleModel>('domain_rules', hiveDir);
  await openDefaultServerCacheBox();
  await openEncryptedAuthBox(hiveDir: hiveDir);
}

Future<void> initializeAppHiveStorage() async {
  await Hive.initFlutter();
  Hive.registerAdapters();
  final hiveDir = await getApplicationDocumentsDirectory();
  const secureStorage = FlutterSecureStorage();
  await bootstrapAppHiveStorage(
    hiveDir: hiveDir,
    openEncryptedAuthBox: ({required hiveDir}) async {
      await AuthLocalDatasource.openEncryptedBox(
        hiveDir: hiveDir,
        readSecret: (key) => secureStorage.read(key: key),
        writeSecret: (key, value) =>
            secureStorage.write(key: key, value: value),
      );
    },
  );
}

Future<Box<dynamic>> _openDefaultServerCacheBox() {
  return Hive.openBox<dynamic>(DefaultServerCacheDatasource.boxName);
}
