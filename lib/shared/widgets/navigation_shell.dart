import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';

/// Navigation shell that wraps all tab screens with a Material 3
/// [NavigationBar] at the bottom.
///
/// Uses [StatefulNavigationShell] from go_router to preserve each tab's
/// navigation state when switching between tabs.
class NavigationShell extends StatelessWidget {
  const NavigationShell({super.key, required this.navigationShell});

  /// The stateful navigation shell provided by [StatefulShellRoute].
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.dns_outlined),
            selectedIcon: const Icon(Icons.dns),
            label: l10n.servers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.alt_route_outlined),
            selectedIcon: const Icon(Icons.alt_route),
            label: l10n.routing,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
