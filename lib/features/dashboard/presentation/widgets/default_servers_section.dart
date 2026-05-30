import 'dart:math' as math;

import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/default_servers_sheet.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';

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
    final state = ref.watch(defaultServersProvider);
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

    final previewItems = state.items.take(3).toList(growable: false);
    final canShowAll = state.items.length > 3;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.defaultServersTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (state.isOfflineData) ...[
                  _OfflineBadge(label: l10n.defaultServersOfflineData),
                  const SizedBox(width: 8),
                ],
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
            const SizedBox(height: 8),
            if (previewItems.isEmpty)
              _EmptyState(
                title: l10n.defaultServersEmptyTitle,
                body: state.lastFailureType == DefaultServersFailureType.offline
                    ? l10n.defaultServersNoCacheOfflineBody
                    : l10n.defaultServersEmptyBody,
              )
            else
              Column(
                children: [
                  for (final item in previewItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DefaultServerTile(
                        item: item,
                        isSelected: item.serverConfig?.id == activeServer?.id,
                        onTap: () => _onTapItem(item),
                      ),
                    ),
                ],
              ),
            if (canShowAll) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _openShowAllSheet(context, state.items),
                  child: Text(l10n.defaultServersShowAll),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onTapItem(DefaultServerItem item) async {
    if (!item.isConnectable) {
      return;
    }
    final target = item.serverConfig!;
    final currentSelection = ref.read(activeServerProvider);

    await ref.read(activeServerProvider.notifier).selectServer(target);

    final connectionState = ref.read(connectionProvider);
    if (connectionState is Connected && currentSelection?.id != target.id) {
      final connectionNotifier = ref.read(connectionProvider.notifier);
      await connectionNotifier.disconnect();
      await connectionNotifier.connect(target);
    }
  }

  void _openShowAllSheet(BuildContext context, List<DefaultServerItem> items) {
    // Cap initial size so the sheet never opens full-screen.
    // On small phones a large list would overflow; DraggableScrollableSheet
    // lets the user expand/collapse and swipe down to dismiss.
    final itemFraction = (items.length * 0.1).clamp(0.3, 0.6);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: itemFraction,
        minChildSize: 0.25,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => DefaultServersSheet(
          items: items,
          scrollController: scrollController,
          onServerTap: (item) {
            Navigator.of(context).pop();
            _onTapItem(item);
          },
        ),
      ),
    );
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

class _DefaultServerTile extends StatelessWidget {
  const _DefaultServerTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final DefaultServerItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = item.dataLimit <= 0
        ? 0.0
        : (item.usedTraffic / item.dataLimit).clamp(0.0, 1.0);
    final enabled = item.isConnectable;
    final tileColor = isSelected
        ? Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.surfaceContainerLow,
          )
        : colorScheme.surfaceContainerLow;
    final tileBorder = isSelected
        ? BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.7),
            width: 1.5,
          )
        : BorderSide.none;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: tileColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: tileBorder,
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      label: _statusLabel(l10n, item.status),
                      color: _statusColor(item.status, colorScheme),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 6),
                Text(
                  '${_formatBytes(item.usedTraffic)} / ${_formatBytes(item.dataLimit)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String rawStatus) {
    return switch (rawStatus.toLowerCase()) {
      'active' => l10n.defaultServersStatusActive,
      'expired' => l10n.defaultServersStatusExpired,
      'limited' => l10n.defaultServersStatusLimited,
      _ => l10n.defaultServersStatusUnknown,
    };
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    return switch (status.toLowerCase()) {
      'active' => Colors.green,
      'expired' => colorScheme.error,
      'limited' => Colors.orange,
      _ => colorScheme.outline,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
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

String _formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0B';
  }
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  final exponent = math.min((math.log(bytes) / math.log(1024)).floor(), 4);
  final value = bytes / math.pow(1024, exponent);
  final fixed = value >= 10 || exponent == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$fixed${units[exponent]}';
}
