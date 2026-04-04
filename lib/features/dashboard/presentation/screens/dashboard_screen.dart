import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/active_server_card.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/connect_button.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/traffic_stats_placeholder.dart';

/// Dashboard screen — home screen of the app.
///
/// Shows the placeholder connect button (Phase 1 disabled),
/// connection state label, active server card, and traffic stats.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ConnectButton(),
            const Gap(16),
            Text(
              l10n.notConnected,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Gap(24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ActiveServerCard(),
            ),
            const Gap(16),
            const TrafficStatsPlaceholder(),
          ],
        ),
      ),
    );
  }
}
