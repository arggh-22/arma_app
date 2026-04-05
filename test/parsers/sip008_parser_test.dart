import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/sip008_parser.dart';

void main() {
  group('Sip008Parser', () {
    test('parses direct JSON array format', () {
      final json = jsonEncode([
        {
          'server': '1.2.3.4',
          'server_port': 8388,
          'password': 'testpwd',
          'method': 'aes-256-gcm',
          'remarks': 'Tokyo',
        },
      ]);

      final result = Sip008Parser.tryParse(json);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].address, '1.2.3.4');
      expect(result[0].port, 8388);
      expect(result[0].password, 'testpwd');
      expect(result[0].method, 'aes-256-gcm');
      expect(result[0].name, 'Tokyo');
      expect(result[0].protocol, ProtocolType.shadowsocks);
      expect(result[0].id, isNotEmpty);
    });

    test('parses wrapped format with version and servers', () {
      final json = jsonEncode({
        'version': 1,
        'servers': [
          {
            'server': '5.6.7.8',
            'server_port': 443,
            'password': 'pwd2',
            'method': 'chacha20-ietf-poly1305',
            'remarks': 'US Node',
          },
          {
            'server': '9.10.11.12',
            'server_port': 8080,
            'password': 'pwd3',
            'method': 'aes-128-gcm',
            'tag': 'EU Node',
          },
        ],
      });

      final result = Sip008Parser.tryParse(json);

      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0].address, '5.6.7.8');
      expect(result[0].name, 'US Node');
      expect(result[1].address, '9.10.11.12');
      expect(result[1].name, 'EU Node');
    });

    test('returns null for invalid JSON', () {
      final result = Sip008Parser.tryParse('not valid json {{{');
      expect(result, isNull);
    });

    test('skips entries with missing required fields', () {
      final json = jsonEncode([
        {
          'server': '1.2.3.4',
          'server_port': 8388,
          'password': 'pwd',
          'method': 'aes-256-gcm',
        },
        {
          // Missing server
          'server_port': 443,
          'password': 'pwd2',
          'method': 'aes-128-gcm',
        },
        {
          'server': '5.6.7.8',
          // Missing server_port
          'password': 'pwd3',
          'method': 'aes-128-gcm',
        },
      ]);

      final result = Sip008Parser.tryParse(json);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].address, '1.2.3.4');
    });

    test('uses tag field when remarks is absent', () {
      final json = jsonEncode([
        {
          'server': '1.2.3.4',
          'server_port': 8388,
          'password': 'pwd',
          'method': 'aes-256-gcm',
          'tag': 'MyTag',
        },
      ]);

      final result = Sip008Parser.tryParse(json);

      expect(result, isNotNull);
      expect(result![0].name, 'MyTag');
    });

    test('uses address:port as name when both remarks and tag are absent', () {
      final json = jsonEncode([
        {
          'server': '1.2.3.4',
          'server_port': 8388,
          'password': 'pwd',
          'method': 'aes-256-gcm',
        },
      ]);

      final result = Sip008Parser.tryParse(json);

      expect(result, isNotNull);
      expect(result![0].name, '1.2.3.4:8388');
    });

    test('returns null for empty string', () {
      final result = Sip008Parser.tryParse('');
      expect(result, isNull);
    });
  });
}
