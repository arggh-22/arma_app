import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_list_default_servers_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tap selects server when disconnected', (tester) async {
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

  testWidgets('connected tap on different server reconnects in parity order', (
    tester,
  ) async {
    final oldServer = _server(id: 'old', name: 'Old server');
    final newServer = _server(id: 'new', name: 'New server');
    final defaultNotifier = TestDefaultServersNotifier(
      DefaultServersState(
        items: [_item(id: 'new', name: 'New server', config: newServer)],
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
        serverName: oldServer.name,
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
  });

  testWidgets('connected tap on already selected server avoids reconnect', (
    tester,
  ) async {
    final selected = _server(id: 'same', name: 'Same server');
    final defaultNotifier = TestDefaultServersNotifier(
      DefaultServersState(
        items: [_item(id: 'same', name: 'Same server', config: selected)],
        isRefreshing: false,
        isOfflineData: false,
        lastFailureType: null,
        hasPendingRetry: false,
        retryAttempt: 0,
      ),
    );
    final activeNotifier = TestActiveServerNotifier(initialServer: selected);
    final connectionNotifier = TestConnectionNotifier(
      initialState: Connected(
        serverName: selected.name,
        connectedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await _pumpSection(
      tester,
      defaultServersNotifier: defaultNotifier,
      activeServerNotifier: activeNotifier,
      connectionNotifier: connectionNotifier,
    );

    await tester.tap(find.text('Same server'));
    await tester.pumpAndSettle();

    expect(activeNotifier.selectedIds, ['same']);
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
          body: ServerListDefaultServersSection(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class TestDefaultServersNotifier extends DefaultServersNotifier {
  TestDefaultServersNotifier(this.initialState);

  final DefaultServersState initialState;

  @override
  DefaultServersState build() => initialState;
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
  ServerConfig? config,
}) {
  return DefaultServerItem(
    id: id,
    name: name,
    status: 'active',
    usedTraffic: 256,
    dataLimit: 1024,
    subscriptionUrl: 'https://example.com/$id',
    expireDate: DateTime.utc(2027, 1, 1),
    isActive: true,
    serverConfig: config ?? _server(id: id, name: name),
  );
}

ServerConfig _server({required String id, required String name}) {
  return ServerConfig(
    id: id,
    name: name,
    protocol: ProtocolType.vless,
    address: 'example.com',
    port: 443,
    addedAt: DateTime.utc(2026, 1, 1),
  );
}
