import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/utils/link_launcher.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_group_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _gb = 1073741824;

Subscription _sub({
  int? totalBytes,
  int? downloadBytes,
  String? supportUrl,
  String? webPageUrl,
}) =>
    Subscription(
      id: 'sub-1',
      name: 'ARMA VPN',
      url: 'https://example.com/sub',
      totalBytes: totalBytes,
      downloadBytes: downloadBytes,
      supportUrl: supportUrl,
      webPageUrl: webPageUrl,
      expireDate: DateTime.now().add(const Duration(days: 12)),
      lastUpdated: DateTime.utc(2026, 1, 1),
      addedAt: DateTime.utc(2026, 1, 1),
    );

Future<void> _pump(
  WidgetTester tester,
  Subscription? sub, {
  LinkLauncher? launcher,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (launcher != null) linkLauncherProvider.overrideWithValue(launcher),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ServerGroupHeader(
              groupName: 'ARMA VPN',
              subscription: sub,
              serverCount: 3,
              isCollapsed: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the data-usage progress bar for a subscription with a total',
      (tester) async {
    await _pump(tester, _sub(totalBytes: 10 * _gb, downloadBytes: _gb));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('1.0 GB / 10 GB'), findsOneWidget);
  });

  testWidgets('hides the usage bar when the subscription has no data total',
      (tester) async {
    await _pump(tester, _sub());
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('shows a used-only line for an unlimited plan (no total)',
      (tester) async {
    // Unlimited: usage present but no `total` (e.g. total omitted from header).
    await _pump(tester, _sub(downloadBytes: 2 * _gb));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('2.0 GB / ∞'), findsOneWidget);
  });

  testWidgets('treats an explicit total=0 as unlimited', (tester) async {
    await _pump(tester, _sub(totalBytes: 0, downloadBytes: 2 * _gb));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('2.0 GB / ∞'), findsOneWidget);
  });

  testWidgets('shows Support/Renew links and launches their urls',
      (tester) async {
    final launched = <String>[];
    await _pump(
      tester,
      _sub(
        supportUrl: 'https://t.me/support',
        webPageUrl: 'https://cabinet.example.com',
      ),
      launcher: (uri) async {
        launched.add(uri.toString());
        return true;
      },
    );

    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Renew'), findsOneWidget);

    await tester.tap(find.text('Renew'));
    await tester.pump();
    await tester.tap(find.text('Support'));
    await tester.pump();

    expect(launched, ['https://cabinet.example.com', 'https://t.me/support']);
  });

  testWidgets('hides Support/Renew when the subscription has no links',
      (tester) async {
    await _pump(tester, _sub());
    expect(find.text('Support'), findsNothing);
    expect(find.text('Renew'), findsNothing);
  });
}
