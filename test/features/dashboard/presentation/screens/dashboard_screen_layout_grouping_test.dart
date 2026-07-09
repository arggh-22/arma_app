import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
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
  testWidgets(
    'keeps a single scroll root with explicit top/bottom visual groups',
    (tester) async {
      await _pumpDashboard(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        find.byKey(const Key('dashboard-top-visual-group')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dashboard-bottom-visual-group')),
        findsOneWidget,
      );

      final topY = tester
          .getTopLeft(find.byKey(const Key('dashboard-top-visual-group')))
          .dy;
      final bottomY = tester
          .getTopLeft(find.byKey(const Key('dashboard-bottom-visual-group')))
          .dy;
      expect(topY, lessThan(bottomY));
    },
  );

  testWidgets('bottom visual group keeps announcement before default servers', (
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
        announcementText: 'Announcement body',
      ),
    );

    final bottomGroup = find.byKey(const Key('dashboard-bottom-visual-group'));
    expect(bottomGroup, findsOneWidget);

    final announcement = find.descendant(
      of: bottomGroup,
      matching: find.byKey(const Key('dashboard-announcement-card')),
    );
    final defaults = find.descendant(
      of: bottomGroup,
      matching: find.byType(DefaultServersSection),
    );

    expect(announcement, findsOneWidget);
    expect(defaults, findsOneWidget);
    expect(
      tester.getTopLeft(announcement).dy,
      lessThan(tester.getTopLeft(defaults).dy),
    );
  });
}

Future<void> _pumpDashboard(WidgetTester tester, {AuthState? authState}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectionProvider.overrideWith(() => _TestConnectionNotifier()),
        activeServerProvider.overrideWith(() => _TestActiveServerNotifier()),
        uiPreferencesProvider.overrideWith(() => _TestUiPreferencesNotifier()),
        defaultServersProvider.overrideWith(
          () => _TestDefaultServersNotifier(),
        ),
        authStateProvider.overrideWith(
          () => _TestAuthStateNotifier(
            authState ??
                const AuthState(
                  token: 'token',
                  isAuthenticated: true,
                  isGuest: true,
                  userId: 1,
                ),
          ),
        ),
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
