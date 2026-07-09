import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/active_server_card.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'neutral card stays without parked emphasis when no server selected',
    (tester) async {
      await _pumpCard(tester, server: null);

      final card = tester.widget<GlassCard>(find.byType(GlassCard));

      expect(card.glow, isFalse);
      expect(card.borderColor, isNull);
    },
  );

  testWidgets(
    'selected server gets parked highlight border and tinted surface',
    (tester) async {
      await _pumpCard(
        tester,
        server: ServerConfig(
          id: 'server-1',
          name: 'Primary',
          protocol: ProtocolType.vless,
          address: 'example.com',
          port: 443,
          addedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final card = tester.widget<GlassCard>(find.byType(GlassCard));
      final theme = Theme.of(tester.element(find.byType(ActiveServerCard)));

      expect(card.glow, isTrue);
      expect(card.borderColor, isNotNull);
      expect(
        card.borderColor!.toARGB32() & 0x00FFFFFF,
        theme.colorScheme.primary.toARGB32() & 0x00FFFFFF,
      );
      expect(card.fillAlpha, greaterThan(0.05));
    },
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required ServerConfig? server,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeServerProvider.overrideWith(
          () => _TestActiveServerNotifier(server),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ActiveServerCard()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestActiveServerNotifier extends ActiveServerNotifier {
  _TestActiveServerNotifier(this._server);

  final ServerConfig? _server;

  @override
  ServerConfig? build() => _server;
}
