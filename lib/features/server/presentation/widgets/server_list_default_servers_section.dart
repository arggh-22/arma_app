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
  const ServerListDefaultServersSection({
    super.key,
    this.onServerTap,
  });

  final Future<void> Function(DefaultServerItem item)? onServerTap;

  @override
  ConsumerState<ServerListDefaultServersSection> createState() =>
      _ServerListDefaultServersSectionState();
}

class _ServerListDefaultServersSectionState
    extends ConsumerState<ServerListDefaultServersSection> {
  bool _isExpanded = true;

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
              for (final item in defaultServersState.items)
                _DefaultServerRow(
                  key: ValueKey('server-list-default-server-row-${item.id}'),
                  item: item,
                  isSelected: activeServer?.id == item.serverConfig?.id,
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
            const Gap(8),
          ],
        ],
      ),
    );
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
