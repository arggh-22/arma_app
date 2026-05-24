import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/widgets/connection_timer.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/widgets/traffic_stats_card.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/active_server_card.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/connect_button.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/default_servers_section.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/ui_preferences_provider.dart';

/// Dashboard screen — home screen of the app.
///
/// Shows the animated connect button, connection status text,
/// elapsed timer, active server card, and real-time traffic stats.
/// All widgets are wired to live Riverpod providers from Plan 02-04.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showLinkFab = true;

  bool _onScroll(UserScrollNotification notification) {
    switch (notification.direction) {
      case ScrollDirection.reverse:
        if (_showLinkFab) {
          setState(() => _showLinkFab = false);
        }
      case ScrollDirection.forward:
        if (!_showLinkFab) {
          setState(() => _showLinkFab = true);
        }
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(connectionProvider);
    final uiPreferences = ref.watch(uiPreferencesProvider);

    final (statusText, statusColor) = switch (status) {
      Disconnected(:final lastError) => (
        lastError ?? l10n.notConnected,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      Connecting() => (
        '${l10n.connecting}...',
        Theme.of(context).colorScheme.primary,
      ),
      Connected() => (l10n.connected, Colors.green),
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
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              const ConnectButton(),
              const Gap(16),
              Text(
                statusText,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: statusColor),
              ),
              const Gap(8),
              const ConnectionTimer(),
              const Gap(24),
              const ActiveServerCard(),
              if (uiPreferences.showDashboardStatistics) ...[
                const Gap(16),
                const TrafficStatsCard(),
              ],
              const Gap(24),
              const DefaultServersSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: _showLinkFab
          ? FloatingActionButton.extended(
              key: const Key('dashboard-telegram-link-fab'),
              onPressed: () => context.push('/telegram-link'),
              icon: const FaIcon(FontAwesomeIcons.telegram, size: 18),
              label: Text(l10n.telegramLinkFabLabel),
            )
          : null,
    );
  }
}
