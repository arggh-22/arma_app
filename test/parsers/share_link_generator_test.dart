import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_generator.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  group('ShareLinkGenerator - VLESS', () {
    test('generates valid VLESS share link', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Test VLESS',
        protocol: ProtocolType.vless,
        address: '1.2.3.4',
        port: 443,
        uuid: 'abc-def-123',
        network: 'ws',
        security: 'tls',
        sni: 'example.com',
        path: '/ws',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);

      expect(link, startsWith('vless://'));
      expect(link, contains('abc-def-123@1.2.3.4:443'));
      expect(link, contains('type=ws'));
      expect(link, contains('security=tls'));
      expect(link, contains('sni=example.com'));
      expect(link, contains('#Test%20VLESS'));
    });

    test('generates VLESS Reality link with pbk, sid, fp, flow', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Reality',
        protocol: ProtocolType.vless,
        address: '1.2.3.4',
        port: 443,
        uuid: 'uuid-reality',
        network: 'tcp',
        security: 'reality',
        publicKey: 'mypublickey',
        shortId: 'ab12',
        fingerprint: 'chrome',
        flow: 'xtls-rprx-vision',
        spiderX: '/path',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);

      expect(link, contains('pbk=mypublickey'));
      expect(link, contains('sid=ab12'));
      expect(link, contains('fp=chrome'));
      expect(link, contains('flow=xtls-rprx-vision'));
      expect(link, contains('spx='));
    });

    test('roundtrip: VLESS generate → parse preserves key fields', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Roundtrip VLESS',
        protocol: ProtocolType.vless,
        address: '1.2.3.4',
        port: 443,
        uuid: 'vless-uuid-test',
        network: 'ws',
        security: 'tls',
        sni: 'example.com',
        path: '/ws',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);
      final parsed = ShareLinkParser.parse(link);

      expect(parsed, isNotNull);
      expect(parsed!.protocol, ProtocolType.vless);
      expect(parsed.address, '1.2.3.4');
      expect(parsed.port, 443);
      expect(parsed.uuid, 'vless-uuid-test');
      expect(parsed.network, 'ws');
      expect(parsed.security, 'tls');
    });
  });

  group('ShareLinkGenerator - VMess', () {
    test('generates valid VMess legacy base64-JSON link', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Test VMess',
        protocol: ProtocolType.vmess,
        address: '5.6.7.8',
        port: 443,
        uuid: 'vmess-uuid-test',
        network: 'ws',
        security: 'tls',
        host: 'vmess.example.com',
        path: '/vmess',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);

      expect(link, startsWith('vmess://'));

      // Decode and verify JSON structure
      final base64Part = link.replaceFirst('vmess://', '');
      final jsonStr = utf8.decode(base64Decode(base64Part));
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(json['v'], '2');
      expect(json['ps'], 'Test VMess');
      expect(json['add'], '5.6.7.8');
      expect(json['port'], '443');
      expect(json['id'], 'vmess-uuid-test');
      expect(json['net'], 'ws');
      expect(json['host'], 'vmess.example.com');
      expect(json['path'], '/vmess');
      expect(json['tls'], 'tls');
    });

    test('roundtrip: VMess generate → parse preserves key fields', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Roundtrip VMess',
        protocol: ProtocolType.vmess,
        address: '5.6.7.8',
        port: 443,
        uuid: 'vmess-roundtrip-uuid',
        network: 'tcp',
        security: 'none',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);
      final parsed = ShareLinkParser.parse(link);

      expect(parsed, isNotNull);
      expect(parsed!.protocol, ProtocolType.vmess);
      expect(parsed.address, '5.6.7.8');
      expect(parsed.port, 443);
      expect(parsed.uuid, 'vmess-roundtrip-uuid');
    });
  });

  group('ShareLinkGenerator - Trojan', () {
    test('generates valid Trojan share link', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Test Trojan',
        protocol: ProtocolType.trojan,
        address: '9.10.11.12',
        port: 443,
        password: 'trojanpwd',
        network: 'tcp',
        security: 'tls',
        sni: 'trojan.example.com',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);

      expect(link, startsWith('trojan://'));
      expect(link, contains('trojanpwd@9.10.11.12:443'));
      expect(link, contains('type=tcp'));
      expect(link, contains('security=tls'));
      expect(link, contains('sni=trojan.example.com'));
    });

    test('roundtrip: Trojan generate → parse preserves key fields', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Roundtrip Trojan',
        protocol: ProtocolType.trojan,
        address: '9.10.11.12',
        port: 443,
        password: 'trojanpwd',
        network: 'tcp',
        security: 'tls',
        sni: 'trojan.example.com',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);
      final parsed = ShareLinkParser.parse(link);

      expect(parsed, isNotNull);
      expect(parsed!.protocol, ProtocolType.trojan);
      expect(parsed.address, '9.10.11.12');
      expect(parsed.port, 443);
      expect(parsed.password, 'trojanpwd');
    });
  });

  group('ShareLinkGenerator - Shadowsocks', () {
    test('generates valid Shadowsocks SIP002 link', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Test SS',
        protocol: ProtocolType.shadowsocks,
        address: '13.14.15.16',
        port: 8388,
        password: 'sspwd',
        method: 'aes-256-gcm',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);

      expect(link, startsWith('ss://'));
      expect(link, contains('@13.14.15.16:8388'));
      expect(link, contains('#Test%20SS'));

      // Verify base64(method:password) portion
      final afterSs = link.replaceFirst('ss://', '');
      final atIdx = afterSs.indexOf('@');
      final userInfo = afterSs.substring(0, atIdx);
      final decoded = utf8.decode(base64Decode(userInfo));
      expect(decoded, 'aes-256-gcm:sspwd');
    });

    test('roundtrip: Shadowsocks generate → parse preserves key fields', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Roundtrip SS',
        protocol: ProtocolType.shadowsocks,
        address: '13.14.15.16',
        port: 8388,
        password: 'sspwd',
        method: 'aes-256-gcm',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);
      final parsed = ShareLinkParser.parse(link);

      expect(parsed, isNotNull);
      expect(parsed!.protocol, ProtocolType.shadowsocks);
      expect(parsed.address, '13.14.15.16');
      expect(parsed.port, 8388);
      expect(parsed.password, 'sspwd');
      expect(parsed.method, 'aes-256-gcm');
    });
  });

  group('ShareLinkGenerator - Hysteria2', () {
    test('generates valid Hysteria2 share link', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Test HY2',
        protocol: ProtocolType.hysteria2,
        address: '17.18.19.20',
        port: 443,
        password: 'hy2pwd',
        sni: 'hy2.example.com',
        obfs: 'salamander',
        obfsPassword: 'obfspwd',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);

      expect(link, startsWith('hysteria2://'));
      expect(link, contains('hy2pwd@17.18.19.20:443'));
      expect(link, contains('sni=hy2.example.com'));
      expect(link, contains('obfs=salamander'));
      expect(link, contains('obfs-password=obfspwd'));
    });

    test('roundtrip: Hysteria2 generate → parse preserves key fields', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Roundtrip HY2',
        protocol: ProtocolType.hysteria2,
        address: '17.18.19.20',
        port: 443,
        password: 'hy2pwd',
        sni: 'hy2.example.com',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);
      final parsed = ShareLinkParser.parse(link);

      expect(parsed, isNotNull);
      expect(parsed!.protocol, ProtocolType.hysteria2);
      expect(parsed.address, '17.18.19.20');
      expect(parsed.port, 443);
      expect(parsed.password, 'hy2pwd');
    });
  });

  group('ShareLinkGenerator - Edge cases', () {
    test('handles special characters in server name (URI encoding)', () {
      final config = ServerConfig(
        id: 'test-id',
        name: 'Test Node / #1 (US)',
        protocol: ProtocolType.vless,
        address: '1.2.3.4',
        port: 443,
        uuid: 'uuid-special',
        addedAt: now,
      );

      final link = ShareLinkGenerator.generate(config);

      // Name should be URI-encoded in the fragment
      expect(link, isNot(contains('#Test Node')));
      // But should be decodable back
      final fragment = link.split('#').last;
      final decoded = Uri.decodeComponent(fragment);
      expect(decoded, 'Test Node / #1 (US)');
    });
  });
}
