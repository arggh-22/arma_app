import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/theme/app_colors.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';

/// Card widget showing the currently active/selected server.
///
/// Displays server name, protocol badge, and address:port when a server
/// is selected. Tapping navigates to the server list tab.
/// Shows "No server selected" fallback otherwise.
class ActiveServerCard extends ConsumerWidget {
  const ActiveServerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.watch(activeServerProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = server != null;
    final cardColor = isSelected
        ? Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.surfaceContainerLow,
          )
        : colorScheme.surfaceContainerLow;
    final cardBorder = isSelected
        ? BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.7),
            width: 1.5,
          )
        : BorderSide.none;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: cardBorder,
      ),
      child: InkWell(
        onTap: () {
          // Navigate to servers tab (index 1)
          final shell = StatefulNavigationShell.maybeOf(context);
          if (shell != null) {
            shell.goBranch(1);
          } else {
            context.go('/servers');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: server == null
              ? Row(
                  children: [
                    Icon(
                      Icons.dns_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        l10n.noServerSelected,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.protocolColor(server.protocol),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        server.protocol.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            server.name,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '${server.address}:${server.port}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
