import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/features/server/data/utils/flag_emoji_extractor.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/latency_indicator.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/protocol_badge.dart';

/// Displays a single server configuration as a compact Happ-style card.
///
/// Shows flag emoji (extracted from name), server name, address:port subtitle,
/// protocol badge pill, and latency indicator. Active server has a 4px teal
/// left border. Supports tap-to-select, long-press for multi-select, and
/// inline latency retesting.
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
    final flagEmoji = FlagEmojiExtractor.extract(server.name);

    return Semantics(
      label:
          '${server.name}, ${server.protocol.label}, tap to select',
      child: Card(
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? BorderSide(color: colorScheme.outlineVariant, width: 1)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        color: isMultiSelect && isChecked
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerLow,
        child: Container(
          decoration: isSelected && !isMultiSelect
              ? BoxDecoration(
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
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.only(
                left: isSelected && !isMultiSelect ? 12 : 16,
                right: 16,
                top: 12,
                bottom: 12,
              ),
              child: Row(
                children: [
                  // Multi-select checkbox
                  if (isMultiSelect) ...[
                    Checkbox(
                      value: isChecked,
                      onChanged: (_) => onToggleSelect?.call(),
                    ),
                    const Gap(4),
                  ],

                  // Flag emoji or protocol badge as leading icon
                  if (flagEmoji != null) ...[
                    Text(flagEmoji, style: const TextStyle(fontSize: 24)),
                    const Gap(12),
                  ] else ...[
                    ProtocolBadge(protocol: server.protocol),
                    const Gap(8),
                  ],

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
                        const Gap(2),
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

                  // Protocol badge (trailing when flag is present)
                  if (flagEmoji != null) ...[
                    const Gap(8),
                    ProtocolBadge(protocol: server.protocol),
                  ],

                  const Gap(8),

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
      ),
    );
  }
}
