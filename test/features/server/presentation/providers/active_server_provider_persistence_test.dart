import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestServerList extends ServerListNotifier {
  _TestServerList(this.servers);
  final List<ServerConfig> servers;

  @override
  Future<List<ServerConfig>> build() async => servers;
}

class _TestDefaultServers extends DefaultServersNotifier {
  _TestDefaultServers(this.items);
  final List<DefaultServerItem> items;

  @override
  DefaultServersState build() => DefaultServersState(
    items: items,
    isRefreshing: false,
    isOfflineData: false,
    lastFailureType: null,
    hasPendingRetry: false,
    retryAttempt: 0,
  );
}

ServerConfig _cfg(String id, {String name = 'Server', String addr = 'a.com'}) =>
    ServerConfig(
      id: id,
      name: name,
      protocol: ProtocolType.vless,
      address: addr,
      port: 443,
      rawConfig: '{"outbounds":[]}',
      addedAt: DateTime.utc(2026, 1, 1),
    );

DefaultServerItem _item(ServerConfig cfg) => DefaultServerItem(
  id: cfg.id,
  name: cfg.name,
  status: 'active',
  usedTraffic: 0,
  dataLimit: 1,
  subscriptionUrl: 'https://example.com/sub',
  expireDate: DateTime.utc(2027, 1, 1),
  isActive: true,
  serverConfig: cfg,
);

ProviderContainer _container(
  SharedPreferences prefs, {
  List<ServerConfig> imported = const [],
  List<DefaultServerItem> defaults = const [],
}) {
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      serverListProvider.overrideWith(() => _TestServerList(imported)),
      defaultServersProvider.overrideWith(() => _TestDefaultServers(defaults)),
    ],
  );
}

void main() {
  test(
    'default-server selection survives a restart (snapshot fallback)',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final defaultServer = _cfg('default-api-104-1', name: 'Germany');

      final s1 = _container(prefs);
      await s1.read(activeServerProvider.notifier).selectServer(defaultServer);
      s1.dispose();

      // Restart with the default list not yet loaded → restored from snapshot.
      final s2 = _container(prefs);
      addTearDown(s2.dispose);

      final restored = s2.read(activeServerProvider);
      expect(restored, isNotNull);
      expect(restored!.id, 'default-api-104-1');
      expect(restored.name, 'Germany');
    },
  );

  test(
    'default-server resolves fresh from the live list when present',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final stale = _cfg('default-api-104-1', name: 'Germany', addr: 'old.com');
      final fresh = _cfg('default-api-104-1', name: 'Germany', addr: 'new.com');

      final s1 = _container(prefs);
      await s1.read(activeServerProvider.notifier).selectServer(stale);
      s1.dispose();

      // Live list has the same id with a fresh address → prefer the live one.
      final s2 = _container(prefs, defaults: [_item(fresh)]);
      addTearDown(s2.dispose);
      expect(s2.read(activeServerProvider)?.address, 'new.com');
    },
  );

  test('default-server clears when it is gone from the loaded list', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final defaultServer = _cfg('default-api-104-1');

    final s1 = _container(prefs);
    await s1.read(activeServerProvider.notifier).selectServer(defaultServer);
    s1.dispose();

    // List loaded but this server is no longer present (expired/removed).
    final s2 = _container(prefs, defaults: [_item(_cfg('default-api-999-1'))]);
    addTearDown(s2.dispose);
    expect(s2.read(activeServerProvider), isNull);
  });

  test('imported selection clears if the server was deleted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final imported = _cfg('uuid-1', name: 'Imported');

    final s1 = _container(prefs, imported: [imported]);
    await s1.read(serverListProvider.future);
    await s1.read(activeServerProvider.notifier).selectServer(imported);
    s1.dispose();

    final s2 = _container(prefs);
    addTearDown(s2.dispose);
    await s2.read(serverListProvider.future);
    expect(s2.read(activeServerProvider), isNull);
  });
}
