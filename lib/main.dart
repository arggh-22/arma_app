import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arma_proxy_vpn_client/app.dart';
import 'package:arma_proxy_vpn_client/features/routing/data/models/domain_rule_model.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/server_config_model.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/subscription_model.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

/// Opens a Hive box, clearing it if the on-disk data is incompatible
/// with the current schema (e.g. after a field type change).
Future<Box<T>> _openBoxSafe<T>(String name) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (_) {
    final box = await Hive.openBox(name);
    await box.deleteFromDisk();
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
  await _openBoxSafe<ServerConfigModel>('configs');
  await _openBoxSafe<SubscriptionModel>('subscriptions');
  await _openBoxSafe<DomainRuleModel>('domain_rules');

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
