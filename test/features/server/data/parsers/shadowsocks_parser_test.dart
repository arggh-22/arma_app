import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/shadowsocks_parser.dart';

void main() {
  group('ShadowsocksParser', () {
    test('parses standard SS link with base64 method:password', () {
      // base64("aes-256-gcm:password") = "YWVzLTI1Ni1nY206cGFzc3dvcmQ="
      final methodPassword = base64Encode(utf8.encode('aes-256-gcm:password'));
      final link = 'ss://$methodPassword@server.example.com:8388#ServerName';

      final result = ShadowsocksParser.parse(link);

      expect(result, isNotNull);
      expect(result!.protocol, ProtocolType.shadowsocks);
      expect(result.method, 'aes-256-gcm');
      expect(result.password, 'password');
      expect(result.address, 'server.example.com');
      expect(result.port, 8388);
      expect(result.name, 'ServerName');
      expect(result.id, isNotEmpty);
      expect(result.addedAt, isA<DateTime>());
    });

    test('handles base64 without padding', () {
      // base64("aes-256-gcm:pw") without padding
      var encoded = base64Encode(utf8.encode('aes-256-gcm:pw'));
      encoded = encoded.replaceAll('=', '');
      final link = 'ss://$encoded@server.com:8388#NoPadding';

      final result = ShadowsocksParser.parse(link);

      expect(result, isNotNull);
      expect(result!.method, 'aes-256-gcm');
      expect(result.password, 'pw');
    });

    test('parses SIP002 format with plugin param', () {
      final methodPassword =
          base64Encode(utf8.encode('chacha20-ietf-poly1305:mypassword'));
      final link =
          'ss://$methodPassword@server.com:443'
          '?plugin=obfs-local%3Bobfs%3Dhttp%3Bobfs-host%3Dexample.com'
          '#SIP002-Server';

      final result = ShadowsocksParser.parse(link);

      expect(result, isNotNull);
      expect(result!.method, 'chacha20-ietf-poly1305');
      expect(result.password, 'mypassword');
      expect(result.name, 'SIP002-Server');
    });

    test('rejects unknown encryption method', () {
      final methodPassword =
          base64Encode(utf8.encode('unknown-cipher:password'));
      final link = 'ss://$methodPassword@server.com:8388#BadMethod';

      final result = ShadowsocksParser.parse(link);

      expect(result, isNull);
    });

    test('parses valid encryption methods', () {
      final validMethods = [
        'aes-128-gcm',
        'aes-256-gcm',
        'chacha20-ietf-poly1305',
        'xchacha20-ietf-poly1305',
        '2022-blake3-aes-128-gcm',
        '2022-blake3-aes-256-gcm',
        '2022-blake3-chacha20-poly1305',
        'none',
        'plain',
      ];

      for (final method in validMethods) {
        final encoded = base64Encode(utf8.encode('$method:testpass'));
        final link = 'ss://$encoded@server.com:8388#$method';
        final result = ShadowsocksParser.parse(link);
        expect(result, isNotNull, reason: 'Failed for method: $method');
        expect(result!.method, method);
      }
    });

    test('defaults name to address:port when fragment missing', () {
      final encoded = base64Encode(utf8.encode('aes-256-gcm:password'));
      final link = 'ss://$encoded@noname-ss.com:9999';

      final result = ShadowsocksParser.parse(link);

      expect(result, isNotNull);
      expect(result!.name, 'noname-ss.com:9999');
    });

    test('returns null for input exceeding 10000 characters', () {
      final longLink = 'ss://${'A' * 10000}';
      final result = ShadowsocksParser.parse(longLink);
      expect(result, isNull);
    });

    test('truncates server name to 50 characters', () {
      final encoded = base64Encode(utf8.encode('aes-256-gcm:password'));
      final longName = 'S' * 100;
      final link = 'ss://$encoded@server.com:8388#$longName';

      final result = ShadowsocksParser.parse(link);

      expect(result, isNotNull);
      expect(result!.name.length, 50);
    });

    test('returns null for malformed base64 content', () {
      const link = 'ss://!!!notbase64!!!@server.com:8388#Bad';
      final result = ShadowsocksParser.parse(link);
      expect(result, isNull);
    });

    test('returns null for missing password in decoded content', () {
      // base64("aes-256-gcm") - no colon separator
      final encoded = base64Encode(utf8.encode('aes-256-gcm'));
      final link = 'ss://$encoded@server.com:8388#NoPassword';

      final result = ShadowsocksParser.parse(link);

      expect(result, isNull);
    });
  });
}
