import 'dart:async';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
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
    expect(find.text('Get your link code'), findsOneWidget);
    expect(find.byKey(const Key('telegram-code-input')), findsOneWidget);
    expect(find.byKey(const Key('telegram-paste-button')), findsOneWidget);
    expect(
      find.byKey(const Key('telegram-link-submit-button')),
      findsOneWidget,
    );
  });

  testWidgets('paste action fills input from clipboard', (tester) async {
    final repository = _FakeTelegramLinkRepository();
    await _pumpGuide(tester, repository: repository, clipboardText: '123456');

    await _tapPaste(tester);
    await tester.pumpAndSettle();

    expect(find.text('123456'), findsOneWidget);
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

    expect(launchedUri.toString(), 'https://t.me/devarmabot?start=link');
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

  testWidgets('linked outcome shows success view and Done pops back', (
    tester,
  ) async {
    final repository = _FakeTelegramLinkRepository(
      outcome: const TelegramLinkOutcome(type: TelegramLinkOutcomeType.linked),
    );
    await _pumpGuide(tester, repository: repository);

    await tester.enterText(
      find.byKey(const Key('telegram-code-input')),
      '123456',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    // Linked switches the screen to the inline success view (no auto-pop).
    expect(
      find.byKey(const Key('telegram-linked-success-view')),
      findsOneWidget,
    );
    expect(find.text('Telegram Linked!'), findsOneWidget);
    expect(find.byType(TelegramLinkGuideScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('telegram-linked-done-button')));
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
      find.byKey(const Key('telegram-code-input')),
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
      find.byKey(const Key('telegram-code-input')),
      '123456',
    );
    await _tapSubmit(tester);
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('telegram-code-input')))
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

  testWidgets('failure outcome keeps screen and allows retry', (tester) async {
    final repository = _FakeTelegramLinkRepository(
      responder: (code) async {
        if (code == '123456') {
          return const TelegramLinkOutcome(
            type: TelegramLinkOutcomeType.network,
          );
        }
        return const TelegramLinkOutcome(type: TelegramLinkOutcomeType.linked);
      },
    );
    await _pumpGuide(tester, repository: repository);

    await tester.enterText(
      find.byKey(const Key('telegram-code-input')),
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

    // Let the error snackbar auto-dismiss before retrying.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('telegram-code-input')),
      '234567',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    // Second attempt links → inline success view replaces the form.
    expect(
      find.byKey(const Key('telegram-linked-success-view')),
      findsOneWidget,
    );
  });

  testWidgets('invalid code is blocked and does not call repository', (
    tester,
  ) async {
    final repository = _FakeTelegramLinkRepository();
    await _pumpGuide(tester, repository: repository);

    await tester.enterText(
      find.byKey(const Key('telegram-code-input')),
      '12ab',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(repository.calls, 0);
    expect(find.byType(TelegramLinkGuideScreen), findsOneWidget);
    expect(
      find.text('Enter the 6-digit code from the Telegram bot.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpGuide(
  WidgetTester tester, {
  required _FakeTelegramLinkRepository repository,
  String? clipboardText,
  TelegramUrlLauncher? launcher,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        telegramLinkRepositoryProvider.overrideWithValue(repository),
        // On a successful link the notifier refreshes auth in the background;
        // stub it so no real network call happens during the test.
        authStatusRefreshProvider.overrideWithValue(
          () async => const AuthState(
            token: 'token',
            isAuthenticated: true,
            isGuest: false,
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
    Future<TelegramLinkOutcome> Function(String code)? responder,
  }) : _outcome =
           outcome ??
           const TelegramLinkOutcome(
             type: TelegramLinkOutcomeType.alreadyLinked,
           ),
       _responder = responder;

  final TelegramLinkOutcome _outcome;
  final Future<TelegramLinkOutcome> Function(String code)? _responder;
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
