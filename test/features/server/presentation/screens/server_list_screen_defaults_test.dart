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
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/empty_server_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders defaults section above imported groups in normal mode', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      servers: [_server(id: 'imported-1', name: 'Imported 1')],
      defaults: [_item(id: 'default-1', name: 'Default 1')],
    );

    final defaultTop = tester.getTopLeft(find.text('Default 1')).dy;
    final importedTop = tester.getTopLeft(find.text('Imported (1)')).dy;

    expect(defaultTop, lessThan(importedTop));
    expect(
      find.byKey(const ValueKey('server-list-default-servers-section')),
      findsOneWidget,
    );
  });

  testWidgets(
    'renders defaults section when imported list is empty but defaults exist',
    (tester) async {
      await _pumpScreen(
        tester,
        servers: const [],
        defaults: [_item(id: 'default-1', name: 'Default 1')],
      );

      expect(
        find.byKey(const ValueKey('server-list-default-servers-section')),
        findsOneWidget,
      );
      expect(find.text('Default 1'), findsOneWidget);
      expect(find.byType(EmptyServerState), findsNothing);
    },
  );

  testWidgets(
    'shows empty state only when imported list and defaults are both empty',
    (tester) async {
      await _pumpScreen(tester, servers: const [], defaults: const []);

      expect(find.byType(EmptyServerState), findsOneWidget);
      expect(
        find.byKey(const ValueKey('server-list-default-servers-section')),
        findsNothing,
      );
    },
  );

  testWidgets('hides defaults section when multi-select mode is active', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpScreen(
      tester,
      servers: [_server(id: 'imported-1', name: 'Imported 1')],
      defaults: [_item(id: 'default-1', name: 'Default 1')],
      selectedIds: {'imported-1'},
    );

    expect(
      find.byKey(const ValueKey('server-list-default-servers-section')),
      findsNothing,
    );
    expect(find.text('Default 1'), findsNothing);
  });

  testWidgets('defaults section is expanded by default and supports toggle', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      servers: [_server(id: 'imported-1', name: 'Imported 1')],
      defaults: [_item(id: 'default-1', name: 'Default 1')],
    );

    expect(find.text('Default 1'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('server-list-default-servers-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Default 1'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('server-list-default-servers-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Default 1'), findsOneWidget);
  });

  testWidgets('renders defaults as grouped per-subscription sublists', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      servers: [_server(id: 'imported-1', name: 'Imported 1')],
      defaults: [
        _item(
          id: 'default-a-1',
          name: 'Default A1',
          subscriptionUrl: 'https://example.com/sub-a',
          groupName: 'Default Key A',
        ),
        _item(
          id: 'default-a-2',
          name: 'Default A2',
          subscriptionUrl: 'https://example.com/sub-a',
          groupName: 'Default Key A',
        ),
        _item(
          id: 'default-b-1',
          name: 'Default B1',
          subscriptionUrl: 'https://example.com/sub-b',
          groupName: 'Default Key B',
        ),
      ],
    );

    expect(
      find.byKey(
        const ValueKey(
          'server-list-default-subgroup-header-https://example.com/sub-a',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Default Key A (2)'), findsOneWidget);
    expect(find.text('Default Key B (1)'), findsOneWidget);
  });

  testWidgets('default subgroups support independent collapse and expand', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      servers: [_server(id: 'imported-1', name: 'Imported 1')],
      defaults: [
        _item(
          id: 'default-a-1',
          name: 'Default A1',
          subscriptionUrl: 'https://example.com/sub-a',
          groupName: 'Default Key A',
        ),
        _item(
          id: 'default-a-2',
          name: 'Default A2',
          subscriptionUrl: 'https://example.com/sub-a',
          groupName: 'Default Key A',
        ),
        _item(
          id: 'default-b-1',
          name: 'Default B1',
          subscriptionUrl: 'https://example.com/sub-b',
          groupName: 'Default Key B',
        ),
      ],
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'server-list-default-subgroup-toggle-https://example.com/sub-a',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Default A1'), findsNothing);
    expect(find.text('Default A2'), findsNothing);
    expect(find.text('Default B1'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey(
          'server-list-default-subgroup-toggle-https://example.com/sub-a',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Default A1'), findsOneWidget);
    expect(find.text('Default A2'), findsOneWidget);
  });

  testWidgets('default subgroups start expanded when screen is opened', (
    tester,
  ) async {
    const subgroupUrl = 'https://example.com/sub-a';

    await _pumpScreen(
      tester,
      servers: [_server(id: 'imported-1', name: 'Imported 1')],
      defaults: [
        _item(
          id: 'default-a-1',
          name: 'Default A1',
          subscriptionUrl: subgroupUrl,
          groupName: 'Default Key A',
        ),
      ],
    );

    await tester.tap(
      find.byKey(
        const ValueKey('server-list-default-subgroup-toggle-$subgroupUrl'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Default A1'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpScreen(
      tester,
      servers: [_server(id: 'imported-1', name: 'Imported 1')],
      defaults: [
        _item(
          id: 'default-a-1',
          name: 'Default A1',
          subscriptionUrl: subgroupUrl,
          groupName: 'Default Key A',
        ),
      ],
    );

    expect(find.text('Default A1'), findsOneWidget);
  });

  testWidgets('selected default row shows selected-state emphasis', (
    tester,
  ) async {
    final selected = _server(id: 'default-1', name: 'Default 1');
    await _pumpScreen(
      tester,
      servers: [_server(id: 'imported-1', name: 'Imported 1')],
      defaults: [_item(id: 'default-1', name: 'Default 1', config: selected)],
      activeServer: selected,
    );

    expect(
      find.byKey(
        const ValueKey('server-list-default-server-selected-default-1'),
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<ServerConfig> servers,
  required List<DefaultServerItem> defaults,
  Set<String> selectedIds = const {},
  ServerConfig? activeServer,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serverListProvider.overrideWith(() => TestServerListNotifier(servers)),
        activeServerProvider.overrideWith(
          () => TestActiveServerNotifier(initialServer: activeServer),
        ),
        multiSelectProvider.overrideWith(
          () => TestMultiSelectNotifier(initialState: selectedIds),
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
  TestActiveServerNotifier({this.initialServer});

  final ServerConfig? initialServer;

  @override
  ServerConfig? build() => initialServer;
}

class TestMultiSelectNotifier extends MultiSelectNotifier {
  TestMultiSelectNotifier({required this.initialState});

  final Set<String> initialState;

  @override
  Set<String> build() => initialState;
}

class TestSortFilterNotifier extends SortFilterNotifier {
  @override
  ({SortCriteria sort, FilterCriteria filter}) build() =>
      (sort: SortCriteria.defaultOrder, filter: FilterCriteria.all);
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
  ServerConfig? config,
  String? subscriptionUrl,
  String groupName = 'Default Group',
}) {
  return DefaultServerItem(
    id: id,
    name: name,
    status: 'active',
    usedTraffic: 200,
    dataLimit: 1000,
    subscriptionUrl: subscriptionUrl ?? 'https://example.com/$id',
    expireDate: DateTime.utc(2027, 1, 1),
    isActive: true,
    serverConfig: config ?? _server(id: id, name: name, groupName: groupName),
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
