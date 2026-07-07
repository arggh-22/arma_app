import 'dart:async';

import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_bootstrap_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_refresh_scheduler_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_server_startup_selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/theme/app_theme.dart';
import 'package:arma_proxy_vpn_client/core/router/app_router.dart';
import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/locale_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/subscription_provider.dart';

/// Root application widget.
///
/// Configures Material 3 theming with teal seed color, persisted theme mode
/// and locale via Riverpod providers, go_router for navigation, and
/// AppLocalizations for 4-language support (EN, FA/RTL, RU, ZH).
///
/// Triggers auto-refresh of subscriptions with autoUpdate=true on first
/// build (D-04, CONF-07).
class ArmaApp extends ConsumerStatefulWidget {
  const ArmaApp({super.key});

  @override
  ConsumerState<ArmaApp> createState() => _ArmaAppState();
}

class _ArmaAppState extends ConsumerState<ArmaApp> with WidgetsBindingObserver {
  bool _autoRefreshTriggered = false;
  bool _authBootstrapTriggered = false;
  bool _autoUpdateRecoveryTriggered = false;
  bool _randomDefaultServerSelectionTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Request notification permission on first app open (Android 13+)
    _requestNotificationPermission();
    // Trigger auto-refresh once after first frame (D-04, CONF-07).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_authBootstrapTriggered) {
        _authBootstrapTriggered = true;
        ref.invalidate(authBootstrapProvider);
        unawaited(ref.read(authBootstrapProvider.future));
      }
      if (!_autoRefreshTriggered) {
        _autoRefreshTriggered = true;
        ref.read(subscriptionProvider.notifier).refreshAllAutoUpdate();
      }
      if (!_autoUpdateRecoveryTriggered) {
        _autoUpdateRecoveryTriggered = true;
        _triggerDefaultServerAutoUpdateRecovery();
      }
      if (!_randomDefaultServerSelectionTriggered) {
        _randomDefaultServerSelectionTriggered = true;
        _triggerRandomDefaultServerSelection();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerDefaultServerAutoUpdateRecovery();
      _maybeForceRefreshDefaultServers();
    }
  }

  /// Honors the subscription `profile-update-always` header (spec §2): when the
  /// last fetch reported it, pull a fresh config each time the app is reopened.
  void _maybeForceRefreshDefaultServers() {
    if (ref.read(defaultServersProvider).profileUpdateAlways) {
      unawaited(ref.read(defaultServersProvider.notifier).refresh());
    }
  }

  void _triggerDefaultServerAutoUpdateRecovery() {
    unawaited(_runDefaultServerAutoUpdateRecovery());
  }

  Future<void> _runDefaultServerAutoUpdateRecovery() async {
    final scheduler = ref.read(defaultServerRefreshSchedulerProvider.notifier);
    await scheduler.applyPersistedInterval();
    await scheduler.checkAndRunOverdueRefresh();
  }

  void _triggerRandomDefaultServerSelection() {
    unawaited(_runRandomDefaultServerSelection());
  }

  Future<void> _runRandomDefaultServerSelection() async {
    await ref
        .read(defaultServerStartupSelectionProvider)
        .autoSelectRandomServer();
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final platformService = VpnPlatformService();
      await platformService.requestNotificationPermission();
    } catch (e) {
      debugPrint('[ArmaApp] Error requesting notification permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Arma VPN',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
