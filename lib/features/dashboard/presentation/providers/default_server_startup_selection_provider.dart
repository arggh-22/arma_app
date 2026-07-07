import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/latency_level.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/ping_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Startup auto-selection of a default server.
///
/// On first start (when nothing is selected yet), refreshes the default server
/// list and picks a server fast so the user isn't kept waiting:
/// a quick **TCP Connect** sweep (regardless of the configured ping type,
/// which may be slow HTTP), then selects the **first working** server in the
/// backend's preferred order. Falls back to the first connectable server if
/// none respond.
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

    // Fast TCP sweep (bounded by the 3s probe timeout), then take the first
    // reachable server in the list — realistic and quick for the user.
    await _ref
        .read(latencyProvider.notifier)
        .testAllServersWith(candidates, PingType.tcpConnect);
    final latencyMap = _ref.read(latencyProvider);

    final selected = candidates.firstWhere(
      (server) => isLatencyWorking(latencyMap[server.id]),
      orElse: () => candidates.first,
    );

    await _ref.read(activeServerProvider.notifier).selectServer(selected);
  }
}

final defaultServerStartupSelectionProvider =
    Provider<DefaultServerStartupSelectionController>(
      (ref) => DefaultServerStartupSelectionController(ref),
    );
