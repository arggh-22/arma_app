import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

void main() {
  group('ServerConfig entity', () {
    final now = DateTime(2026, 1, 1);

    test('can be created with required fields', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Test Server',
        protocol: ProtocolType.vless,
        address: '192.168.1.1',
        port: 443,
        addedAt: now,
      );

      expect(config.id, 'test-id');
      expect(config.name, 'Test Server');
      expect(config.protocol, ProtocolType.vless);
      expect(config.address, '192.168.1.1');
      expect(config.port, 443);
      expect(config.addedAt, now);
    });

    test('has correct default values', () {
      final config = ServerConfig(
        id: 'id',
        name: 'name',
        protocol: ProtocolType.vmess,
        address: 'addr',
        port: 80,
        addedAt: now,
      );

      expect(config.encryption, 'none');
      expect(config.network, 'tcp');
      expect(config.security, 'none');
      expect(config.alterId, 0);
      expect(config.groupName, 'Manual');
      expect(config.uuid, isNull);
      expect(config.password, isNull);
      expect(config.sni, isNull);
      expect(config.flow, isNull);
      expect(config.subscriptionId, isNull);
    });

    test('copyWith produces new instance with changed fields', () {
      final config = ServerConfig(
        id: 'id',
        name: 'Original',
        protocol: ProtocolType.trojan,
        address: 'addr',
        port: 443,
        addedAt: now,
      );

      final copied = config.copyWith(name: 'Updated', port: 8080);

      expect(copied.name, 'Updated');
      expect(copied.port, 8080);
      expect(copied.id, 'id'); // unchanged
      expect(copied.protocol, ProtocolType.trojan); // unchanged
    });

    test('toJson / fromJson round-trips correctly', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Test Server',
        protocol: ProtocolType.shadowsocks,
        address: '10.0.0.1',
        port: 8388,
        uuid: 'some-uuid',
        method: 'aes-256-gcm',
        password: 'secret',
        encryption: 'auto',
        network: 'ws',
        security: 'tls',
        sni: 'example.com',
        groupName: 'Subscription A',
        addedAt: now,
      );

      final json = config.toJson();
      final restored = ServerConfig.fromJson(json);

      expect(restored, config);
      expect(restored.id, config.id);
      expect(restored.method, 'aes-256-gcm');
      expect(restored.groupName, 'Subscription A');
    });

    test('equality works correctly', () {
      final a = ServerConfig(
        id: 'same',
        name: 'Server',
        protocol: ProtocolType.vless,
        address: 'addr',
        port: 443,
        addedAt: now,
      );
      final b = ServerConfig(
        id: 'same',
        name: 'Server',
        protocol: ProtocolType.vless,
        address: 'addr',
        port: 443,
        addedAt: now,
      );
      final c = ServerConfig(
        id: 'different',
        name: 'Server',
        protocol: ProtocolType.vless,
        address: 'addr',
        port: 443,
        addedAt: now,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
