import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'multi_select_provider.g.dart';

/// Multi-select state: set of selected server IDs.
/// Empty set = not in selection mode.
@riverpod
class MultiSelectNotifier extends _$MultiSelectNotifier {
  @override
  Set<String> build() => {};

  /// Whether multi-select mode is active (any items selected).
  bool get isActive => state.isNotEmpty;

  /// Enter multi-select mode with an initial server selected.
  void enterSelectionMode(String firstId) {
    state = {firstId};
  }

  /// Toggle selection of a server. If all are deselected, exit selection mode.
  void toggle(String serverId) {
    final next = {...state};
    if (next.contains(serverId)) {
      next.remove(serverId);
    } else {
      next.add(serverId);
    }
    state = next;
  }

  /// Select all provided server IDs.
  void selectAll(List<String> ids) => state = {...ids};

  /// Clear all selections and exit multi-select mode.
  void clearSelection() => state = {};
}
