import 'package:arma_proxy_vpn_client/core/utils/app_snackbar.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/pinned_keys_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/subscription_actions_sheet.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/subscription_key_block.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/reveal_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/screens/server_xray_config_screen.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/debug_long_press_wrapper.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';

/// Home screen default servers list, grouped into one collapsible block per
/// API key (subscription).
///
/// Each key the user has from the API becomes a [SubscriptionKeyBlock] showing
/// its own name, expiry, usage and announcement, with inline Update / Ping
/// actions and a "…" management sheet. Pinned blocks float to the top.
class DefaultServersSection extends ConsumerStatefulWidget {
  const DefaultServersSection({super.key});

  @override
  ConsumerState<DefaultServersSection> createState() =>
      _DefaultServersSectionState();
}

class _DefaultServersSectionState extends ConsumerState<DefaultServersSection> {
  /// Subscription URLs whose block is currently expanded (default collapsed).
  final Set<String> _expanded = {};

  /// The subscription URL currently refreshing (shows a spinner on its block).
  String? _refreshingUrl;

  /// Subscription URLs currently being pinged.
  final Set<String> _pinging = {};

  /// Per-server card keys, used to scroll a server into view on reveal.
  final Map<String, GlobalKey> _cardKeys = {};

  /// The last reveal id this section acted on (avoids re-scrolling on rebuild).
  String? _revealHandledId;

  GlobalKey _cardKey(String serverId) =>
      _cardKeys.putIfAbsent(serverId, GlobalKey.new);

  /// When the active-server card requests a reveal for one of *our* servers,
  /// expand its block and scroll it into view. Ids we don't own are left for
  /// the Servers tab to handle.
  void _handleReveal(String? serverId) {
    if (serverId == null || serverId == _revealHandledId) return;

    final state = ref.read(defaultServersProvider);
    DefaultServerItem? owner;
    for (final item in state.items) {
      if (item.serverConfig?.id == serverId) {
        owner = item;
        break;
      }
    }
    if (owner == null) return; // not a default server — not ours to handle.

    _revealHandledId = serverId;
    setState(() => _expanded.add(owner!.subscriptionUrl));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _cardKeys[serverId]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.2,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      // Clear so the same request doesn't linger; allow future reveals.
      _revealHandledId = null;
      ref.read(revealServerProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(defaultServersProvider);
    final latencyMap = ref.watch(latencyProvider);
    final activeServer = ref.watch(activeServerProvider);
    final pinned = ref.watch(pinnedKeysProvider);

    ref.listen<DefaultServersState>(defaultServersProvider, (previous, next) {
      final previousFailure = previous?.lastFailureType;
      final currentFailure = next.lastFailureType;
      if (currentFailure == null || previousFailure == currentFailure) {
        return;
      }
      showAppSnackBar(context, message: _failureMessage(l10n, currentFailure));
    });

    // React to a reveal request from the active-server card.
    ref.listen<String?>(revealServerProvider, (_, id) => _handleReveal(id));

    if (state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _EmptyState(
          title: l10n.defaultServersEmptyTitle,
          body: state.lastFailureType == DefaultServersFailureType.offline
              ? l10n.defaultServersNoCacheOfflineBody
              : l10n.defaultServersEmptyBody,
        ),
      );
    }

    // Group the flat item list by subscription (key) URL, preserving the API
    // ordering. Pinned keys are hoisted to the top without disturbing the
    // relative order within each partition.
    final groups = <String, List<DefaultServerItem>>{};
    for (final item in state.items) {
      groups.putIfAbsent(item.subscriptionUrl, () => []).add(item);
    }
    final entries = groups.entries.toList();
    final ordered = <MapEntry<String, List<DefaultServerItem>>>[
      ...entries.where((e) => pinned.contains(e.key)),
      ...entries.where((e) => !pinned.contains(e.key)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.defaultServersTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (state.isOfflineData)
                _OfflineBadge(label: l10n.defaultServersOfflineData),
            ],
          ),
        ),
        for (var i = 0; i < ordered.length; i++) ...[
          if (i > 0) const Gap(12),
          _buildBlock(context, ordered[i], activeServer, latencyMap, pinned),
        ],
      ],
    );
  }

  Widget _buildBlock(
    BuildContext context,
    MapEntry<String, List<DefaultServerItem>> group,
    ServerConfig? activeServer,
    Map<String, int> latencyMap,
    Set<String> pinned,
  ) {
    final url = group.key;
    final items = group.value;
    final first = items.first;

    final configs = <ServerConfig>[
      for (final item in items)
        if (item.isConnectable) item.serverConfig!,
    ];

    final isExpanded = _expanded.contains(url);

    return SubscriptionKeyBlock(
      key: ValueKey('subscription-block-$url'),
      name: first.keyName.isNotEmpty ? first.keyName : first.name,
      isActive: first.isActive,
      isPinned: pinned.contains(url),
      expireDate: first.expireDate,
      usedBytes: first.usedTraffic,
      totalBytes: first.dataLimit,
      announcement: first.announcement,
      serverCount: configs.length,
      isExpanded: isExpanded,
      isRefreshing: _refreshingUrl == url,
      isPinging: _pinging.contains(url),
      onToggleExpand: () => setState(() {
        if (!_expanded.remove(url)) {
          _expanded.add(url);
        }
      }),
      onRefresh: () => _onRefresh(url),
      onPing: configs.isEmpty ? null : () => _onPing(url, configs),
      onMore: () => _onMore(url, first.keyName, configs),
      children: [
        for (final config in configs)
          Padding(
            key: _cardKey(config.id),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: DebugLongPressWrapper(
              onDebugLongPress: kDebugMode
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ServerXrayConfigScreen(server: config),
                        ),
                      )
                  : () {},
              child: ServerCard(
                server: config,
                isSelected: config.id == activeServer?.id,
                latency: latencyMap[config.id],
                onTap: () {
                  HapticFeedback.selectionClick();
                  _onTapConfig(config);
                },
                onLatencyTap: () =>
                    ref.read(latencyProvider.notifier).testServer(config),
              ),
            ),
          ),
      ],
    );
  }

  void _onMore(String url, String keyName, List<ServerConfig> configs) {
    final isPinned = ref.read(pinnedKeysProvider).contains(url);
    showSubscriptionActionsSheet(
      context,
      title: keyName,
      actions: [
        SubscriptionAction(
          icon: Icons.refresh,
          label: 'Update subscription',
          onTap: () => _onRefresh(url),
        ),
        if (configs.isNotEmpty)
          SubscriptionAction(
            icon: Icons.speed,
            label: 'Ping',
            onTap: () => _onPing(url, configs),
          ),
        SubscriptionAction(
          icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
          label: isPinned ? 'Unpin' : 'Pin',
          onTap: () => ref.read(pinnedKeysProvider.notifier).toggle(url),
        ),
      ],
    );
  }

  Future<void> _onRefresh(String url) async {
    setState(() => _refreshingUrl = url);
    try {
      await ref.read(defaultServersProvider.notifier).refresh();
    } finally {
      if (mounted) {
        setState(() => _refreshingUrl = null);
      }
    }
  }

  Future<void> _onPing(String url, List<ServerConfig> configs) async {
    if (configs.isEmpty) return;
    setState(() => _pinging.add(url));
    try {
      await ref.read(latencyProvider.notifier).testAllServers(configs);
    } finally {
      if (mounted) {
        setState(() => _pinging.remove(url));
      }
    }
  }

  Future<void> _onTapConfig(ServerConfig target) async {
    final currentSelection = ref.read(activeServerProvider);
    await ref.read(activeServerProvider.notifier).selectServer(target);

    final connectionState = ref.read(connectionProvider);
    if (connectionState is Connected && currentSelection?.id != target.id) {
      final connectionNotifier = ref.read(connectionProvider.notifier);
      await connectionNotifier.disconnect();
      await connectionNotifier.connect(target);
    }
  }

  String _failureMessage(
    AppLocalizations l10n,
    DefaultServersFailureType failureType,
  ) {
    return switch (failureType) {
      DefaultServersFailureType.timeout => l10n.defaultServersTimeoutError,
      DefaultServersFailureType.offline => l10n.defaultServersOfflineError,
      DefaultServersFailureType.unauthorized =>
        l10n.defaultServersUnauthorizedError,
      DefaultServersFailureType.server => l10n.defaultServersServerError,
      DefaultServersFailureType.client => l10n.defaultServersClientError,
      DefaultServersFailureType.malformedResponse =>
        l10n.defaultServersMalformedError,
      DefaultServersFailureType.unknown => l10n.defaultServersServerError,
    };
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
