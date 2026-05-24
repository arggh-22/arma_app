import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_server_startup_selection_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaultServerStartupSelectionProvider', () {
    test(
      'refreshes then selects a random connectable default server',
      () async {
        final defaultNotifier = _TestDefaultServersNotifier(
          itemsAfterRefresh: [
            _item(id: 'default-api-1', name: 'One'),
            _item(id: 'default-api-2', name: 'Two'),
          ],
        );
        final activeNotifier = _TestActiveServerNotifier();

        final container = ProviderContainer(
          overrides: [
            defaultServersProvider.overrideWith(() => defaultNotifier),
            activeServerProvider.overrideWith(() => activeNotifier),
            defaultServerRandomIndexPickerProvider.overrideWithValue(
              (max) => 1,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(defaultServerStartupSelectionProvider)
            .autoSelectRandomServer();

        expect(defaultNotifier.refreshCalls, 1);
        expect(activeNotifier.selectedIds, ['default-api-2']);
      },
    );

    test(
      'does not select anything when no connectable default servers exist',
      () async {
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
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(defaultServerStartupSelectionProvider)
            .autoSelectRandomServer();

        expect(defaultNotifier.refreshCalls, 1);
        expect(activeNotifier.selectedIds, isEmpty);
      },
    );
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
  final List<String> selectedIds = [];

  @override
  ServerConfig? build() => null;

  @override
  Future<void> selectServer(ServerConfig? server) async {
    if (server != null) {
      selectedIds.add(server.id);
    }
    state = server;
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
    serverConfig: isActive
        ? ServerConfig(
            id: id,
            name: name,
            protocol: ProtocolType.vless,
            address: 'example.com',
            port: 443,
            addedAt: DateTime.utc(2026, 1, 1),
          )
        : null,
  );
}
