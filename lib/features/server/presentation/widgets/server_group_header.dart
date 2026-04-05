import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';

/// Section header displaying the group name for a set of server cards.
///
/// For subscription groups (subscription != null), shows:
/// - Collapse toggle icon
/// - Subscription name in primary color
/// - Refresh button (with loading spinner)
/// - Info line: server count, data usage (GB), expiry (days)
///
/// For manual groups, shows the simple group name.
class ServerGroupHeader extends StatelessWidget {
  const ServerGroupHeader({
    super.key,
    required this.groupName,
    this.subscription,
    this.serverCount = 0,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onRefresh,
    this.isRefreshing = false,
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

  /// Called when the refresh button is tapped.
  final VoidCallback? onRefresh;

  /// Whether the subscription is currently being refreshed.
  final bool isRefreshing;

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
      child: Text(
        groupName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildSubscriptionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: collapse toggle, name, refresh button
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

              // Refresh button
              if (isRefreshing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: onRefresh,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),

          // Info line: server count + data usage + expiry
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              _buildInfoLine(l10n),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the info line: "3 servers · 2.1/10.0 GB · expires 30d"
  String _buildInfoLine(AppLocalizations l10n) {
    final parts = <String>[l10n.subscriptionInfoFormat(serverCount)];

    final sub = subscription;
    if (sub != null) {
      // Data usage
      if (sub.totalBytes != null && sub.totalBytes! > 0) {
        final usedBytes = (sub.uploadBytes ?? 0) + (sub.downloadBytes ?? 0);
        final usedGb = usedBytes / (1024 * 1024 * 1024);
        final totalGb = sub.totalBytes! / (1024 * 1024 * 1024);
        parts.add('${usedGb.toStringAsFixed(1)}/${totalGb.toStringAsFixed(1)} GB');
      }

      // Expiry
      if (sub.expireDate != null) {
        final daysLeft = sub.expireDate!.difference(DateTime.now()).inDays;
        if (daysLeft >= 0) {
          parts.add('expires ${daysLeft}d');
        } else {
          parts.add('expired');
        }
      }
    }

    return parts.join(' · ');
  }
}
