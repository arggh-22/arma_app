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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _gb = 1073741824;

class _Servers extends ServerListNotifier {
  @override
  Future<List<ServerConfig>> build() async => [
    ServerConfig(
      id: 'srv-1',
      name: 'Node 1',
      protocol: ProtocolType.vless,
      address: 'a.example.com',
      port: 443,
      subscriptionId: 'sub-1',
      groupName: 'ARMA VPN',
      addedAt: DateTime.utc(2026, 1, 1),
    ),
  ];
}

class _Subs extends SubscriptionNotifier {
  @override
  List<Subscription> build() => [
    Subscription(
      id: 'sub-1',
      name: 'ARMA VPN',
      url: 'https://example.com/sub',
      totalBytes: 10 * _gb,
      downloadBytes: _gb,
      uploadBytes: 0,
      expireDate: DateTime.now().add(const Duration(days: 12)),
      lastUpdated: DateTime.utc(2026, 1, 1),
      addedAt: DateTime.utc(2026, 1, 1),
    ),
  ];
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
  testWidgets('servers screen shows the subscription data-usage bar', (
    tester,
  ) async {
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

    // Redesigned blocks show usage as text (used / total), matching home.
    expect(find.text('1.0 GB / 10 GB'), findsOneWidget);
  });
}
