import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';

class DefaultServersSheet extends StatelessWidget {
  const DefaultServersSheet({
    super.key,
    required this.items,
    required this.onServerTap,
  });

  final List<DefaultServerItem> items;
  final ValueChanged<DefaultServerItem> onServerTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.defaultServersShowAll,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    enabled: item.isConnectable,
                    title: Text(item.name),
                    subtitle: Text(item.status),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: item.isConnectable ? () => onServerTap(item) : null,
                  );
                },
                separatorBuilder: (_, _) => const Divider(height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
