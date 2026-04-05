import 'package:flutter/material.dart';

/// Section header displaying the group name for a set of server cards.
///
/// Groups are typically subscription names or "Manual" for manually
/// imported configurations.
class ServerGroupHeader extends StatelessWidget {
  const ServerGroupHeader({super.key, required this.groupName});

  /// The group name to display (e.g., subscription name or "Manual").
  final String groupName;

  @override
  Widget build(BuildContext context) {
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
}
