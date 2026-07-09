import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/theme/app_theme.dart';

/// Glassmorphic container — the design system's base surface.
///
/// Renders a translucent fill with a 1px glass-edge border and rounded
/// corners. Set [frosted] to add a `blur(12px)` backdrop filter (use
/// sparingly: hero panels, floating nav — not long lists). Set [glow]
/// to add the ambient indigo light-source shadow under active elements.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.fillAlpha = 0.05,
    this.borderColor,
    this.frosted = false,
    this.glow = false,
    this.glowColor,
  });

  final Widget? child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  /// Opacity of the white glass fill (dark mode only).
  final double fillAlpha;

  /// Override for the 1px edge border color.
  final Color? borderColor;

  /// Whether to apply a backdrop blur (expensive — avoid in lists).
  final bool frosted;

  /// Whether to render the ambient glow shadow.
  final bool glow;

  /// Glow color override (defaults to Electric Indigo).
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(ArmaTokens.radiusCard);
    final fill = isDark
        ? ArmaTokens.glassFill(fillAlpha)
        : Theme.of(context).colorScheme.surface;
    final border =
        borderColor ??
        (isDark
            ? ArmaTokens.glassBorder()
            : Theme.of(context).colorScheme.outlineVariant);

    Widget content = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );

    if (frosted) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    }

    if (glow) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: ArmaTokens.ambientGlow(color: glowColor, alpha: 0.25),
        ),
        child: content,
      );
    }

    return content;
  }
}
