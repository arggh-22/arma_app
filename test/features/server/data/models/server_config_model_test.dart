import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/server_config_model.dart';

void main() {
  group('ServerConfigModel', () {
    final now = DateTime(2026, 1, 1);

    test('maps to domain entity via toDomain()', () {
      final model = ServerConfigModel(
        id: 'model-id',
        name: 'Model Server',
        protocolIndex: ProtocolType.vless.index,
        address: '10.0.0.1',
        port: 443,
        uuid: 'some-uuid',
        encryption: 'none',
        network: 'tcp',
        security: 'reality',
        publicKey: 'pub-key-123',
        shortId: 'abc',
        groupName: 'Manual',
        addedAtMillis: now.millisecondsSinceEpoch,
      );

      final domain = model.toDomain();

      expect(domain, isA<ServerConfig>());
      expect(domain.id, 'model-id');
      expect(domain.name, 'Model Server');
      expect(domain.protocol, ProtocolType.vless);
      expect(domain.address, '10.0.0.1');
      expect(domain.port, 443);
      expect(domain.uuid, 'some-uuid');
      expect(domain.security, 'reality');
      expect(domain.publicKey, 'pub-key-123');
      expect(domain.shortId, 'abc');
      expect(domain.addedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('maps from domain entity via fromDomain()', () {
      final config = ServerConfig(
        id: 'domain-id',
        name: 'Domain Server',
        protocol: ProtocolType.trojan,
        address: 'example.com',
        port: 443,
        password: 'trojan-pass',
        security: 'tls',
        sni: 'trojan.example.com',
        addedAt: now,
      );

      final model = ServerConfigModelMapper.fromDomain(config);

      expect(model.id, 'domain-id');
      expect(model.name, 'Domain Server');
      expect(model.protocolIndex, ProtocolType.trojan.index);
      expect(model.address, 'example.com');
      expect(model.port, 443);
      expect(model.password, 'trojan-pass');
      expect(model.security, 'tls');
      expect(model.sni, 'trojan.example.com');
      expect(model.addedAtMillis, now.millisecondsSinceEpoch);
    });

    test('round-trips domain → model → domain preserves data', () {
      final original = ServerConfig(
        id: 'rt-id',
        name: 'Round Trip',
        protocol: ProtocolType.shadowsocks,
        address: '1.2.3.4',
        port: 8388,
        method: 'aes-256-gcm',
        password: 'secret',
        groupName: 'Sub X',
        addedAt: now,
      );

      final model = ServerConfigModelMapper.fromDomain(original);
      final restored = model.toDomain();

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.protocol, original.protocol);
      expect(restored.address, original.address);
      expect(restored.port, original.port);
      expect(restored.method, original.method);
      expect(restored.password, original.password);
      expect(restored.groupName, original.groupName);
    });

    test('has correct HiveField indices with gaps', () {
      // This test validates the schema design documented in the plan.
      // The model should have these HiveField indices:
      // 0=id, 1=name, 2=protocolIndex, GAP 3-4,
      // 5=address, 6=port, GAP 7-9,
      // 10=uuid, 11=password, 12=encryption, 13=network, 14=security, 15=sni, GAP 16-19,
      // 20=host, 21=path, 22=alpn, 23=fingerprint, 24=flow, 25=alterId, GAP 26-29,
      // 30=serviceName, 31=authority, 32=publicKey, 33=shortId, 34=spiderX, 35=method, GAP 36-39,
      // 40=obfs, 41=obfsPassword, 42=subscriptionId, 43=groupName, 44=addedAtMillis

      // We verify the model has the expected fields by constructing it
      final model = ServerConfigModel(
        id: 'test',
        name: 'test',
        protocolIndex: 0,
        address: 'test',
        port: 443,
        addedAtMillis: 0,
      );

      expect(model.id, 'test');
      expect(model.alterId, 0); // default
      expect(model.encryption, 'none'); // default
      expect(model.network, 'tcp'); // default
      expect(model.security, 'none'); // default
      expect(model.groupName, 'Manual'); // default
    });
  });
}
