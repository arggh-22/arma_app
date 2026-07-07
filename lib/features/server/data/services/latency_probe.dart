import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/latency_level.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/ping_type.dart';
import 'package:arma_proxy_vpn_client/xray/xray_config_builder.dart';

/// Hard latency-measurement timeout (spec §4.3: 3s, max 5s).
const Duration kLatencyProbeTimeout = Duration(seconds: 3);

/// Strategy for measuring a server's latency. Returns the delay in ms, or
/// [kLatencyFailed] (-1) on timeout/failure.
abstract class LatencyProbe {
  Future<int> measure(ServerConfig server);
}

/// Selects the probe for a [PingType].
LatencyProbe latencyProbeFor(
  PingType type,
  VpnPlatformService platformService,
) {
  switch (type) {
    case PingType.http:
      return XrayHttpProbe(platformService);
    case PingType.tcpConnect:
      return const TcpConnectProbe();
    case PingType.icmp:
      return const IcmpProbe();
  }
}

/// HTTP end-to-end probe (spec §2A / §4.1): routes an HTTP request through the
/// server's Xray proxy via the native `MeasureDelay`. The native side performs
/// the actual HEAD→GET request to the connectivity-check endpoint.
class XrayHttpProbe implements LatencyProbe {
  const XrayHttpProbe(this._platformService);

  final VpnPlatformService _platformService;

  /// Spec §2A endpoint — returns 204 No Content with an empty body.
  static const _connectivityCheckUrl =
      'http://connectivitycheck.gstatic.com/generate_204';

  @override
  Future<int> measure(ServerConfig server) {
    final configJson = XrayConfigBuilder.buildForLatencyTest(server);
    return _platformService.measureDelay(
      configJson,
      testUrl: _connectivityCheckUrl,
    );
  }
}

/// TCP Connect probe (spec §2B): direct TCP handshake to the server's
/// host:port, bypassing the tunnel. Fast liveness check for the whole list.
class TcpConnectProbe implements LatencyProbe {
  const TcpConnectProbe();

  @override
  Future<int> measure(ServerConfig server) async {
    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        server.address,
        server.port,
        timeout: kLatencyProbeTimeout,
      );
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      debugPrint('[TcpConnectProbe] ${server.address}:${server.port} → $e');
      return kLatencyFailed;
    } finally {
      socket?.destroy();
    }
  }
}

/// ICMP probe (spec §2C): system `ping` to the server IP, bypassing the tunnel.
/// Best-effort — uses the OS `ping` binary (available on Android/Linux/macOS);
/// returns [kLatencyFailed] where unsupported (e.g. iOS has no `Process`).
class IcmpProbe implements LatencyProbe {
  const IcmpProbe();

  @override
  Future<int> measure(ServerConfig server) async {
    final timeoutSecs = kLatencyProbeTimeout.inSeconds;
    // macOS/iOS use `-t` for per-packet timeout; Linux/Android use `-W`.
    final args = Platform.isMacOS
        ? ['-c', '1', '-t', '$timeoutSecs', server.address]
        : ['-c', '1', '-W', '$timeoutSecs', server.address];
    try {
      final result = await Process.run('ping', args)
          .timeout(kLatencyProbeTimeout + const Duration(seconds: 1));
      if (result.exitCode != 0) return kLatencyFailed;
      final ms = _parsePingMs('${result.stdout}');
      return ms ?? kLatencyFailed;
    } catch (e) {
      debugPrint('[IcmpProbe] ${server.address} → $e');
      return kLatencyFailed;
    }
  }

  /// Extracts the round-trip time from `ping` output (`time=12.3 ms`).
  static int? _parsePingMs(String output) {
    final match = RegExp(r'time[=<]\s*([\d.]+)').firstMatch(output);
    if (match == null) return null;
    final value = double.tryParse(match.group(1) ?? '');
    return value?.round();
  }
}
