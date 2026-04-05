import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/core/theme/app_colors.dart';

/// Displays a colored badge indicating the server's protocol type.
///
/// Each protocol gets a distinct background color (see [AppColors.protocolColor])
/// with white label text for visual identification in server cards.
class ProtocolBadge extends StatelessWidget {
  const ProtocolBadge({super.key, required this.protocol});

  /// The protocol type to display.
  final ProtocolType protocol;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Protocol: ${protocol.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.protocolColor(protocol),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          protocol.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
