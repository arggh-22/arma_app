import 'dart:io';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/server/data/services/latency_probe.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/latency_level.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/ping_type.dart';
import 'package:flutter_test/flutter_test.dart';

ServerConfig _server(String address, int port) => ServerConfig(
  id: 's',
  name: 'S',
  protocol: ProtocolType.vless,
  address: address,
  port: port,
  addedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  group('latencyProbeFor', () {
    test('maps each ping type to its probe', () {
      final svc = VpnPlatformService();
      expect(latencyProbeFor(PingType.http, svc), isA<XrayHttpProbe>());
      expect(latencyProbeFor(PingType.tcpConnect, svc), isA<TcpConnectProbe>());
      expect(latencyProbeFor(PingType.icmp, svc), isA<IcmpProbe>());
    });
  });

  group('TcpConnectProbe', () {
    test('returns a non-negative latency for a reachable port', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close());

      final ms = await const TcpConnectProbe().measure(
        _server('127.0.0.1', server.port),
      );

      expect(ms, isNot(kLatencyFailed));
      expect(ms, greaterThanOrEqualTo(0));
    });

    test('returns -1 when the port is closed', () async {
      // Bind then immediately release to obtain a port with nothing listening.
      final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final closedPort = probe.port;
      await probe.close();

      final ms = await const TcpConnectProbe().measure(
        _server('127.0.0.1', closedPort),
      );

      expect(ms, kLatencyFailed);
    });
  });
}
