import 'dart:async';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
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
  });

  testWidgets('paste action fills input from clipboard', (tester) async {
    final repository = _FakeTelegramLinkRepository();
    await _pumpGuide(tester, repository: repository, clipboardText: '12345678');

    await tester.tap(find.byKey(const Key('telegram-paste-button')));
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
    await tester.tap(find.byKey(const Key('telegram-link-submit-button')));
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
    await tester.tap(find.byKey(const Key('telegram-link-submit-button')));
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
    await tester.tap(find.byKey(const Key('telegram-link-submit-button')));
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
    await tester.tap(find.byKey(const Key('telegram-link-submit-button')));
    await tester.pumpAndSettle();

    expect(find.byType(TelegramLinkGuideScreen), findsOneWidget);
    expect(
      find.text('No network connection. Reconnect and try again.'),
      findsOneWidget,
    );
    expect(repository.calls, 1);

    await tester.enterText(
      find.byKey(const Key('telegram-id-input')),
      '234567',
    );
    await tester.tap(find.byKey(const Key('telegram-link-submit-button')));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.byType(TelegramLinkGuideScreen), findsNothing);
  });

  testWidgets('invalid Telegram ID is blocked and does not call repository', (
    tester,
  ) async {
    final repository = _FakeTelegramLinkRepository();
    await _pumpGuide(tester, repository: repository);

    await tester.enterText(find.byKey(const Key('telegram-id-input')), '12ab');
    await tester.tap(find.byKey(const Key('telegram-link-submit-button')));
    await tester.pumpAndSettle();

    expect(repository.calls, 0);
    expect(find.byType(TelegramLinkGuideScreen), findsOneWidget);
    expect(find.text('Telegram ID is invalid. Use 5–20 digits.'), findsOneWidget);
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
