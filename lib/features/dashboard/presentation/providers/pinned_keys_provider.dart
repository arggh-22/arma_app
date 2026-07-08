import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

/// SharedPreferences key holding the set of pinned subscription URLs.
const _pinnedKeysPrefsKey = 'dashboard_pinned_keys';

/// Tracks which dashboard subscription blocks the user has pinned to the top.
///
/// Keyed by the subscription/key URL (stable across API refreshes). Persisted
/// to SharedPreferences so pins survive restarts. Written manually (no code
/// generation) to keep the Hive build_runner front-end happy.
class PinnedKeysNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // SharedPreferences is overridden in main.dart; guard so widget tests that
    // pump the dashboard without the override still render (pins default off).
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      return prefs.getStringList(_pinnedKeysPrefsKey)?.toSet() ??
          const <String>{};
    } on Object {
      return const <String>{};
    }
  }

  bool isPinned(String url) => state.contains(url);

  /// Pin the block if it isn't pinned, otherwise unpin it. Persists the result.
  Future<void> toggle(String url) async {
    final next = {...state};
    if (!next.add(url)) {
      next.remove(url);
    }
    state = next;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_pinnedKeysPrefsKey, next.toList());
    } on Object {
      // No persistence available (e.g. tests) — keep the in-memory pin state.
    }
  }
}

final pinnedKeysProvider =
    NotifierProvider<PinnedKeysNotifier, Set<String>>(PinnedKeysNotifier.new);
