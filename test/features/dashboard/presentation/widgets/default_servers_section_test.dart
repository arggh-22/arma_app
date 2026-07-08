import 'dart:async';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/default_servers_section.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/subscription_key_block.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/reveal_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_card.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders one collapsible block per API key, servers collapsed',
      (tester) async {
    final notifier = TestDefaultServersNotifier(
      _state(items: [
        _item(id: '1', name: 'A'),
        _item(id: '2', name: 'B'),
        _item(id: '3', name: 'C'),
        _item(id: '4', name: 'D'),
      ]),
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);

    // Four distinct keys → four blocks. Server cards stay hidden until a block
    // is expanded (Happ-style collapsed default).
    expect(find.byType(SubscriptionKeyBlock), findsNWidgets(4));
    expect(find.byType(ServerCard), findsNothing);
    expect(find.text('Key-1'), findsOneWidget);
    expect(find.text('Key-4'), findsOneWidget);
  });

  testWidgets('expanding a block reveals its server cards', (tester) async {
    final notifier = TestDefaultServersNotifier(
      _state(items: [_item(id: '1', name: 'Alpha')]),
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);
    expect(find.byType(ServerCard), findsNothing);

    await tester.tap(find.text('Key-1'));
    await tester.pumpAndSettle();

    expect(find.byType(ServerCard), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('per-block Ping tests only that block\'s servers',
      (tester) async {
    final latency = TestLatencyNotifier();
    final notifier = TestDefaultServersNotifier(
      _state(items: [
        _item(id: '1', name: 'A'),
        _item(id: '2', name: 'B'),
      ]),
    );

    await _pumpSection(
      tester,
      defaultServersNotifier: notifier,
      latencyNotifier: latency,
    );

    // Ping the first block only.
    await tester.tap(find.byIcon(Icons.speed).first);
    await tester.pump();

    expect(latency.bulkTested, [
      ['1'],
    ]);
  });

  testWidgets('shows the subscription data-usage text in the block header',
      (tester) async {
    const gb = 1073741824;
    final notifier = TestDefaultServersNotifier(
      _state(items: [
        _item(
          id: '1',
          name: 'A',
          subscriptionUrl: 'https://example.com/sub',
          usedTraffic: gb,
          dataLimit: 10 * gb,
        ),
        _item(
          id: '2',
          name: 'B',
          subscriptionUrl: 'https://example.com/sub',
          usedTraffic: gb,
          dataLimit: 10 * gb,
        ),
      ]),
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);

    // Both servers share one subscription → a single block, usage shown once.
    expect(find.byType(SubscriptionKeyBlock), findsOneWidget);
    expect(find.text('1.0 GB / 10 GB'), findsOneWidget);
  });

  testWidgets(
    'refresh action shows spinner while keeping the block visible',
    (tester) async {
      final refreshCompleter = Completer<void>();
      final notifier = TestDefaultServersNotifier(
        _state(items: [_item(id: '1', name: 'Visible')]),
        onRefresh: () => refreshCompleter.future,
      );

      await _pumpSection(tester, defaultServersNotifier: notifier);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.text('Key-1'), findsOneWidget);
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
      ]),
    );

    await _pumpSection(
      tester,
      defaultServersNotifier: notifier,
      activeServerNotifier: TestActiveServerNotifier(
        initialServer: selectedServer,
      ),
    );

    await tester.tap(find.text('Key-sel'));
    await tester.pumpAndSettle();

    expect(find.byType(ServerCard), findsOneWidget);
    // Selected card renders the active checkmark.
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

    await tester.tap(find.text('Key-new'));
    await tester.pumpAndSettle();
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

      await tester.tap(find.text('Key-new'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New server'));
      await tester.pumpAndSettle();

      expect(activeNotifier.selectedIds, ['new']);
      expect(connectionNotifier.events, ['disconnect', 'connect:new']);
    },
  );

  testWidgets('reveal request expands the owning block and shows the card',
      (tester) async {
    final server = _serverConfig(id: 'default-api-1', name: 'Reveal me');
    final notifier = TestDefaultServersNotifier(
      _state(items: [
        _item(id: '1', name: 'Reveal me', serverConfig: server),
      ]),
    );

    await _pumpSection(tester, defaultServersNotifier: notifier);
    // Collapsed by default — no card yet.
    expect(find.byType(ServerCard), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DefaultServersSection)),
      listen: false,
    );
    container.read(revealServerProvider.notifier).request('default-api-1');
    await tester.pumpAndSettle();

    // Block auto-expanded and the reveal request was consumed.
    expect(find.byType(ServerCard), findsOneWidget);
    expect(find.text('Reveal me'), findsOneWidget);
    expect(container.read(revealServerProvider), isNull);
  });

  testWidgets('inactive key renders as a warning block with no server cards',
      (tester) async {
    final defaultNotifier = TestDefaultServersNotifier(
      _state(items: [
        _item(id: 'expired', name: 'Expired server', isActive: false),
      ]),
    );

    await _pumpSection(tester, defaultServersNotifier: defaultNotifier);

    // The key still shows (Happ keeps problematic keys visible) but carries a
    // warning glyph and exposes no connectable server cards, even expanded.
    expect(find.byType(SubscriptionKeyBlock), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
    await tester.tap(find.text('Key-expired'));
    await tester.pumpAndSettle();
    expect(find.byType(ServerCard), findsNothing);
    // Not the global empty-state — that only shows when there are zero keys.
    expect(find.text('No default servers available'), findsNothing);
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
  int usedTraffic = 1024,
  int dataLimit = 4096,
  String? subscriptionUrl,
}) {
  final config = serverConfig ?? _serverConfig(id: id, name: name);
  return DefaultServerItem(
    id: id,
    name: name,
    // Distinct from the server name so block-header vs card assertions don't
    // collide on the same string.
    keyName: 'Key-$id',
    status: status,
    usedTraffic: usedTraffic,
    dataLimit: dataLimit,
    subscriptionUrl: subscriptionUrl ?? 'https://example.com/$id',
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
