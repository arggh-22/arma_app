import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/data/mappers/default_server_item_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultServerItemMapper', () {
    test('maps fields and normalizes deterministic server id', () {
      final key = DefaultServerKey(
        id: 42,
        name: 'Default #42',
        keyBody: 'vless://uuid@server.com:443?type=tcp&security=tls#VlessTest',
        subscriptionUrl: 'https://example.com/sub/42',
        expireDate: DateTime.utc(2026, 12, 1),
        isActive: true,
        status: 'active',
        usedTraffic: 1024,
        dataLimit: 4096,
      );

      final item = DefaultServerItemMapper.map(key);

      expect(item.id, 'default-api-42');
      expect(item.name, key.name);
      expect(item.subscriptionUrl, key.subscriptionUrl);
      expect(item.expireDate, key.expireDate);
      expect(item.status, key.status);
      expect(item.usedTraffic, key.usedTraffic);
      expect(item.dataLimit, key.dataLimit);
      expect(item.serverConfig, isNotNull);
      expect(item.serverConfig!.id, 'default-api-42');
      expect(item.isConnectable, isTrue);
    });

    test('invalid key body maps to non-connectable item', () {
      final key = DefaultServerKey(
        id: 9,
        name: 'Broken',
        keyBody: 'invalid://payload',
        subscriptionUrl: 'https://example.com/sub/9',
        expireDate: DateTime.utc(2026, 7, 1),
        isActive: true,
        status: 'active',
        usedTraffic: 1,
        dataLimit: 2,
      );

      final item = DefaultServerItemMapper.map(key);

      expect(item.id, 'default-api-9');
      expect(item.serverConfig, isNull);
      expect(item.isConnectable, isFalse);
    });
  });
}
