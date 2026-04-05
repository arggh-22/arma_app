// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EngineSettingsNotifier)
final engineSettingsProvider = EngineSettingsNotifierProvider._();

final class EngineSettingsNotifierProvider
    extends $NotifierProvider<EngineSettingsNotifier, EngineSettings> {
  EngineSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engineSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engineSettingsNotifierHash();

  @$internal
  @override
  EngineSettingsNotifier create() => EngineSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EngineSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EngineSettings>(value),
    );
  }
}

String _$engineSettingsNotifierHash() =>
    r'348d834fcf0b5dc0f480a2b18935e393027fa9b5';

abstract class _$EngineSettingsNotifier extends $Notifier<EngineSettings> {
  EngineSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EngineSettings, EngineSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EngineSettings, EngineSettings>,
              EngineSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
