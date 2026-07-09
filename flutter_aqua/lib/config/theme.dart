import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData build() {
    final base = ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF0099DD));
    final cs = base.colorScheme;

    return base.copyWith(
      scaffoldBackgroundColor: cs.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
