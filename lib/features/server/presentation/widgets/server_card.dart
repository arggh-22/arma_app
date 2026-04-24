import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/latency_indicator.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/protocol_badge.dart';

/// Displays a single server configuration as a compact Happ-style card.
///
/// Shows protocol badge, server name, address:port subtitle, and latency.
/// Active server has a 4px teal left border. Supports tap-to-select,
/// long-press for multi-select, and inline latency retesting.
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

    final Color bg = isMultiSelect && isChecked
        ? colorScheme.primaryContainer
        : (isSelected && !isMultiSelect
            ? colorScheme.primary.withValues(alpha: 0.06)
            : Colors.transparent);

    return Semantics(
      label: '${server.name}, ${server.protocol.label}, tap to select',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: isSelected && !isMultiSelect
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: colorScheme.primary,
                      width: 4,
                    ),
                  ),
                )
              : null,
          child: InkWell(
            onTap: isMultiSelect ? onToggleSelect : onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.only(
                left: isSelected && !isMultiSelect ? 8 : 12,
                right: 12,
                top: 8,
                bottom: 8,
              ),
              child: Row(
                children: [
                  // Multi-select checkbox
                  if (isMultiSelect) ...[
                    Checkbox(
                      value: isChecked,
                      onChanged: (_) => onToggleSelect?.call(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Gap(4),
                  ],

                  // Protocol badge is always before server name for consistency.
                  ProtocolBadge(protocol: server.protocol),
                  const Gap(8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.name,
                          style: theme.textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${server.address}:${server.port}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const Gap(8),

                  // Latency indicator
                  LatencyIndicator(
                    latency: latency,
                    onTap: onLatencyTap,
                  ),

                  // Active checkmark (only in normal mode)
                  if (!isMultiSelect && isSelected) ...[
                    const Gap(6),
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
