import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A single management action rendered in [showSubscriptionActionsSheet].
class SubscriptionAction {
  const SubscriptionAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
}

/// Bottom sheet listing the management actions for one subscription block
/// (redesign: the header "…" button opens this instead of a popup menu).
///
/// Mirrors the Happ reference sheet — a grabber handle above a vertical list
/// of icon + bold-label rows. The caller supplies the actions so the same
/// sheet serves API-key blocks (Update / Ping / Pin) and future callers.
Future<void> showSubscriptionActionsSheet(
  BuildContext context, {
  required String title,
  required List<SubscriptionAction> actions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colorScheme = theme.colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final action in actions)
              ListTile(
                leading: Icon(
                  action.icon,
                  color: action.isDestructive ? colorScheme.error : null,
                ),
                title: Text(
                  action.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: action.isDestructive ? colorScheme.error : null,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  action.onTap();
                },
              ),
            const Gap(8),
          ],
        ),
      );
    },
  );
}
