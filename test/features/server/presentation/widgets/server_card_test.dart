import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ServerConfig _server({String? rawConfig}) => ServerConfig(
      id: 's1',
      name: 'Node',
      protocol: ProtocolType.vless,
      address: 'example.com',
      port: 443,
      rawConfig: rawConfig,
      addedAt: DateTime.utc(2026, 1, 1),
    );

Future<void> _pump(WidgetTester tester, ServerConfig server) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ServerCard(server: server, isSelected: false),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a JSON badge when the server carries a raw JSON config',
      (tester) async {
    await _pump(tester, _server(rawConfig: '{"outbounds":[]}'));
    expect(find.text('JSON'), findsOneWidget);
    // Protocol badge still present.
    expect(find.text('VLESS'), findsOneWidget);
  });

  testWidgets('hides the JSON badge for field-based servers', (tester) async {
    await _pump(tester, _server());
    expect(find.text('JSON'), findsNothing);
    expect(find.text('VLESS'), findsOneWidget);
  });
}
