import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';

/// Routing screen with bypass LAN toggle and placeholder card.
///
/// Phase 1: Only the bypass LAN toggle is functional (local state).
/// Full routing rules will be implemented in Phase 4.
class RoutingScreen extends StatefulWidget {
  const RoutingScreen({super.key});

  @override
  State<RoutingScreen> createState() => _RoutingScreenState();
}

class _RoutingScreenState extends State<RoutingScreen> {
  bool _bypassLan = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.routing,
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(
              l10n.bypassLan,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              l10n.bypassLanSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            value: _bypassLan,
            onChanged: (value) {
              setState(() {
                _bypassLan = value;
              });
            },
          ),
          const Gap(16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  l10n.routingPlaceholder,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
