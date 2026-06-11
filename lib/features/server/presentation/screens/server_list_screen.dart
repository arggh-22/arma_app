import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/utils/clipboard_helper.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/subscription_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/best_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/multi_select_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/sort_filter_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/subscription_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/screens/server_xray_config_screen.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/debug_long_press_wrapper.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/empty_server_state.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/import_fab.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_card.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_list_default_servers_section.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_group_header.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/sort_filter_bar.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';

/// Server list screen — full integration of Phase 3 features.
///
/// Displays imported servers as grouped cards with protocol badges,
/// latency indicators, tap-to-select, multi-select bulk delete,
/// sort/filter bar, subscription group headers with metadata,
/// Best Server and Test All buttons, pull-to-refresh, and
/// expandable import FAB.
class ServerListScreen extends ConsumerStatefulWidget {
  const ServerListScreen({super.key});

  @override
  ConsumerState<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends ConsumerState<ServerListScreen> {
  final Set<String> _collapsedGroups = {};
  final Set<String> _refreshingSubscriptions = {};
  final Set<String> _pingingSubscriptions = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final serversAsync = ref.watch(serverListProvider);
    final activeServer = ref.watch(activeServerProvider);
    final multiSelect = ref.watch(multiSelectProvider);
    final defaultServersState = ref.watch(defaultServersProvider);
    final isMultiSelectActive = multiSelect.isNotEmpty;

    return Scaffold(
      appBar: isMultiSelectActive
          ? _buildMultiSelectAppBar(context, l10n, multiSelect, serversAsync)
          : _buildNormalAppBar(context, l10n, serversAsync),
      body: serversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              FilledButton(
                onPressed: () => ref.invalidate(serverListProvider),
                child: Text(l10n.retryAction),
              ),
            ],
          ),
        ),
        data: (servers) {
          final hasVisibleDefaults =
              !isMultiSelectActive && defaultServersState.items.isNotEmpty;
          if (servers.isEmpty && !hasVisibleDefaults) {
            return EmptyServerState(
              onImportTap: () => _importFromClipboard(context, ref),
            );
          }

          return Column(
            children: [
              // Sort/filter bar (hidden in multi-select mode)
              if (!isMultiSelectActive) const SortFilterBar(),

              // Grouped server list with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _onPullToRefresh(l10n),
                  child: _buildGroupedList(
                    context,
                    ref,
                    servers,
                    activeServer,
                    multiSelect,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isMultiSelectActive ? null : const ImportFab(),
    );
  }

  /// Normal-mode AppBar with Best Server and Test All buttons.
  PreferredSizeWidget _buildNormalAppBar(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<ServerConfig>> serversAsync,
  ) {
    final latencyMap = ref.watch(latencyProvider);
    final isBulkTesting = ref.watch(latencyProvider.notifier).isBulkTesting;
    final hasLatencyData = latencyMap.values.any((v) => v > 0);

    return AppBar(
      title: Text(l10n.servers, style: Theme.of(context).textTheme.titleLarge),
      actions: [
        // Best Server button
        IconButton(
          icon: Icon(
            Icons.auto_awesome,
            color: hasLatencyData
                ? null
                : Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          tooltip: l10n.bestServer,
          onPressed: hasLatencyData ? () => _onBestServer(serversAsync) : null,
        ),

        // Test All button
        Semantics(
          label: l10n.testAllServers,
          child: isBulkTesting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: l10n.testAllServers,
                  onPressed: () => _onTestAll(serversAsync),
                ),
        ),
      ],
    );
  }

  /// Multi-select mode AppBar with count, Select All, and Delete.
  PreferredSizeWidget _buildMultiSelectAppBar(
    BuildContext context,
    AppLocalizations l10n,
    Set<String> selected,
    AsyncValue<List<ServerConfig>> serversAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () =>
            ref.read(multiSelectProvider.notifier).clearSelection(),
      ),
      title: Text(l10n.selectedCount(selected.length)),
      actions: [
        // Select All
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: l10n.selectAll,
          onPressed: () {
            final servers = serversAsync.value ?? [];
            ref
                .read(multiSelectProvider.notifier)
                .selectAll(servers.map((s) => s.id).toList());
          },
        ),

        // Delete
        IconButton(
          icon: Icon(Icons.delete, color: colorScheme.error),
          onPressed: () => _showBulkDeleteDialog(context, l10n, selected),
        ),
      ],
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<ServerConfig> servers,
    ServerConfig? activeServer,
    Set<String> multiSelect,
  ) {
    final isMultiSelectActive = multiSelect.isNotEmpty;
    final sortFilter = ref.watch(sortFilterProvider);
    final latencyMap = ref.watch(latencyProvider);
    final subscriptions = ref.watch(subscriptionProvider);

    // Apply filter
    final filteredServers = _applyFilter(
      servers,
      sortFilter.filter,
      latencyMap,
    );

    // Apply sort
    final sortedServers = _applySort(
      filteredServers,
      sortFilter.sort,
      latencyMap,
    );

    // Group servers by groupName
    final groups = <String, List<ServerConfig>>{};
    for (final server in sortedServers) {
      groups.putIfAbsent(server.groupName, () => []).add(server);
    }

    final groupEntries = groups.entries.toList();

    // Build flat list of widgets: headers + cards with spacing
    final items = <Widget>[];
    if (!isMultiSelectActive) {
      items.add(const ServerListDefaultServersSection());
      if (groupEntries.isNotEmpty) {
        items.add(const Gap(8));
      }
    }

    for (var i = 0; i < groupEntries.length; i++) {
      if (i > 0) {
        items.add(const Gap(24));
      }
      final entry = groupEntries[i];
      final groupServers = entry.value;

      // Find subscription for this group
      final firstServer = groupServers.first;
      Subscription? subscription;
      if (firstServer.subscriptionId != null) {
        subscription = subscriptions
            .where((s) => s.id == firstServer.subscriptionId)
            .firstOrNull;
      }

      final isCollapsed = _collapsedGroups.contains(entry.key);

      items.add(
        ServerGroupHeader(
          key: ValueKey('server-group-header-${entry.key}'),
          groupName: entry.key,
          subscription: subscription,
          serverCount: groupServers.length,
          isCollapsed: isCollapsed,
          isRefreshing: _refreshingSubscriptions.contains(
            firstServer.subscriptionId,
          ),
          isPinging: _pingingSubscriptions.contains(firstServer.subscriptionId),
          onToggleCollapse: () {
            setState(() {
              if (isCollapsed) {
                _collapsedGroups.remove(entry.key);
              } else {
                _collapsedGroups.add(entry.key);
              }
            });
          },
          onRefresh: subscription != null
              ? () => _onRefreshSubscription(subscription!.id)
              : null,
          onPing: () => _onPingGroup(context, subscription?.id, groupServers),
          onDeleteAll: subscription != null
              ? () => _onDeleteAllInSubscription(
                  context,
                  subscription!.id,
                  groupServers,
                )
              : null,
        ),
      );

      // Skip server cards if group is collapsed
      if (isCollapsed) continue;

      items.add(const Gap(2));
      for (var j = 0; j < groupServers.length; j++) {
        final server = groupServers[j];
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: isMultiSelectActive
                ? ServerCard(
                    server: server,
                    isSelected: server.id == activeServer?.id,
                    latency: latencyMap[server.id],
                    isMultiSelect: true,
                    isChecked: multiSelect.contains(server.id),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(activeServerProvider.notifier)
                          .selectServer(server);
                    },
                    onLongPress: () {},
                    onLatencyTap: () =>
                        ref.read(latencyProvider.notifier).testServer(server),
                    onToggleSelect: () => ref
                        .read(multiSelectProvider.notifier)
                        .toggle(server.id),
                  )
                : Dismissible(
                    key: ValueKey('dismiss-${server.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async => true,
                    onDismissed: (_) {
                      _onSwipeDelete(context, ref, server);
                    },
                    child: DebugLongPressWrapper(
                      onDebugLongPress: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ServerXrayConfigScreen(server: server),
                        ),
                      ),
                      child: ServerCard(
                        server: server,
                        isSelected: server.id == activeServer?.id,
                        latency: latencyMap[server.id],
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _onTapServer(server);
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          ref
                              .read(multiSelectProvider.notifier)
                              .enterSelectionMode(server.id);
                        },
                        onLatencyTap: () =>
                            ref.read(latencyProvider.notifier).testServer(server),
                      ),
                    ),
                  ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      children: items,
    );
  }

  /// Select a server, and — when already connected — tear down the old
  /// tunnel and bring up the new one. Without the reconnect, tapping a
  /// different server while connected only updated the "active" selection
  /// in the UI; the tunnel kept running with the previous server's config,
  /// so the app showed the new server as active while no traffic flowed.
  Future<void> _onTapServer(ServerConfig server) async {
    final currentSelection = ref.read(activeServerProvider);

    await ref.read(activeServerProvider.notifier).selectServer(server);

    final connectionState = ref.read(connectionProvider);
    if (connectionState is Connected && currentSelection?.id != server.id) {
      final connectionNotifier = ref.read(connectionProvider.notifier);
      await connectionNotifier.disconnect();
      await connectionNotifier.connect(server);
    }
  }

  /// Apply filter criteria to the server list.
  List<ServerConfig> _applyFilter(
    List<ServerConfig> servers,
    FilterCriteria filter,
    Map<String, int> latencyMap,
  ) {
    switch (filter) {
      case FilterCriteria.all:
        return servers;
      case FilterCriteria.working:
        return servers.where((s) {
          final latency = latencyMap[s.id];
          return latency != null && latency > 0 && latency <= 300;
        }).toList();
      case FilterCriteria.failed:
        return servers.where((s) {
          final latency = latencyMap[s.id];
          return latency == -1 || (latency != null && latency > 300);
        }).toList();
    }
  }

  /// Apply sort criteria to the server list.
  List<ServerConfig> _applySort(
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

  /// Pull-to-refresh: triggers subscription auto-update.
  Future<void> _onPullToRefresh(AppLocalizations l10n) async {
    await ref.read(subscriptionProvider.notifier).refreshAllAutoUpdate();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.subscriptionRefreshNoChange),
        duration: AppConstants.snackBarDurationDefault,
      ),
    );
  }

  /// Best Server: select the server with the lowest latency.
  void _onBestServer(AsyncValue<List<ServerConfig>> serversAsync) {
    final servers = serversAsync.value ?? [];
    final best = ref.read(bestServerProvider(servers));
    if (best != null) {
      ref.read(activeServerProvider.notifier).selectServer(best);
      HapticFeedback.selectionClick();
    }
  }

  /// Test All: trigger bulk latency testing.
  void _onTestAll(AsyncValue<List<ServerConfig>> serversAsync) {
    final servers = serversAsync.value ?? [];
    if (servers.isNotEmpty) {
      ref.read(latencyProvider.notifier).testAllServers(servers);
    }
  }

  /// Refresh a single subscription.
  Future<void> _onRefreshSubscription(String subscriptionId) async {
    setState(() => _refreshingSubscriptions.add(subscriptionId));
    try {
      await ref
          .read(subscriptionProvider.notifier)
          .refreshSubscription(subscriptionId);
    } finally {
      if (mounted) {
        setState(() => _refreshingSubscriptions.remove(subscriptionId));
      }
    }
  }

  /// Ping all servers in a group (subscription or manual).
  ///
  /// For subscription groups, [subscriptionId] is used to track per-group
  /// busy state. For manual groups (no subscription), busy state is skipped.
  Future<void> _onPingGroup(
    BuildContext context,
    String? subscriptionId,
    List<ServerConfig> servers,
  ) async {
    if (servers.isEmpty) return;
    if (subscriptionId != null) {
      setState(() => _pingingSubscriptions.add(subscriptionId));
    }
    try {
      await ref.read(latencyProvider.notifier).testAllServers(servers);
    } finally {
      if (mounted && subscriptionId != null) {
        setState(() => _pingingSubscriptions.remove(subscriptionId));
      }
    }
  }

  /// Swipe-to-delete a single server with undo snackbar.
  void _onSwipeDelete(
    BuildContext context,
    WidgetRef ref,
    ServerConfig server,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // Clear active server if this was the active one
    final activeServer = ref.read(activeServerProvider);
    if (activeServer?.id == server.id) {
      ref.read(activeServerProvider.notifier).selectServer(null);
    }

    // Delete the server
    ref.read(serverListProvider.notifier).deleteServer(server.id);

    // Show undo snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${server.name} deleted'),
        duration: AppConstants.snackBarDurationLong,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            // Re-add the server to restore it
            ref.read(serverListProvider.notifier).addServer(server);
          },
        ),
      ),
    );
  }

  /// Delete all servers in a subscription group with confirmation.
  void _onDeleteAllInSubscription(
    BuildContext context,
    String subscriptionId,
    List<ServerConfig> servers,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteServersTitle(servers.length)),
        content: Text(l10n.deleteServersBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.keepServers),
          ),
          TextButton(
            onPressed: () {
              for (final server in servers) {
                ref.read(serverListProvider.notifier).deleteServer(server.id);
                final activeServer = ref.read(activeServerProvider);
                if (activeServer?.id == server.id) {
                  ref.read(activeServerProvider.notifier).selectServer(null);
                }
              }
              // Also delete the subscription itself
              ref
                  .read(subscriptionProvider.notifier)
                  .deleteSubscription(subscriptionId);
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteServersConfirm(servers.length)),
          ),
        ],
      ),
    );
  }

  /// Bulk delete confirmation dialog.
  void _showBulkDeleteDialog(
    BuildContext context,
    AppLocalizations l10n,
    Set<String> selected,
  ) {
    final count = selected.length;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteServersTitle(count)),
        content: Text(l10n.deleteServersBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.keepServers),
          ),
          TextButton(
            onPressed: () {
              for (final id in selected) {
                ref.read(serverListProvider.notifier).deleteServer(id);
                // Clear active server if deleted
                final activeServer = ref.read(activeServerProvider);
                if (activeServer?.id == id) {
                  ref.read(activeServerProvider.notifier).selectServer(null);
                }
              }
              ref.read(multiSelectProvider.notifier).clearSelection();
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteServersConfirm(count)),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromClipboard(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final text = await ClipboardHelper.getText();

    if (!context.mounted) return;

    if (text == null || text.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.parseErrorEmptyClipboard),
          duration: AppConstants.snackBarDurationLong,
        ),
      );
      return;
    }

    final trimmed = text.trim();

    // Support empty-state import of subscription URLs too.
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Fetching subscription...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      try {
        final importedCount = await ref
            .read(subscriptionProvider.notifier)
            .addSubscription(url: trimmed, name: '', userAgent: 'arma');
        if (!context.mounted) return;
        messenger.clearSnackBars();

        if (importedCount <= 0) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.parseErrorInvalidLink),
              duration: AppConstants.snackBarDurationDefault,
            ),
          );
          return;
        }

        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.importedServersCount(importedCount)),
            duration: AppConstants.snackBarDurationDefault,
            backgroundColor: Colors.green.shade700,
          ),
        );
      } catch (_) {
        if (!context.mounted) return;
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.subscriptionFetchError),
            duration: AppConstants.snackBarDurationDefault,
          ),
        );
      }
      return;
    }

    final config = ShareLinkParser.parse(trimmed);
    if (config == null) {
      // Fallback: allow multi-line/base64 clipboard payloads.
      final multiConfigs = SubscriptionParser.parseBody(trimmed);
      if (multiConfigs.isNotEmpty) {
        final existingServers = await ref.read(serverListProvider.future);
        if (!context.mounted) return;

        final newConfigs = multiConfigs.where((candidate) {
          return !existingServers.any(
            (s) =>
                s.address == candidate.address &&
                s.port == candidate.port &&
                s.protocol == candidate.protocol,
          );
        }).toList();

        if (newConfigs.isEmpty) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.duplicateServer),
              duration: AppConstants.snackBarDurationDefault,
            ),
          );
          return;
        }

        for (final item in newConfigs) {
          await ref.read(serverListProvider.notifier).addServer(item);
        }

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.importedServersCount(newConfigs.length)),
            duration: AppConstants.snackBarDurationDefault,
            backgroundColor: Colors.green.shade700,
          ),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.parseErrorInvalidLink),
          duration: AppConstants.snackBarDurationLong,
        ),
      );
      return;
    }

    // Check for duplicates by address + port + protocol
    final servers = await ref.read(serverListProvider.future);
    if (!context.mounted) return;

    final isDuplicate = servers.any(
      (s) =>
          s.address == config.address &&
          s.port == config.port &&
          s.protocol == config.protocol,
    );

    if (isDuplicate) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.duplicateServer),
          duration: AppConstants.snackBarDurationDefault,
        ),
      );
      return;
    }

    await ref.read(serverListProvider.notifier).addServer(config);

    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('${l10n.importSuccess} — ${config.name}'),
        duration: AppConstants.snackBarDurationDefault,
        backgroundColor: Colors.green.shade700,
        action: SnackBarAction(label: l10n.viewAction, onPressed: () {}),
      ),
    );
  }
}
