import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/traffic_stats.dart';
import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';

part 'traffic_stats_provider.g.dart';

/// Riverpod notifier streaming real-time traffic statistics from the VPN engine.
///
/// Listens to EventChannel events of type "stats" and updates state with
/// uplink/downlink bytes per second. Reset to zero when VPN disconnects.
///
/// keepAlive: true — traffic stats persist across widget rebuilds.
@Riverpod(keepAlive: true)
class TrafficStatsNotifier extends _$TrafficStatsNotifier {
  final VpnPlatformService _platformService = VpnPlatformService();
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  @override
  TrafficStats build() {
    _eventSubscription = _platformService.vpnEvents
        .where((e) => e['type'] == 'stats')
        .listen((event) {
      state = TrafficStats(
        uplinkBytesPerSecond: (event['uplink'] as num?)?.toInt() ?? 0,
        downlinkBytesPerSecond: (event['downlink'] as num?)?.toInt() ?? 0,
      );
    });

    ref.onDispose(() => _eventSubscription?.cancel());

    return TrafficStats.zero;
  }

  /// Reset traffic stats to zero (e.g., on disconnect).
  void reset() {
    state = TrafficStats.zero;
  }
}
