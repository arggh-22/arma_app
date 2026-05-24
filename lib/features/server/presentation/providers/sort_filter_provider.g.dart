// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sort_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages sort and filter state for the server list.

@ProviderFor(SortFilterNotifier)
final sortFilterProvider = SortFilterNotifierProvider._();

/// Manages sort and filter state for the server list.
final class SortFilterNotifierProvider
    extends
        $NotifierProvider<
          SortFilterNotifier,
          ({FilterCriteria filter, SortCriteria sort})
        > {
  /// Manages sort and filter state for the server list.
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
  Override overrideWithValue(
    ({FilterCriteria filter, SortCriteria sort}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({FilterCriteria filter, SortCriteria sort})>(
            value,
          ),
    );
  }
}

String _$sortFilterNotifierHash() =>
    r'32d585414e41c62378681bdc224b0b0039886eac';

/// Manages sort and filter state for the server list.

abstract class _$SortFilterNotifier
    extends $Notifier<({FilterCriteria filter, SortCriteria sort})> {
  ({FilterCriteria filter, SortCriteria sort}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({FilterCriteria filter, SortCriteria sort}),
              ({FilterCriteria filter, SortCriteria sort})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({FilterCriteria filter, SortCriteria sort}),
                ({FilterCriteria filter, SortCriteria sort})
              >,
              ({FilterCriteria filter, SortCriteria sort}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
