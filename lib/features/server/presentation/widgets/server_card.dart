import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/protocol_badge.dart';

/// Displays a single server configuration as a Material 3 card.
///
/// Shows the protocol badge, server name, address:port, and a
/// checkmark icon when selected. Supports tap-to-select and
/// long-press for contextual actions (e.g., delete).
class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.server,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  /// The server configuration to display.
  final ServerConfig server;

  /// Whether this server is the currently active/selected server.
  final bool isSelected;

  /// Called when the card is tapped (typically to select the server).
  final VoidCallback? onTap;

  /// Called when the card is long-pressed (typically to show delete dialog).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label:
          '${server.name}, ${server.protocol.label}, tap to select',
      child: Card(
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: colorScheme.primary, width: 2)
              : isDark
                  ? BorderSide(color: colorScheme.outlineVariant, width: 1)
                  : BorderSide.none,
        ),
        color: colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ProtocolBadge(protocol: server.protocol),
                const Gap(8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${server.address}:${server.port}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
