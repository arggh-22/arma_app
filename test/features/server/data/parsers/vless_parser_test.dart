import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/vless_parser.dart';

void main() {
  group('VlessParser', () {
    test('parses Reality XTLS-Vision link with all params', () {
      const link =
          'vless://test-uuid-1234@server.example.com:443'
          '?type=tcp&security=reality&pbk=publicKeyABC'
          '&fp=chrome&sni=example.com&sid=shortId123'
          '&spx=%2Fpath&flow=xtls-rprx-vision#ServerName';

      final result = VlessParser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.vless);
      expect(result.uuid, 'test-uuid-1234');
      expect(result.address, 'server.example.com');
      expect(result.port, 443);
      expect(result.network, 'tcp');
      expect(result.security, 'reality');
      expect(result.publicKey, 'publicKeyABC');
      expect(result.fingerprint, 'chrome');
      expect(result.sni, 'example.com');
      expect(result.shortId, 'shortId123');
      expect(result.spiderX, '/path');
      expect(result.flow, 'xtls-rprx-vision');
      expect(result.name, 'ServerName');
      expect(result.id, isNotEmpty);
      expect(result.addedAt, isA<DateTime>());
    });

    test('parses VLESS with WebSocket transport', () {
      const link =
          'vless://uuid-ws@ws-server.com:8080'
          '?type=ws&security=tls&sni=ws-server.com'
          '&host=cdn.example.com&path=%2Fws-path#WS-Server';

      final result = VlessParser.parse(link);

      expect(result, isNotNull);
      expect(result!.network, 'ws');
      expect(result.path, '/ws-path');
      expect(result.host, 'cdn.example.com');
      expect(result.security, 'tls');
    });

    test('parses VLESS with gRPC transport', () {
      const link =
          'vless://uuid-grpc@grpc-server.com:443'
          '?type=grpc&security=tls&sni=grpc-server.com'
          '&serviceName=mygrpc#gRPC-Server';

      final result = VlessParser.parse(link);

      expect(result, isNotNull);
      expect(result!.network, 'grpc');
      expect(result.serviceName, 'mygrpc');
    });

    test('decodes non-ASCII server name (URL-encoded Farsi)', () {
      // "سرور تهران" URL-encoded
      const farsiName =
          '%D8%B3%D8%B1%D9%88%D8%B1%20%D8%AA%D9%87%D8%B1%D8%A7%D9%86';
      final link =
          'vless://uuid-farsi@iran-server.com:443'
          '?type=tcp&security=tls#$farsiName';

      final result = VlessParser.parse(link);

      expect(result, isNotNull);
      expect(result!.name, 'سرور تهران');
    });

    test('defaults name to address:port when fragment missing', () {
      const link =
          'vless://uuid-no-name@noname.server.com:8443'
          '?type=tcp&security=none';

      final result = VlessParser.parse(link);

      expect(result, isNotNull);
      expect(result!.name, 'noname.server.com:8443');
    });

    test('returns null for invalid port (not a number)', () {
      const link =
          'vless://uuid@server.com:notaport'
          '?type=tcp&security=none#Name';

      final result = VlessParser.parse(link);

      expect(result, isNull);
    });

    test('returns null for port out of range', () {
      const link =
          'vless://uuid@server.com:99999'
          '?type=tcp&security=none#Name';

      final result = VlessParser.parse(link);

      expect(result, isNull);
    });

    test('returns null for empty address', () {
      const link = 'vless://uuid@:443?type=tcp&security=none#Name';

      final result = VlessParser.parse(link);

      expect(result, isNull);
    });

    test('truncates server name to 50 characters', () {
      final longName = 'A' * 100;
      final link =
          'vless://uuid@server.com:443?type=tcp&security=none#$longName';

      final result = VlessParser.parse(link);

      expect(result, isNotNull);
      expect(result!.name.length, 50);
    });

    test('returns null for input exceeding 10000 characters', () {
      final longLink =
          'vless://uuid@server.com:443?type=tcp&security=none#'
          '${'A' * 10000}';

      final result = VlessParser.parse(longLink);

      expect(result, isNull);
    });
  });
}
