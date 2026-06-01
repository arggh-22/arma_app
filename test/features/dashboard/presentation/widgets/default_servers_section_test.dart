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

    // The show-all sheet uses a lazily-built scrollable list; the 4th item
    // may be below the fold, so scroll it into view before asserting.
    await tester.scrollUntilVisible(
      find.text('D'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
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

  testWidgets('matching active server tile gets selected visual highlight', (
    tester,
  ) async {
    final selectedServer = _serverConfig(id: 'sel', name: 'Selected');
    final notifier = TestDefaultServersNotifier(
      DefaultServersState(
        items: [
          _item(id: 'sel', name: 'Selected', serverConfig: selectedServer),
          _item(id: 'other', name: 'Other'),
        ],
        isRefreshing: false,
        isOfflineData: false,
        lastFailureType: null,
        hasPendingRetry: false,
        retryAttempt: 0,
      ),
    );

    await _pumpSection(
      tester,
      defaultServersNotifier: notifier,
      activeServerNotifier: TestActiveServerNotifier(initialServer: selectedServer),
    );

    final selectedMaterial = _tileMaterialForName(tester, 'Selected');
    final otherMaterial = _tileMaterialForName(tester, 'Other');
    final theme = Theme.of(tester.element(find.byType(DefaultServersSection)));

    final selectedShape = selectedMaterial.shape as RoundedRectangleBorder;
    final otherShape = otherMaterial.shape as RoundedRectangleBorder;

    expect(selectedShape.side.width, greaterThan(0));
    expect(selectedMaterial.color, isNot(theme.colorScheme.surfaceContainerLow));
    expect(otherShape.side.width, equals(0));
    expect(otherMaterial.color, theme.colorScheme.surfaceContainerLow);
  });

  testWidgets('disconnected tap selects active server only', (tester) async {
    final defaultNotifier = TestDefaultServersNotifier(
      DefaultServersState(
        items: [_item(id: 'new', name: 'New server')],
        isRefreshing: false,
        isOfflineData: false,
        lastFailureType: null,
        hasPendingRetry: false,
        retryAttempt: 0,
      ),
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
        DefaultServersState(
          items: [
            _item(id: 'new', name: 'New server', serverConfig: newServer),
          ],
          isRefreshing: false,
          isOfflineData: false,
          lastFailureType: null,
          hasPendingRetry: false,
          retryAttempt: 0,
        ),
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

  testWidgets('non-active items remain non-interactive', (tester) async {
    final defaultNotifier = TestDefaultServersNotifier(
      DefaultServersState(
        items: [
          _item(
            id: 'expired',
            name: 'Expired server',
            status: 'expired',
            isActive: false,
          ),
        ],
        isRefreshing: false,
        isOfflineData: false,
        lastFailureType: null,
        hasPendingRetry: false,
        retryAttempt: 0,
      ),
    );
    final activeNotifier = TestActiveServerNotifier();
    final connectionNotifier = TestConnectionNotifier();

    await _pumpSection(
      tester,
      defaultServersNotifier: defaultNotifier,
      activeServerNotifier: activeNotifier,
      connectionNotifier: connectionNotifier,
    );

    await tester.tap(find.text('Expired server'));
    await tester.pumpAndSettle();

    expect(activeNotifier.selectedIds, isEmpty);
    expect(connectionNotifier.events, isEmpty);
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required TestDefaultServersNotifier defaultServersNotifier,
  TestActiveServerNotifier? activeServerNotifier,
  TestConnectionNotifier? connectionNotifier,
}) async {
  final activeNotifier = activeServerNotifier ?? TestActiveServerNotifier();
  final connection = connectionNotifier ?? TestConnectionNotifier();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultServersProvider.overrideWith(() => defaultServersNotifier),
        activeServerProvider.overrideWith(() => activeNotifier),
        connectionProvider.overrideWith(() => connection),
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

Material _tileMaterialForName(WidgetTester tester, String name) {
  final candidate = find.ancestor(of: find.text(name), matching: find.byType(Material));
  return tester.widget<Material>(candidate.first);
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
