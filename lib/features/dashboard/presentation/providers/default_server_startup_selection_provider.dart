import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/best_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Startup auto-selection of a default server.
///
/// On first start (when nothing is selected yet), refreshes the default server
/// list, measures each server's latency with the configured ping type, and
/// selects the fastest reachable one. Falls back to the first connectable
/// server if none respond.
class DefaultServerStartupSelectionController {
  const DefaultServerStartupSelectionController(this._ref);

  final Ref _ref;

  Future<void> autoSelectBestServer() async {
    // Respect an existing selection — only auto-pick when nothing is active
    // (fresh install / first start).
    if (_ref.read(activeServerProvider) != null) {
      return;
    }

    await _ref.read(defaultServersProvider.notifier).refresh();

    final candidates = _ref
        .read(defaultServersProvider)
        .items
        .where((item) => item.isConnectable)
        .map((item) => item.serverConfig!)
        .toList(growable: false);

    if (candidates.isEmpty) {
      return;
    }

    // Auto-test latency (uses the selected ping type), then pick the fastest.
    await _ref.read(latencyProvider.notifier).testAllServers(candidates);
    final latencyMap = _ref.read(latencyProvider);
    final best = selectBestServer(candidates, latencyMap) ?? candidates.first;

    await _ref.read(activeServerProvider.notifier).selectServer(best);
  }
}

final defaultServerStartupSelectionProvider =
    Provider<DefaultServerStartupSelectionController>(
      (ref) => DefaultServerStartupSelectionController(ref),
    );
