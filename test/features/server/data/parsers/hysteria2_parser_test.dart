import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/hysteria2_parser.dart';

void main() {
  group('Hysteria2Parser', () {
    test('parses hysteria2:// link with all params', () {
      const link =
          'hysteria2://auth-token@server.example.com:443'
          '?sni=example.com&insecure=0'
          '&obfs=salamander&obfs-password=xxx#ServerName';

      final result = Hysteria2Parser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.hysteria2);
      expect(result.password, 'auth-token');
      expect(result.address, 'server.example.com');
      expect(result.port, 443);
      expect(result.sni, 'example.com');
      expect(result.obfs, 'salamander');
      expect(result.obfsPassword, 'xxx');
      expect(result.name, 'ServerName');
      expect(result.id, isNotEmpty);
      expect(result.addedAt, isA<DateTime>());
    });

    test('parses hy2:// alternate scheme', () {
      const link = 'hy2://auth-alt@alt-server.com:443#AltScheme';

      final result = Hysteria2Parser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.hysteria2);
      expect(result.password, 'auth-alt');
      expect(result.address, 'alt-server.com');
      expect(result.name, 'AltScheme');
    });

    test('handles missing obfs params gracefully', () {
      const link = 'hysteria2://auth@server.com:443?sni=server.com#NoObfs';

      final result = Hysteria2Parser.parse(link);

      expect(result, isNotNull);
      expect(result!.obfs, isNull);
      expect(result.obfsPassword, isNull);
    });

    test('defaults name to address:port when fragment missing', () {
      const link = 'hysteria2://auth@noname-hy2.com:9443';

      final result = Hysteria2Parser.parse(link);

      expect(result, isNotNull);
      expect(result!.name, 'noname-hy2.com:9443');
    });

    test('returns null for empty auth/password', () {
      const link = 'hysteria2://@server.com:443#NoAuth';

      final result = Hysteria2Parser.parse(link);

      expect(result, isNull);
    });

    test('returns null for input exceeding 10000 characters', () {
      final longLink = 'hysteria2://auth@server.com:443#${'A' * 10000}';
      final result = Hysteria2Parser.parse(longLink);
      expect(result, isNull);
    });

    test('truncates server name to 50 characters', () {
      final longName = 'H' * 100;
      final link = 'hysteria2://auth@server.com:443#$longName';

      final result = Hysteria2Parser.parse(link);

      expect(result, isNotNull);
      expect(result!.name.length, 50);
    });

    test('parses with non-ASCII server name', () {
      // Russian: "Москва Сервер" URL-encoded
      const russianName =
          '%D0%9C%D0%BE%D1%81%D0%BA%D0%B2%D0%B0%20'
          '%D0%A1%D0%B5%D1%80%D0%B2%D0%B5%D1%80';
      final link = 'hysteria2://auth@ru-server.com:443#$russianName';

      final result = Hysteria2Parser.parse(link);

      expect(result, isNotNull);
      expect(result!.name, 'Москва Сервер');
    });
  });
}
