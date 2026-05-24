import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/widgets/traffic_stats_card.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/default_servers_section.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/ui_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hides announcement card when title and text are missing', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      authState: const AuthState(
        token: 'token',
        isAuthenticated: true,
        isGuest: true,
        userId: 1,
      ),
    );

    expect(find.byKey(const Key('dashboard-announcement-card')), findsNothing);
  });

  testWidgets('shows title-only announcement without read more', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      authState: const AuthState(
        token: 'token',
        isAuthenticated: true,
        isGuest: true,
        userId: 1,
        announcementTitle: 'Maintenance',
      ),
    );

    expect(
      find.byKey(const Key('dashboard-announcement-card')),
      findsOneWidget,
    );
    expect(find.text('Maintenance'), findsOneWidget);
    expect(
      find.byKey(const Key('dashboard-announcement-read-more')),
      findsNothing,
    );
  });

  testWidgets(
    'shows text-only announcement with read more and opens bottom sheet',
    (tester) async {
      await _pumpDashboard(
        tester,
        authState: const AuthState(
          token: 'token',
          isAuthenticated: true,
          isGuest: false,
          userId: 1,
          announcementText: 'Extended outage details for tonight.',
        ),
      );

      expect(
        find.byKey(const Key('dashboard-announcement-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dashboard-announcement-read-more')),
        findsOneWidget,
      );

      final readMore = find.byKey(
        const Key('dashboard-announcement-read-more'),
      );
      await tester.ensureVisible(readMore);
      await tester.tap(readMore);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dashboard-announcement-sheet')),
        findsOneWidget,
      );
      expect(find.text('Extended outage details for tonight.'), findsWidgets);
    },
  );

  testWidgets('places announcement between statistics and default servers', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      authState: const AuthState(
        token: 'token',
        isAuthenticated: true,
        isGuest: true,
        userId: 1,
        announcementTitle: 'Notice',
        announcementText: 'Some text',
      ),
    );

    final statsY = tester.getTopLeft(find.byType(TrafficStatsCard)).dy;
    final announcementY = tester
        .getTopLeft(find.byKey(const Key('dashboard-announcement-card')))
        .dy;
    final defaultServersY = tester
        .getTopLeft(find.byType(DefaultServersSection))
        .dy;

    expect(statsY, lessThan(announcementY));
    expect(announcementY, lessThan(defaultServersY));
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required AuthState authState,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectionProvider.overrideWith(() => _TestConnectionNotifier()),
        activeServerProvider.overrideWith(() => _TestActiveServerNotifier()),
        uiPreferencesProvider.overrideWith(() => _TestUiPreferencesNotifier()),
        defaultServersProvider.overrideWith(
          () => _TestDefaultServersNotifier(),
        ),
        authStateProvider.overrideWith(() => _TestAuthStateNotifier(authState)),
        dashboardTelegramLauncherProvider.overrideWithValue((_) async => true),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DashboardScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestAuthStateNotifier extends AuthStateNotifier {
  _TestAuthStateNotifier(this._state);

  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
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
