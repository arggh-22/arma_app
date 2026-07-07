import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/connect_button.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disconnected: uppercase status word and power glyph', (
    tester,
  ) async {
    await _pumpButton(tester, const Disconnected());

    expect(find.text('NOT CONNECTED'), findsOneWidget);
    expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
  });

  testWidgets('connected: uppercase status word and shield glyph', (
    tester,
  ) async {
    await _pumpButton(
      tester,
      Connected(serverName: 'Tokyo', connectedAt: DateTime.now()),
    );

    expect(find.text('CONNECTED'), findsOneWidget);
    expect(find.byIcon(Icons.shield), findsOneWidget);
  });

  testWidgets('tap while connected requests disconnect', (tester) async {
    final notifier = _TestConnectionNotifier(
      Connected(serverName: 'Tokyo', connectedAt: DateTime.now()),
    );
    await _pumpButton(tester, null, notifier: notifier);

    await tester.tap(find.byType(ConnectButton));
    await tester.pumpAndSettle();

    expect(notifier.disconnectCalls, 1);
  });

  testWidgets('tap while disconnected connects to the active server', (
    tester,
  ) async {
    final notifier = _TestConnectionNotifier(const Disconnected());
    await _pumpButton(
      tester,
      null,
      notifier: notifier,
      activeServer: _server(),
    );

    await tester.tap(find.byType(ConnectButton));
    await tester.pumpAndSettle();

    expect(notifier.connectedServers.map((s) => s.id), ['s1']);
  });
}

ServerConfig _server() => ServerConfig(
  id: 's1',
  name: 'Tokyo',
  protocol: ProtocolType.vless,
  address: 'example.com',
  port: 443,
  addedAt: DateTime.utc(2026, 1, 1),
);

Future<void> _pumpButton(
  WidgetTester tester,
  ConnectionStatus? status, {
  _TestConnectionNotifier? notifier,
  ServerConfig? activeServer,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectionProvider.overrideWith(
          () => notifier ?? _TestConnectionNotifier(status!),
        ),
        activeServerProvider.overrideWith(
          () => _TestActiveServerNotifier(activeServer),
        ),
        serverListProvider.overrideWith(
          () => _TestServerListNotifier(
            activeServer == null ? const [] : [activeServer],
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: ConnectButton())),
      ),
    ),
  );
  // Let the one-shot shimmer animation finish so no timers stay pending.
  await tester.pumpAndSettle();
}

class _TestConnectionNotifier extends ConnectionNotifier {
  _TestConnectionNotifier(this.initialStatus);

  final ConnectionStatus initialStatus;
  final List<ServerConfig> connectedServers = [];
  int disconnectCalls = 0;

  @override
  ConnectionStatus build() => initialStatus;

  @override
  Future<void> connect(ServerConfig server, {bool isManual = true}) async {
    connectedServers.add(server);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
  }
}

class _TestActiveServerNotifier extends ActiveServerNotifier {
  _TestActiveServerNotifier(this._server);

  final ServerConfig? _server;

  @override
  ServerConfig? build() => _server;

  @override
  Future<void> selectServer(ServerConfig? server) async {
    state = server;
  }
}

class _TestServerListNotifier extends ServerListNotifier {
  _TestServerListNotifier(this.servers);

  final List<ServerConfig> servers;

  @override
  Future<List<ServerConfig>> build() async => servers;
}
