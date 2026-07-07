import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/sort_filter_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/server_sort_filter.dart';
import 'package:flutter_test/flutter_test.dart';

ServerConfig _s(String id, String name) => ServerConfig(
      id: id,
      name: name,
      protocol: ProtocolType.vless,
      address: '$id.example.com',
      port: 443,
      addedAt: DateTime.utc(2026, 1, 1),
    );

SortFilterState _state(SortCriteria sort) => (
      sort: sort,
      filter: FilterCriteria.all,
      query: '',
      protocol: null,
    );

void main() {
  // Backend/response order: intentionally NOT alphabetical.
  final servers = [_s('3', 'Zulu'), _s('1', 'Alpha'), _s('2', 'Mike')];

  test('defaultOrder preserves the backend/response order', () {
    final sorted = applyServerSort(servers, SortCriteria.defaultOrder, const {});
    expect(sorted.map((s) => s.id).toList(), ['3', '1', '2']);
  });

  test('name sort reorders alphabetically (contrast)', () {
    final sorted = applyServerSort(servers, SortCriteria.name, const {});
    expect(sorted.map((s) => s.name).toList(), ['Alpha', 'Mike', 'Zulu']);
  });

  test('filtering keeps the original relative order', () {
    final filtered = applyServerFilter(servers, _state(SortCriteria.defaultOrder), const {});
    expect(filtered.map((s) => s.id).toList(), ['3', '1', '2']);
  });
}
