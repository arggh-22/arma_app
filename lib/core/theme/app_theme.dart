import 'package:flutter/material.dart';

/// Arma design tokens — "cyber-noir" glassmorphism palette.
///
/// Anchored by Electric Indigo over Obsidian/Deep Navy voids, with Cyber
/// Cyan for data readouts and a soft violet glow for active elements
/// (see stitch_incy_green_vpn_design/arma/DESIGN.md).
class ArmaTokens {
  ArmaTokens._();

  /// Root application canvas.
  static const obsidian = Color(0xFF020617);

  /// Card / container base.
  static const deepNavy = Color(0xFF0F172A);

  /// Elevated container tints (slate scale).
  static const navy900 = Color(0xFF0B1120);
  static const navy800 = Color(0xFF16203A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate400 = Color(0xFF94A3B8);
  static const slate200 = Color(0xFFE2E8F0);

  /// Primary accent — high-priority actions and active states.
  static const indigo = Color(0xFF8B5CF6);

  /// Primary gradient end / pressed state.
  static const indigoDeep = Color(0xFF7C3AED);

  /// Soft light-source glow behind active elements.
  static const glow = Color(0xFFC084FC);

  /// Secondary accent — data visualizations and live telemetry.
  static const cyan = Color(0xFF06B6D4);

  /// Positive status (low latency, connected).
  static const success = Color(0xFF4ADE80);

  /// Warning status (medium load, expiring).
  static const warning = Color(0xFFFBBF24);

  /// Error status (offline, expired).
  static const danger = Color(0xFFF87171);

  /// 1px glass-edge border color (light hitting a glass edge).
  static Color glassBorder([double alpha = 0.10]) =>
      Colors.white.withValues(alpha: alpha);

  /// Translucent glass surface fill.
  static Color glassFill([double alpha = 0.05]) =>
      Colors.white.withValues(alpha: alpha);

  /// Ambient indigo glow shadow under "charged" elements.
  static List<BoxShadow> ambientGlow({
    Color? color,
    double alpha = 0.35,
    double blur = 24,
    double spread = 2,
  }) => [
    BoxShadow(
      color: (color ?? indigo).withValues(alpha: alpha),
      blurRadius: blur,
      spreadRadius: spread,
    ),
  ];

  /// Pill radius for floating elements (nav bar, search field).
  static const radiusPill = 999.0;

  /// Card radius.
  static const radiusCard = 16.0;

  /// Primary action radius.
  static const radiusAction = 24.0;
}

/// Material 3 theme configuration for the Arma glassmorphism design.
///
/// Provides [light] and [dark] ThemeData. Dark is the flagship
/// "Obsidian / Electric Indigo" look; light is a softened counterpart
/// generated from the same accent.
class AppTheme {
  AppTheme._();

  /// Flagship dark theme — Obsidian canvas, glass cards, indigo accents.
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: ArmaTokens.indigo,
      onPrimary: Colors.white,
      primaryContainer: ArmaTokens.indigoDeep,
      onPrimaryContainer: Color(0xFFEDE9FE),
      secondary: ArmaTokens.cyan,
      onSecondary: Color(0xFF002830),
      secondaryContainer: Color(0xFF164E63),
      onSecondaryContainer: Color(0xFFCFFAFE),
      tertiary: ArmaTokens.glow,
      onTertiary: Color(0xFF2E1065),
      surface: ArmaTokens.obsidian,
      onSurface: ArmaTokens.slate200,
      surfaceContainerLowest: ArmaTokens.obsidian,
      surfaceContainerLow: ArmaTokens.navy900,
      surfaceContainer: ArmaTokens.deepNavy,
      surfaceContainerHigh: ArmaTokens.navy800,
      surfaceContainerHighest: ArmaTokens.slate800,
      onSurfaceVariant: ArmaTokens.slate400,
      outline: ArmaTokens.slate700,
      outlineVariant: ArmaTokens.slate800,
      error: ArmaTokens.danger,
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFECACA),
      inverseSurface: ArmaTokens.slate200,
      onInverseSurface: ArmaTokens.deepNavy,
      inversePrimary: ArmaTokens.indigoDeep,
      surfaceTint: Colors.transparent,
    );
    return _base(colorScheme).copyWith(
      scaffoldBackgroundColor: ArmaTokens.obsidian,
      cardTheme: CardThemeData(
        elevation: 0,
        color: ArmaTokens.glassFill(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArmaTokens.radiusCard),
          side: BorderSide(color: ArmaTokens.glassBorder()),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  /// Light theme — same indigo accent over soft slate surfaces.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ArmaTokens.indigo,
      brightness: Brightness.light,
      primary: ArmaTokens.indigoDeep,
      secondary: Color.lerp(ArmaTokens.cyan, Colors.black, 0.15),
    );
    return _base(colorScheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4F2FB),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArmaTokens.radiusCard),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  /// Shared component styling for both brightness modes.
  static ThemeData _base(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final sheetColor = isDark ? ArmaTokens.deepNavy : colorScheme.surface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      splashFactory: InkSparkle.splashFactory,
      textTheme: Typography.material2021(colorScheme: colorScheme)
          .englishLike
          .copyWith(
            // Tight-tracked, bold headlines for the "armored" brand feel.
            headlineLarge: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            headlineMedium: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
            ),
            // Uppercase-friendly metadata labels.
            labelSmall: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          )
          .apply(
            bodyColor: colorScheme.onSurface,
            displayColor: colorScheme.onSurface,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? ArmaTokens.glassFill(0.06)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArmaTokens.radiusCard),
          borderSide: BorderSide(
            color: isDark ? ArmaTokens.glassBorder() : colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArmaTokens.radiusCard),
          borderSide: BorderSide(
            color: isDark
                ? ArmaTokens.glassBorder()
                : colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArmaTokens.radiusCard),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? ArmaTokens.glassFill(0.06)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        selectedColor: colorScheme.primary.withValues(alpha: 0.22),
        checkmarkColor: colorScheme.primary,
        side: BorderSide(
          color: isDark ? ArmaTokens.glassBorder() : colorScheme.outlineVariant,
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: const StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : colorScheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : (isDark
                    ? ArmaTokens.glassFill(0.08)
                    : colorScheme.surfaceContainerHighest),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : colorScheme.outline,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ArmaTokens.radiusAction),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArmaTokens.radiusAction),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(
            BorderSide(
              color: isDark ? ArmaTokens.glassBorder() : colorScheme.outline,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colorScheme.primary.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? (isDark ? Colors.white : colorScheme.primary)
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sheetColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArmaTokens.radiusAction),
          side: isDark
              ? BorderSide(color: ArmaTokens.glassBorder())
              : BorderSide.none,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheetColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: sheetColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ArmaTokens.radiusAction),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? ArmaTokens.navy800 : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? BorderSide(color: ArmaTokens.glassBorder())
              : BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? ArmaTokens.navy800 : null,
        contentTextStyle: isDark
            ? const TextStyle(color: ArmaTokens.slate200)
            : null,
        actionTextColor: isDark ? ArmaTokens.glow : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? BorderSide(color: ArmaTokens.glassBorder())
              : BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? ArmaTokens.glassBorder(0.06) : null,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: isDark ? ArmaTokens.glassFill(0.08) : null,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
