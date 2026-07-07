import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';

/// Shows a bottom snackbar that behaves consistently everywhere:
/// - replaces any current/queued snackbar (no stacking that never clears),
/// - auto-hides after [duration] (default 4s),
/// - dismisses on tap or horizontal swipe.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = AppConstants.snackBarDurationDefault,
  Color? backgroundColor,
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: backgroundColor,
      action: action,
      dismissDirection: DismissDirection.horizontal,
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => messenger.hideCurrentSnackBar(),
        child: Text(message),
      ),
    ),
  );
}
