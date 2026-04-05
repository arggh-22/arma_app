import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arma_proxy_vpn_client/app.dart';
import 'package:arma_proxy_vpn_client/features/routing/data/models/domain_rule_model.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/server_config_model.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/subscription_model.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter (uses app documents directory)
  await Hive.initFlutter();
  Hive.registerAdapter(ServerConfigModelAdapter());
  Hive.registerAdapter(SubscriptionModelAdapter());
  Hive.registerAdapter(DomainRuleModelAdapter());
  await Hive.openBox<ServerConfigModel>('configs');
  await Hive.openBox<SubscriptionModel>('subscriptions');
  await Hive.openBox<DomainRuleModel>('domain_rules');

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
