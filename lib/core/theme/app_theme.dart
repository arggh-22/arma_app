import 'package:flutter/material.dart';

/// Material 3 theme configuration with teal seed color.
///
/// Provides [light] and [dark] ThemeData with consistent card styling.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF00897B);

  /// Light theme with teal Material 3 color scheme.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  /// Dark theme with teal Material 3 color scheme.
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
