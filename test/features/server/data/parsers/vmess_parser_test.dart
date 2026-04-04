import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/vmess_parser.dart';

void main() {
  group('VmessParser', () {
    group('legacy base64-JSON format', () {
      test('parses standard legacy VMess link', () {
        final json = {
          'v': '2',
          'ps': 'ServerName',
          'add': 'server.com',
          'port': '443',
          'id': 'uuid-test',
          'aid': '0',
          'scy': 'auto',
          'net': 'ws',
          'type': '',
          'host': '',
          'path': '/',
          'tls': 'tls',
          'sni': '',
        };
        final encoded = base64Encode(utf8.encode(jsonEncode(json)));
        final link = 'vmess://$encoded';

        final result = VmessParser.parse(link);

        expect(result, isNotNull);
        expect(result!.protocol, ProtocolType.vmess);
        expect(result.name, 'ServerName');
        expect(result.address, 'server.com');
        expect(result.port, 443);
        expect(result.uuid, 'uuid-test');
        expect(result.alterId, 0);
        expect(result.encryption, 'auto');
        expect(result.network, 'ws');
        expect(result.path, '/');
        expect(result.security, 'tls');
      });

      test('handles base64 with missing padding', () {
        final json = {
          'v': '2',
          'ps': 'Test',
          'add': 'example.com',
          'port': '443',
          'id': 'test-id',
          'aid': '0',
          'scy': 'auto',
          'net': 'tcp',
          'type': '',
          'host': '',
          'path': '',
          'tls': '',
          'sni': '',
        };
        var encoded = base64Encode(utf8.encode(jsonEncode(json)));
        // Remove padding
        encoded = encoded.replaceAll('=', '');
        final link = 'vmess://$encoded';

        final result = VmessParser.parse(link);

        expect(result, isNotNull);
        expect(result!.address, 'example.com');
      });

      test('handles URL-safe base64 (- and _ chars)', () {
        final json = {
          'v': '2',
          'ps': 'Server+Name/Test',
          'add': 'server.com',
          'port': '443',
          'id': 'uuid-123',
          'aid': '0',
          'scy': 'auto',
          'net': 'tcp',
          'type': '',
          'host': '',
          'path': '',
          'tls': '',
          'sni': '',
        };
        var encoded = base64Encode(utf8.encode(jsonEncode(json)));
        // Convert to URL-safe base64
        encoded = encoded.replaceAll('+', '-').replaceAll('/', '_');
        final link = 'vmess://$encoded';

        final result = VmessParser.parse(link);

        expect(result, isNotNull);
        expect(result!.uuid, 'uuid-123');
      });

      test('parses v field != "2" (some servers use "1")', () {
        final json = {
          'v': '1',
          'ps': 'OldServer',
          'add': 'old.server.com',
          'port': '8080',
          'id': 'old-uuid',
          'aid': '64',
          'scy': 'aes-128-gcm',
          'net': 'tcp',
          'type': '',
          'host': '',
          'path': '',
          'tls': '',
          'sni': '',
        };
        final encoded = base64Encode(utf8.encode(jsonEncode(json)));
        final link = 'vmess://$encoded';

        final result = VmessParser.parse(link);

        expect(result, isNotNull);
        expect(result!.name, 'OldServer');
        expect(result.alterId, 64);
      });

      test('handles empty/null fields in JSON with defaults', () {
        final json = {
          'v': '2',
          'add': 'minimal.com',
          'port': '443',
          'id': 'uuid-min',
        };
        final encoded = base64Encode(utf8.encode(jsonEncode(json)));
        final link = 'vmess://$encoded';

        final result = VmessParser.parse(link);

        expect(result, isNotNull);
        expect(result!.address, 'minimal.com');
        expect(result.network, 'tcp');
        expect(result.security, 'none');
        expect(result.encryption, 'auto');
        expect(result.alterId, 0);
        // Name defaults to address:port when ps is missing
        expect(result.name, contains('minimal.com'));
      });

      test('maps empty tls field to security=none', () {
        final json = {
          'v': '2',
          'ps': 'NoTLS',
          'add': 'notls.com',
          'port': '80',
          'id': 'uuid-notls',
          'aid': '0',
          'scy': 'auto',
          'net': 'tcp',
          'tls': '',
        };
        final encoded = base64Encode(utf8.encode(jsonEncode(json)));
        final link = 'vmess://$encoded';

        final result = VmessParser.parse(link);

        expect(result, isNotNull);
        expect(result!.security, 'none');
      });
    });

    group('standard URI format', () {
      test('parses standard VMess URI', () {
        const link =
            'vmess://uuid-std@server.com:443'
            '?type=ws&security=tls&path=%2F'
            '&host=example.com&encryption=auto&alterId=0#ServerName';

        final result = VmessParser.parse(link);

        expect(result, isNotNull);
        expect(result!.protocol, ProtocolType.vmess);
        expect(result.uuid, 'uuid-std');
        expect(result.address, 'server.com');
        expect(result.port, 443);
        expect(result.network, 'ws');
        expect(result.security, 'tls');
        expect(result.path, '/');
        expect(result.host, 'example.com');
        expect(result.encryption, 'auto');
        expect(result.alterId, 0);
        expect(result.name, 'ServerName');
      });
    });

    test('returns null for completely invalid input', () {
      final result = VmessParser.parse('vmess://!!!invalid!!!');
      expect(result, isNull);
    });

    test('returns null for input exceeding 10000 characters', () {
      final longLink = 'vmess://${'A' * 10000}';
      final result = VmessParser.parse(longLink);
      expect(result, isNull);
    });

    test('truncates server name to 50 characters', () {
      final json = {
        'v': '2',
        'ps': 'A' * 100,
        'add': 'server.com',
        'port': '443',
        'id': 'uuid-long-name',
        'aid': '0',
        'scy': 'auto',
        'net': 'tcp',
        'tls': '',
      };
      final encoded = base64Encode(utf8.encode(jsonEncode(json)));
      final link = 'vmess://$encoded';

      final result = VmessParser.parse(link);

      expect(result, isNotNull);
      expect(result!.name.length, 50);
    });
  });
}
