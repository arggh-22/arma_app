import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
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
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/subscription_key_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Two distinct subscriptions that share the same profile-title ("ARMA VPN") —
// the arma admin panel can hand out several keys under one brand name.
ServerConfig _srv(String id, String subId) => ServerConfig(
  id: id,
  name: id,
  protocol: ProtocolType.vless,
  address: '$id.example.com',
  port: 443,
  subscriptionId: subId,
  groupName: 'ARMA VPN',
  addedAt: DateTime.utc(2026, 1, 1),
);

Subscription _sub(String id) => Subscription(
  id: id,
  name: 'ARMA VPN',
  url: 'https://example.com/$id',
  lastUpdated: DateTime.utc(2026, 1, 1),
  addedAt: DateTime.utc(2026, 1, 1),
);

class _Servers extends ServerListNotifier {
  @override
  Future<List<ServerConfig>> build() async => [
    _srv('a1', 'sub-a'),
    _srv('b1', 'sub-b'),
  ];
}

class _Subs extends SubscriptionNotifier {
  @override
  List<Subscription> build() => [_sub('sub-a'), _sub('sub-b')];
}

class _Active extends ActiveServerNotifier {
  @override
  ServerConfig? build() => null;
}

class _Latency extends LatencyNotifier {
  @override
  Map<String, int> build() => {};
}

class _SortFilter extends SortFilterNotifier {
  @override
  SortFilterState build() => (
    sort: SortCriteria.defaultOrder,
    filter: FilterCriteria.all,
    query: '',
    protocol: null,
  );
}

class _Defaults extends DefaultServersNotifier {
  @override
  DefaultServersState build() => const DefaultServersState.initial();
}

void main() {
  testWidgets(
    'two subscriptions sharing a name render as separate blocks (no merge/crash)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            serverListProvider.overrideWith(() => _Servers()),
            subscriptionProvider.overrideWith(() => _Subs()),
            activeServerProvider.overrideWith(() => _Active()),
            latencyProvider.overrideWith(() => _Latency()),
            sortFilterProvider.overrideWith(() => _SortFilter()),
            multiSelectProvider.overrideWith(() => MultiSelectNotifier()),
            defaultServersProvider.overrideWith(() => _Defaults()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ServerListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No sliver child-order assertion, and two distinct blocks (not one).
      expect(tester.takeException(), isNull);
      expect(find.byType(SubscriptionKeyBlock), findsNWidgets(2));
    },
  );
}
