import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';

/// Circular connect button for the Dashboard.
///
/// Phase 1 placeholder — disabled at 50% opacity.
/// Tapping shows a snackbar indicating the feature is coming.
/// 120dp diameter per UI-SPEC D-03.
class ConnectButton extends StatelessWidget {
  const ConnectButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Connect button, disabled',
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.disabledConnect),
              duration: AppConstants.snackBarDurationShort,
            ),
          );
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          child: Icon(
            Icons.power_settings_new,
            color: colorScheme.onPrimary,
            size: 48,
          ),
        ),
      ),
    );
  }
}
