import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/features/server/domain/latency_level.dart';

/// Inline latency display widget per UI-SPEC §6 and Health Check spec §3.
///
/// Shows latency values with color-coded text:
/// - **null (untested):** tappable ping icon (network_check)
/// - **-2 (testing):** small circular progress indicator
/// - **-1 (failed) / 600+ ms:** gray "Timeout"
/// - **0-120ms (excellent):** green text
/// - **121-250ms (medium):** yellow/orange text
/// - **251-600ms (poor):** red text
///
/// Wrapped in InkWell for tap-to-retest (SERV-03).
/// Fixed 56dp width to prevent layout shift.
class LatencyIndicator extends StatelessWidget {
  const LatencyIndicator({super.key, this.latency, this.onTap});

  /// Latency in milliseconds. Null = untested, -2 = testing, -1 = failed.
  final int? latency;

  /// Callback when tapped (retest latency).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: _semanticsLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          // Comfortable touch target (min 48dp height per Material guidance)
          // so the small icon/value is easy to tap.
          width: 60,
          height: 48,
          child: Center(child: _buildContent(theme, colorScheme)),
        ),
      ),
    );
  }

  String get _semanticsLabel {
    if (latency == null) return 'Tap to test latency';
    if (latency == -2) return 'Testing';
    // Match the visible "Timeout" for failures and over-threshold values.
    if (latencyLevelFor(latency) == LatencyLevel.timeout) return 'Timeout';
    return '${latency}ms latency';
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    // Untested — show a tappable "ping" icon so it's clear you can test.
    if (latency == null) {
      return Icon(
        Icons.network_check,
        size: 18,
        color: colorScheme.onSurfaceVariant,
      );
    }

    // Testing
    if (latency == -2) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(colorScheme.primary),
        ),
      );
    }

    final level = latencyLevelFor(latency);
    final color = latencyColor(level, colorScheme);

    // Failed / timed out (-1 or > 600 ms): gray "Timeout" per §3.
    if (level == LatencyLevel.timeout) {
      return Text(
        'Timeout',
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      );
    }

    // Success — color coded by band (green / yellow / red).
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt, size: 12, color: color),
        Text(
          '${latency}ms',
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
