import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/latency_level.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/sort_filter_provider.dart';

/// Shared server list sort/filter logic used by both the Servers tab and the
/// home screen's default servers list, so the two behave identically.

/// Applies the status filter, protocol quick-filter, and search query.
List<ServerConfig> applyServerFilter(
  List<ServerConfig> servers,
  SortFilterState sortFilter,
  Map<String, int> latencyMap,
) {
  var result = switch (sortFilter.filter) {
    FilterCriteria.all => servers,
    FilterCriteria.working =>
      servers.where((s) => isLatencyWorking(latencyMap[s.id])).toList(),
    FilterCriteria.failed =>
      servers.where((s) => isLatencyFailed(latencyMap[s.id])).toList(),
  };

  if (sortFilter.protocol != null) {
    result = result.where((s) => s.protocol == sortFilter.protocol).toList();
  }

  final query = sortFilter.query.trim().toLowerCase();
  if (query.isNotEmpty) {
    result = result.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query) ||
          s.groupName.toLowerCase().contains(query);
    }).toList();
  }

  return result;
}

/// Applies the sort criteria to [servers].
List<ServerConfig> applyServerSort(
  List<ServerConfig> servers,
  SortCriteria sort,
  Map<String, int> latencyMap,
) {
  final sorted = [...servers];
  switch (sort) {
    case SortCriteria.defaultOrder:
      // Keep persisted subscription/import order from storage.
      break;
    case SortCriteria.name:
      sorted.sort((a, b) => a.name.compareTo(b.name));
    case SortCriteria.latency:
      sorted.sort((a, b) {
        final la = latencyMap[a.id];
        final lb = latencyMap[b.id];
        // Untested servers go last
        if (la == null && lb == null) return 0;
        if (la == null) return 1;
        if (lb == null) return -1;
        // Failed (-1) after successful, testing (-2) after failed
        if (la < 0 && lb > 0) return 1;
        if (la > 0 && lb < 0) return -1;
        return la.compareTo(lb);
      });
    case SortCriteria.protocol:
      sorted.sort((a, b) => a.protocol.label.compareTo(b.protocol.label));
  }
  return sorted;
}
