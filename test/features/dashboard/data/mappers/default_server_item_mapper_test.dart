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

    test('mapAll expands sub-link payload into per-server rows', () {
      final key = DefaultServerKey(
        id: 7,
        name: 'Key 7',
        keyBody: [
          'vless://11111111-1111-1111-1111-111111111111@a.example:443?type=tcp&security=tls#Alpha',
          'trojan://password@b.example:443?security=tls#Beta',
        ].join('\n'),
        subscriptionUrl: 'https://example.com/sub/7',
        expireDate: DateTime.utc(2026, 12, 1),
        isActive: true,
        status: 'active',
        usedTraffic: 55,
        dataLimit: 100,
      );

      final items = DefaultServerItemMapper.mapAll(key);

      expect(items, hasLength(2));
      expect(items[0].id, 'default-api-7-1');
      expect(items[1].id, 'default-api-7-2');
      expect(items[0].name, 'Alpha');
      expect(items[1].name, 'Beta');
      expect(items[0].serverConfig, isNotNull);
      expect(items[1].serverConfig, isNotNull);
      expect(items[0].serverConfig!.id, items[0].id);
      expect(items[1].serverConfig!.id, items[1].id);
      expect(items[0].serverConfig!.name, 'Alpha');
      expect(items[1].serverConfig!.name, 'Beta');
      expect(items[0].status, key.status);
      expect(items[1].status, key.status);
    });

    test('mapAll keeps single-link name/id behavior', () {
      final key = DefaultServerKey(
        id: 5,
        name: 'Single Link',
        keyBody:
            'vless://11111111-1111-1111-1111-111111111111@one.example:443?type=tcp&security=tls#ParsedName',
        subscriptionUrl: 'https://example.com/sub/5',
        expireDate: DateTime.utc(2026, 12, 1),
        isActive: true,
        status: 'active',
        usedTraffic: 0,
        dataLimit: 1,
      );

      final items = DefaultServerItemMapper.mapAll(key);

      expect(items, hasLength(1));
      expect(items.single.id, 'default-api-5');
      expect(items.single.name, 'Single Link');
      expect(items.single.serverConfig, isNotNull);
      expect(items.single.serverConfig!.id, 'default-api-5');
      expect(items.single.serverConfig!.name, 'Single Link');
    });
  });
}
