import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/ui_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows Link FAB and opens Telegram guide route', (tester) async {
    await _pumpDashboard(tester);

    final fabFinder = find.byKey(const Key('dashboard-telegram-link-fab'));
    expect(fabFinder, findsOneWidget);

    await tester.tap(fabFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('telegram-guide-screen')), findsOneWidget);
  });

  testWidgets('hides FAB on down-scroll and shows it on up-scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpDashboard(tester);
    expect(
      find.byKey(const Key('dashboard-telegram-link-fab')),
      findsOneWidget,
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-telegram-link-fab')), findsNothing);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 250));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('dashboard-telegram-link-fab')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpDashboard(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/telegram-link',
        builder: (context, state) => const Scaffold(
          body: Center(key: Key('telegram-guide-screen'), child: Text('guide')),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectionProvider.overrideWith(() => _TestConnectionNotifier()),
        activeServerProvider.overrideWith(() => _TestActiveServerNotifier()),
        uiPreferencesProvider.overrideWith(() => _TestUiPreferencesNotifier()),
        defaultServersProvider.overrideWith(
          () => _TestDefaultServersNotifier(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestConnectionNotifier extends ConnectionNotifier {
  @override
  ConnectionStatus build() => const Disconnected();
}

class _TestActiveServerNotifier extends ActiveServerNotifier {
  @override
  ServerConfig? build() => null;
}

class _TestUiPreferencesNotifier extends UiPreferencesNotifier {
  @override
  UiPreferences build() => const UiPreferences();
}

class _TestDefaultServersNotifier extends DefaultServersNotifier {
  @override
  DefaultServersState build() {
    return const DefaultServersState(
      items: [],
      isRefreshing: false,
      isOfflineData: false,
      lastFailureType: null,
      hasPendingRetry: false,
      retryAttempt: 0,
    );
  }

  @override
  Future<void> refresh() async {}
}
