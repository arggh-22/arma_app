import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/protocol_badge.dart';
import 'package:arma_proxy_vpn_client/shared/widgets/glass_card.dart';

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

    return GlassCard(
      glow: isSelected,
      fillAlpha: isSelected ? 0.08 : 0.05,
      borderColor: isSelected
          ? colorScheme.primary.withValues(alpha: 0.55)
          : null,
      padding: EdgeInsets.zero,
      onTap: () {
        // Navigate to servers tab (index 1)
        final shell = StatefulNavigationShell.maybeOf(context);
        if (shell != null) {
          shell.goBranch(1);
        } else {
          context.go('/servers');
        }
      },
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
                    ProtocolBadge(protocol: server.protocol),
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
    );
  }
}
