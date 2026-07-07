import 'dart:async';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/default_servers_section.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_card.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders all default servers as cards', (tester) async {
    final notifier = TestDefaultServersNotifier(
      _state(items: [
        _item(id: '1', name: 'A'),
        _item(id: '2', name: 'B'),
        _item(id: '3', name: 'C'),
        _item(id: '4', name: 'D'),
      ]),
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);

    expect(find.byType(ServerCard), findsNWidgets(4));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('only shows protocol chips present in the list', (tester) async {
    // All default configs are VLESS, so only the VLESS chip should appear.
    final notifier = TestDefaultServersNotifier(
      _state(items: [
        _item(id: '1', name: 'A'),
        _item(id: '2', name: 'B'),
      ]),
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);

    expect(find.byKey(const Key('protocol-filter-all')), findsOneWidget);
    expect(find.byKey(const Key('protocol-filter-vless')), findsOneWidget);
    expect(find.byKey(const Key('protocol-filter-vmess')), findsNothing);
    expect(find.byKey(const Key('protocol-filter-trojan')), findsNothing);
  });

  testWidgets('Test All triggers latency testing for default servers',
      (tester) async {
    final latency = TestLatencyNotifier();
    final notifier = TestDefaultServersNotifier(
      _state(items: [_item(id: '1', name: 'A'), _item(id: '2', name: 'B')]),
    );

    await _pumpSection(
      tester,
      defaultServersNotifier: notifier,
      latencyNotifier: latency,
    );

    await tester.tap(find.byKey(const Key('default-servers-test-all')));
    await tester.pump();

    expect(latency.bulkTested, [
      ['1', '2'],
    ]);
  });

  testWidgets('search filters the default servers list', (tester) async {
    final notifier = TestDefaultServersNotifier(
      _state(items: [
        _item(id: 'us', name: 'USA'),
        _item(id: 'de', name: 'Germany'),
      ]),
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);

    expect(find.text('USA'), findsOneWidget);
    expect(find.text('Germany'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('server-search-field')),
      'usa',
    );
    await tester.pumpAndSettle();

    expect(find.text('USA'), findsOneWidget);
    expect(find.text('Germany'), findsNothing);
  });

  testWidgets(
    'refresh action shows spinner while keeping current cards visible',
    (tester) async {
      final refreshCompleter = Completer<void>();
      final notifier = TestDefaultServersNotifier(
        _state(items: [_item(id: '1', name: 'Visible')]),
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
      _state(
        items: const [],
        lastFailureType: DefaultServersFailureType.offline,
      ),
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);

    expect(find.text('No default servers available'), findsOneWidget);
    expect(
      find.text(
        'No connection and no cached servers yet. Tap Refresh when online.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows timeout failure snackbar on refresh failure',
      (tester) async {
    late TestDefaultServersNotifier notifier;
    notifier = TestDefaultServersNotifier(
      _state(items: [_item(id: '1', name: 'X')]),
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

  testWidgets('matching active server card shows selected indicator',
      (tester) async {
    final selectedServer = _serverConfig(id: 'sel', name: 'Selected');
    final notifier = TestDefaultServersNotifier(
      _state(items: [
        _item(id: 'sel', name: 'Selected', serverConfig: selectedServer),
        _item(id: 'other', name: 'Other'),
      ]),
    );

    await _pumpSection(
      tester,
      defaultServersNotifier: notifier,
      activeServerNotifier: TestActiveServerNotifier(
        initialServer: selectedServer,
      ),
    );

    expect(find.byType(ServerCard), findsNWidgets(2));
    // Selected card renders the active checkmark; only one is selected.
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('disconnected tap selects active server only', (tester) async {
    final defaultNotifier = TestDefaultServersNotifier(
      _state(items: [_item(id: 'new', name: 'New server')]),
    );
    final activeNotifier = TestActiveServerNotifier();
    final connectionNotifier = TestConnectionNotifier();

    await _pumpSection(
      tester,
      defaultServersNotifier: defaultNotifier,
      activeServerNotifier: activeNotifier,
      connectionNotifier: connectionNotifier,
    );

    await tester.tap(find.text('New server'));
    await tester.pumpAndSettle();

    expect(activeNotifier.selectedIds, ['new']);
    expect(connectionNotifier.events, isEmpty);
  });

  testWidgets(
    'connected tap on different server selects then reconnects',
    (tester) async {
      final oldServer = _serverConfig(id: 'old', name: 'Old server');
      final newServer = _serverConfig(id: 'new', name: 'New server');
      final defaultNotifier = TestDefaultServersNotifier(
        _state(items: [
          _item(id: 'new', name: 'New server', serverConfig: newServer),
        ]),
      );
      final activeNotifier = TestActiveServerNotifier(initialServer: oldServer);
      final connectionNotifier = TestConnectionNotifier(
        initialState: Connected(
          serverName: 'Old server',
          connectedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      await _pumpSection(
        tester,
        defaultServersNotifier: defaultNotifier,
        activeServerNotifier: activeNotifier,
        connectionNotifier: connectionNotifier,
      );

      await tester.tap(find.text('New server'));
      await tester.pumpAndSettle();

      expect(activeNotifier.selectedIds, ['new']);
      expect(connectionNotifier.events, ['disconnect', 'connect:new']);
    },
  );

  testWidgets('inactive servers are not rendered', (tester) async {
    final defaultNotifier = TestDefaultServersNotifier(
      _state(items: [
        _item(id: 'expired', name: 'Expired server', isActive: false),
      ]),
    );

    await _pumpSection(tester, defaultServersNotifier: defaultNotifier);

    expect(find.text('Expired server'), findsNothing);
    expect(find.byType(ServerCard), findsNothing);
    // Falls back to the empty-state guidance.
    expect(find.text('No default servers available'), findsOneWidget);
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required TestDefaultServersNotifier defaultServersNotifier,
  TestActiveServerNotifier? activeServerNotifier,
  TestConnectionNotifier? connectionNotifier,
  TestLatencyNotifier? latencyNotifier,
}) async {
  final activeNotifier = activeServerNotifier ?? TestActiveServerNotifier();
  final connection = connectionNotifier ?? TestConnectionNotifier();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultServersProvider.overrideWith(() => defaultServersNotifier),
        activeServerProvider.overrideWith(() => activeNotifier),
        connectionProvider.overrideWith(() => connection),
        if (latencyNotifier != null)
          latencyProvider.overrideWith(() => latencyNotifier),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: DefaultServersSection(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

DefaultServersState _state({
  required List<DefaultServerItem> items,
  DefaultServersFailureType? lastFailureType,
}) {
  return DefaultServersState(
    items: items,
    isRefreshing: false,
    isOfflineData: false,
    lastFailureType: lastFailureType,
    hasPendingRetry: false,
    retryAttempt: 0,
  );
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

class TestLatencyNotifier extends LatencyNotifier {
  final List<List<String>> bulkTested = [];

  @override
  Map<String, int> build() => {};

  @override
  Future<void> testAllServers(List<ServerConfig> servers) async {
    bulkTested.add(servers.map((s) => s.id).toList());
  }
}

class TestActiveServerNotifier extends ActiveServerNotifier {
  TestActiveServerNotifier({this.initialServer});

  final ServerConfig? initialServer;
  final List<String> selectedIds = [];

  @override
  ServerConfig? build() => initialServer;

  @override
  Future<void> selectServer(ServerConfig? server) async {
    if (server != null) {
      selectedIds.add(server.id);
    }
    state = server;
  }
}

class TestConnectionNotifier extends ConnectionNotifier {
  TestConnectionNotifier({this.initialState = const Disconnected()});

  final ConnectionStatus initialState;
  final List<String> events = [];

  @override
  ConnectionStatus build() => initialState;

  @override
  Future<void> connect(ServerConfig server, {bool isManual = true}) async {
    events.add('connect:${server.id}');
    state = Connected(serverName: server.name, connectedAt: DateTime.now());
  }

  @override
  Future<void> disconnect() async {
    events.add('disconnect');
    state = const Disconnected();
  }
}

DefaultServerItem _item({
  required String id,
  required String name,
  String status = 'active',
  bool isActive = true,
  ServerConfig? serverConfig,
}) {
  final config = serverConfig ?? _serverConfig(id: id, name: name);
  return DefaultServerItem(
    id: id,
    name: name,
    status: status,
    usedTraffic: 1024,
    dataLimit: 4096,
    subscriptionUrl: 'https://example.com/$id',
    expireDate: DateTime.utc(2027, 1, 1),
    isActive: isActive,
    serverConfig: config,
  );
}

ServerConfig _serverConfig({required String id, required String name}) {
  return ServerConfig(
    id: id,
    name: name,
    protocol: ProtocolType.vless,
    address: 'example.com',
    port: 443,
    addedAt: DateTime.utc(2026, 1, 1),
  );
}
