import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/utils/byte_format.dart';
import 'package:arma_proxy_vpn_client/core/utils/expiry_format.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';

/// Section header displaying the group name for a set of server cards.
///
/// For subscription groups (subscription != null), shows:
/// - Collapse toggle icon
/// - Subscription name in primary color
/// - 3-dot PopupMenu (Refresh / Delete All / Copy URL)
/// - Data usage progress bar with text
/// - Expiry countdown (month/week/day/hour/minute; red when <3 days,
///   warning icon when <1 day or expired)
///
/// For manual groups, shows the simple group name with count.
class ServerGroupHeader extends StatelessWidget {
  const ServerGroupHeader({
    super.key,
    required this.groupName,
    this.subscription,
    this.serverCount = 0,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onRefresh,
    this.onPing,
    this.onDeleteAll,
    this.isRefreshing = false,
    this.isPinging = false,
  });

  /// The group name to display (e.g., subscription name or "Manual").
  final String groupName;

  /// Subscription data for subscription groups. Null for manual groups.
  final Subscription? subscription;

  /// Number of servers in this group.
  final int serverCount;

  /// Whether this group is currently collapsed.
  final bool isCollapsed;

  /// Called when the collapse toggle is tapped.
  final VoidCallback? onToggleCollapse;

  /// Called when the refresh action is selected.
  final VoidCallback? onRefresh;

  /// Called when the ping/check-all action is selected.
  final VoidCallback? onPing;

  /// Called when "Delete All" is selected from the menu.
  final VoidCallback? onDeleteAll;

  /// Whether the subscription is currently being refreshed.
  final bool isRefreshing;

  /// Whether the subscription is currently being pinged.
  final bool isPinging;

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return _buildManualHeader(context);
    }
    return _buildSubscriptionHeader(context);
  }

  Widget _buildManualHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          InkWell(
            onTap: onToggleCollapse,
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              isCollapsed ? Icons.expand_more : Icons.expand_less,
              size: 24,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$groupName ($serverCount)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final sub = subscription!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: collapse toggle, name, 3-dot menu
          Row(
            children: [
              // Collapse toggle
              InkWell(
                onTap: onToggleCollapse,
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  isCollapsed ? Icons.expand_more : Icons.expand_less,
                  size: 24,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),

              // Subscription name
              Expanded(
                child: Text(
                  groupName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Inline Update (refresh) button
              _IconAction(
                icon: Icons.refresh,
                tooltip: 'Update',
                busy: isRefreshing,
                onTap: onRefresh,
                color: colorScheme.onSurfaceVariant,
              ),

              // Inline Ping (check) button
              _IconAction(
                icon: Icons.network_check,
                tooltip: 'Check servers',
                busy: isPinging,
                onTap: onPing,
                color: colorScheme.onSurfaceVariant,
              ),

              // 3-dot overflow menu (Update / Check / Copy URL / Delete All)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      onRefresh?.call();
                    case 'ping':
                      onPing?.call();
                    case 'deleteAll':
                      onDeleteAll?.call();
                    case 'copyUrl':
                      Clipboard.setData(ClipboardData(text: sub.url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.linkCopied),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: 8),
                        Text('Update'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'ping',
                    child: Row(
                      children: [
                        Icon(Icons.network_check, size: 20),
                        SizedBox(width: 8),
                        Text('Check servers'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copyUrl',
                    child: Row(
                      children: [
                        const Icon(Icons.copy, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.linkCopied),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'deleteAll',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20,
                            color: colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'Delete all',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Data usage — a progress bar for capped plans, or a "used" line for
          // unlimited plans (no `total` in subscription-userinfo).
          if (_hasUsageInfo(sub)) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: _buildDataUsageBar(context, sub),
            ),
          ],

          // Info line: server count + expiry
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4),
            child: _buildInfoRow(context, l10n, sub),
          ),
        ],
      ),
    );
  }

  /// Whether the subscription reports any usage/allowance worth displaying.
  static bool _hasUsageInfo(Subscription sub) {
    final used = (sub.uploadBytes ?? 0) + (sub.downloadBytes ?? 0);
    final hasTotal = sub.totalBytes != null && sub.totalBytes! > 0;
    return hasTotal || used > 0;
  }

  Widget _buildDataUsageBar(BuildContext context, Subscription sub) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usedBytes = (sub.uploadBytes ?? 0) + (sub.downloadBytes ?? 0);
    final total = sub.totalBytes;
    final hasTotal = total != null && total > 0;

    // Unlimited plan (no data cap / total=0) — show usage against the infinity
    // symbol, no fraction bar.
    if (!hasTotal) {
      return Text(
        '${formatBytes(usedBytes)} / ∞',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final fraction = (usedBytes / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            // A contrasty track so the bar is clearly visible even at 0% usage.
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
            color: fraction > 0.9 ? colorScheme.error : colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatBytes(usedBytes)} / ${formatBytes(total)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, AppLocalizations l10n, Subscription sub) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parts = <InlineSpan>[];

    // Server count
    parts.add(TextSpan(
      text: l10n.subscriptionInfoFormat(serverCount),
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ));

    // Expiry / unlimited marker.
    final expireDate = sub.expireDate;
    final isUnlimited = expireDate == null || expireDate.millisecondsSinceEpoch <= 0;
    if (isUnlimited) {
      parts.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              Icons.all_inclusive,
              size: 14,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    } else {
      final expiry = describeExpiry(expireDate);
      final expiryColor = expiry.isUrgent || expiry.isCritical
          ? colorScheme.error
          : colorScheme.onSurfaceVariant;

      parts.add(TextSpan(
        text: '  ·  ',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ));

      // Warning icon when less than a day remains (or expired).
      if (expiry.isCritical) {
        parts.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: colorScheme.error,
              ),
            ),
          ),
        );
      }

      parts.add(TextSpan(
        text: 'expires ${expiry.label}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: expiryColor,
          fontWeight:
              (expiry.isUrgent || expiry.isCritical) ? FontWeight.bold : null,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: parts),
    );
  }
}

/// Compact icon button that swaps to a spinner when [busy] is true.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.busy,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final bool busy;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );
  }
}
