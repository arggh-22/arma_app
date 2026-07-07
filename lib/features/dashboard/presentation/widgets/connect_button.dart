import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/theme/app_theme.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';

/// Hero connect control — a massive glowing circle that morphs between
/// connection states (design: Home Dashboard hero tunnel element).
///
/// Visual states:
///   - Disconnected: dark glass circle, muted power glyph, "DISCONNECTED"
///   - Connecting: indigo ring pulsing around a shield glyph, "CONNECTING"
///   - Connected: solid Electric Indigo glow, shield glyph, "CONNECTED"
///   - Disconnecting: faded connected state
///
/// Tapping calls connect/disconnect via [ConnectionNotifier].
class ConnectButton extends ConsumerWidget {
  const ConnectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionProvider);
    final activeServer = ref.watch(activeServerProvider);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final diameter = (MediaQuery.sizeOf(context).width * 0.55).clamp(
      180.0,
      240.0,
    );

    final (statusWord, icon, ringColor, glowAlpha, isPulsing, semanticLabel) =
        switch (status) {
          Disconnected() => (
            l10n.notConnected.toUpperCase(),
            Icons.power_settings_new,
            colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            0.12,
            false,
            'Connect',
          ),
          Connecting() => (
            l10n.connecting.toUpperCase(),
            Icons.shield_outlined,
            colorScheme.primary,
            0.30,
            true,
            'Connecting',
          ),
          Connected() => (
            l10n.connected.toUpperCase(),
            Icons.shield,
            colorScheme.primary,
            0.45,
            false,
            'Disconnect',
          ),
          Disconnecting() => (
            l10n.disconnecting.toUpperCase(),
            Icons.shield_outlined,
            colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            0.10,
            false,
            'Disconnecting',
          ),
        };

    final isActive = status is Connected || status is Connecting;
    final contentColor = isActive
        ? (isDark ? Colors.white : colorScheme.primary)
        : colorScheme.onSurfaceVariant;

    Future<void> handleTap() async {
      switch (status) {
        case Disconnected():
          var selectedServer = activeServer;
          if (selectedServer == null) {
            try {
              final servers = await ref.read(serverListProvider.future);
              if (servers.isNotEmpty) {
                selectedServer = servers.first;
                await ref
                    .read(activeServerProvider.notifier)
                    .selectServer(selectedServer);
              }
            } catch (e) {
              debugPrint('[ConnectButton] Failed to auto-select server: $e');
            }
          }

          if (selectedServer != null) {
            await ref.read(connectionProvider.notifier).connect(selectedServer);
          }
        case Connecting():
        case Connected():
          await ref.read(connectionProvider.notifier).disconnect();
        case Disconnecting():
          break; // Ignore taps during shutdown
      }
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: status is Disconnecting ? null : () => handleTap(),
        child: AnimatedOpacity(
          opacity: status is Disconnecting ? 0.45 : 1.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        ArmaTokens.indigoDeep.withValues(
                          alpha: isActive ? 0.55 : 0.18,
                        ),
                        ArmaTokens.deepNavy.withValues(alpha: 0.9),
                      ]
                    : [
                        colorScheme.primary.withValues(
                          alpha: isActive ? 0.30 : 0.08,
                        ),
                        colorScheme.surface,
                      ],
              ),
              border: Border.all(color: ringColor, width: 2),
              boxShadow: ArmaTokens.ambientGlow(
                color: isActive ? ArmaTokens.indigo : ArmaTokens.glow,
                alpha: glowAlpha,
                blur: 60,
                spread: 8,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    color: contentColor,
                    size: diameter * 0.22,
                  ),
                ),
                SizedBox(height: diameter * 0.07),
                Text(
                  statusWord,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          )
              .animate(target: isPulsing ? 1 : 0)
              .scaleXY(
                begin: 1.0,
                end: 1.04,
                duration: 800.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scaleXY(
                begin: 1.04,
                end: 1.0,
                duration: 800.ms,
                curve: Curves.easeInOut,
              )
              .animate(onPlay: isPulsing ? (c) => c.repeat() : null)
              .shimmer(
                duration: 1500.ms,
                color: colorScheme.primary.withValues(alpha: 0.25),
              ),
        ),
      ),
    );
  }
}
