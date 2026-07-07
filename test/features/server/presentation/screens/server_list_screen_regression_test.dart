import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/multi_select_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/sort_filter_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/subscription_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/screens/server_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'imported groups still collapse and expand with defaults visible',
    (tester) async {
      await _pumpScreen(
        tester,
        servers: [
          _server(id: 'imported-1', name: 'Imported 1'),
          _server(id: 'imported-2', name: 'Imported 2'),
        ],
        defaults: [_item(id: 'default-1', name: 'Default 1')],
      );

      expect(find.text('Default 1'), findsOneWidget);
      expect(find.text('Imported 1'), findsOneWidget);
      expect(find.text('Imported 2'), findsOneWidget);

      final importedHeader = find.byKey(
        const ValueKey('server-group-header-Imported'),
      );
      await tester.tap(
        find.descendant(
          of: importedHeader,
          matching: find.byIcon(Icons.expand_less),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Imported 1'), findsNothing);
      expect(find.text('Imported 2'), findsNothing);
      expect(find.text('Default 1'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: importedHeader,
          matching: find.byIcon(Icons.expand_more),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Imported 1'), findsOneWidget);
      expect(find.text('Imported 2'), findsOneWidget);
    },
  );

  testWidgets(
    'imported groups stay interactive while grouped defaults are visible',
    (tester) async {
      await _pumpScreen(
        tester,
        servers: [
          _server(id: 'imported-1', name: 'Imported 1'),
          _server(id: 'imported-2', name: 'Imported 2'),
        ],
        defaults: [
          _item(
            id: 'default-1',
            name: 'Default 1',
            subscriptionUrl: 'https://example.com/default-group-a',
            groupName: 'Default Group A',
          ),
          _item(
            id: 'default-2',
            name: 'Default 2',
            subscriptionUrl: 'https://example.com/default-group-a',
            groupName: 'Default Group A',
          ),
        ],
      );

      expect(find.text('Default Group A (2)'), findsOneWidget);

      final importedHeader = find.byKey(
        const ValueKey('server-group-header-Imported'),
      );
      await tester.tap(
        find.descendant(
          of: importedHeader,
          matching: find.byIcon(Icons.expand_less),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Imported 1'), findsNothing);
      expect(find.text('Imported 2'), findsNothing);
      expect(find.text('Default Group A (2)'), findsOneWidget);
    },
  );

  testWidgets('multi-select keeps imported affordances while hiding defaults', (
    tester,
  ) async {
    final multiSelectNotifier = TestMultiSelectNotifier(
      initialState: {'imported-1'},
    );
    await _pumpScreen(
      tester,
      servers: [
        _server(id: 'imported-1', name: 'Imported 1'),
        _server(id: 'imported-2', name: 'Imported 2'),
      ],
      defaults: [_item(id: 'default-1', name: 'Default 1')],
      multiSelectNotifier: multiSelectNotifier,
    );

    expect(
      find.byKey(const ValueKey('server-list-default-servers-section')),
      findsNothing,
    );
    expect(find.byType(Checkbox), findsNWidgets(2));

    await tester.tap(find.text('Imported 2'));
    await tester.pumpAndSettle();
    expect(multiSelectNotifier.toggledIds, contains('imported-2'));
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<ServerConfig> servers,
  required List<DefaultServerItem> defaults,
  TestMultiSelectNotifier? multiSelectNotifier,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serverListProvider.overrideWith(() => TestServerListNotifier(servers)),
        activeServerProvider.overrideWith(() => TestActiveServerNotifier()),
        multiSelectProvider.overrideWith(
          () => multiSelectNotifier ?? TestMultiSelectNotifier(),
        ),
        sortFilterProvider.overrideWith(() => TestSortFilterNotifier()),
        latencyProvider.overrideWith(() => TestLatencyNotifier()),
        subscriptionProvider.overrideWith(() => TestSubscriptionNotifier()),
        defaultServersProvider.overrideWith(
          () => TestDefaultServersNotifier(
            DefaultServersState(
              items: defaults,
              isRefreshing: false,
              isOfflineData: false,
              lastFailureType: null,
              hasPendingRetry: false,
              retryAttempt: 0,
            ),
          ),
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

class TestServerListNotifier extends ServerListNotifier {
  TestServerListNotifier(this.servers);

  final List<ServerConfig> servers;

  @override
  Future<List<ServerConfig>> build() async => servers;
}

class TestActiveServerNotifier extends ActiveServerNotifier {
  @override
  ServerConfig? build() => null;
}

class TestMultiSelectNotifier extends MultiSelectNotifier {
  TestMultiSelectNotifier({this.initialState = const {}});

  final Set<String> initialState;
  final List<String> toggledIds = [];

  @override
  Set<String> build() => initialState;

  @override
  void toggle(String serverId) {
    toggledIds.add(serverId);
    super.toggle(serverId);
  }
}

class TestSortFilterNotifier extends SortFilterNotifier {
  @override
  SortFilterState build() => (
    sort: SortCriteria.defaultOrder,
    filter: FilterCriteria.all,
    query: '',
    protocol: null,
  );
}

class TestLatencyNotifier extends LatencyNotifier {
  @override
  Map<String, int> build() => {};
}

class TestSubscriptionNotifier extends SubscriptionNotifier {
  @override
  List<Subscription> build() => const [];
}

class TestDefaultServersNotifier extends DefaultServersNotifier {
  TestDefaultServersNotifier(this.initialState);

  final DefaultServersState initialState;

  @override
  DefaultServersState build() => initialState;
}

DefaultServerItem _item({
  required String id,
  required String name,
  String? subscriptionUrl,
  String groupName = 'Default Group',
}) {
  return DefaultServerItem(
    id: id,
    name: name,
    status: 'active',
    usedTraffic: 128,
    dataLimit: 1024,
    subscriptionUrl: subscriptionUrl ?? 'https://example.com/$id',
    expireDate: DateTime.utc(2027, 1, 1),
    isActive: true,
    serverConfig: _server(id: id, name: name, groupName: groupName),
  );
}

ServerConfig _server({
  required String id,
  required String name,
  String groupName = 'Imported',
}) {
  return ServerConfig(
    id: id,
    name: name,
    protocol: ProtocolType.vless,
    address: 'example.com',
    port: 443,
    addedAt: DateTime.utc(2026, 1, 1),
    groupName: groupName,
  );
}
