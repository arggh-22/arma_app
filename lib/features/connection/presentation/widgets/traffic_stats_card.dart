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
  const TrafficStatsCard({super.key, this.middle});

  /// Optional widget rendered between the upload and download capsules — used
  /// on the dashboard to flank the connection timer (↑ upload · timer ·
  /// download ↓). When null the two capsules sit side by side as before.
  final Widget? middle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(trafficStatsProvider);
    final uploadSpeed = formatSpeed(stats.uplinkBytesPerSecond);
    final downloadSpeed = formatSpeed(stats.downlinkBytesPerSecond);

    final upload = _TelemetryCapsule(
      icon: Icons.arrow_upward_rounded,
      speed: uploadSpeed,
      accent: ArmaTokens.cyan,
    );
    final download = _TelemetryCapsule(
      icon: Icons.arrow_downward_rounded,
      speed: downloadSpeed,
      accent: ArmaTokens.success,
    );

    if (middle == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [upload, const Gap(12), download],
      );
    }

    // Upload · timer · download on a single row, scaled down on narrow
    // screens so the wide timer never overflows.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [upload, const Gap(16), middle!, const Gap(16), download],
      ),
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
    final accentColor = isDark
        ? accent
        : Color.lerp(accent, Colors.black, 0.3)!;

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
