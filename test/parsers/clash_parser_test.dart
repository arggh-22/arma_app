import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/clash_parser.dart';

void main() {
  group('ClashParser', () {
    test('parses vmess entry with ws-opts', () {
      const yaml = '''
proxies:
  - name: "Tokyo VMess"
    type: vmess
    server: 1.2.3.4
    port: 443
    uuid: test-uuid-1234
    alterId: 0
    cipher: auto
    network: ws
    tls: true
    servername: example.com
    ws-opts:
      path: /ws
      headers:
        Host: example.com
''';

      final result = ClashParser.tryParse(yaml);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].name, 'Tokyo VMess');
      expect(result[0].protocol, ProtocolType.vmess);
      expect(result[0].address, '1.2.3.4');
      expect(result[0].port, 443);
      expect(result[0].uuid, 'test-uuid-1234');
      expect(result[0].network, 'ws');
      expect(result[0].security, 'tls');
      expect(result[0].path, '/ws');
      expect(result[0].host, 'example.com');
      expect(result[0].sni, 'example.com');
    });

    test('parses trojan entry with TLS', () {
      const yaml = '''
proxies:
  - name: "US Trojan"
    type: trojan
    server: 5.6.7.8
    port: 443
    password: mypassword
    tls: true
    sni: trojan.example.com
''';

      final result = ClashParser.tryParse(yaml);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].name, 'US Trojan');
      expect(result[0].protocol, ProtocolType.trojan);
      expect(result[0].address, '5.6.7.8');
      expect(result[0].port, 443);
      expect(result[0].password, 'mypassword');
      expect(result[0].security, 'tls');
      expect(result[0].sni, 'trojan.example.com');
    });

    test('skips unsupported type (snell)', () {
      const yaml = '''
proxies:
  - name: "Valid"
    type: vmess
    server: 1.2.3.4
    port: 443
    uuid: test-uuid
    alterId: 0
    cipher: auto
  - name: "Unsupported"
    type: snell
    server: 5.6.7.8
    port: 443
    psk: some-key
''';

      final result = ClashParser.tryParse(yaml);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].name, 'Valid');
    });

    test('returns null for invalid YAML', () {
      final result = ClashParser.tryParse('not: [valid: yaml: {{{');
      expect(result, isNull);
    });

    test('returns null for YAML without proxies key', () {
      const yaml = '''
servers:
  - name: "No proxies"
    type: vmess
''';

      final result = ClashParser.tryParse(yaml);
      expect(result, isNull);
    });

    test('parses shadowsocks entry', () {
      const yaml = '''
proxies:
  - name: "SS Node"
    type: ss
    server: 3.4.5.6
    port: 8388
    cipher: aes-256-gcm
    password: sspwd
''';

      final result = ClashParser.tryParse(yaml);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].protocol, ProtocolType.shadowsocks);
      expect(result[0].address, '3.4.5.6');
      expect(result[0].port, 8388);
      expect(result[0].method, 'aes-256-gcm');
      expect(result[0].password, 'sspwd');
    });

    test('parses vless entry', () {
      const yaml = '''
proxies:
  - name: "VLESS Node"
    type: vless
    server: 2.3.4.5
    port: 443
    uuid: vless-uuid-1234
    network: tcp
    tls: true
    flow: xtls-rprx-vision
    servername: vless.example.com
''';

      final result = ClashParser.tryParse(yaml);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].protocol, ProtocolType.vless);
      expect(result[0].uuid, 'vless-uuid-1234');
      expect(result[0].flow, 'xtls-rprx-vision');
    });

    test('parses hysteria2 entry', () {
      const yaml = '''
proxies:
  - name: "HY2 Node"
    type: hysteria2
    server: 6.7.8.9
    port: 443
    password: hy2pwd
    sni: hy2.example.com
    obfs: salamander
    obfs-password: obfspwd
''';

      final result = ClashParser.tryParse(yaml);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].protocol, ProtocolType.hysteria2);
      expect(result[0].password, 'hy2pwd');
      expect(result[0].obfs, 'salamander');
      expect(result[0].obfsPassword, 'obfspwd');
    });

    test('parses grpc-opts correctly', () {
      const yaml = '''
proxies:
  - name: "gRPC Node"
    type: vless
    server: 1.2.3.4
    port: 443
    uuid: grpc-uuid
    network: grpc
    tls: true
    grpc-opts:
      grpc-service-name: myservice
''';

      final result = ClashParser.tryParse(yaml);

      expect(result, isNotNull);
      expect(result![0].network, 'grpc');
      expect(result[0].serviceName, 'myservice');
    });

    test('parses h2-opts correctly', () {
      const yaml = '''
proxies:
  - name: "H2 Node"
    type: vmess
    server: 1.2.3.4
    port: 443
    uuid: h2-uuid
    alterId: 0
    cipher: auto
    network: h2
    tls: true
    h2-opts:
      path: /h2path
      host:
        - h2.example.com
''';

      final result = ClashParser.tryParse(yaml);

      expect(result, isNotNull);
      expect(result![0].network, 'h2');
      expect(result[0].path, '/h2path');
      expect(result[0].host, 'h2.example.com');
    });
  });
}
