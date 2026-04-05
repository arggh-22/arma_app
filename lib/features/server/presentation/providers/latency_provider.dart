import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/xray/xray_config_builder.dart';

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

  /// Test a single server's latency (SERV-03).
  Future<int> testServer(ServerConfig server) async {
    // Mark as testing (-2 = in progress)
    state = {...state, server.id: -2};
    final configJson = XrayConfigBuilder.buildForLatencyTest(server);
    final delay = await _platformService.measureDelay(configJson);
    state = {...state, server.id: delay};
    debugPrint('[LatencyNotifier] testServer(${server.name}): ${delay}ms');
    return delay;
  }

  /// Test all servers with concurrency limit of 3 (SERV-04, D-09).
  /// Results update progressively as each test completes.
  Future<void> testAllServers(List<ServerConfig> servers) async {
    if (_isBulkTesting) return;
    _isBulkTesting = true;

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
        final configJson = XrayConfigBuilder.buildForLatencyTest(server);
        final delay = await _platformService.measureDelay(configJson);
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
