import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';

/// Static traffic stats placeholder for the Dashboard.
///
/// Shows "↓ 0 B/s" and "↑ 0 B/s" as static values.
/// Real traffic monitoring will be implemented in Phase 2.
class TrafficStatsPlaceholder extends StatelessWidget {
  const TrafficStatsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(l10n.downloadSpeed('0 B/s'), style: style),
        const Gap(32),
        Text(l10n.uploadSpeed('0 B/s'), style: style),
      ],
    );
  }
}
