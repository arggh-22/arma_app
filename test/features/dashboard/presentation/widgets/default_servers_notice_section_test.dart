import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/default_servers_notice_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the announcement and dismisses it', (tester) async {
    await _pump(
      tester,
      const DefaultServersState(
        items: [],
        isRefreshing: false,
        isOfflineData: false,
        lastFailureType: null,
        hasPendingRetry: false,
        retryAttempt: 0,
        announcement: 'Scheduled maintenance tonight',
      ),
    );

    expect(find.text('Announcement'), findsOneWidget);
    expect(find.text('Scheduled maintenance tonight'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('default-servers-announcement-dismiss')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scheduled maintenance tonight'), findsNothing);
  });

  testWidgets('shows support/renew buttons and launches their urls',
      (tester) async {
    final launched = <String>[];

    await _pump(
      tester,
      const DefaultServersState(
        items: [],
        isRefreshing: false,
        isOfflineData: false,
        lastFailureType: null,
        hasPendingRetry: false,
        retryAttempt: 0,
        supportUrl: 'https://t.me/support_bot',
        webPageUrl: 'https://cabinet.example.com',
      ),
      launcher: (uri) async {
        launched.add(uri.toString());
        return true;
      },
    );

    await tester.tap(find.byKey(const Key('default-servers-support')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('default-servers-renew')));
    await tester.pump();

    expect(launched, ['https://t.me/support_bot', 'https://cabinet.example.com']);
  });

  testWidgets('renders nothing when there are no notices', (tester) async {
    await _pump(
      tester,
      const DefaultServersState(
        items: [],
        isRefreshing: false,
        isOfflineData: false,
        lastFailureType: null,
        hasPendingRetry: false,
        retryAttempt: 0,
      ),
    );

    expect(
      find.byKey(const Key('default-servers-notice-section')),
      findsNothing,
    );
  });
}

Future<void> _pump(
  WidgetTester tester,
  DefaultServersState state, {
  SubscriptionLinkLauncher? launcher,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultServersProvider.overrideWith(() => _TestNotifier(state)),
        if (launcher != null)
          subscriptionLinkLauncherProvider.overrideWithValue(launcher),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: DefaultServersNoticeSection()),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _TestNotifier extends DefaultServersNotifier {
  _TestNotifier(this._state);

  final DefaultServersState _state;

  @override
  DefaultServersState build() => _state;
}
