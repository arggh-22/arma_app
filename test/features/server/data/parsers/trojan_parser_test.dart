import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/trojan_parser.dart';

void main() {
  group('TrojanParser', () {
    test('parses Trojan TCP TLS link', () {
      const link =
          'trojan://password123@server.example.com:443'
          '?type=tcp&security=tls&sni=example.com#ServerName';

      final result = TrojanParser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.trojan);
      expect(result.password, 'password123');
      expect(result.address, 'server.example.com');
      expect(result.port, 443);
      expect(result.security, 'tls');
      expect(result.sni, 'example.com');
      expect(result.name, 'ServerName');
      expect(result.id, isNotEmpty);
      expect(result.addedAt, isA<DateTime>());
    });

    test('parses Trojan with WebSocket transport', () {
      const link =
          'trojan://pass-ws@ws-trojan.com:8080'
          '?type=ws&security=tls&sni=ws-trojan.com'
          '&path=%2Ftrojan-ws#WS-Trojan';

      final result = TrojanParser.parse(link);

      expect(result, isNotNull);
      expect(result!.network, 'ws');
      expect(result.path, '/trojan-ws');
    });

    test('decodes URL-encoded password with special characters', () {
      // password: "p@ss:w0rd/test"
      const link =
          'trojan://p%40ss%3Aw0rd%2Ftest@server.com:443'
          '?type=tcp&security=tls&sni=server.com#SpecialPass';

      final result = TrojanParser.parse(link);

      expect(result, isNotNull);
      expect(result!.password, 'p@ss:w0rd/test');
    });

    test('defaults security to tls when not specified', () {
      const link = 'trojan://pass-default@server.com:443#DefaultTLS';

      final result = TrojanParser.parse(link);

      expect(result, isNotNull);
      expect(result!.security, 'tls');
    });

    test('defaults name to address:port when fragment missing', () {
      const link = 'trojan://pass@noname-trojan.com:8443?type=tcp&security=tls';

      final result = TrojanParser.parse(link);

      expect(result, isNotNull);
      expect(result!.name, 'noname-trojan.com:8443');
    });

    test('returns null for empty password', () {
      const link = 'trojan://@server.com:443?type=tcp&security=tls#NoPass';

      final result = TrojanParser.parse(link);

      expect(result, isNull);
    });

    test('returns null for input exceeding 10000 characters', () {
      final longLink = 'trojan://pass@server.com:443#${'A' * 10000}';
      final result = TrojanParser.parse(longLink);
      expect(result, isNull);
    });

    test('truncates server name to 50 characters', () {
      final longName = 'T' * 100;
      final link =
          'trojan://pass@server.com:443?type=tcp&security=tls#$longName';

      final result = TrojanParser.parse(link);

      expect(result, isNotNull);
      expect(result!.name.length, 50);
    });
  });
}
