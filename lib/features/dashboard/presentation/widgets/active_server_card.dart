import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/reveal_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/protocol_badge.dart';
import 'package:arma_proxy_vpn_client/shared/widgets/glass_card.dart';

/// Card widget showing the currently active/selected server.
///
/// Displays server name, protocol badge, and its group name (or the app
/// brand name for default servers) when a server is selected. Tapping
/// navigates to the server list tab.
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
      onTap: () => _onTap(context, ref, server),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: server == null
              ? Row(
                  children: [
                    Icon(
                      Icons.dns_outlined,
                      size: 20,
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
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                )
              : Row(
                  children: [
                    ProtocolBadge(protocol: server.protocol),
                    const Gap(8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              server.name,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          Flexible(
                            child: Text(
                              // Default servers show the app/brand name;
                              // imported servers show their subscription name.
                              server.id.startsWith('default-api')
                                  ? l10n.appName
                                  : server.groupName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
      ),
    );
  }

  /// Reveal the selected server where it lives. Default-api servers are on the
  /// home screen, so we ask the home list to scroll to it; imported servers
  /// live on the Servers tab, so we switch tabs and let that screen scroll.
  void _onTap(BuildContext context, WidgetRef ref, ServerConfig? server) {
    if (server == null) {
      _goToServersTab(context);
      return;
    }

    ref.read(revealServerProvider.notifier).request(server.id);

    if (!server.id.startsWith('default-api')) {
      _goToServersTab(context);
    }
  }

  void _goToServersTab(BuildContext context) {
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null) {
      shell.goBranch(1);
    } else {
      context.go('/servers');
    }
  }
}
