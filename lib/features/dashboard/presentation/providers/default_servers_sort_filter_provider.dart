import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/sort_filter_provider.dart';

/// Sort / filter / search state for the home screen's default servers list.
///
/// Kept separate from the Servers tab [sortFilterProvider] so filtering the
/// default servers on home does not affect the imported-servers list (and
/// vice versa). Reuses the same [SortFilterState] shape and enums.
class DefaultServersSortFilterNotifier extends Notifier<SortFilterState> {
  @override
  SortFilterState build() => (
    sort: SortCriteria.defaultOrder,
    filter: FilterCriteria.all,
    query: '',
    protocol: null,
  );

  void setSort(SortCriteria criteria) => state = (
    sort: criteria,
    filter: state.filter,
    query: state.query,
    protocol: state.protocol,
  );

  void setFilter(FilterCriteria criteria) => state = (
    sort: state.sort,
    filter: criteria,
    query: state.query,
    protocol: state.protocol,
  );

  void setQuery(String query) => state = (
    sort: state.sort,
    filter: state.filter,
    query: query,
    protocol: state.protocol,
  );

  void setProtocol(ProtocolType? protocol) => state = (
    sort: state.sort,
    filter: state.filter,
    query: state.query,
    protocol: protocol,
  );
}

final defaultServersSortFilterProvider =
    NotifierProvider<DefaultServersSortFilterNotifier, SortFilterState>(
  DefaultServersSortFilterNotifier.new,
);
