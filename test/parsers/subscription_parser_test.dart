import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/subscription_parser.dart';

void main() {
  group('SubscriptionParser', () {
    test('parses base64-encoded body with share links', () {
      final plainText =
          'vless://test-uuid@1.2.3.4:443?type=tcp&security=tls#TestVLESS\n'
          'trojan://password@5.6.7.8:443?type=tcp&security=tls#TestTrojan';
      final base64Body = base64Encode(utf8.encode(plainText));

      final result = SubscriptionParser.parseBody(base64Body);

      expect(result.length, 2);
      expect(result[0].protocol, ProtocolType.vless);
      expect(result[0].address, '1.2.3.4');
      expect(result[1].protocol, ProtocolType.trojan);
      expect(result[1].address, '5.6.7.8');
    });

    test('parses plain text body with one share link per line', () {
      const plainText =
          'vless://test-uuid@1.2.3.4:443?type=tcp&security=tls#TestVLESS\n'
          'trojan://password@5.6.7.8:443?type=tcp&security=tls#TestTrojan';

      final result = SubscriptionParser.parseBody(plainText);

      expect(result.length, 2);
      expect(result[0].protocol, ProtocolType.vless);
      expect(result[1].protocol, ProtocolType.trojan);
    });

    test('handles base64 body with missing padding', () {
      final plainText =
          'vless://test-uuid@1.2.3.4:443?type=tcp&security=tls#TestNode';
      var base64Body = base64Encode(utf8.encode(plainText));
      // Remove trailing padding
      base64Body = base64Body.replaceAll('=', '');

      final result = SubscriptionParser.parseBody(base64Body);

      expect(result.length, 1);
      expect(result[0].protocol, ProtocolType.vless);
      expect(result[0].address, '1.2.3.4');
    });

    test('delegates SIP008 JSON array to Sip008Parser', () {
      final json = jsonEncode([
        {
          'server': '1.2.3.4',
          'server_port': 8388,
          'password': 'pwd',
          'method': 'aes-256-gcm',
          'remarks': 'SIP008 Test',
        },
      ]);

      final result = SubscriptionParser.parseBody(json);

      expect(result.length, 1);
      expect(result[0].protocol, ProtocolType.shadowsocks);
      expect(result[0].address, '1.2.3.4');
    });

    test('delegates SIP008 wrapped JSON to Sip008Parser', () {
      final json = jsonEncode({
        'version': 1,
        'servers': [
          {
            'server': '1.2.3.4',
            'server_port': 8388,
            'password': 'pwd',
            'method': 'aes-256-gcm',
            'remarks': 'Wrapped Test',
          },
        ],
      });

      final result = SubscriptionParser.parseBody(json);

      expect(result.length, 1);
      expect(result[0].protocol, ProtocolType.shadowsocks);
    });

    test('delegates Clash YAML to ClashParser', () {
      const yaml = '''proxies:
  - name: "Clash VMess"
    type: vmess
    server: 1.2.3.4
    port: 443
    uuid: test-uuid
    alterId: 0
    cipher: auto''';

      final result = SubscriptionParser.parseBody(yaml);

      expect(result.length, 1);
      expect(result[0].protocol, ProtocolType.vmess);
      expect(result[0].address, '1.2.3.4');
    });

    test('returns empty list for empty body', () {
      final result = SubscriptionParser.parseBody('');

      expect(result, isEmpty);
    });

    test('skips invalid lines and returns only valid configs', () {
      const plainText =
          'vless://test-uuid@1.2.3.4:443?type=tcp&security=tls#Valid\n'
          'invalid-line-here\n'
          'another bad line\n'
          'trojan://password@5.6.7.8:443?type=tcp&security=tls#Valid2';

      final result = SubscriptionParser.parseBody(plainText);

      expect(result.length, 2);
      expect(result[0].protocol, ProtocolType.vless);
      expect(result[1].protocol, ProtocolType.trojan);
    });

    test('handles Windows-style line endings (CRLF)', () {
      const plainText =
          'vless://test-uuid@1.2.3.4:443?type=tcp&security=tls#N1\r\n'
          'trojan://password@5.6.7.8:443?type=tcp&security=tls#N2';

      final result = SubscriptionParser.parseBody(plainText);

      expect(result.length, 2);
    });

    test('handles body with only whitespace and empty lines', () {
      const plainText = '  \n\n  \n  ';

      final result = SubscriptionParser.parseBody(plainText);

      expect(result, isEmpty);
    });
  });
}
