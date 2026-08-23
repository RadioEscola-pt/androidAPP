import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Brand & seed
// ---------------------------------------------------------------------------
const brandColor = Color(0xFFFF9A17);
const _seedColor = Color(0xFFFF9A17);

// ---------------------------------------------------------------------------
// Category accent colors
// ---------------------------------------------------------------------------
const categoryCat1Color = Color(0xFF2E7D32);
const categoryCat2Color = Color(0xFF1565C0);
const categoryCat3Color = Color(0xFF7B1FA2);

Color categoryAccentColor(int index) {
  return switch (index) {
    0 => categoryCat1Color,
    1 => categoryCat2Color,
    2 => categoryCat3Color,
    _ => categoryCat2Color,
  };
}

// ---------------------------------------------------------------------------
// Semantic colors
// ---------------------------------------------------------------------------
const successColor = Color(0xFF2E7D32);
const errorColor = Color(0xFFC62828);
const warningColor = Color(0xFFE65100);

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

/// Border radii – only two sizes used across the app.
const radiusS = 12.0;
const radiusM = 16.0;

/// Standard content padding (horizontal) for screens.
const screenPaddingH = 20.0;

/// Shared button shape used across theme.
final _buttonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(radiusS),
);

// ---------------------------------------------------------------------------
// Themes
// ---------------------------------------------------------------------------

ThemeData _buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ),
    useMaterial3: true,
    brightness: brightness == Brightness.dark ? Brightness.dark : null,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: _buttonShape,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: _buttonShape,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
  );
}

final lightTheme = _buildTheme(Brightness.light);
final darkTheme = _buildTheme(Brightness.dark);
