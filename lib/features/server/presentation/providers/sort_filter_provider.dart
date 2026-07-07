import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';

part 'sort_filter_provider.g.dart';

/// Criteria for sorting the server list.
enum SortCriteria { defaultOrder, name, latency, protocol }

/// Criteria for filtering the server list by latency status.
enum FilterCriteria { all, working, failed }

/// Combined sort / filter / search state for the server list.
typedef SortFilterState = ({
  SortCriteria sort,
  FilterCriteria filter,
  String query,
  ProtocolType? protocol,
});

/// Manages sort, status filter, protocol quick-filter, and search query
/// state for the server list.
@riverpod
class SortFilterNotifier extends _$SortFilterNotifier {
  @override
  SortFilterState build() => (
    sort: SortCriteria.defaultOrder,
    filter: FilterCriteria.all,
    query: '',
    protocol: null,
  );

  /// Update the sort criteria, preserving the other fields.
  void setSort(SortCriteria criteria) => state = (
    sort: criteria,
    filter: state.filter,
    query: state.query,
    protocol: state.protocol,
  );

  /// Update the status filter, preserving the other fields.
  void setFilter(FilterCriteria criteria) => state = (
    sort: state.sort,
    filter: criteria,
    query: state.query,
    protocol: state.protocol,
  );

  /// Update the free-text search query, preserving the other fields.
  void setQuery(String query) => state = (
    sort: state.sort,
    filter: state.filter,
    query: query,
    protocol: state.protocol,
  );

  /// Update the protocol quick-filter (null = all protocols).
  void setProtocol(ProtocolType? protocol) => state = (
    sort: state.sort,
    filter: state.filter,
    query: state.query,
    protocol: protocol,
  );
}
