// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routing_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier managing all routing settings with persistence.
///
/// Reads from SharedPreferences (lightweight values) and Hive (domain rules).
/// Writes back immediately on each mutation — no save button needed.

@ProviderFor(RoutingSettingsNotifier)
final routingSettingsProvider = RoutingSettingsNotifierProvider._();

/// Riverpod notifier managing all routing settings with persistence.
///
/// Reads from SharedPreferences (lightweight values) and Hive (domain rules).
/// Writes back immediately on each mutation — no save button needed.
final class RoutingSettingsNotifierProvider
    extends $NotifierProvider<RoutingSettingsNotifier, RoutingSettings> {
  /// Riverpod notifier managing all routing settings with persistence.
  ///
  /// Reads from SharedPreferences (lightweight values) and Hive (domain rules).
  /// Writes back immediately on each mutation — no save button needed.
  RoutingSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routingSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routingSettingsNotifierHash();

  @$internal
  @override
  RoutingSettingsNotifier create() => RoutingSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoutingSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoutingSettings>(value),
    );
  }
}

String _$routingSettingsNotifierHash() =>
    r'16ec8f387fa0c849dd2b6d6edfdabe4772edbded';

/// Riverpod notifier managing all routing settings with persistence.
///
/// Reads from SharedPreferences (lightweight values) and Hive (domain rules).
/// Writes back immediately on each mutation — no save button needed.

abstract class _$RoutingSettingsNotifier extends $Notifier<RoutingSettings> {
  RoutingSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RoutingSettings, RoutingSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RoutingSettings, RoutingSettings>,
              RoutingSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
