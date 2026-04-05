import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/traffic_stats_provider.dart';
import 'package:arma_proxy_vpn_client/xray/formatters/speed_formatter.dart';

/// Real-time traffic stats display with two side-by-side cards (D-05).
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatCard(
          context,
          icon: Icons.arrow_downward,
          label: '↓',
          speed: downloadSpeed,
          color: Colors.green,
        ),
        const Gap(16),
        _buildStatCard(
          context,
          icon: Icons.arrow_upward,
          label: '↑',
          speed: uploadSpeed,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String speed,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const Gap(8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
                Text(speed, style: theme.textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
