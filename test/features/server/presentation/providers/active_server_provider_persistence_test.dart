import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
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

ServerConfig _cfg(String id, {String name = 'Server'}) => ServerConfig(
      id: id,
      name: name,
      protocol: ProtocolType.vless,
      address: 'example.com',
      port: 443,
      rawConfig: '{"outbounds":[]}',
      addedAt: DateTime.utc(2026, 1, 1),
    );

ProviderContainer _container(SharedPreferences prefs, List<ServerConfig> list) {
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      serverListProvider.overrideWith(() => _TestServerList(list)),
    ],
  );
}

void main() {
  test('default-server selection survives a restart (via snapshot)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final defaultServer = _cfg('default-api-104-1', name: 'Germany');

    // Session 1: select a default server (not present in the imported list).
    final s1 = _container(prefs, const []);
    await s1.read(activeServerProvider.notifier).selectServer(defaultServer);
    s1.dispose();

    // Session 2 (restart): same prefs, default server still not in the list.
    final s2 = _container(prefs, const []);
    addTearDown(s2.dispose);

    final restored = s2.read(activeServerProvider);
    expect(restored, isNotNull);
    expect(restored!.id, 'default-api-104-1');
    expect(restored.name, 'Germany');
    expect(restored.rawConfig, isNotNull);
  });

  test('imported selection clears if the server was deleted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final imported = _cfg('uuid-1', name: 'Imported');

    final s1 = _container(prefs, [imported]);
    await s1.read(serverListProvider.future);
    await s1.read(activeServerProvider.notifier).selectServer(imported);
    s1.dispose();

    // Restart with the server removed from the list → selection clears.
    final s2 = _container(prefs, const []);
    addTearDown(s2.dispose);
    await s2.read(serverListProvider.future);

    expect(s2.read(activeServerProvider), isNull);
  });
}
