import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/widgets/connection_timer.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/widgets/traffic_stats_card.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/active_server_card.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/connect_button.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/ui_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('top visual group contains connect, status timer, active server, and stats path', (
    tester,
  ) async {
    await _pumpDashboard(tester, showStats: true);

    final topGroup = find.byKey(const Key('dashboard-top-visual-group'));
    expect(topGroup, findsOneWidget);
    expect(
      find.descendant(of: topGroup, matching: find.byType(ConnectButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: topGroup, matching: find.byType(ConnectionTimer)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: topGroup, matching: find.byType(ActiveServerCard)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: topGroup, matching: find.byType(TrafficStatsCard)),
      findsOneWidget,
    );
  });

  testWidgets('top visual group hides stats card when preference disabled', (
    tester,
  ) async {
    await _pumpDashboard(tester, showStats: false);

    final topGroup = find.byKey(const Key('dashboard-top-visual-group'));
    expect(topGroup, findsOneWidget);
    expect(
      find.descendant(of: topGroup, matching: find.byType(TrafficStatsCard)),
      findsNothing,
    );
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required bool showStats,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectionProvider.overrideWith(() => _TestConnectionNotifier()),
        activeServerProvider.overrideWith(() => _TestActiveServerNotifier()),
        uiPreferencesProvider.overrideWith(
          () => _TestUiPreferencesNotifier(showStats: showStats),
        ),
        defaultServersProvider.overrideWith(() => _TestDefaultServersNotifier()),
        authStateProvider.overrideWith(() => _TestAuthStateNotifier()),
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
  @override
  Future<AuthState> build() async {
    return const AuthState(
      token: 'token',
      isAuthenticated: true,
      isGuest: true,
      userId: 1,
    );
  }
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
  _TestUiPreferencesNotifier({required this.showStats});

  final bool showStats;

  @override
  UiPreferences build() {
    return UiPreferences(showDashboardStatistics: showStats);
  }
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
