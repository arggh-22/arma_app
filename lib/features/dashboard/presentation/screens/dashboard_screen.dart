import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/widgets/connection_timer.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/widgets/traffic_stats_card.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/active_server_card.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/connect_button.dart';

/// Dashboard screen — home screen of the app.
///
/// Shows the animated connect button, connection status text,
/// elapsed timer, active server card, and real-time traffic stats.
/// All widgets are wired to live Riverpod providers from Plan 02-04.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(connectionProvider);

    final (statusText, statusColor) = switch (status) {
      Disconnected(:final lastError) => (
        lastError ?? l10n.notConnected,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      Connecting() => (
        '${l10n.connecting}...',
        Theme.of(context).colorScheme.primary,
      ),
      Connected() => (
        l10n.connected,
        Colors.green,
      ),
      Disconnecting() => (
        'Disconnecting...',
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };

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
              statusText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: statusColor,
                  ),
            ),
            const Gap(8),
            const ConnectionTimer(),
            const Gap(24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ActiveServerCard(),
            ),
            const Gap(16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TrafficStatsCard(),
            ),
          ],
        ),
      ),
    );
  }
}
