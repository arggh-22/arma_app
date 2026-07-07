import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/server/data/services/latency_probe.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/ping_type.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/ping_type_provider.dart';

part 'latency_provider.g.dart';

/// Latency test results: serverId → milliseconds (-1 = failed, -2 = testing).
/// Ephemeral state — not persisted to Hive (latency changes constantly).
@Riverpod(keepAlive: true)
class LatencyNotifier extends _$LatencyNotifier {
  final VpnPlatformService _platformService = VpnPlatformService();
  bool _isBulkTesting = false;

  @override
  Map<String, int> build() => {};

  bool get isBulkTesting => _isBulkTesting;

  /// The probe strategy for the currently selected ping type (spec §2).
  LatencyProbe get _probe =>
      latencyProbeFor(ref.read(pingTypeProvider), _platformService);

  /// Test a single server's latency (SERV-03).
  Future<int> testServer(ServerConfig server) async {
    final probe = _probe;
    // Mark as testing (-2 = in progress)
    state = {...state, server.id: -2};
    final delay = await probe.measure(server);
    state = {...state, server.id: delay};
    debugPrint('[LatencyNotifier] testServer(${server.name}): ${delay}ms');
    return delay;
  }

  /// Test all servers with the currently selected ping type (SERV-04, D-09).
  Future<void> testAllServers(List<ServerConfig> servers) =>
      testAllServersWith(servers, ref.read(pingTypeProvider));

  /// Test all servers with an explicit [type] (e.g. a fast TCP sweep on
  /// startup), concurrency limit of 3. Results update progressively.
  Future<void> testAllServersWith(
    List<ServerConfig> servers,
    PingType type,
  ) async {
    if (_isBulkTesting) return;
    _isBulkTesting = true;
    final probe = latencyProbeFor(type, _platformService);

    // Mark all as in-progress
    final inProgress = <String, int>{};
    for (final s in servers) {
      inProgress[s.id] = -2; // -2 = testing
    }
    state = {...state, ...inProgress};

    // Batch processing with concurrency limit of 3
    for (var i = 0; i < servers.length; i += 3) {
      final batch = servers.skip(i).take(3).toList();
      await Future.wait(batch.map((server) async {
        final delay = await probe.measure(server);
        state = {...state, server.id: delay};
        debugPrint(
          '[LatencyNotifier] bulk test ${server.name}: ${delay}ms',
        );
      }));
    }
    _isBulkTesting = false;
  }

  /// Get latency for a server. Returns null if untested.
  int? getLatency(String serverId) => state[serverId];
}
