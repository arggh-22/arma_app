import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';

/// Animated circular connect button for the Dashboard.
///
/// Visual states (D-03):
///   - Disconnected: grey circle, no animation
///   - Connecting: teal circle with pulsing scale + shimmer, repeating
///   - Connected: teal circle with solid glow shadow
///   - Disconnecting: grey circle, no animation
///
/// 120dp diameter with power icon. Tapping calls connect/disconnect
/// via [ConnectionNotifier].
class ConnectButton extends ConsumerWidget {
  const ConnectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionProvider);
    final activeServer = ref.watch(activeServerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final (buttonColor, glowColor, isAnimating, semanticLabel) = switch (status) {
      Disconnected() => (
        Colors.grey.shade600,
        null as Color?,
        false,
        'Connect',
      ),
      Connecting() => (
        colorScheme.primary,
        null as Color?,
        true,
        'Connecting',
      ),
      Connected() => (
        colorScheme.primary,
        colorScheme.primary.withValues(alpha: 0.4) as Color?,
        false,
        'Disconnect',
      ),
      Disconnecting() => (
        Colors.grey.shade600,
        null as Color?,
        false,
        'Disconnecting',
      ),
    };

    void handleTap() {
      switch (status) {
        case Disconnected():
          if (activeServer != null) {
            ref.read(connectionProvider.notifier).connect(activeServer);
          }
        case Connected():
          ref.read(connectionProvider.notifier).disconnect();
        case Connecting():
        case Disconnecting():
          break; // Ignore taps during transition
      }
    }

    return Semantics(
      label: semanticLabel,
      child: GestureDetector(
        onTap: (status is Connecting || status is Disconnecting)
            ? null
            : handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: buttonColor,
            boxShadow: glowColor != null
                ? [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: const Icon(
            Icons.power_settings_new,
            color: Colors.white,
            size: 48,
          ),
        )
            .animate(target: isAnimating ? 1 : 0)
            .scaleXY(
              begin: 1.0,
              end: 1.05,
              duration: 800.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scaleXY(
              begin: 1.05,
              end: 1.0,
              duration: 800.ms,
              curve: Curves.easeInOut,
            )
            .animate(
              onPlay: isAnimating ? (c) => c.repeat() : null,
            )
            .shimmer(
              duration: 1500.ms,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
      ),
    );
  }
}
