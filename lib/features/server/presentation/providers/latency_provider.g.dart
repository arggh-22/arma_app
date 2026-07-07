// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'latency_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Latency test results: serverId → milliseconds (-1 = failed, -2 = testing).
/// Ephemeral state — not persisted to Hive (latency changes constantly).

@ProviderFor(LatencyNotifier)
final latencyProvider = LatencyNotifierProvider._();

/// Latency test results: serverId → milliseconds (-1 = failed, -2 = testing).
/// Ephemeral state — not persisted to Hive (latency changes constantly).
final class LatencyNotifierProvider
    extends $NotifierProvider<LatencyNotifier, Map<String, int>> {
  /// Latency test results: serverId → milliseconds (-1 = failed, -2 = testing).
  /// Ephemeral state — not persisted to Hive (latency changes constantly).
  LatencyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latencyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latencyNotifierHash();

  @$internal
  @override
  LatencyNotifier create() => LatencyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$latencyNotifierHash() => r'5b7cd80300aecc2d78c33d555a8383d45ab46891';

/// Latency test results: serverId → milliseconds (-1 = failed, -2 = testing).
/// Ephemeral state — not persisted to Hive (latency changes constantly).

abstract class _$LatencyNotifier extends $Notifier<Map<String, int>> {
  Map<String, int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, int>, Map<String, int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, int>, Map<String, int>>,
              Map<String, int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
