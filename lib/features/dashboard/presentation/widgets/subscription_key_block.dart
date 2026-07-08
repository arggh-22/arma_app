import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/theme/app_theme.dart';
import 'package:arma_proxy_vpn_client/core/utils/byte_format.dart';
import 'package:arma_proxy_vpn_client/core/utils/expiry_format.dart';
import 'package:arma_proxy_vpn_client/shared/widgets/glass_card.dart';

/// One API key (subscription) rendered as a single collapsible block on the
/// home screen (redesign — mirrors the Happ per-subscription card).
///
/// The always-visible part is the header: status glyph, key name, inline
/// Update / Ping actions, and a "…" button that opens the management sheet,
/// followed by an info line (expiry + data usage) and the key's announcement.
/// The [children] (server cards) are shown only when [isExpanded].
class SubscriptionKeyBlock extends StatelessWidget {
  const SubscriptionKeyBlock({
    super.key,
    required this.name,
    required this.isActive,
    required this.isPinned,
    required this.expireDate,
    required this.usedBytes,
    required this.totalBytes,
    required this.serverCount,
    required this.isExpanded,
    required this.isRefreshing,
    required this.isPinging,
    required this.onToggleExpand,
    required this.onRefresh,
    required this.onPing,
    required this.onMore,
    required this.children,
    this.announcement,
  });

  final String name;
  final bool isActive;
  final bool isPinned;
  final DateTime expireDate;
  final int usedBytes;
  final int totalBytes;
  final int serverCount;
  final bool isExpanded;
  final bool isRefreshing;
  final bool isPinging;
  final VoidCallback onToggleExpand;
  final VoidCallback? onRefresh;
  final VoidCallback? onPing;
  final VoidCallback onMore;
  final List<Widget> children;
  final String? announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      glow: isPinned,
      fillAlpha: isPinned ? 0.08 : 0.05,
      borderColor: isPinned
          ? colorScheme.primary.withValues(alpha: 0.55)
          : null,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — tapping the row (outside the action buttons) expands or
          // collapses the block.
          InkWell(
            onTap: onToggleExpand,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(ArmaTokens.radiusCard),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(2),
                  Icon(
                    isActive ? Icons.shield : Icons.warning_amber_rounded,
                    size: 20,
                    color: isActive ? colorScheme.primary : ArmaTokens.warning,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPinned) ...[
                          const Gap(6),
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _HeaderAction(
                    icon: Icons.refresh,
                    tooltip: 'Update subscription',
                    busy: isRefreshing,
                    onTap: onRefresh,
                  ),
                  _HeaderAction(
                    icon: Icons.speed,
                    tooltip: 'Ping',
                    busy: isPinging,
                    onTap: onPing,
                  ),
                  _HeaderAction(
                    icon: Icons.more_vert,
                    tooltip: 'Manage',
                    busy: false,
                    onTap: onMore,
                  ),
                ],
              ),
            ),
          ),

          // Info line: expiry + data usage.
          Padding(
            padding: const EdgeInsets.fromLTRB(38, 0, 12, 10),
            child: _InfoRow(
              expireDate: expireDate,
              usedBytes: usedBytes,
              totalBytes: totalBytes,
            ),
          ),

          // Per-key announcement (shown collapsed or expanded).
          if (announcement != null && announcement!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(38, 0, 12, 12),
              child: _Announcement(text: announcement!.trim()),
            ),

          // Server list — mounted only when expanded (kept out of the tree
          // when collapsed so it neither renders nor participates in taps).
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: 1),
                        const Gap(6),
                        ...children,
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.expireDate,
    required this.usedBytes,
    required this.totalBytes,
  });

  final DateTime expireDate;
  final int usedBytes;
  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isUnlimitedExpiry = expireDate.millisecondsSinceEpoch <= 0;
    final expiry = isUnlimitedExpiry ? null : describeExpiry(expireDate);
    final emphasize = expiry != null && (expiry.isUrgent || expiry.isCritical);
    final expiryColor =
        emphasize ? colorScheme.error : colorScheme.onSurfaceVariant;

    final String expiryText;
    if (isUnlimitedExpiry) {
      expiryText = 'Expires: never';
    } else if (expiry!.isExpired) {
      expiryText = 'Expired';
    } else {
      // Countdown: months / weeks / days when far out; hours + minutes when
      // less than a day remains.
      expiryText = 'Expires: ${_formatCountdown(expireDate.difference(_now()))}';
    }

    final usageText = totalBytes > 0
        ? '${formatBytes(usedBytes)} / ${formatBytes(totalBytes)}'
        : '${formatBytes(usedBytes)} / ∞';

    final subtle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Icon(Icons.data_usage, size: 13, color: colorScheme.onSurfaceVariant),
        const Gap(4),
        Text(usageText, style: subtle),
        const Spacer(),
        if (emphasize) ...[
          Icon(Icons.warning_amber_rounded, size: 13, color: expiryColor),
          const Gap(3),
        ],
        Text(
          expiryText,
          style: subtle?.copyWith(
            color: expiryColor,
            fontWeight: emphasize ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}

/// Current time — indirected so it reads clearly at the single call site.
DateTime _now() => DateTime.now();

/// Formats the time left until expiry using the largest sensible unit, and
/// hours + minutes once under a day (e.g. `2mo`, `3w`, `5d`, `8h 42m`, `12m`).
String _formatCountdown(Duration remaining) {
  if (remaining.inSeconds <= 0) return '0m';
  final days = remaining.inDays;
  if (days >= 30) return '${days ~/ 30}mo';
  if (days >= 7) return '${days ~/ 7}w';
  if (days >= 1) return '${days}d';
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes % 60;
  if (hours >= 1) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

class _Announcement extends StatelessWidget {
  const _Announcement({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 16,
            color: colorScheme.onSecondaryContainer,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact header icon button that swaps to a spinner while [busy].
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onTap,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
    );
  }
}
