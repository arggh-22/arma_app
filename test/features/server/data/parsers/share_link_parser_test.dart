import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_parser.dart';

void main() {
  group('ShareLinkParser', () {
    test('dispatches vless:// to VlessParser', () {
      const link =
          'vless://uuid@server.com:443'
          '?type=tcp&security=tls#VlessTest';

      final result = ShareLinkParser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.vless);
    });

    test('dispatches vmess:// to VmessParser', () {
      final json = {
        'v': '2',
        'ps': 'VmessTest',
        'add': 'server.com',
        'port': '443',
        'id': 'uuid-vmess',
        'aid': '0',
        'scy': 'auto',
        'net': 'tcp',
        'tls': '',
      };
      final encoded = base64Encode(utf8.encode(jsonEncode(json)));
      final link = 'vmess://$encoded';

      final result = ShareLinkParser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.vmess);
    });

    test('dispatches trojan:// to TrojanParser', () {
      const link =
          'trojan://password@server.com:443'
          '?type=tcp&security=tls#TrojanTest';

      final result = ShareLinkParser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.trojan);
    });

    test('dispatches ss:// to ShadowsocksParser', () {
      final encoded = base64Encode(utf8.encode('aes-256-gcm:password'));
      final link = 'ss://$encoded@server.com:8388#SSTest';

      final result = ShareLinkParser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.shadowsocks);
    });

    test('dispatches hysteria2:// to Hysteria2Parser', () {
      const link = 'hysteria2://auth@server.com:443#Hy2Test';

      final result = ShareLinkParser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.hysteria2);
    });

    test('dispatches hy2:// to Hysteria2Parser', () {
      const link = 'hy2://auth@server.com:443#Hy2AltTest';

      final result = ShareLinkParser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.hysteria2);
    });

    test('parses raw JSON VMess format', () {
      final json = jsonEncode({
        'v': '2',
        'ps': 'RawJSON',
        'add': 'raw.server.com',
        'port': '443',
        'id': 'uuid-raw',
        'aid': '0',
        'scy': 'auto',
        'net': 'tcp',
        'tls': '',
      });

      final result = ShareLinkParser.parse(json);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.vmess);
      expect(result.name, 'RawJSON');
    });

    test('returns null for empty string', () {
      final result = ShareLinkParser.parse('');
      expect(result, isNull);
    });

    test('returns null for https:// URL', () {
      final result = ShareLinkParser.parse('https://google.com');
      expect(result, isNull);
    });

    test('returns null for invalid garbage', () {
      final result = ShareLinkParser.parse('invalid garbage');
      expect(result, isNull);
    });

    test('handles leading/trailing whitespace', () {
      const link =
          '  vless://uuid@server.com:443'
          '?type=tcp&security=tls#WhitespaceTest  ';

      final result = ShareLinkParser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.vless);
    });

    test('returns null for null-like whitespace-only input', () {
      final result = ShareLinkParser.parse('   ');
      expect(result, isNull);
    });

    test('returns null for input exceeding 10000 characters', () {
      final longInput = 'vless://${'A' * 10000}';
      final result = ShareLinkParser.parse(longInput);
      expect(result, isNull);
    });

    test('parses Chinese server name correctly', () {
      // Chinese: "香港节点" URL-encoded
      const chineseName = '%E9%A6%99%E6%B8%AF%E8%8A%82%E7%82%B9';
      final link =
          'vless://uuid@hk-server.com:443'
          '?type=tcp&security=tls#$chineseName';

      final result = ShareLinkParser.parse(link);

      expect(result, isNotNull);
      expect(result!.name, '香港节点');
    });
  });
}
