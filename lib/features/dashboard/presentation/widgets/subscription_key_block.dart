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
    this.showInfoLine = true,
    this.announcement,
    this.supportUrl,
    this.webPageUrl,
    this.onOpenUrl,
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
  final VoidCallback? onMore;
  final List<Widget> children;

  /// Whether to show the usage + expiry line under the header. Hidden for
  /// manual groups on the Servers tab that carry no subscription metadata.
  final bool showInfoLine;
  final String? announcement;

  /// Per-key `support-url` — opens the "Support" button when present.
  final String? supportUrl;

  /// Per-key `profile-web-page-url` — opens the "Renew" button when present.
  final String? webPageUrl;

  /// Opens an external link (renew / support). Required for the buttons to
  /// appear.
  final ValueChanged<String>? onOpenUrl;

  static bool _hasLink(String? url) => url != null && url.trim().isNotEmpty;

  bool get _hasLinks =>
      onOpenUrl != null && (_hasLink(webPageUrl) || _hasLink(supportUrl));

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
              padding: const EdgeInsets.fromLTRB(8, 1, 4, 1),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(2),
                  Icon(
                    isActive ? Icons.shield : Icons.warning_amber_rounded,
                    size: 18,
                    color: isActive ? colorScheme.primary : ArmaTokens.warning,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: theme.textTheme.titleSmall?.copyWith(
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
                  if (onRefresh != null)
                    _HeaderAction(
                      icon: Icons.refresh,
                      tooltip: 'Update subscription',
                      busy: isRefreshing,
                      onTap: onRefresh,
                    ),
                  if (onPing != null)
                    _HeaderAction(
                      icon: Icons.speed,
                      tooltip: 'Ping',
                      busy: isPinging,
                      onTap: onPing,
                    ),
                  if (onMore != null)
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
          if (showInfoLine)
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 0, 12, 6),
              child: _InfoRow(
                expireDate: expireDate,
                usedBytes: usedBytes,
                totalBytes: totalBytes,
              ),
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
                        // Renew / Support — only in the expanded card, right
                        // under the expiry area.
                        if (_hasLinks)
                          Padding(
                            padding: const EdgeInsets.only(left: 22, bottom: 8),
                            child: _LinkButtons(
                              webPageUrl: webPageUrl,
                              supportUrl: supportUrl,
                              onOpenUrl: onOpenUrl!,
                            ),
                          ),
                        // Subscription announcement, under the action buttons
                        // (mirrors the Servers-tab group header notice).
                        if (announcement != null &&
                            announcement!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 0, 0, 8),
                            child: _Announcement(text: announcement!.trim()),
                          ),
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

/// Renew (prominent, filled) + Support (secondary, outlined) actions shown at
/// the top of an expanded block.
class _LinkButtons extends StatelessWidget {
  const _LinkButtons({
    required this.webPageUrl,
    required this.supportUrl,
    required this.onOpenUrl,
  });

  final String? webPageUrl;
  final String? supportUrl;
  final ValueChanged<String> onOpenUrl;

  static bool _has(String? url) => url != null && url.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final hasRenew = _has(webPageUrl);
    final hasSupport = _has(supportUrl);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasRenew)
          FilledButton.icon(
            onPressed: () => onOpenUrl(webPageUrl!),
            icon: const Icon(Icons.card_membership_outlined, size: 16),
            label: const Text('Renew'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        if (hasRenew && hasSupport) const Gap(8),
        if (hasSupport)
          OutlinedButton.icon(
            onPressed: () => onOpenUrl(supportUrl!),
            icon: const Icon(Icons.support_agent_outlined, size: 16),
            label: const Text('Support'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
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
        width: 32,
        height: 32,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onTap,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}
