import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/theme/app_theme.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    final isActive = isSelected && !isMultiSelect;
    final Color bg = isMultiSelect && isChecked
        ? colorScheme.primary.withValues(alpha: 0.18)
        : isActive
        ? colorScheme.primary.withValues(alpha: isDark ? 0.10 : 0.06)
        : (isDark ? ArmaTokens.glassFill(0.04) : Colors.transparent);
    final Color borderColor = isActive
        ? colorScheme.primary.withValues(alpha: 0.55)
        : (isDark ? ArmaTokens.glassBorder(0.06) : Colors.transparent);

    return Semantics(
      label:
          '${server.name}, ${server.protocol.label}${server.rawConfig != null ? ', JSON config' : ''}, tap to select',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: isActive
                ? ArmaTokens.ambientGlow(alpha: 0.12, blur: 16, spread: 0)
                : null,
          ),
          child: InkWell(
            onTap: isMultiSelect ? onToggleSelect : onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
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
                        if (server.serverDescription != null &&
                            server.serverDescription!.isNotEmpty) ...[
                          const Gap(2),
                          Text(
                            server.serverDescription!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Gap(4),
                        Row(
                          children: [
                            ProtocolBadge(protocol: server.protocol),
                            if (server.rawConfig != null &&
                                server.rawConfig!.isNotEmpty) ...[
                              const Gap(6),
                              const _JsonBadge(),
                            ],
                            const Gap(8),
                            Expanded(
                              child: Text(
                                '${server.address}:${server.port}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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

/// Small capsule marking a server that carries a full JSON Xray config
/// (from a JSON subscription) — rendered next to the protocol badge.
class _JsonBadge extends StatelessWidget {
  const _JsonBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? accent : Color.lerp(accent, Colors.black, 0.35)!;

    return Semantics(
      label: 'JSON config',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Text(
          'JSON',
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
