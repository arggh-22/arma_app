import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/screens/server_xray_config_screen.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/debug_long_press_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';

class DefaultServersSheet extends StatelessWidget {
  const DefaultServersSheet({
    super.key,
    required this.items,
    required this.onServerTap,
    required this.scrollController,
  });

  final List<DefaultServerItem> items;
  final ValueChanged<DefaultServerItem> onServerTap;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.defaultServersShowAll,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const Divider(height: 1),
        // Scrollable list
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            itemCount: items.length,
            padding: const EdgeInsets.only(bottom: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return DebugLongPressWrapper(
                onDebugLongPress: item.serverConfig != null && kDebugMode
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ServerXrayConfigScreen(
                              server: item.serverConfig!,
                            ),
                          ),
                        )
                    : () {},
                child: ListTile(
                  enabled: item.isConnectable,
                  title: Text(item.name),
                  subtitle: Text(item.status),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: item.isConnectable ? () => onServerTap(item) : null,
                ),
              );
            },
            separatorBuilder: (_, _) => const Divider(height: 1),
          ),
        ),
      ],
    );
  }
}
