import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/theme/app_theme.dart';
import 'package:arma_proxy_vpn_client/core/router/app_router.dart';

/// Root application widget.
///
/// Configures Material 3 theming with teal seed color, system/light/dark
/// theme mode, and go_router for declarative navigation.
class ArmaApp extends ConsumerWidget {
  const ArmaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Arma VPN',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system, // Will be replaced by provider in Plan 02
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
