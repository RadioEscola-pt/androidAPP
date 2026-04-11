import 'package:flutter/material.dart';

const _seedColor = Color(0xFF1565C0);

final _filledButtonTheme = FilledButtonThemeData(
  style: FilledButton.styleFrom(
    minimumSize: const Size(double.infinity, 48),
  ),
);

final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
  useMaterial3: true,
  filledButtonTheme: _filledButtonTheme,
);

final darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  brightness: Brightness.dark,
  filledButtonTheme: _filledButtonTheme,
);
