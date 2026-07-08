import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/data/services/latency_probe.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/ping_type.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/ping_type_provider.dart';

part 'latency_provider.g.dart';

/// Latency test results: serverId → milliseconds (-1 = failed, -2 = testing).
/// Ephemeral state — not persisted to Hive (latency changes constantly).
@Riverpod(keepAlive: true)
class LatencyNotifier extends _$LatencyNotifier {
  final VpnPlatformService _platformService = VpnPlatformService();
  // Count, not a bool: a forced sweep may overlap a user-initiated one, and
  // whichever finishes first must not clear the "busy" signal for the other.
  int _bulkTestCount = 0;

  @override
  Map<String, int> build() => {};

  bool get isBulkTesting => _bulkTestCount > 0;

  /// For HTTP probes, tear down THIS app's own VPN first so the probe dials
  /// the proxy directly instead of routing through (and looping over) our own
  /// tunnel, which makes the measurement slow or time out.
  ///
  /// Returns the server to reconnect to when the probes are done (the active
  /// selection at the moment of disconnect), or null if nothing was torn down.
  /// Callers must pass the result to [_reconnectAfterHttp] in a `finally`.
  ///
  /// NOTE: this can only disconnect *our* VPN. A VPN owned by another app —
  /// especially an always-on / lockdown one — cannot be bypassed or disabled
  /// by us; Android routes all traffic through it, so probes will remain slow
  /// until the user turns that app off.
  Future<ServerConfig?> _ensureDirectPathForHttp(PingType type) async {
    if (type != PingType.http) return null;
    final status = ref.read(connectionProvider);
    if (status is! Connected && status is! Connecting) {
      debugPrint(
        '[LatencyNotifier] HTTP ping — own VPN not connected ($status); '
        'if a probe is slow, another app owns the active VPN.',
      );
      return null;
    }

    final activeServer = ref.read(activeServerProvider);
    debugPrint('[LatencyNotifier] HTTP ping — disconnecting own VPN first');
    await ref.read(connectionProvider.notifier).disconnect();

    // Wait until the native side reports the tunnel is FULLY down — a fixed
    // delay isn't enough (stopVpn is async), and probing while the TUN is
    // still tearing down routes the request through the dying tunnel, which is
    // exactly the slow/timeout behavior we're trying to avoid.
    final deadline = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(deadline)) {
      try {
        if (!await _platformService.isRunning) break;
      } catch (_) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    // Small extra settle so the OS has released VPN routing before we dial.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    debugPrint('[LatencyNotifier] HTTP ping — own VPN stopped, probing direct');

    if (activeServer == null) {
      debugPrint(
        '[LatencyNotifier] HTTP ping — no active selection to reconnect to '
        'after the probes; VPN will stay down.',
      );
    }
    return activeServer;
  }

  /// Restores the VPN torn down by [_ensureDirectPathForHttp].
  Future<void> _reconnectAfterHttp(ServerConfig? server) async {
    if (server == null) return;
    debugPrint(
      '[LatencyNotifier] HTTP ping done — reconnecting ${server.name}',
    );
    await ref.read(connectionProvider.notifier).connect(server);
  }

  /// Test a single server's latency (SERV-03).
  Future<int> testServer(ServerConfig server) async {
    final type = ref.read(pingTypeProvider);
    final reconnectTo = await _ensureDirectPathForHttp(type);
    try {
      final probe = latencyProbeFor(type, _platformService);
      // Mark as testing (-2 = in progress)
      state = {...state, server.id: -2};
      final delay = await probe.measure(server);
      state = {...state, server.id: delay};
      debugPrint('[LatencyNotifier] testServer(${server.name}): ${delay}ms');
      return delay;
    } finally {
      await _reconnectAfterHttp(reconnectTo);
    }
  }

  /// Test all servers with the currently selected ping type (SERV-04, D-09).
  Future<void> testAllServers(List<ServerConfig> servers) =>
      testAllServersWith(servers, ref.read(pingTypeProvider));

  /// Test all servers with an explicit [type] (e.g. a fast TCP sweep on
  /// startup), concurrency limit of 3. Results update progressively.
  ///
  /// Set [force] to run even if another bulk test is already in progress —
  /// used by startup so its sweep is never silently skipped.
  Future<void> testAllServersWith(
    List<ServerConfig> servers,
    PingType type, {
    bool force = false,
  }) async {
    if (_bulkTestCount > 0 && !force) return;
    _bulkTestCount++;
    ServerConfig? reconnectTo;
    try {
      reconnectTo = await _ensureDirectPathForHttp(type);
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
        await Future.wait(
          batch.map((server) async {
            final delay = await probe.measure(server);
            state = {...state, server.id: delay};
            debugPrint(
              '[LatencyNotifier] bulk test ${server.name}: ${delay}ms',
            );
          }),
        );
      }
    } finally {
      _bulkTestCount--;
      await _reconnectAfterHttp(reconnectTo);
    }
  }

  /// Get latency for a server. Returns null if untested.
  int? getLatency(String serverId) => state[serverId];
}
