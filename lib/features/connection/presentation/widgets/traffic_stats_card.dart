import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/theme/app_theme.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/traffic_stats_provider.dart';
import 'package:arma_proxy_vpn_client/xray/formatters/speed_formatter.dart';

/// Real-time telemetry readout — ↑ upstream / ↓ downstream velocity,
/// rendered as two glass capsules (design: hero telemetry stream).
///
/// Updated live from [trafficStatsProvider]; uses [formatSpeed] for
/// human-readable formatting (B/s, KB/s, MB/s, GB/s).
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
        _TelemetryCapsule(
          icon: Icons.arrow_upward_rounded,
          speed: uploadSpeed,
          accent: ArmaTokens.cyan,
        ),
        const Gap(12),
        _TelemetryCapsule(
          icon: Icons.arrow_downward_rounded,
          speed: downloadSpeed,
          accent: ArmaTokens.success,
        ),
      ],
    );
  }
}

class _TelemetryCapsule extends StatelessWidget {
  const _TelemetryCapsule({
    required this.icon,
    required this.speed,
    required this.accent,
  });

  final IconData icon;
  final String speed;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? accent : Color.lerp(accent, Colors.black, 0.3)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? ArmaTokens.glassFill(0.06)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ArmaTokens.radiusPill),
        border: Border.all(
          color: isDark
              ? ArmaTokens.glassBorder()
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 16),
          const Gap(6),
          Text(
            speed,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
