import 'package:flutter/material.dart';

class GameTheme {
  static const Color midnight = Color(0xFF07111F);
  static const Color ocean = Color(0xFF0B2745);
  static const Color cyan = Color(0xFF4DEBFF);
  static const Color gold = Color(0xFFFFD35A);
  static const Color mint = Color(0xFF61F2B2);
  static const Color danger = Color(0xFFFF6680);
  static const Color violet = Color(0xFF9A7BFF);

  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      primary: cyan,
      secondary: gold,
      surface: const Color(0xFF102238),
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: midnight,
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.2),
        headlineMedium: TextStyle(fontWeight: FontWeight.w900),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(height: 1.35),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF17324F).withValues(alpha: .98),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
