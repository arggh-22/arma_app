// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multi_select_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Multi-select state: set of selected server IDs.
/// Empty set = not in selection mode.

@ProviderFor(MultiSelectNotifier)
final multiSelectProvider = MultiSelectNotifierProvider._();

/// Multi-select state: set of selected server IDs.
/// Empty set = not in selection mode.
final class MultiSelectNotifierProvider
    extends $NotifierProvider<MultiSelectNotifier, Set<String>> {
  /// Multi-select state: set of selected server IDs.
  /// Empty set = not in selection mode.
  MultiSelectNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'multiSelectProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$multiSelectNotifierHash();

  @$internal
  @override
  MultiSelectNotifier create() => MultiSelectNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$multiSelectNotifierHash() =>
    r'298a8cd6bcab15a21d986410acd2c29c3177bd28';

/// Multi-select state: set of selected server IDs.
/// Empty set = not in selection mode.

abstract class _$MultiSelectNotifier extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
