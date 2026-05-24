import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/router/app_router.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/telegram_link_outcome.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/telegram_link_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/screens/telegram_link_guide_screen.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/ui_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  testWidgets('shows Link FAB and opens Telegram guide route', (tester) async {
    await _pumpDashboard(
      tester,
      authState: const AuthState(
        token: 'token',
        isAuthenticated: true,
        isGuest: true,
        userId: 1,
      ),
    );

    final fabFinder = find.byKey(const Key('dashboard-telegram-link-fab'));
    expect(fabFinder, findsOneWidget);
    expect(find.text('Link'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is FaIcon && widget.icon == FontAwesomeIcons.telegram,
      ),
      findsOneWidget,
    );

    await tester.tap(fabFinder);
    await tester.pumpAndSettle();

    expect(find.byType(TelegramLinkGuideScreen), findsOneWidget);
  });

  testWidgets('shows icon-only Telegram FAB for linked users and opens bot', (
    tester,
  ) async {
    Uri? launchedUri;
    await _pumpDashboard(
      tester,
      authState: const AuthState(
        token: 'token',
        isAuthenticated: true,
        isGuest: false,
        userId: 2,
      ),
      launcher: (uri) async {
        launchedUri = uri;
        return true;
      },
    );

    expect(find.byKey(const Key('dashboard-telegram-link-fab')), findsNothing);
    expect(find.byKey(const Key('dashboard-telegram-bot-fab')), findsOneWidget);
    expect(find.text('Link'), findsNothing);

    await tester.tap(find.byKey(const Key('dashboard-telegram-bot-fab')));
    await tester.pumpAndSettle();

    expect(launchedUri.toString(), 'https://t.me/devarmabot');
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

Future<void> _pumpDashboard(
  WidgetTester tester, {
  AuthState? authState,
  DashboardTelegramLauncher? launcher,
}) async {
  goRouter.go('/dashboard');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectionProvider.overrideWith(() => _TestConnectionNotifier()),
        activeServerProvider.overrideWith(() => _TestActiveServerNotifier()),
        uiPreferencesProvider.overrideWith(() => _TestUiPreferencesNotifier()),
        defaultServersProvider.overrideWith(
          () => _TestDefaultServersNotifier(),
        ),
        telegramLinkRepositoryProvider.overrideWithValue(
          _TestTelegramLinkRepository(),
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
        dashboardTelegramLauncherProvider.overrideWithValue(
          launcher ?? (_) async => true,
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: goRouter,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestAuthStateNotifier extends AuthStateNotifier {
  _TestAuthStateNotifier([this._state]);

  final AuthState? _state;

  @override
  Future<AuthState> build() async {
    return _state ??
        const AuthState(
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

class _TestTelegramLinkRepository implements TelegramLinkRepository {
  @override
  Future<TelegramLinkOutcome> linkTelegram(String telegramId) async {
    return const TelegramLinkOutcome(
      type: TelegramLinkOutcomeType.alreadyLinked,
    );
  }
}
