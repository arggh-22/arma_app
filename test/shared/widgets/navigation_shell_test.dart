import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/shared/widgets/navigation_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('floating nav shows exactly three destinations', (tester) async {
    await _pumpShell(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Servers'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    // Routing is no longer a tab — it lives inside Settings.
    expect(find.text('Routing'), findsNothing);
  });

  testWidgets('tapping a destination switches the active branch', (
    tester,
  ) async {
    await _pumpShell(tester);

    expect(find.text('home-screen'), findsOneWidget);

    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    expect(find.text('servers-screen'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('settings-screen'), findsOneWidget);
  });

  group('desktop layout', () {
    testWidgets('uses a NavigationRail instead of the floating pill', (
      tester,
    ) async {
      // Reset must happen inside the test body (the framework verifies debug
      // vars are unset before group tearDowns run).
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await _pumpShell(tester);

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.text('Home'), findsWidgets);
        expect(find.text('Servers'), findsWidgets);
        expect(find.text('Settings'), findsWidgets);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('rail destination switches the active branch', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await _pumpShell(tester);

        expect(find.text('home-screen'), findsOneWidget);

        await tester.tap(find.text('Servers'));
        await tester.pumpAndSettle();
        expect(find.text('servers-screen'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}

Future<void> _pumpShell(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            NavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const _Stub('home-screen'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/servers',
                builder: (context, state) => const _Stub('servers-screen'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const _Stub('settings-screen'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

class _Stub extends StatelessWidget {
  const _Stub(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
