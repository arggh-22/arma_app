import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/features/routing/domain/entities/domain_rule.dart';

/// A single row in the domain rules list.
///
/// Shows a color dot for the action, the domain text,
/// a dropdown to change the action, and a delete button.
class DomainRuleRow extends StatelessWidget {
  final DomainRule rule;
  final ValueChanged<String> onActionChanged;
  final VoidCallback onDelete;

  const DomainRuleRow({
    super.key,
    required this.rule,
    required this.onActionChanged,
    required this.onDelete,
  });

  Color _actionColor(String action, ColorScheme cs) => switch (action) {
        'proxy' => cs.primary,
        'direct' => Colors.green,
        'block' => cs.error,
        _ => cs.primary,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _actionColor(rule.action, cs);

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Action color dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Domain text
            Expanded(
              child: Text(rule.domain, style: theme.textTheme.bodyMedium),
            ),
            // Action dropdown
            DropdownButton<String>(
              value: rule.action,
              underline: const SizedBox.shrink(),
              items: ['proxy', 'direct', 'block']
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(
                        a[0].toUpperCase() + a.substring(1),
                        style: TextStyle(color: _actionColor(a, cs)),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onActionChanged(v);
              },
            ),
            const SizedBox(width: 8),
            // Delete button
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: cs.onSurfaceVariant,
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
