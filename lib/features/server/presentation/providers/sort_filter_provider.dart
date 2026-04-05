import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sort_filter_provider.g.dart';

/// Criteria for sorting the server list.
enum SortCriteria { name, latency, protocol }

/// Criteria for filtering the server list by latency status.
enum FilterCriteria { all, working, failed }

/// Manages sort and filter state for the server list.
@riverpod
class SortFilterNotifier extends _$SortFilterNotifier {
  @override
  ({SortCriteria sort, FilterCriteria filter}) build() =>
      (sort: SortCriteria.name, filter: FilterCriteria.all);

  /// Update the sort criteria, preserving the current filter.
  void setSort(SortCriteria criteria) =>
      state = (sort: criteria, filter: state.filter);

  /// Update the filter criteria, preserving the current sort.
  void setFilter(FilterCriteria criteria) =>
      state = (sort: state.sort, filter: criteria);
}
