import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/theme/app_theme.dart';

/// Navigation shell wrapping all tab screens.
///
/// Responsive by platform:
/// - **Mobile** (Android/iOS): the design system's frosted floating pill bottom
///   bar (unchanged).
/// - **Desktop** (Linux/Windows/macOS): a left [NavigationRail] in the same
///   Electric Indigo glass language, with the tab content centered in a
///   max-width column — the desktop idiom for a wide window.
///
/// Both use [StatefulNavigationShell] from go_router so each tab preserves its
/// navigation state when switching.
class NavigationShell extends StatelessWidget {
  const NavigationShell({super.key, required this.navigationShell});

  /// The stateful navigation shell provided by [StatefulShellRoute].
  final StatefulNavigationShell navigationShell;

  /// Desktop platforms get the rail layout; mobile keeps the floating pill.
  ///
  /// Uses [defaultTargetPlatform] (not `dart:io Platform`) so it honors
  /// [debugDefaultTargetPlatformOverride]: `flutter test` defaults to Android,
  /// so widget tests keep exercising the mobile layout unless they opt in.
  static bool get _isDesktop {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  List<_NavItem> _items(AppLocalizations l10n) => [
    _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: l10n.navHome),
    _NavItem(icon: Icons.dns_outlined, selectedIcon: Icons.dns, label: l10n.servers),
    _NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: l10n.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _isDesktop ? _buildDesktop(context, l10n) : _buildMobile(context, l10n);
  }

  // ── Mobile: floating pill bottom bar (unchanged) ──────────────────────────
  Widget _buildMobile(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: _FloatingNavBar(
          currentIndex: navigationShell.currentIndex,
          onSelect: _select,
          items: _items(l10n),
        ),
      ),
    );
  }

  // ── Desktop: left navigation rail + centered content ──────────────────────
  Widget _buildDesktop(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = _items(l10n);
    // Expand the rail (icons + labels) once the window is wide enough.
    final extended = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? ArmaTokens.navy900 : theme.colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? ArmaTokens.glassBorder()
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            child: NavigationRail(
              extended: extended,
              backgroundColor: Colors.transparent,
              groupAlignment: -0.85,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelType: extended ? null : NavigationRailLabelType.all,
              indicatorColor: ArmaTokens.indigo.withValues(alpha: 0.18),
              selectedIconTheme: const IconThemeData(color: ArmaTokens.indigo),
              selectedLabelTextStyle: const TextStyle(
                color: ArmaTokens.indigo,
                fontWeight: FontWeight.w600,
              ),
              leading: _RailHeader(extended: extended),
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                // Keep content readable instead of stretching across a wide
                // window; screens keep their own internal layout.
                constraints: const BoxConstraints(maxWidth: 1100),
                child: navigationShell,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Branded header at the top of the desktop rail: the shield mark, plus the
/// app name when the rail is expanded.
class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        bottom: 12,
        left: extended ? 20 : 0,
        right: extended ? 20 : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, color: theme.colorScheme.primary, size: 26),
          if (extended) ...[
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.appName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onSelect,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(ArmaTokens.radiusPill));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        // Lighter blur than before (was sigma 20): a backdrop blur over the
        // scrolling body (extendBody) re-samples every frame, so a smaller
        // kernel keeps the frosted look far cheaper. Pill opacity is bumped
        // to stay legible against the reduced blur.
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: isDark
                ? ArmaTokens.deepNavy.withValues(alpha: 0.82)
                : colorScheme.surface.withValues(alpha: 0.90),
            borderRadius: radius,
            border: Border.all(
              color: isDark
                  ? ArmaTokens.glassBorder()
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _FloatingNavDestination(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingNavDestination extends StatelessWidget {
  const _FloatingNavDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(ArmaTokens.radiusPill),
                boxShadow: selected
                    ? ArmaTokens.ambientGlow(alpha: 0.20, blur: 14, spread: 0)
                    : null,
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                letterSpacing: 0.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
