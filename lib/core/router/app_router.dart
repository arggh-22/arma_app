import 'package:go_router/go_router.dart';

import 'package:arma_proxy_vpn_client/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:arma_proxy_vpn_client/features/log/presentation/screens/log_viewer_screen.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/screens/server_list_screen.dart';
import 'package:arma_proxy_vpn_client/features/routing/presentation/screens/routing_screen.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/screens/settings_screen.dart';
import 'package:arma_proxy_vpn_client/shared/widgets/navigation_shell.dart';

/// Application router using [GoRouter] with [StatefulShellRoute.indexedStack]
/// to preserve tab state across bottom navigation switches.
final goRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          NavigationShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/servers',
              builder: (context, state) => const ServerListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/routing',
              builder: (context, state) => const RoutingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/logs',
      builder: (context, state) => const LogViewerScreen(),
    ),
  ],
);
