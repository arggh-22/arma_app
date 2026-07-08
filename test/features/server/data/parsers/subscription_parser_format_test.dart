import 'dart:convert';

import 'package:arma_proxy_vpn_client/features/server/data/parsers/subscription_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vlessLink =
      'vless://11111111-1111-1111-1111-111111111111@example.com:443'
      '?type=tcp&security=none#Node-A';

  test('plain share-link body is tagged "link"', () {
    final configs = SubscriptionParser.parseBody(vlessLink);
    expect(configs, isNotEmpty);
    expect(configs.every((c) => c.configFormat == 'link'), isTrue);
  });

  test('base64-encoded share links are tagged "base64"', () {
    final body = base64Encode(utf8.encode(vlessLink));
    final configs = SubscriptionParser.parseBody(body);
    expect(configs, isNotEmpty);
    expect(configs.every((c) => c.configFormat == 'base64'), isTrue);
  });

  test('ARMA JSON subscription entries are tagged "json"', () {
    final body = jsonEncode([
      {
        'remarks': 'JSON Node',
        'outbounds': [
          {
            'tag': 'proxy',
            'protocol': 'vless',
            'settings': {
              'vnext': [
                {
                  'address': 'example.com',
                  'port': 443,
                  'users': [
                    {'id': '11111111-1111-1111-1111-111111111111'},
                  ],
                },
              ],
            },
            'streamSettings': {'network': 'tcp', 'security': 'none'},
          },
        ],
      },
    ]);
    final configs = SubscriptionParser.parseBody(body);
    expect(configs, isNotEmpty);
    expect(configs.every((c) => c.configFormat == 'json'), isTrue);
  });
}
