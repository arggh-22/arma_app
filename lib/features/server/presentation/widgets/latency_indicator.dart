import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/theme/app_theme.dart';

/// Inline latency display widget per UI-SPEC §6.
///
/// Shows latency values with color-coded text:
/// - **null (untested):** dash in onSurfaceVariant
/// - **-2 (testing):** small circular progress indicator
/// - **-1 (failed):** error icon
/// - **0-150ms (good):** green text
/// - **151-300ms (fair):** orange text
/// - **301ms+ (poor):** error color text
///
/// Wrapped in InkWell for tap-to-retest (SERV-03).
/// Fixed 56dp width to prevent layout shift.
class LatencyIndicator extends StatelessWidget {
  const LatencyIndicator({
    super.key,
    this.latency,
    this.onTap,
  });

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
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 56,
          child: Center(child: _buildContent(theme, colorScheme)),
        ),
      ),
    );
  }

  String get _semanticsLabel {
    if (latency == null) return 'Untested';
    if (latency == -2) return 'Testing';
    if (latency == -1) return 'Failed';
    return '${latency}ms latency';
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    // Untested
    if (latency == null) {
      return Text(
        '—',
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
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

    // Failed
    if (latency == -1) {
      return Icon(
        Icons.error_outline,
        size: 16,
        color: colorScheme.error,
      );
    }

    // Success — color coded by latency range
    final Color textColor;
    if (latency! <= 150) {
      textColor = ArmaTokens.success;
    } else if (latency! <= 300) {
      textColor = ArmaTokens.warning;
    } else {
      textColor = colorScheme.error;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt, size: 12, color: textColor),
        Text(
          '${latency}ms',
          style: theme.textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
