import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:arma_proxy_vpn_client/app.dart';
import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/storage/app_hive_bootstrap.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/background/default_server_background_dispatcher.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConstants.init();
  await Workmanager().initialize(defaultServerBackgroundDispatcher);
  await initializeAppHiveStorage();

  // Load SharedPreferences for settings persistence
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ArmaApp(),
    ),
  );
}
