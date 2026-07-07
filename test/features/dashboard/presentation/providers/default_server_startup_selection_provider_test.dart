import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_server_startup_selection_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaultServerStartupSelectionProvider', () {
    test('refreshes, latency-tests, then selects the fastest server', () async {
      final defaultNotifier = _TestDefaultServersNotifier(
        itemsAfterRefresh: [
          _item(id: 'default-api-1', name: 'One'),
          _item(id: 'default-api-2', name: 'Two'),
          _item(id: 'default-api-3', name: 'Three'),
        ],
      );
      final activeNotifier = _TestActiveServerNotifier();
      final latencyNotifier = _TestLatencyNotifier({
        'default-api-1': 200,
        'default-api-2': 50, // fastest
        'default-api-3': 300,
      });

      final container = ProviderContainer(
        overrides: [
          defaultServersProvider.overrideWith(() => defaultNotifier),
          activeServerProvider.overrideWith(() => activeNotifier),
          latencyProvider.overrideWith(() => latencyNotifier),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(defaultServerStartupSelectionProvider)
          .autoSelectBestServer();

      expect(defaultNotifier.refreshCalls, 1);
      expect(latencyNotifier.testedIds, [
        'default-api-1',
        'default-api-2',
        'default-api-3',
      ]);
      expect(activeNotifier.selectedIds, ['default-api-2']);
    });

    test('falls back to the first server when none respond', () async {
      final defaultNotifier = _TestDefaultServersNotifier(
        itemsAfterRefresh: [
          _item(id: 'default-api-1', name: 'One'),
          _item(id: 'default-api-2', name: 'Two'),
        ],
      );
      final activeNotifier = _TestActiveServerNotifier();
      final latencyNotifier = _TestLatencyNotifier({
        'default-api-1': -1,
        'default-api-2': -1,
      });

      final container = ProviderContainer(
        overrides: [
          defaultServersProvider.overrideWith(() => defaultNotifier),
          activeServerProvider.overrideWith(() => activeNotifier),
          latencyProvider.overrideWith(() => latencyNotifier),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(defaultServerStartupSelectionProvider)
          .autoSelectBestServer();

      expect(activeNotifier.selectedIds, ['default-api-1']);
    });

    test('does nothing when no connectable default servers exist', () async {
      final defaultNotifier = _TestDefaultServersNotifier(
        itemsAfterRefresh: [
          _item(id: 'default-api-expired', name: 'Expired', isActive: false),
        ],
      );
      final activeNotifier = _TestActiveServerNotifier();

      final container = ProviderContainer(
        overrides: [
          defaultServersProvider.overrideWith(() => defaultNotifier),
          activeServerProvider.overrideWith(() => activeNotifier),
          latencyProvider.overrideWith(() => _TestLatencyNotifier(const {})),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(defaultServerStartupSelectionProvider)
          .autoSelectBestServer();

      expect(defaultNotifier.refreshCalls, 1);
      expect(activeNotifier.selectedIds, isEmpty);
    });

    test('keeps an existing active server (skips on later starts)', () async {
      final existing = _config('imported-1', 'Imported');
      final defaultNotifier = _TestDefaultServersNotifier(
        itemsAfterRefresh: [_item(id: 'default-api-1', name: 'One')],
      );
      final activeNotifier = _TestActiveServerNotifier(initial: existing);

      final container = ProviderContainer(
        overrides: [
          defaultServersProvider.overrideWith(() => defaultNotifier),
          activeServerProvider.overrideWith(() => activeNotifier),
          latencyProvider.overrideWith(() => _TestLatencyNotifier(const {})),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(defaultServerStartupSelectionProvider)
          .autoSelectBestServer();

      // Skips before refreshing or selecting.
      expect(defaultNotifier.refreshCalls, 0);
      expect(activeNotifier.selectedIds, isEmpty);
    });
  });
}

class _TestDefaultServersNotifier extends DefaultServersNotifier {
  _TestDefaultServersNotifier({required this.itemsAfterRefresh});

  final List<DefaultServerItem> itemsAfterRefresh;
  int refreshCalls = 0;

  @override
  DefaultServersState build() {
    return const DefaultServersState(
      items: [],
      isRefreshing: false,
      isOfflineData: false,
      lastFailureType: null,
      hasPendingRetry: false,
      retryAttempt: 0,
    );
  }

  @override
  Future<void> refresh() async {
    refreshCalls++;
    state = DefaultServersState(
      items: itemsAfterRefresh,
      isRefreshing: false,
      isOfflineData: false,
      lastFailureType: null,
      hasPendingRetry: false,
      retryAttempt: 0,
    );
  }
}

class _TestActiveServerNotifier extends ActiveServerNotifier {
  _TestActiveServerNotifier({this.initial});

  final ServerConfig? initial;
  final List<String> selectedIds = [];

  @override
  ServerConfig? build() => initial;

  @override
  Future<void> selectServer(ServerConfig? server) async {
    if (server != null) {
      selectedIds.add(server.id);
    }
    state = server;
  }
}

class _TestLatencyNotifier extends LatencyNotifier {
  _TestLatencyNotifier(this.latencies);

  final Map<String, int> latencies;
  final List<String> testedIds = [];

  @override
  Map<String, int> build() => {};

  @override
  Future<void> testAllServers(List<ServerConfig> servers) async {
    testedIds.addAll(servers.map((s) => s.id));
    state = {...state, ...latencies};
  }
}

DefaultServerItem _item({
  required String id,
  required String name,
  bool isActive = true,
}) {
  return DefaultServerItem(
    id: id,
    name: name,
    status: isActive ? 'active' : 'expired',
    usedTraffic: 0,
    dataLimit: 1,
    subscriptionUrl: 'https://example.com/$id',
    expireDate: DateTime.utc(2027, 1, 1),
    isActive: isActive,
    serverConfig: isActive ? _config(id, name) : null,
  );
}

ServerConfig _config(String id, String name) => ServerConfig(
      id: id,
      name: name,
      protocol: ProtocolType.vless,
      address: 'example.com',
      port: 443,
      addedAt: DateTime.utc(2026, 1, 1),
    );
