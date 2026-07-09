import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';

/// Displays the empty state when no servers have been imported.
///
/// Shows a large icon, heading, descriptive body text, and an
/// "Import from Clipboard" filled button to guide the user.
class EmptyServerState extends StatelessWidget {
  const EmptyServerState({super.key, required this.onImportTap});

  /// Called when the user taps the "Import from Clipboard" button.
  final VoidCallback onImportTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const Gap(16),
          Text(l10n.noServersYet, style: theme.textTheme.headlineSmall),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.noServersBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Gap(24),
          FilledButton(
            onPressed: onImportTap,
            child: Text(l10n.importFromClipboard),
          ),
        ],
      ),
    );
  }
}
