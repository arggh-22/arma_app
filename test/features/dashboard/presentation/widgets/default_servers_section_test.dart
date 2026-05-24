import 'dart:async';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/default_servers_section.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows top 3 preview and opens show-all sheet', (tester) async {
    final notifier = TestDefaultServersNotifier(
      DefaultServersState(
        items: [
          _item(id: '1', name: 'A'),
          _item(id: '2', name: 'B'),
          _item(id: '3', name: 'C'),
          _item(id: '4', name: 'D'),
        ],
        isRefreshing: false,
        isOfflineData: false,
        lastFailureType: null,
        hasPendingRetry: false,
        retryAttempt: 0,
      ),
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);

    await tester.tap(find.text('Show all servers'));
    await tester.pumpAndSettle();

    expect(find.text('D'), findsOneWidget);
  });

  testWidgets(
    'refresh action shows spinner while keeping current rows visible',
    (tester) async {
      final refreshCompleter = Completer<void>();
      final notifier = TestDefaultServersNotifier(
        DefaultServersState(
          items: [_item(id: '1', name: 'Visible')],
          isRefreshing: false,
          isOfflineData: false,
          lastFailureType: null,
          hasPendingRetry: false,
          retryAttempt: 0,
        ),
        onRefresh: () => refreshCompleter.future,
      );

      await _pumpSection(tester, defaultServersNotifier: notifier);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.text('Visible'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      refreshCompleter.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('shows offline badge and empty-state guidance', (tester) async {
    final notifier = TestDefaultServersNotifier(
      DefaultServersState(
        items: const [],
        isRefreshing: false,
        isOfflineData: false,
        lastFailureType: DefaultServersFailureType.offline,
        hasPendingRetry: false,
        retryAttempt: 0,
      ),
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);

    expect(find.text('No default servers available'), findsOneWidget);
    expect(
      find.text('No connection and no cached servers yet. Tap Refresh when online.'),
      findsOneWidget,
    );
  });

  testWidgets('shows timeout failure snackbar on refresh failure', (tester) async {
    late TestDefaultServersNotifier notifier;
    notifier = TestDefaultServersNotifier(
      DefaultServersState(
        items: [_item(id: '1', name: 'X')],
        isRefreshing: false,
        isOfflineData: false,
        lastFailureType: null,
        hasPendingRetry: false,
        retryAttempt: 0,
      ),
      onRefresh: () async {
        notifier.state = notifier.state.copyWith(
          lastFailureType: DefaultServersFailureType.timeout,
        );
      },
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(
      find.text('Request timed out. Tap Refresh to try again.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required TestDefaultServersNotifier defaultServersNotifier,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultServersProvider.overrideWith(() => defaultServersNotifier),
        activeServerProvider.overrideWith(() => TestActiveServerNotifier()),
        connectionProvider.overrideWith(() => TestConnectionNotifier()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: DefaultServersSection(),
        ),
      ),
    ),
  );
  await tester.pump();
}

class TestDefaultServersNotifier extends DefaultServersNotifier {
  TestDefaultServersNotifier(this.initialState, {this.onRefresh});

  final DefaultServersState initialState;
  final Future<void> Function()? onRefresh;

  @override
  DefaultServersState build() => initialState;

  @override
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    if (onRefresh != null) {
      await onRefresh!();
    }
    state = state.copyWith(isRefreshing: false);
  }
}

class TestActiveServerNotifier extends ActiveServerNotifier {
  @override
  ServerConfig? build() => null;

  @override
  Future<void> selectServer(ServerConfig? server) async {
    state = server;
  }
}

class TestConnectionNotifier extends ConnectionNotifier {
  @override
  ConnectionStatus build() => const Disconnected();

  @override
  Future<void> connect(ServerConfig server, {bool isManual = true}) async {}

  @override
  Future<void> disconnect() async {}
}

DefaultServerItem _item({
  required String id,
  required String name,
}) {
  return DefaultServerItem(
    id: id,
    name: name,
    status: 'active',
    usedTraffic: 1024,
    dataLimit: 4096,
    subscriptionUrl: 'https://example.com/$id',
    expireDate: DateTime.utc(2027, 1, 1),
    isActive: true,
    serverConfig: ServerConfig(
      id: id,
      name: name,
      protocol: ProtocolType.vless,
      address: 'example.com',
      port: 443,
      addedAt: DateTime.utc(2026, 1, 1),
    ),
  );
}
