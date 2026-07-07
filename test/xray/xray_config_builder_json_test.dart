import 'dart:convert';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/xray/xray_config_builder.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal JSON-subscription profile config (as stored in
/// [ServerConfig.rawConfig]) with the socks/http inbounds the server ships.
const _rawProfile = '''
{
  "dns": {"servers": ["1.1.1.1"]},
  "inbounds": [
    {"tag": "socks", "protocol": "socks", "port": 10808, "listen": "127.0.0.1"},
    {"tag": "http", "protocol": "http", "port": 10809, "listen": "127.0.0.1"}
  ],
  "outbounds": [
    {"tag": "proxy", "protocol": "vless",
      "settings": {"vnext": [{"address": "srv-101.net-infra.systems", "port": 8443,
        "users": [{"id": "ce05fed6", "encryption": "none", "flow": ""}]}]},
      "streamSettings": {"network": "xhttp", "security": "reality",
        "xhttpSettings": {"path": "/static-lib-assets", "mode": "auto"}}},
    {"tag": "direct", "protocol": "freedom"},
    {"tag": "block", "protocol": "blackhole"}
  ],
  "routing": {"rules": [{"type": "field", "outboundTag": "direct", "ip": ["geoip:ru"]}]},
  "burstObservatory": {"subjectSelector": ["proxy"]}
}
''';

ServerConfig _rawServer() => ServerConfig(
      id: 'default-api-1',
      name: 'Auto',
      protocol: ProtocolType.vless,
      address: 'srv-101.net-infra.systems',
      port: 8443,
      network: 'xhttp',
      security: 'reality',
      rawConfig: _rawProfile,
      addedAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  group('XrayConfigBuilder with rawConfig', () {
    test('build() swaps inbounds for the TUN inbound, keeps server config', () {
      final json = XrayConfigBuilder.build(_rawServer());
      final config = jsonDecode(json) as Map<String, dynamic>;

      final inbounds = config['inbounds'] as List;
      expect(inbounds, hasLength(1));
      expect((inbounds.single as Map)['protocol'], 'tun');

      // Server's own outbounds, routing, observatory and dns are preserved.
      expect(json, contains('srv-101.net-infra.systems'));
      expect(config.containsKey('burstObservatory'), isTrue);
      expect(config.containsKey('routing'), isTrue);
      expect(config.containsKey('dns'), isTrue);

      // Stats + policy injected so traffic stats keep working.
      expect(config.containsKey('stats'), isTrue);
      expect(config.containsKey('policy'), isTrue);
    });

    test('buildForLatencyTest() extracts the proxy outbound, no inbounds', () {
      final json = XrayConfigBuilder.buildForLatencyTest(_rawServer());
      final config = jsonDecode(json) as Map<String, dynamic>;

      expect(config.containsKey('inbounds'), isFalse);
      expect(config.containsKey('routing'), isFalse);

      final outbounds = config['outbounds'] as List;
      expect(outbounds, hasLength(2));
      expect((outbounds.first as Map)['protocol'], 'vless');
      expect((outbounds.first as Map)['tag'], 'proxy');
      expect((outbounds.last as Map)['protocol'], 'freedom');
      // xhttp transport settings survive into the latency config.
      expect(json, contains('xhttpSettings'));
    });

    test('build() falls back to field-based config when rawConfig is null', () {
      final json = XrayConfigBuilder.build(
        _rawServer().copyWith(rawConfig: null),
      );
      final config = jsonDecode(json) as Map<String, dynamic>;
      // Field-based build has no burstObservatory and a tun inbound.
      expect(config.containsKey('burstObservatory'), isFalse);
      expect((config['inbounds'] as List).single['protocol'], 'tun');
    });
  });
}
