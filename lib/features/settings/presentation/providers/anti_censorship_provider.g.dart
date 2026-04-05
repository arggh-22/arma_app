// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anti_censorship_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AntiCensorshipNotifier)
final antiCensorshipProvider = AntiCensorshipNotifierProvider._();

final class AntiCensorshipNotifierProvider
    extends $NotifierProvider<AntiCensorshipNotifier, AntiCensorshipSettings> {
  AntiCensorshipNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'antiCensorshipProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$antiCensorshipNotifierHash();

  @$internal
  @override
  AntiCensorshipNotifier create() => AntiCensorshipNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AntiCensorshipSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AntiCensorshipSettings>(value),
    );
  }
}

String _$antiCensorshipNotifierHash() =>
    r'094512fd13c5680c71021cd53605e4e3299c17fd';

abstract class _$AntiCensorshipNotifier
    extends $Notifier<AntiCensorshipSettings> {
  AntiCensorshipSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AntiCensorshipSettings, AntiCensorshipSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AntiCensorshipSettings, AntiCensorshipSettings>,
              AntiCensorshipSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
