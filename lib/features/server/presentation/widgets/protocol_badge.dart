import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/core/theme/app_colors.dart';

/// Displays a protocol tag as a small translucent capsule with colored
/// text — the design's "chips & tags" treatment (semi-transparent fill,
/// protocol accent text, hairline border of the same accent).
class ProtocolBadge extends StatelessWidget {
  const ProtocolBadge({super.key, required this.protocol});

  /// The protocol type to display.
  final ProtocolType protocol;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.protocolColor(protocol);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Bright accents need darkening to stay readable on light surfaces.
    final textColor = isDark ? accent : Color.lerp(accent, Colors.black, 0.35)!;

    return Semantics(
      label: 'Protocol: ${protocol.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Text(
          protocol.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
