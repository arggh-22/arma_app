import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class ServerListDefaultServersSection extends ConsumerStatefulWidget {
  const ServerListDefaultServersSection({super.key, this.onServerTap});

  final Future<void> Function(DefaultServerItem item)? onServerTap;

  @override
  ConsumerState<ServerListDefaultServersSection> createState() =>
      _ServerListDefaultServersSectionState();
}

class _ServerListDefaultServersSectionState
    extends ConsumerState<ServerListDefaultServersSection> {
  bool _isExpanded = true;
  final Set<String> _collapsedSubgroups = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final defaultServersState = ref.watch(defaultServersProvider);
    final activeServer = ref.watch(activeServerProvider);

    return Padding(
      key: const ValueKey('server-list-default-servers-section'),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.defaultServersTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (defaultServersState.isOfflineData)
                  Text(
                    l10n.defaultServersOfflineData,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                IconButton(
                  key: const ValueKey('server-list-default-servers-toggle'),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            if (defaultServersState.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  defaultServersState.lastFailureType ==
                          DefaultServersFailureType.offline
                      ? l10n.defaultServersNoCacheOfflineBody
                      : l10n.defaultServersEmptyBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              ..._buildGroupedRows(
                items: defaultServersState.items,
                activeServerId: activeServer?.id,
              ),
            const Gap(8),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildGroupedRows({
    required List<DefaultServerItem> items,
    required String? activeServerId,
  }) {
    final grouped = <String, List<DefaultServerItem>>{};
    for (final item in items) {
      grouped
          .putIfAbsent(item.subscriptionUrl, () => <DefaultServerItem>[])
          .add(item);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      final subscriptionUrl = entry.key;
      final groupItems = entry.value;
      final isCollapsed = _collapsedSubgroups.contains(subscriptionUrl);
      final title = _groupTitle(groupItems);

      widgets.add(
        _DefaultSubgroupHeader(
          key: ValueKey('server-list-default-subgroup-header-$subscriptionUrl'),
          title: title,
          count: groupItems.length,
          isCollapsed: isCollapsed,
          onTap: () {
            setState(() {
              if (isCollapsed) {
                _collapsedSubgroups.remove(subscriptionUrl);
              } else {
                _collapsedSubgroups.add(subscriptionUrl);
              }
            });
          },
          toggleKey: ValueKey(
            'server-list-default-subgroup-toggle-$subscriptionUrl',
          ),
        ),
      );

      if (isCollapsed) {
        continue;
      }

      for (final item in groupItems)
        widgets.add(
          _DefaultServerRow(
            key: ValueKey('server-list-default-server-row-${item.id}'),
            item: item,
            isSelected: activeServerId == item.serverConfig?.id,
            onTap: () async {
              if (!item.isConnectable) {
                return;
              }
              if (widget.onServerTap case final onTap?) {
                await onTap(item);
                return;
              }
              await _onTapDefaultServer(item);
            },
          ),
        );
    }

    return widgets;
  }

  String _groupTitle(List<DefaultServerItem> groupItems) {
    final first = groupItems.first;
    final sourceName = first.serverConfig?.groupName.trim();
    if (sourceName != null && sourceName.isNotEmpty && sourceName != 'Manual') {
      return sourceName;
    }
    return first.name;
  }

  Future<void> _onTapDefaultServer(DefaultServerItem item) async {
    final target = item.serverConfig;
    if (target == null) {
      return;
    }

    final currentSelection = ref.read(activeServerProvider);
    await ref.read(activeServerProvider.notifier).selectServer(target);

    final connectionState = ref.read(connectionProvider);
    if (connectionState is Connected && currentSelection?.id != target.id) {
      final connectionNotifier = ref.read(connectionProvider.notifier);
      await connectionNotifier.disconnect();
      await connectionNotifier.connect(target);
    }
  }
}

class _DefaultSubgroupHeader extends StatelessWidget {
  const _DefaultSubgroupHeader({
    super.key,
    required this.title,
    required this.count,
    required this.isCollapsed,
    required this.onTap,
    required this.toggleKey,
  });

  final String title;
  final int count;
  final bool isCollapsed;
  final VoidCallback onTap;
  final Key toggleKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          IconButton(
            key: toggleKey,
            onPressed: onTap,
            icon: Icon(
              isCollapsed ? Icons.expand_more : Icons.expand_less,
              color: colorScheme.onSurfaceVariant,
            ),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              '$title ($count)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultServerRow extends StatelessWidget {
  const _DefaultServerRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final DefaultServerItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: colorScheme.primary, width: 4),
                  ),
                )
              : null,
          child: InkWell(
            onTap: item.isConnectable ? onTap : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.only(
                left: isSelected ? 8 : 12,
                right: 12,
                top: 8,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      key: ValueKey(
                        'server-list-default-server-selected-${item.id}',
                      ),
                      Icons.check_circle,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
