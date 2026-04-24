import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/traffic_stats_provider.dart';
import 'package:arma_proxy_vpn_client/xray/formatters/speed_formatter.dart';

/// Real-time traffic stats display in a single merged card (D-05).
///
/// Shows ↓ download speed and ↑ upload speed, updated in real-time
/// from [trafficStatsProvider]. Uses [formatSpeed] for human-readable
/// formatting (B/s, KB/s, MB/s, GB/s).
class TrafficStatsCard extends ConsumerWidget {
  const TrafficStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(trafficStatsProvider);
    final uploadSpeed = formatSpeed(stats.uplinkBytesPerSecond);
    final downloadSpeed = formatSpeed(stats.downlinkBytesPerSecond);

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _buildStatRow(
                context,
                icon: Icons.arrow_downward,
                speed: downloadSpeed,
                color: Colors.green,
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: colorScheme.outlineVariant,
            ),
            Expanded(
              child: _buildStatRow(
                context,
                icon: Icons.arrow_upward,
                speed: uploadSpeed,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String speed,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(8),
          Text(speed, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
