import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/utils/app_snackbar.dart';
import 'package:arma_proxy_vpn_client/core/utils/clipboard_helper.dart';
import 'package:arma_proxy_vpn_client/core/utils/link_launcher.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/pinned_keys_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/subscription_actions_sheet.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/subscription_key_block.dart';
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
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/reveal_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/sort_filter_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/subscription_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/screens/server_xray_config_screen.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/server_sort_filter.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/debug_long_press_wrapper.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/empty_server_state.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/import_fab.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_card.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/sort_filter_bar.dart';

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
  /// Accordion state: only one subscription group is expanded at a time.
  /// `null` = default (first group open); `''` = all collapsed; otherwise the
  /// key of the single open group.
  String? _expandedGroup;
  final Set<String> _refreshingSubscriptions = {};
  final Set<String> _pingingSubscriptions = {};

  /// Import FAB hides while scrolling down and reappears on scroll up,
  /// mirroring the dashboard's Telegram link FAB.
  ///
  /// A [ValueNotifier] (not `setState`) drives visibility so a scroll only
  /// rebuilds the FAB — never the heavy grouped list. Rebuilding the list
  /// mid-fling dropped frames and stalled the scroll, forcing a second swipe.
  final ValueNotifier<bool> _showImportFab = ValueNotifier<bool>(true);

  bool _onScroll(UserScrollNotification notification) {
    // The sort/filter bar is a horizontal ListView whose scroll notifications
    // bubble up here too — ignore them so only the vertical server list drives
    // the FAB, otherwise swiping the filter chips flickers the FAB.
    if (notification.metrics.axis != Axis.vertical) return false;
    switch (notification.direction) {
      case ScrollDirection.reverse:
        _showImportFab.value = false;
      case ScrollDirection.forward:
        _showImportFab.value = true;
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  @override
  void dispose() {
    _showImportFab.dispose();
    super.dispose();
  }

  /// Per-server card keys, used to scroll a server into view on reveal.
  final Map<String, GlobalKey> _cardKeys = {};

  /// The last reveal id this screen acted on (avoids re-scrolling on rebuild).
  String? _revealHandledId;

  GlobalKey _cardKey(String serverId) =>
      _cardKeys.putIfAbsent(serverId, GlobalKey.new);

  /// When the active-server card requests a reveal for an imported server,
  /// open its group (accordion) and scroll it into view. Ids we don't own
  /// (e.g. default-api servers) are ignored and left for the home screen.
  void _maybeReveal(List<ServerConfig> servers) {
    final id = ref.watch(revealServerProvider);
    if (id == null || id == _revealHandledId) return;

    ServerConfig? target;
    for (final server in servers) {
      if (server.id == id) {
        target = server;
        break;
      }
    }
    if (target == null) return; // not loaded / not an imported server.

    _revealHandledId = id;
    // Groups are keyed by subscription id (see _buildGroupedList), NOT by the
    // display group name — so the accordion key must be computed the same way,
    // otherwise the group never expands and the card can't be scrolled into view.
    final groupKey = target.subscriptionId ?? 'manual:${target.groupName}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final needsExpand = _expandedGroup != groupKey;
      if (needsExpand) {
        setState(() => _expandedGroup = groupKey);
      }
      // The group body reveals its cards with a 200ms AnimatedSize (see
      // SubscriptionKeyBlock). Scrolling one frame after expanding computes
      // the offset mid-animation and lands on the wrong spot — which is why a
      // collapsed group used to need a second tap. Wait for the expand to
      // settle before scrolling; skip the wait when it was already open so an
      // open group still reveals in a single tap.
      final settleDelay = needsExpand
          ? const Duration(milliseconds: 240)
          : Duration.zero;
      Future.delayed(settleDelay, () {
        if (!mounted) return;
        final ctx = _cardKeys[id]?.currentContext;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.2,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
        _revealHandledId = null;
        ref.read(revealServerProvider.notifier).clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final serversAsync = ref.watch(serverListProvider);
    final activeServer = ref.watch(activeServerProvider);
    final multiSelect = ref.watch(multiSelectProvider);
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
          // Honor a pending "scroll to this server" request from the
          // dashboard's active-server card.
          _maybeReveal(servers);

          if (servers.isEmpty) {
            return EmptyServerState(
              onImportTap: () => _importFromClipboard(context, ref),
            );
          }

          return NotificationListener<UserScrollNotification>(
            onNotification: _onScroll,
            child: Column(
              children: [
                // Sort/filter bar (hidden in multi-select mode)
                if (!isMultiSelectActive)
                  SortFilterBar(
                    state: ref.watch(sortFilterProvider),
                    availableProtocols: {
                      for (final server in servers) server.protocol,
                    },
                    onSort: ref.read(sortFilterProvider.notifier).setSort,
                    onFilter: ref.read(sortFilterProvider.notifier).setFilter,
                    onQuery: ref.read(sortFilterProvider.notifier).setQuery,
                    onProtocol: ref
                        .read(sortFilterProvider.notifier)
                        .setProtocol,
                  ),

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
            ),
          );
        },
      ),
      // Lift the FAB clear of the floating pill nav. Hides on scroll down,
      // reappears on scroll up (see _onScroll). The FAB stays mounted and
      // slides/fades via the ValueNotifier, so scrolling never rebuilds the
      // list — only this small subtree — which keeps flings from stalling.
      floatingActionButton: isMultiSelectActive
          ? null
          : ValueListenableBuilder<bool>(
              valueListenable: _showImportFab,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 84),
                child: ImportFab(),
              ),
              builder: (context, show, child) {
                return AnimatedSlide(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  offset: show ? Offset.zero : const Offset(0, 2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    opacity: show ? 1 : 0,
                    child: IgnorePointer(ignoring: !show, child: child),
                  ),
                );
              },
            ),
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

    final servers = serversAsync.value ?? const <ServerConfig>[];
    final providerCount = servers.map((s) => s.groupName).toSet().length;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.servers),
          if (servers.isNotEmpty)
            Text(
              l10n.serversCountSubtitle(servers.length, providerCount),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
        ],
      ),
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
    final pinned = ref.watch(pinnedKeysProvider);
    final globalAnnouncement = ref
        .watch(authStateProvider)
        .asData
        ?.value
        .announcementText
        ?.trim();

    // Apply status filter, protocol quick-filter, and search query
    final filteredServers = applyServerFilter(servers, sortFilter, latencyMap);

    // Apply sort
    final sortedServers = applyServerSort(
      filteredServers,
      sortFilter.sort,
      latencyMap,
    );

    // Group servers by SUBSCRIPTION, not by display name: two subscriptions
    // can share the same profile-title (e.g. two "ARMA VPN" keys), and keying
    // on the name would merge their servers into one block. Manual servers
    // (no subscription) fall back to their group name.
    final groups = <String, List<ServerConfig>>{};
    for (final server in sortedServers) {
      final key = server.subscriptionId ?? 'manual:${server.groupName}';
      groups.putIfAbsent(key, () => []).add(server);
    }

    final groupEntries = groups.entries.toList();

    // Stable group ordering: newest subscription first, keyed by the
    // subscription's addedAt (which is preserved across refreshes), so
    // updating a subscription no longer reshuffles the list. Manual groups
    // fall back to their newest server's timestamp. Servers *within* a group
    // keep their (default = server-response, or user-selected) order.
    final subById = {for (final s in subscriptions) s.id: s};
    DateTime groupTimestamp(List<ServerConfig> groupServers) {
      final subId = groupServers.first.subscriptionId;
      final sub = subId == null ? null : subById[subId];
      if (sub != null) return sub.addedAt;
      return groupServers
          .map((s) => s.addedAt)
          .reduce((a, b) => (a.isAfter(b) ? a : b));
    }

    groupEntries.sort(
      (a, b) => groupTimestamp(b.value).compareTo(groupTimestamp(a.value)),
    );

    // Pinned groups float to the top. Keyed by the subscription URL (shared
    // with the home screen) for real subs, or the group key for manual groups.
    String pinKeyFor(List<ServerConfig> gs) {
      final subId = gs.first.subscriptionId;
      final sub = subId == null ? null : subById[subId];
      return sub?.url ?? (subId ?? 'manual:${gs.first.groupName}');
    }

    bool isPinnedGroup(List<ServerConfig> gs) => pinned.contains(pinKeyFor(gs));

    final ordered = <MapEntry<String, List<ServerConfig>>>[
      ...groupEntries.where((e) => isPinnedGroup(e.value)),
      ...groupEntries.where((e) => !isPinnedGroup(e.value)),
    ];

    // Accordion: resolve the single open group. Default to the first (top)
    // group; `''` means the user collapsed all.
    final openGroupKey = _expandedGroup == null
        ? (ordered.isNotEmpty ? ordered.first.key : null)
        : (_expandedGroup!.isEmpty ? null : _expandedGroup);

    // One collapsible block per group, styled like the home screen.
    final items = <Widget>[];

    for (var i = 0; i < ordered.length; i++) {
      if (i > 0) items.add(const Gap(12));
      final entry = ordered[i];
      final groupServers = entry.value;

      final subId = groupServers.first.subscriptionId;
      final subscription = subId == null ? null : subById[subId];
      final displayName =
          (subscription != null && subscription.name.trim().isNotEmpty)
          ? subscription.name.trim()
          : groupServers.first.groupName;
      final pinKey = subscription?.url ?? entry.key;

      final isExpanded = entry.key == openGroupKey;
      final now = DateTime.now();
      final expireDate =
          subscription?.expireDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final isActive =
          expireDate.millisecondsSinceEpoch <= 0 || expireDate.isAfter(now);
      final usedBytes =
          (subscription?.uploadBytes ?? 0) + (subscription?.downloadBytes ?? 0);
      final ownAnnouncement = subscription?.announcement?.trim();
      final announcement = subscription == null
          ? null
          : (ownAnnouncement != null && ownAnnouncement.isNotEmpty
                ? ownAnnouncement
                : (globalAnnouncement != null && globalAnnouncement.isNotEmpty
                      ? globalAnnouncement
                      : null));

      items.add(
        SubscriptionKeyBlock(
          // Key on the (unique) group key, not the display name — two
          // subscriptions can share a profile-title, and duplicate ListView
          // child keys trip the sliver child-order assertion.
          key: ValueKey('server-group-header-${entry.key}'),
          name: subscription != null
              ? displayName
              : '$displayName (${groupServers.length})',
          isActive: isActive,
          isPinned: pinned.contains(pinKey),
          showInfoLine: subscription != null,
          expireDate: expireDate,
          usedBytes: usedBytes,
          totalBytes: subscription?.totalBytes ?? 0,
          announcement: announcement,
          supportUrl: subscription?.supportUrl,
          webPageUrl: subscription?.webPageUrl,
          onOpenUrl: _openUrl,
          serverCount: groupServers.length,
          isExpanded: isExpanded,
          isRefreshing: _refreshingSubscriptions.contains(subscription?.id),
          isPinging: _pingingSubscriptions.contains(subscription?.id),
          onToggleExpand: () {
            setState(() {
              // Open this group (collapsing every other), or collapse it if
              // it's already the open one (accordion).
              _expandedGroup = isExpanded ? '' : entry.key;
            });
          },
          onRefresh: (isMultiSelectActive || subscription == null)
              ? null
              : () => _onRefreshSubscription(subscription.id),
          onPing: isMultiSelectActive
              ? null
              : () => _onPingGroup(context, subscription?.id, groupServers),
          onMore: isMultiSelectActive
              ? null
              : () => _onMoreGroup(
                  context,
                  subscription,
                  groupServers,
                  pinKey,
                  displayName,
                ),
          children: [
            for (final server in groupServers)
              _buildServerCard(
                context,
                ref,
                server,
                activeServer,
                latencyMap,
                multiSelect,
                isMultiSelectActive,
              ),
          ],
        ),
      );
    }

    // Empty search/filter result hint (servers exist, none match).
    if (groupEntries.isEmpty && servers.isNotEmpty) {
      items.add(
        Padding(
          key: const Key('server-filter-empty-hint'),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const Gap(12),
              Text(
                AppLocalizations.of(context)!.searchNoResults,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      // Bottom padding clears the floating pill nav + import FAB.
      padding: const EdgeInsets.only(top: 8, bottom: 140),
      children: items,
    );
  }

  /// One server row, nested inside a subscription block. Supports tap-select,
  /// long-press multi-select, swipe-to-delete, and inline latency retest.
  Widget _buildServerCard(
    BuildContext context,
    WidgetRef ref,
    ServerConfig server,
    ServerConfig? activeServer,
    Map<String, int> latencyMap,
    Set<String> multiSelect,
    bool isMultiSelectActive,
  ) {
    return Padding(
      key: _cardKey(server.id),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: isMultiSelectActive
          ? ServerCard(
              server: server,
              isSelected: server.id == activeServer?.id,
              latency: latencyMap[server.id],
              isMultiSelect: true,
              isChecked: multiSelect.contains(server.id),
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(activeServerProvider.notifier).selectServer(server);
              },
              onLongPress: () {},
              onLatencyTap: () =>
                  ref.read(latencyProvider.notifier).testServer(server),
              onToggleSelect: () =>
                  ref.read(multiSelectProvider.notifier).toggle(server.id),
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
              onDismissed: (_) => _onSwipeDelete(context, ref, server),
              child: DebugLongPressWrapper(
                onDebugLongPress: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ServerXrayConfigScreen(server: server),
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
    );
  }

  /// Opens an external link (renew / support) in the browser.
  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launch = ref.read(linkLauncherProvider);
    final opened = await launch(uri);
    if (!mounted || opened) return;
    showAppSnackBar(
      context,
      message: AppLocalizations.of(context)!.couldNotOpenLink,
    );
  }

  /// Subscription management sheet (mirrors the home screen's "…" sheet, plus
  /// Copy link and Delete for imported subscriptions).
  /// Management sheet for a group. Works for real subscriptions (Update +
  /// Copy link available) and for manually/clipboard-imported groups that have
  /// no subscription URL (Ping / Pin / Delete only — there's nothing to update
  /// from). [pinKey] identifies the group in the shared pinned-keys set.
  void _onMoreGroup(
    BuildContext context,
    Subscription? subscription,
    List<ServerConfig> groupServers,
    String pinKey,
    String title,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isPinned = ref.read(pinnedKeysProvider).contains(pinKey);
    final hasUrl = subscription != null && subscription.url.trim().isNotEmpty;
    showSubscriptionActionsSheet(
      context,
      title: title,
      actions: [
        if (hasUrl)
          SubscriptionAction(
            icon: Icons.refresh,
            label: l10n.updateSubscriptionAction,
            onTap: () => _onRefreshSubscription(subscription.id),
          ),
        SubscriptionAction(
          icon: Icons.speed,
          label: l10n.pingAction,
          onTap: () => _onPingGroup(context, subscription?.id, groupServers),
        ),
        if (hasUrl)
          SubscriptionAction(
            icon: Icons.copy,
            label: l10n.copyLink,
            onTap: () {
              Clipboard.setData(ClipboardData(text: subscription.url));
              showAppSnackBar(context, message: l10n.linkCopied);
            },
          ),
        SubscriptionAction(
          icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
          label: isPinned ? l10n.unpinAction : l10n.pinAction,
          onTap: () => ref.read(pinnedKeysProvider.notifier).toggle(pinKey),
        ),
        SubscriptionAction(
          icon: Icons.delete_outline,
          label: l10n.deleteAllAction,
          isDestructive: true,
          onTap: () => _onDeleteGroup(context, subscription, groupServers),
        ),
      ],
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
    // Connecting counts too: without it, tapping B while A was still coming
    // up showed B as selected while the tunnel finished establishing to A.
    if ((connectionState is Connected || connectionState is Connecting) &&
        currentSelection?.id != server.id) {
      // connect() tears the current session down and waits for the native side
      // to confirm it stopped before starting the new server, so we must NOT
      // fire a separate disconnect() here (that raced the restart).
      await ref.read(connectionProvider.notifier).connect(server);
    }
  }

  /// Pull-to-refresh: triggers subscription auto-update.
  Future<void> _onPullToRefresh(AppLocalizations l10n) async {
    await ref.read(subscriptionProvider.notifier).refreshAllAutoUpdate();
    if (!mounted) return;
    showAppSnackBar(context, message: l10n.subscriptionRefreshNoChange);
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _refreshingSubscriptions.add(subscriptionId));
    try {
      final count = await ref
          .read(subscriptionProvider.notifier)
          .refreshSubscription(subscriptionId);
      if (!mounted) return;
      showAppSnackBar(context, message: l10n.importedServersCount(count));
    } catch (_) {
      // Subscription servers can fail (expired token, 4xx, offline). Surface a
      // message instead of letting the exception crash the app.
      if (!mounted) return;
      showAppSnackBar(context, message: l10n.subscriptionFetchError);
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
    showAppSnackBar(
      context,
      message: '${server.name} deleted',
      duration: AppConstants.snackBarDurationLong,
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: () {
          // Re-add the server to restore it
          ref.read(serverListProvider.notifier).addServer(server);
        },
      ),
    );
  }

  /// Delete a whole group with confirmation. For a real subscription this also
  /// removes the subscription record; for a manual/clipboard group it just
  /// deletes the servers.
  void _onDeleteGroup(
    BuildContext context,
    Subscription? subscription,
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
              // Clear the active selection if it points into this group.
              final activeServer = ref.read(activeServerProvider);
              if (servers.any((s) => s.id == activeServer?.id)) {
                ref.read(activeServerProvider.notifier).selectServer(null);
              }
              if (subscription != null) {
                // deleteSubscription removes the sub record AND its servers.
                ref
                    .read(subscriptionProvider.notifier)
                    .deleteSubscription(subscription.id);
              } else {
                for (final server in servers) {
                  ref.read(serverListProvider.notifier).deleteServer(server.id);
                }
              }
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
      showAppSnackBar(
        context,
        message: l10n.parseErrorEmptyClipboard,
        duration: AppConstants.snackBarDurationLong,
      );
      return;
    }

    final trimmed = text.trim();

    // Subscription URL import — supports pasting several links at once
    // (newline / whitespace / comma separated). Each URL becomes its OWN
    // subscription so distinct keys never merge into a single block.
    final subscriptionUrls = trimmed
        .split(RegExp(r'[\s,]+'))
        .map((u) => u.trim())
        .where((u) => u.startsWith('http://') || u.startsWith('https://'))
        .toList();

    if (subscriptionUrls.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                subscriptionUrls.length == 1
                    ? 'Fetching subscription...'
                    : 'Fetching ${subscriptionUrls.length} subscriptions...',
              ),
            ],
          ),
          duration: const Duration(seconds: 60),
        ),
      );

      var totalImported = 0;
      for (final url in subscriptionUrls) {
        try {
          totalImported += await ref
              .read(subscriptionProvider.notifier)
              .addSubscription(url: url, name: '', userAgent: 'arma');
        } catch (_) {
          // Skip a bad/expired link but keep importing the rest.
        }
      }
      if (!context.mounted) return;

      if (totalImported <= 0) {
        showAppSnackBar(
          context,
          message: subscriptionUrls.length == 1
              ? l10n.parseErrorInvalidLink
              : l10n.subscriptionFetchError,
        );
        return;
      }

      showAppSnackBar(
        context,
        message: l10n.importedServersCount(totalImported),
        backgroundColor: Colors.green.shade700,
      );
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
          showAppSnackBar(context, message: l10n.duplicateServer);
          return;
        }

        for (final item in newConfigs) {
          await ref.read(serverListProvider.notifier).addServer(item);
        }

        if (!context.mounted) return;
        showAppSnackBar(
          context,
          message: l10n.importedServersCount(newConfigs.length),
          backgroundColor: Colors.green.shade700,
        );
        return;
      }

      showAppSnackBar(
        context,
        message: l10n.parseErrorInvalidLink,
        duration: AppConstants.snackBarDurationLong,
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
      showAppSnackBar(context, message: l10n.duplicateServer);
      return;
    }

    await ref.read(serverListProvider.notifier).addServer(config);

    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message: '${l10n.importSuccess} — ${config.name}',
      backgroundColor: Colors.green.shade700,
    );
  }
}
