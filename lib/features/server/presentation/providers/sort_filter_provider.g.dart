// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sort_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages sort, status filter, protocol quick-filter, and search query
/// state for the server list.

@ProviderFor(SortFilterNotifier)
final sortFilterProvider = SortFilterNotifierProvider._();

/// Manages sort, status filter, protocol quick-filter, and search query
/// state for the server list.
final class SortFilterNotifierProvider
    extends $NotifierProvider<SortFilterNotifier, SortFilterState> {
  /// Manages sort, status filter, protocol quick-filter, and search query
  /// state for the server list.
  SortFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sortFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sortFilterNotifierHash();

  @$internal
  @override
  SortFilterNotifier create() => SortFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SortFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SortFilterState>(value),
    );
  }
}

String _$sortFilterNotifierHash() =>
    r'ffa3597f76d2025173bb72dc4ac5ae13e765da6f';

/// Manages sort, status filter, protocol quick-filter, and search query
/// state for the server list.

abstract class _$SortFilterNotifier extends $Notifier<SortFilterState> {
  SortFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SortFilterState, SortFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SortFilterState, SortFilterState>,
              SortFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
