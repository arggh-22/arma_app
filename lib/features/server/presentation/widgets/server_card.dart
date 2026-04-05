import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/latency_indicator.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/protocol_badge.dart';

/// Displays a single server configuration as a Material 3 card.
///
/// Shows the protocol badge, server name, address:port, latency indicator,
/// and a checkmark icon when selected. Supports tap-to-select,
/// long-press for multi-select or contextual actions, and inline
/// latency retesting.
///
/// In multi-select mode, a leading checkbox replaces the trailing
/// checkmark and the card tints with primaryContainer when checked.
class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.server,
    required this.isSelected,
    this.latency,
    this.isMultiSelect = false,
    this.isChecked = false,
    this.onTap,
    this.onLongPress,
    this.onLatencyTap,
    this.onToggleSelect,
  });

  /// The server configuration to display.
  final ServerConfig server;

  /// Whether this server is the currently active/selected server.
  final bool isSelected;

  /// Latency in ms. Null = untested, -2 = testing, -1 = failed.
  final int? latency;

  /// Whether multi-select mode is active.
  final bool isMultiSelect;

  /// Whether this card is checked in multi-select mode.
  final bool isChecked;

  /// Called when the card is tapped (typically to select the server).
  final VoidCallback? onTap;

  /// Called when the card is long-pressed (enter multi-select or delete).
  final VoidCallback? onLongPress;

  /// Called when the latency indicator is tapped (retest).
  final VoidCallback? onLatencyTap;

  /// Called when the checkbox is toggled in multi-select mode.
  final VoidCallback? onToggleSelect;

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
          side: isSelected && !isMultiSelect
              ? BorderSide(color: colorScheme.primary, width: 2)
              : isDark
                  ? BorderSide(color: colorScheme.outlineVariant, width: 1)
                  : BorderSide.none,
        ),
        color: isMultiSelect && isChecked
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: isMultiSelect ? onToggleSelect : onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Multi-select checkbox
                if (isMultiSelect) ...[
                  Checkbox(
                    value: isChecked,
                    onChanged: (_) => onToggleSelect?.call(),
                  ),
                  const Gap(8),
                ],
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
                // Latency indicator
                LatencyIndicator(
                  latency: latency,
                  onTap: onLatencyTap,
                ),
                // Active checkmark (only in normal mode)
                if (!isMultiSelect && isSelected) ...[
                  const Gap(8),
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
