import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/multi_select_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/subscription_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/screens/server_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('search query filters servers by name', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Tokyo-01'), findsOneWidget);
    expect(find.text('Berlin-02'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('server-search-field')),
      'tokyo',
    );
    await tester.pumpAndSettle();

    expect(find.text('Tokyo-01'), findsOneWidget);
    expect(find.text('Berlin-02'), findsNothing);

    // Clear button restores the full list.
    await tester.tap(find.byKey(const Key('server-search-clear')));
    await tester.pumpAndSettle();

    expect(find.text('Tokyo-01'), findsOneWidget);
    expect(find.text('Berlin-02'), findsOneWidget);
  });

  testWidgets('protocol quick-filter chips narrow the list', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const Key('protocol-filter-hysteria2')));
    await tester.pumpAndSettle();

    expect(find.text('Berlin-02'), findsOneWidget);
    expect(find.text('Tokyo-01'), findsNothing);

    // Tapping the same chip again deselects it (back to All).
    await tester.tap(find.byKey(const Key('protocol-filter-hysteria2')));
    await tester.pumpAndSettle();

    expect(find.text('Tokyo-01'), findsOneWidget);
    expect(find.text('Berlin-02'), findsOneWidget);
  });

  testWidgets('shows empty hint when no server matches the search', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.enterText(
      find.byKey(const Key('server-search-field')),
      'no-such-server',
    );
    await tester.pumpAndSettle();

    expect(find.text('Tokyo-01'), findsNothing);
    expect(find.text('Berlin-02'), findsNothing);
    expect(
      find.byKey(const Key('server-filter-empty-hint')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpScreen(WidgetTester tester) async {
  final servers = [
    _server(id: 's1', name: 'Tokyo-01', protocol: ProtocolType.vless),
    _server(id: 's2', name: 'Berlin-02', protocol: ProtocolType.hysteria2),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serverListProvider.overrideWith(() => _TestServerListNotifier(servers)),
        activeServerProvider.overrideWith(() => _TestActiveServerNotifier()),
        multiSelectProvider.overrideWith(() => _TestMultiSelectNotifier()),
        latencyProvider.overrideWith(() => _TestLatencyNotifier()),
        subscriptionProvider.overrideWith(() => _TestSubscriptionNotifier()),
        defaultServersProvider.overrideWith(
          () => _TestDefaultServersNotifier(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ServerListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ServerConfig _server({
  required String id,
  required String name,
  required ProtocolType protocol,
}) {
  return ServerConfig(
    id: id,
    name: name,
    protocol: protocol,
    address: 'example.com',
    port: 443,
    addedAt: DateTime.utc(2026, 1, 1),
    groupName: 'Imported',
  );
}

class _TestServerListNotifier extends ServerListNotifier {
  _TestServerListNotifier(this.servers);

  final List<ServerConfig> servers;

  @override
  Future<List<ServerConfig>> build() async => servers;
}

class _TestActiveServerNotifier extends ActiveServerNotifier {
  @override
  ServerConfig? build() => null;
}

class _TestMultiSelectNotifier extends MultiSelectNotifier {
  @override
  Set<String> build() => const {};
}

class _TestLatencyNotifier extends LatencyNotifier {
  @override
  Map<String, int> build() => {};
}

class _TestSubscriptionNotifier extends SubscriptionNotifier {
  @override
  List<Subscription> build() => const [];
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
}
