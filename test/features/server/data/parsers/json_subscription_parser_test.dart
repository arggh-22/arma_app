import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/json_subscription_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/subscription_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _jsonSubscription = '''
[
  {
    "inbounds": [
      {"tag": "socks", "protocol": "socks", "port": 10808, "listen": "127.0.0.1"}
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {"vnext": [{"address": "cdn-de.net-infra.systems", "port": 443,
          "users": [{"id": "ce05fed6", "encryption": "none", "flow": "xtls-rprx-vision"}]}]},
        "streamSettings": {"network": "tcp", "security": "reality",
          "realitySettings": {"serverName": "cdn-de.net-infra.systems",
            "publicKey": "PK123", "fingerprint": "edge", "shortId": "SID123"}}
      },
      {"tag": "direct", "protocol": "freedom"},
      {"tag": "block", "protocol": "blackhole"}
    ],
    "routing": {"rules": []},
    "remarks": "\u{1F1E9}\u{1F1EA} Germany",
    "meta": {"serverDescription": "VLESS • TCP • REALITY"}
  },
  {
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {"vnext": [{"address": "srv-101.net-infra.systems", "port": 8443,
          "users": [{"id": "ce05fed6", "encryption": "none", "flow": ""}]}]},
        "streamSettings": {"network": "xhttp", "security": "reality",
          "xhttpSettings": {"path": "/static-lib-assets", "host": "srv-101.net-infra.systems", "mode": "auto"},
          "realitySettings": {"serverName": "srv-101.net-infra.systems",
            "publicKey": "PK123", "fingerprint": "edge", "shortId": "SID123"}}
      },
      {
        "tag": "proxy-2",
        "protocol": "vless",
        "settings": {"vnext": [{"address": "srv-110.net-infra.systems", "port": 8443,
          "users": [{"id": "ce05fed6", "encryption": "none", "flow": ""}]}]},
        "streamSettings": {"network": "xhttp", "security": "reality"}
      },
      {"tag": "direct", "protocol": "freedom"},
      {"tag": "block", "protocol": "blackhole"}
    ],
    "burstObservatory": {"subjectSelector": ["proxy"]},
    "remarks": "Auto",
    "meta": {"serverDescription": "Auto"}
  }
]
''';

void main() {
  group('JsonSubscriptionParser', () {
    test('detects a JSON-subscription array', () {
      expect(
        JsonSubscriptionParser.looksLikeJsonSubscription(_jsonSubscription),
        isTrue,
      );
      // A SIP008 array (server/server_port entries) is not a JSON subscription.
      expect(
        JsonSubscriptionParser.looksLikeJsonSubscription(
          '[{"server":"1.2.3.4","server_port":8388,"method":"aes-256-gcm","password":"p"}]',
        ),
        isFalse,
      );
    });

    test('parses entries with extracted display fields', () {
      final servers = JsonSubscriptionParser.tryParse(_jsonSubscription)!;
      expect(servers, hasLength(2));

      final de = servers[0];
      expect(de.name, '🇩🇪 Germany');
      expect(de.serverDescription, 'VLESS • TCP • REALITY');
      expect(de.protocol, ProtocolType.vless);
      expect(de.address, 'cdn-de.net-infra.systems');
      expect(de.port, 443);
      expect(de.network, 'tcp');
      expect(de.security, 'reality');
      expect(de.sni, 'cdn-de.net-infra.systems');
      expect(de.publicKey, 'PK123');
      expect(de.shortId, 'SID123');
      expect(de.fingerprint, 'edge');
      expect(de.flow, 'xtls-rprx-vision');
      // Raw config is preserved verbatim for the core.
      expect(de.rawConfig, contains('realitySettings'));
    });

    test('picks the proxy-tagged outbound and preserves xhttp + balancer', () {
      final servers = JsonSubscriptionParser.tryParse(_jsonSubscription)!;
      final auto = servers[1];

      expect(auto.address, 'srv-101.net-infra.systems');
      expect(auto.port, 8443);
      expect(auto.network, 'xhttp');
      expect(auto.host, 'srv-101.net-infra.systems');
      expect(auto.path, '/static-lib-assets');
      expect(auto.xhttpMode, 'auto');
      // The full object (including the second proxy + observatory) is kept.
      expect(auto.rawConfig, contains('burstObservatory'));
      expect(auto.rawConfig, contains('srv-110.net-infra.systems'));
    });

    test('SubscriptionParser.parseBody routes JSON subscriptions here', () {
      final servers = SubscriptionParser.parseBody(_jsonSubscription);
      expect(servers, hasLength(2));
      expect(servers.every((s) => s.rawConfig != null), isTrue);
    });
  });
}
