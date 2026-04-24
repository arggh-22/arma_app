import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arma_proxy_vpn_client/app.dart';
import 'package:arma_proxy_vpn_client/features/routing/data/models/domain_rule_model.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/server_config_model.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/subscription_model.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

/// Opens a Hive box, clearing on-disk files if the data is incompatible
/// with the current schema (e.g. after a field type change).
///
/// Re-opening untyped does not bypass deserialization because the typeAdapter
/// is matched by typeId, not by Box generic, so we must delete files directly.
Future<Box<T>> _openBoxSafe<T>(String name, Directory dir) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (_) {
    // Make sure box is closed (it may be partially open after the failure)
    if (Hive.isBoxOpen(name)) {
      await Hive.box(name).close();
    }
    // Delete the underlying box files directly
    for (final ext in ['.hive', '.lock']) {
      final f = File('${dir.path}/$name$ext');
      if (await f.exists()) {
        await f.delete();
      }
    }
    return await Hive.openBox<T>(name);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter (uses app documents directory)
  await Hive.initFlutter();
  Hive.registerAdapter(ServerConfigModelAdapter());
  Hive.registerAdapter(SubscriptionModelAdapter());
  Hive.registerAdapter(DomainRuleModelAdapter());

  final hiveDir = await getApplicationDocumentsDirectory();
  await _openBoxSafe<ServerConfigModel>('configs', hiveDir);
  await _openBoxSafe<SubscriptionModel>('subscriptions', hiveDir);
  await _openBoxSafe<DomainRuleModel>('domain_rules', hiveDir);

  // Load SharedPreferences for settings persistence
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ArmaApp(),
    ),
  );
}
