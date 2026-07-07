import 'package:arma_proxy_vpn_client/core/utils/byte_format.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_sort_filter_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/server_sort_filter.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/screens/server_xray_config_screen.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/debug_long_press_wrapper.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_card.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/sort_filter_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/utils/expiry_format.dart';

/// Home screen default servers list.
///
/// Mirrors the Servers tab UI: a search + sort/filter bar over a list of
/// [ServerCard]s, driven by the API-provided default servers. Filtering state
/// is independent from the Servers tab (see [defaultServersSortFilterProvider]).
class DefaultServersSection extends ConsumerStatefulWidget {
  const DefaultServersSection({super.key});

  @override
  ConsumerState<DefaultServersSection> createState() =>
      _DefaultServersSectionState();
}

class _DefaultServersSectionState extends ConsumerState<DefaultServersSection> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(defaultServersProvider);
    final sortFilter = ref.watch(defaultServersSortFilterProvider);
    final latencyMap = ref.watch(latencyProvider);
    final isBulkTesting = ref.watch(latencyProvider.notifier).isBulkTesting;
    final activeServer = ref.watch(activeServerProvider);

    ref.listen<DefaultServersState>(defaultServersProvider, (previous, next) {
      final previousFailure = previous?.lastFailureType;
      final currentFailure = next.lastFailureType;
      if (currentFailure == null || previousFailure == currentFailure) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_failureMessage(l10n, currentFailure))),
      );
    });

    // Connectable default servers as ServerConfigs, then filtered + sorted
    // through the same logic as the Servers tab. Inactive/expired keys are
    // excluded so they can't be selected.
    final allConfigs = <ServerConfig>[
      for (final item in state.items)
        if (item.isConnectable) item.serverConfig!,
    ];
    final visibleConfigs = applyServerSort(
      applyServerFilter(allConfigs, sortFilter, latencyMap),
      sortFilter.sort,
      latencyMap,
    );

    final earliestExpiry = state.items.isEmpty
        ? null
        : state.items
            .map((item) => item.expireDate)
            .reduce((a, b) => a.isBefore(b) ? a : b);

    // Aggregate data usage across distinct subscriptions (a key's servers all
    // carry the same used/total figures, so dedupe by subscription URL first).
    final usageByUrl = <String, DefaultServerItem>{};
    for (final item in state.items) {
      usageByUrl.putIfAbsent(item.subscriptionUrl, () => item);
    }
    final usedBytes =
        usageByUrl.values.fold<int>(0, (sum, i) => sum + i.usedTraffic);
    final totalBytes =
        usageByUrl.values.fold<int>(0, (sum, i) => sum + i.dataLimit);

    final notifier = ref.read(defaultServersSortFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.defaultServersTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (state.isOfflineData) ...[
                _OfflineBadge(label: l10n.defaultServersOfflineData),
                const SizedBox(width: 8),
              ],
              // Test All — populates latency so the Working/Failed filters work.
              if (allConfigs.isNotEmpty)
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
                          key: const Key('default-servers-test-all'),
                          icon: const Icon(Icons.speed),
                          tooltip: l10n.testAllServers,
                          onPressed: () => ref
                              .read(latencyProvider.notifier)
                              .testAllServers(allConfigs),
                        ),
                ),
              IconButton(
                tooltip: l10n.defaultServersRefreshSemantics,
                onPressed: () =>
                    ref.read(defaultServersProvider.notifier).refresh(),
                icon: state.isRefreshing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (earliestExpiry != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _SubscriptionExpiry(expireDate: earliestExpiry),
          ),
        if (totalBytes > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: _UsageBar(usedBytes: usedBytes, totalBytes: totalBytes),
          ),
        if (allConfigs.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: _EmptyState(
              title: l10n.defaultServersEmptyTitle,
              body: state.lastFailureType == DefaultServersFailureType.offline
                  ? l10n.defaultServersNoCacheOfflineBody
                  : l10n.defaultServersEmptyBody,
            ),
          )
        else ...[
          SortFilterBar(
            state: sortFilter,
            availableProtocols: {
              for (final config in allConfigs) config.protocol,
            },
            onSort: notifier.setSort,
            onFilter: notifier.setFilter,
            onQuery: notifier.setQuery,
            onProtocol: notifier.setProtocol,
          ),
          const Gap(4),
          if (visibleConfigs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const Gap(12),
                  Text(
                    l10n.searchNoResults,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final config in visibleConfigs)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: DebugLongPressWrapper(
                  onDebugLongPress: kDebugMode
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ServerXrayConfigScreen(server: config),
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
      ],
    );
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

/// Section-level expiry indicator for the default servers, shown once next to
/// the title (all default servers share the same subscription expiry).
class _SubscriptionExpiry extends StatelessWidget {
  const _SubscriptionExpiry({required this.expireDate});

  final DateTime expireDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final expiry = describeExpiry(expireDate);
    final emphasized = expiry.isUrgent || expiry.isCritical;
    final color =
        emphasized ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          expiry.isCritical ? Icons.warning_amber_rounded : Icons.schedule,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          expiry.isExpired ? 'Subscription expired' : 'Expires in ${expiry.label}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: emphasized ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}

/// Data-usage progress bar for the whole default-servers subscription
/// (spec §2: `subscription-userinfo` → download/total). Turns red near the cap.
class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.usedBytes, required this.totalBytes});

  final int usedBytes;
  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fraction =
        totalBytes <= 0 ? 0.0 : (usedBytes / totalBytes).clamp(0.0, 1.0);
    final nearLimit = fraction >= 0.9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: nearLimit ? colorScheme.error : colorScheme.primary,
          ),
        ),
        const Gap(4),
        Text(
          '${formatBytes(usedBytes)} / ${formatBytes(totalBytes)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
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
