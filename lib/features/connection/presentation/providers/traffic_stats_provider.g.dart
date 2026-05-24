// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traffic_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier streaming real-time traffic statistics from the VPN engine.
///
/// Listens to EventChannel events of type "stats" and updates state with
/// uplink/downlink bytes per second. Reset to zero when VPN disconnects.
///
/// keepAlive: true — traffic stats persist across widget rebuilds.

@ProviderFor(TrafficStatsNotifier)
final trafficStatsProvider = TrafficStatsNotifierProvider._();

/// Riverpod notifier streaming real-time traffic statistics from the VPN engine.
///
/// Listens to EventChannel events of type "stats" and updates state with
/// uplink/downlink bytes per second. Reset to zero when VPN disconnects.
///
/// keepAlive: true — traffic stats persist across widget rebuilds.
final class TrafficStatsNotifierProvider
    extends $NotifierProvider<TrafficStatsNotifier, TrafficStats> {
  /// Riverpod notifier streaming real-time traffic statistics from the VPN engine.
  ///
  /// Listens to EventChannel events of type "stats" and updates state with
  /// uplink/downlink bytes per second. Reset to zero when VPN disconnects.
  ///
  /// keepAlive: true — traffic stats persist across widget rebuilds.
  TrafficStatsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trafficStatsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trafficStatsNotifierHash();

  @$internal
  @override
  TrafficStatsNotifier create() => TrafficStatsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrafficStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrafficStats>(value),
    );
  }
}

String _$trafficStatsNotifierHash() =>
    r'7c07ecee56f180875792b4ef4adfa80118b7022d';

/// Riverpod notifier streaming real-time traffic statistics from the VPN engine.
///
/// Listens to EventChannel events of type "stats" and updates state with
/// uplink/downlink bytes per second. Reset to zero when VPN disconnects.
///
/// keepAlive: true — traffic stats persist across widget rebuilds.

abstract class _$TrafficStatsNotifier extends $Notifier<TrafficStats> {
  TrafficStats build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TrafficStats, TrafficStats>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrafficStats, TrafficStats>,
              TrafficStats,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
