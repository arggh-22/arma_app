import 'dart:convert';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/xray/xray_config_builder.dart';
import 'package:flutter_test/flutter_test.dart';

ServerConfig _makeServer({
  ProtocolType protocol = ProtocolType.vless,
  String address = 'test.example.com',
  int port = 443,
  String? uuid = 'test-uuid-1234',
  String? password,
  String network = 'tcp',
  String security = 'none',
  String? sni,
  String? host,
  String? path,
  String? alpn,
  String? fingerprint,
  String? flow,
  int alterId = 0,
  String? serviceName,
  String? authority,
  String? publicKey,
  String? shortId,
  String? spiderX,
  String? method,
  String encryption = 'none',
}) =>
    ServerConfig(
      id: 'test-id',
      name: 'Test Server',
      protocol: protocol,
      address: address,
      port: port,
      uuid: uuid,
      password: password,
      network: network,
      security: security,
      sni: sni,
      host: host,
      path: path,
      alpn: alpn,
      fingerprint: fingerprint,
      flow: flow,
      alterId: alterId,
      serviceName: serviceName,
      authority: authority,
      publicKey: publicKey,
      shortId: shortId,
      spiderX: spiderX,
      method: method,
      encryption: encryption,
      addedAt: DateTime(2024, 1, 1),
    );

void main() {
  group('VLESS protocol', () {
    test('VLESS TCP Reality with XTLS-Vision', () {
      final server = _makeServer(
        protocol: ProtocolType.vless,
        security: 'reality',
        flow: 'xtls-rprx-vision',
        publicKey: 'testPK',
        shortId: 'abc',
        spiderX: '/test',
        fingerprint: 'chrome',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final outbounds = json['outbounds'] as List;
      final proxy = outbounds[0] as Map<String, dynamic>;

      expect(proxy['protocol'], 'vless');

      final settings = proxy['settings'] as Map<String, dynamic>;
      expect(settings.containsKey('vnext'), isTrue);

      final vnext = (settings['vnext'] as List)[0] as Map<String, dynamic>;
      final users = (vnext['users'] as List)[0] as Map<String, dynamic>;
      expect(users['flow'], 'xtls-rprx-vision');
      expect(users['encryption'], 'none');

      final streamSettings =
          proxy['streamSettings'] as Map<String, dynamic>;
      expect(streamSettings.containsKey('realitySettings'), isTrue);
      expect(streamSettings.containsKey('tlsSettings'), isFalse);

      final reality =
          streamSettings['realitySettings'] as Map<String, dynamic>;
      expect(reality['publicKey'], 'testPK');
      expect(reality['shortId'], 'abc');
      expect(reality['spiderX'], '/test');
    });

    test('VLESS WS TLS clears flow', () {
      final server = _makeServer(
        protocol: ProtocolType.vless,
        network: 'ws',
        security: 'tls',
        flow: 'xtls-rprx-vision',
        path: '/ws-path',
        host: 'ws.example.com',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final outbounds = json['outbounds'] as List;
      final proxy = outbounds[0] as Map<String, dynamic>;
      final settings = proxy['settings'] as Map<String, dynamic>;
      final vnext = (settings['vnext'] as List)[0] as Map<String, dynamic>;
      final users = (vnext['users'] as List)[0] as Map<String, dynamic>;

      // Flow MUST be cleared for non-TCP transport
      expect(users['flow'], '');

      final streamSettings =
          proxy['streamSettings'] as Map<String, dynamic>;
      expect(streamSettings.containsKey('tlsSettings'), isTrue);
      expect(streamSettings.containsKey('wsSettings'), isTrue);
    });

    test('VLESS gRPC Reality', () {
      final server = _makeServer(
        protocol: ProtocolType.vless,
        network: 'grpc',
        security: 'reality',
        serviceName: 'mygrpc',
        authority: 'grpc.example.com',
        publicKey: 'realityPK',
        shortId: 'def',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;
      final streamSettings =
          proxy['streamSettings'] as Map<String, dynamic>;

      expect(streamSettings.containsKey('realitySettings'), isTrue);
      expect(streamSettings.containsKey('grpcSettings'), isTrue);

      final grpc = streamSettings['grpcSettings'] as Map<String, dynamic>;
      expect(grpc['serviceName'], 'mygrpc');
    });
  });

  group('VMess protocol', () {
    test('VMess TCP auto security', () {
      final server = _makeServer(
        protocol: ProtocolType.vmess,
        encryption: 'none',
        alterId: 0,
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;

      expect(proxy['protocol'], 'vmess');

      final settings = proxy['settings'] as Map<String, dynamic>;
      final vnext = (settings['vnext'] as List)[0] as Map<String, dynamic>;
      final users = (vnext['users'] as List)[0] as Map<String, dynamic>;

      expect(users['security'], 'auto');
      expect(users['alterId'], 0);
    });

    test('VMess WS TLS', () {
      final server = _makeServer(
        protocol: ProtocolType.vmess,
        network: 'ws',
        security: 'tls',
        path: '/ws',
        host: 'ws.vmess.com',
        sni: 'ws.vmess.com',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;
      final streamSettings =
          proxy['streamSettings'] as Map<String, dynamic>;

      expect(streamSettings.containsKey('wsSettings'), isTrue);
      expect(streamSettings.containsKey('tlsSettings'), isTrue);

      final ws = streamSettings['wsSettings'] as Map<String, dynamic>;
      expect(ws['path'], '/ws');
    });
  });

  group('Trojan protocol', () {
    test('Trojan uses servers[] not vnext[]', () {
      final server = _makeServer(
        protocol: ProtocolType.trojan,
        password: 'mypass',
        security: 'tls',
        sni: 'trojan.example.com',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;

      expect(proxy['protocol'], 'trojan');

      final settings = proxy['settings'] as Map<String, dynamic>;
      expect(settings.containsKey('servers'), isTrue);
      expect(settings.containsKey('vnext'), isFalse);

      final servers =
          (settings['servers'] as List)[0] as Map<String, dynamic>;
      expect(servers['password'], 'mypass');
      expect(servers['address'], 'test.example.com');
      expect(servers['port'], 443);
    });
  });

  group('Shadowsocks protocol', () {
    test('Shadowsocks includes method', () {
      final server = _makeServer(
        protocol: ProtocolType.shadowsocks,
        method: 'aes-256-gcm',
        password: 'sspass',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;

      expect(proxy['protocol'], 'shadowsocks');

      final settings = proxy['settings'] as Map<String, dynamic>;
      expect(settings.containsKey('servers'), isTrue);
      expect(settings.containsKey('vnext'), isFalse);

      final servers =
          (settings['servers'] as List)[0] as Map<String, dynamic>;
      expect(servers['method'], 'aes-256-gcm');
      expect(servers['password'], 'sspass');
    });
  });

  group('Transport types', () {
    test('TCP transport', () {
      final server = _makeServer(network: 'tcp');

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;
      final streamSettings =
          proxy['streamSettings'] as Map<String, dynamic>;

      expect(streamSettings['network'], 'tcp');
      expect(streamSettings.containsKey('tcpSettings'), isTrue);

      final tcp = streamSettings['tcpSettings'] as Map<String, dynamic>;
      final header = tcp['header'] as Map<String, dynamic>;
      expect(header['type'], 'none');
    });

    test('WebSocket transport', () {
      final server = _makeServer(
        network: 'ws',
        path: '/mypath',
        host: 'ws.host.com',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;
      final streamSettings =
          proxy['streamSettings'] as Map<String, dynamic>;

      expect(streamSettings.containsKey('wsSettings'), isTrue);
      final ws = streamSettings['wsSettings'] as Map<String, dynamic>;
      expect(ws['path'], '/mypath');
      final headers = ws['headers'] as Map<String, dynamic>;
      expect(headers['Host'], 'ws.host.com');
    });

    test('gRPC transport', () {
      final server = _makeServer(
        network: 'grpc',
        serviceName: 'myservice',
        authority: 'grpc.auth.com',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;
      final streamSettings =
          proxy['streamSettings'] as Map<String, dynamic>;

      expect(streamSettings.containsKey('grpcSettings'), isTrue);
      final grpc = streamSettings['grpcSettings'] as Map<String, dynamic>;
      expect(grpc['serviceName'], 'myservice');
      expect(grpc['authority'], 'grpc.auth.com');
      expect(grpc['multiMode'], false);
    });

    test('H2 transport forces TLS', () {
      final server = _makeServer(
        network: 'h2',
        security: 'none',
        host: 'h2.example.com',
        path: '/h2path',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;
      final streamSettings =
          proxy['streamSettings'] as Map<String, dynamic>;

      // H2 always forces TLS
      expect(streamSettings['security'], 'tls');
      expect(streamSettings.containsKey('tlsSettings'), isTrue);
      expect(streamSettings.containsKey('httpSettings'), isTrue);

      final http = streamSettings['httpSettings'] as Map<String, dynamic>;
      expect(http['host'], ['h2.example.com']);
      expect(http['path'], '/h2path');
    });

    test('XHTTP transport normalizes to splithttp network name', () {
      final server = _makeServer(
        network: 'xhttp',
        security: 'tls',
        host: 'cdn.example.com',
        path: '/download',
        sni: 'cdn.example.com',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;
      final stream = proxy['streamSettings'] as Map<String, dynamic>;

      // Must use 'splithttp' network name (not 'xhttp') — AAR only
      // registers this transport as 'splithttp'
      expect(stream['network'], 'splithttp');
      expect(stream.containsKey('splithttpSettings'), isTrue);
      expect(stream.containsKey('xhttpSettings'), isFalse);

      final settings = stream['splithttpSettings'] as Map<String, dynamic>;
      expect(settings['path'], '/download');
      expect(settings['host'], 'cdn.example.com');
      // Default: no mode set (Xray uses packet-up default, matching happ/standard configs)
      expect(settings.containsKey('mode'), isFalse);

      // SplitHTTP forces HTTP/1.1 via ALPN — server returns 400 Bad Request on h2
      final tls = stream['tlsSettings'] as Map<String, dynamic>;
      expect(tls['alpn'], ['http/1.1']);
    });

    test('XHTTP user-configured ALPN is included in tlsSettings', () {
      final server = _makeServer(
        network: 'xhttp',
        security: 'tls',
        alpn: 'h2',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final stream = (json['outbounds'] as List)[0]['streamSettings']
          as Map<String, dynamic>;
      final tls = stream['tlsSettings'] as Map<String, dynamic>;
      // User explicitly set alpn=h2, should be included
      expect(tls['alpn'], ['h2']);
    });

    test('XHTTP user-configured mode is applied when set', () {
      final server = ServerConfig(
        id: 'test-id',
        name: 'xhttp mode test',
        protocol: ProtocolType.vless,
        address: 'srv.example.com',
        port: 443,
        uuid: 'test-uuid',
        network: 'xhttp',
        xhttpMode: 'stream-up',
        security: 'tls',
        path: '/up',
        host: 'cdn.example.com',
        addedAt: DateTime(2024, 1, 1),
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final stream = (json['outbounds'] as List)[0]['streamSettings']
          as Map<String, dynamic>;

      final settings = stream['splithttpSettings'] as Map<String, dynamic>;
      expect(settings['mode'], 'stream-up');
    });

    test('splithttp network type also uses splithttpSettings', () {
      final server = _makeServer(
        network: 'splithttp',
        host: 'cdn.example.com',
        path: '/path',
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final stream = (json['outbounds'] as List)[0]['streamSettings']
          as Map<String, dynamic>;

      expect(stream['network'], 'splithttp');
      expect(stream.containsKey('splithttpSettings'), isTrue);
    });

    test('XHTTP does not set flow even when flow is provided', () {
      final server = _makeServer(
        network: 'xhttp',
        security: 'tls',
        flow: 'xtls-rprx-vision', // should be ignored for non-tcp
      );

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final proxy =
          (json['outbounds'] as List)[0] as Map<String, dynamic>;
      final settings = proxy['settings'] as Map<String, dynamic>;
      final users =
          ((settings['vnext'] as List)[0]['users'] as List)[0]
              as Map<String, dynamic>;

      expect(users['flow'], '');
    });
  });

  group('Config structure', () {
    test('always includes stats and policy', () {
      final server = _makeServer();

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;

      expect(json.containsKey('stats'), isTrue);
      expect(json['stats'], isEmpty);

      final policy = json['policy'] as Map<String, dynamic>;
      final system = policy['system'] as Map<String, dynamic>;
      expect(system['statsOutboundUplink'], true);
      expect(system['statsOutboundDownlink'], true);
    });

    test('includes split DNS', () {
      final server = _makeServer();

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final dns = json['dns'] as Map<String, dynamic>;
      final servers = dns['servers'] as List;

      expect(servers, isNotEmpty);
      expect(servers.contains('localhost'), isTrue);
    });

    test('includes LAN bypass routing', () {
      final server = _makeServer();

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final routing = json['routing'] as Map<String, dynamic>;
      final rules = routing['rules'] as List;

      // Find geoip:private → direct rule
      final privateIpRule = rules.firstWhere(
        (r) => (r as Map<String, dynamic>)['ip']?.contains('geoip:private') == true,
        orElse: () => null,
      );
      expect(privateIpRule, isNotNull);
      expect(privateIpRule['outboundTag'], 'direct');

      // Find geosite:private → direct rule
      final privateDomainRule = rules.firstWhere(
        (r) => (r as Map<String, dynamic>)['domain']?.contains('geosite:private') == true,
        orElse: () => null,
      );
      expect(privateDomainRule, isNotNull);
      expect(privateDomainRule['outboundTag'], 'direct');
    });

    test('has three outbounds: proxy, direct, block', () {
      final server = _makeServer();

      final json = jsonDecode(XrayConfigBuilder.build(server))
          as Map<String, dynamic>;
      final outbounds = json['outbounds'] as List;

      expect(outbounds.length, 3);
      expect(
        outbounds.map((o) => (o as Map<String, dynamic>)['tag']).toList(),
        ['proxy', 'direct', 'block'],
      );
    });
  });
}
