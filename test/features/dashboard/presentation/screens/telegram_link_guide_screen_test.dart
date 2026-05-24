import 'dart:async';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/auth_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/telegram_link_outcome.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/telegram_link_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/screens/telegram_link_guide_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders required guided steps and actions', (tester) async {
    final repository = _FakeTelegramLinkRepository();
    await _pumpGuide(tester, repository: repository);

    expect(find.text('Open Telegram Bot'), findsOneWidget);
    expect(find.text('Tap Start in Telegram bot'), findsOneWidget);
    expect(find.text('Get your Telegram ID'), findsOneWidget);
    expect(find.byKey(const Key('telegram-id-input')), findsOneWidget);
    expect(find.byKey(const Key('telegram-paste-button')), findsOneWidget);
    expect(
      find.byKey(const Key('telegram-link-submit-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('telegram-check-status-button')),
      findsOneWidget,
    );
  });

  testWidgets('paste action fills input from clipboard', (tester) async {
    final repository = _FakeTelegramLinkRepository();
    await _pumpGuide(tester, repository: repository, clipboardText: '12345678');

    await _tapPaste(tester);
    await tester.pumpAndSettle();

    expect(find.text('12345678'), findsOneWidget);
  });

  testWidgets('open bot button calls launcher with fixed Telegram URL', (
    tester,
  ) async {
    final repository = _FakeTelegramLinkRepository();
    Uri? launchedUri;
    await _pumpGuide(
      tester,
      repository: repository,
      launcher: (uri) async {
        launchedUri = uri;
        return true;
      },
    );

    await tester.tap(find.byKey(const Key('telegram-open-bot-button')));
    await tester.pumpAndSettle();

    expect(launchedUri.toString(), 'https://t.me/devarmabot');
  });

  testWidgets('shows feedback when Telegram bot launch fails', (tester) async {
    final repository = _FakeTelegramLinkRepository();
    await _pumpGuide(
      tester,
      repository: repository,
      launcher: (_) async => false,
    );

    await tester.tap(find.byKey(const Key('telegram-open-bot-button')));
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t open Telegram bot. Try again.'), findsOneWidget);
  });

  testWidgets('linked outcome pops back to previous screen', (tester) async {
    final repository = _FakeTelegramLinkRepository(
      outcome: const TelegramLinkOutcome(type: TelegramLinkOutcomeType.linked),
    );
    await _pumpGuide(tester, repository: repository);

    await tester.enterText(
      find.byKey(const Key('telegram-id-input')),
      '123456',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Open Guide'), findsOneWidget);
    expect(find.byType(TelegramLinkGuideScreen), findsNothing);
  });

  testWidgets('unauthorized outcome stays on guide and shows feedback', (
    tester,
  ) async {
    final repository = _FakeTelegramLinkRepository(
      outcome: const TelegramLinkOutcome(
        type: TelegramLinkOutcomeType.unauthorized,
      ),
    );
    await _pumpGuide(tester, repository: repository);

    await tester.enterText(
      find.byKey(const Key('telegram-id-input')),
      '123456',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TelegramLinkGuideScreen), findsOneWidget);
    expect(
      find.text('Session expired. Please sign in again, then retry linking.'),
      findsOneWidget,
    );
  });

  testWidgets('in-flight submit disables controls and shows spinner', (
    tester,
  ) async {
    final completer = Completer<TelegramLinkOutcome>();
    final repository = _FakeTelegramLinkRepository(
      responder: (_) => completer.future,
    );
    await _pumpGuide(tester, repository: repository);

    await tester.enterText(
      find.byKey(const Key('telegram-id-input')),
      '123456',
    );
    await _tapSubmit(tester);
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('telegram-id-input')))
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('telegram-paste-button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('telegram-link-submit-button')),
          )
          .onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const TelegramLinkOutcome(type: TelegramLinkOutcomeType.network),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('failure outcome keeps screen and allows retry submit', (
    tester,
  ) async {
    final repository = _FakeTelegramLinkRepository(
      responder: (id) async {
        if (id == '123456') {
          return const TelegramLinkOutcome(
            type: TelegramLinkOutcomeType.network,
          );
        }
        return const TelegramLinkOutcome(type: TelegramLinkOutcomeType.linked);
      },
    );
    await _pumpGuide(tester, repository: repository);

    await tester.enterText(
      find.byKey(const Key('telegram-id-input')),
      '123456',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TelegramLinkGuideScreen), findsOneWidget);
    expect(
      find.text('No network connection. Reconnect and try again.'),
      findsOneWidget,
    );
    expect(repository.calls, 1);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('telegram-id-input')),
      '234567',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.byType(TelegramLinkGuideScreen), findsNothing);
  });

  testWidgets('status check in-flight disables button and shows spinner', (
    tester,
  ) async {
    final repository = _FakeTelegramLinkRepository();
    final statusCompleter = Completer<AuthState>();
    await _pumpGuide(
      tester,
      repository: repository,
      statusChecker: () => statusCompleter.future,
    );

    await tester.tap(find.byKey(const Key('telegram-check-status-button')));
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('telegram-check-status-button')),
          )
          .onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    statusCompleter.complete(
      const AuthState(
        token: 'token',
        isAuthenticated: true,
        isGuest: true,
        userId: 1,
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('status check linked result pops back to dashboard', (
    tester,
  ) async {
    final repository = _FakeTelegramLinkRepository();
    await _pumpGuide(
      tester,
      repository: repository,
      statusChecker: () async => const AuthState(
        token: 'token',
        isAuthenticated: true,
        isGuest: false,
        userId: 99,
      ),
    );

    await tester.tap(find.byKey(const Key('telegram-check-status-button')));
    await tester.pumpAndSettle();

    expect(find.text('Telegram account linked successfully.'), findsOneWidget);
    expect(find.byType(TelegramLinkGuideScreen), findsNothing);
  });

  testWidgets('status check failure shows error and allows retry', (
    tester,
  ) async {
    final repository = _FakeTelegramLinkRepository();
    var calls = 0;
    await _pumpGuide(
      tester,
      repository: repository,
      statusChecker: () async {
        calls++;
        throw const AuthRepositoryException(
          type: AuthRepositoryFailureType.authenticationFailed,
          message: 'failed',
        );
      },
    );

    await tester.tap(find.byKey(const Key('telegram-check-status-button')));
    await tester.pumpAndSettle();

    expect(find.byType(TelegramLinkGuideScreen), findsOneWidget);
    expect(find.text('Unexpected error. Please try again.'), findsOneWidget);
    expect(calls, 1);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('telegram-check-status-button')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('invalid Telegram ID is blocked and does not call repository', (
    tester,
  ) async {
    final repository = _FakeTelegramLinkRepository();
    await _pumpGuide(tester, repository: repository);

    await tester.enterText(find.byKey(const Key('telegram-id-input')), '12ab');
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(repository.calls, 0);
    expect(find.byType(TelegramLinkGuideScreen), findsOneWidget);
    expect(
      find.text('Telegram ID is invalid. Use 5–20 digits.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpGuide(
  WidgetTester tester, {
  required _FakeTelegramLinkRepository repository,
  String? clipboardText,
  TelegramUrlLauncher? launcher,
  Future<AuthState> Function()? statusChecker,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        telegramLinkRepositoryProvider.overrideWithValue(repository),
        authStatusRefreshProvider.overrideWithValue(
          statusChecker ??
              () async => const AuthState(
                token: 'token',
                isAuthenticated: true,
                isGuest: true,
                userId: 1,
              ),
        ),
        telegramUrlLauncherProvider.overrideWithValue(
          launcher ?? (_) async => true,
        ),
        telegramClipboardReaderProvider.overrideWithValue(
          () async => clipboardText,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TelegramLinkGuideScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Guide'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open Guide'));
  await tester.pumpAndSettle();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final submitButton = find.byKey(const Key('telegram-link-submit-button'));
  await tester.scrollUntilVisible(
    submitButton,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(submitButton);
}

Future<void> _tapPaste(WidgetTester tester) async {
  final pasteButton = find.byKey(const Key('telegram-paste-button'));
  await tester.scrollUntilVisible(
    pasteButton,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(pasteButton);
}

class _FakeTelegramLinkRepository implements TelegramLinkRepository {
  _FakeTelegramLinkRepository({
    TelegramLinkOutcome? outcome,
    Future<TelegramLinkOutcome> Function(String telegramId)? responder,
  }) : _outcome =
           outcome ??
           const TelegramLinkOutcome(
             type: TelegramLinkOutcomeType.alreadyLinked,
           ),
       _responder = responder;

  final TelegramLinkOutcome _outcome;
  final Future<TelegramLinkOutcome> Function(String telegramId)? _responder;
  int calls = 0;

  @override
  Future<TelegramLinkOutcome> linkTelegram(String telegramId) async {
    calls++;
    final responder = _responder;
    if (responder != null) {
      return responder(telegramId);
    }
    return _outcome;
  }
}
