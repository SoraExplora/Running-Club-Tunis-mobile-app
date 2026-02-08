import 'package:flutter/material.dart';
import 'accessible_colors.dart';

class AppTheme {
  static ThemeData light(TextTheme textTheme, AccessibleColors colors, double fontScale) {
    // Apply font scaling
    final scaledTextTheme = textTheme.apply(fontSizeFactor: fontScale);

    // Create a light version of the text theme with black text
    final lightTextTheme = scaledTextTheme.copyWith(
      bodyLarge: scaledTextTheme.bodyLarge?.copyWith(color: Colors.black),
      bodyMedium: scaledTextTheme.bodyMedium?.copyWith(color: Colors.black),
      bodySmall: scaledTextTheme.bodySmall?.copyWith(color: Colors.black),
      titleLarge: scaledTextTheme.titleLarge?.copyWith(color: Colors.black),
      titleMedium: scaledTextTheme.titleMedium?.copyWith(color: Colors.black),
      titleSmall: scaledTextTheme.titleSmall?.copyWith(color: Colors.black),
      displayLarge: scaledTextTheme.displayLarge?.copyWith(color: Colors.black),
      displayMedium: scaledTextTheme.displayMedium?.copyWith(color: Colors.black),
      displaySmall: scaledTextTheme.displaySmall?.copyWith(color: Colors.black),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.ivory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.terracotta,
        brightness: Brightness.light,
        primary: colors.terracotta,
        secondary: colors.stone,
        surface: Colors.white,
        onSurface: Colors.black, // This ensures text is black
        surfaceTint: colors.ivory, // Use surfaceTint instead of background
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
        labelStyle: TextStyle(color: Colors.black.withValues(alpha: 0.75)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.terracotta, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerColor: Colors.black.withValues(alpha: 0.08),
      textTheme: lightTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark(TextTheme textTheme, AccessibleColors colors, double fontScale) {
    // Apply font scaling
    final scaledTextTheme = textTheme.apply(fontSizeFactor: fontScale);

    // Create a dark version of the text theme with white text
    final darkTextTheme = scaledTextTheme.copyWith(
      bodyLarge: scaledTextTheme.bodyLarge?.copyWith(color: Colors.white),
      bodyMedium: scaledTextTheme.bodyMedium?.copyWith(color: Colors.white),
      bodySmall: scaledTextTheme.bodySmall?.copyWith(color: Colors.white),
      titleLarge: scaledTextTheme.titleLarge?.copyWith(color: Colors.white),
      titleMedium: scaledTextTheme.titleMedium?.copyWith(color: Colors.white),
      titleSmall: scaledTextTheme.titleSmall?.copyWith(color: Colors.white),
      displayLarge: scaledTextTheme.displayLarge?.copyWith(color: Colors.white),
      displayMedium: scaledTextTheme.displayMedium?.copyWith(color: Colors.white),
      displaySmall: scaledTextTheme.displaySmall?.copyWith(color: Colors.white),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.coffee,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.terracotta,
        brightness: Brightness.dark,
        primary: colors.terracotta,
        secondary: colors.stone,
        surface: colors.stone,
        onSurface: Colors.white, // This ensures text is white
        surfaceTint: colors.coffee, // Use surfaceTint instead of background
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.stone.withValues(alpha: 0.55),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.terracotta, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.stone.withValues(alpha: 0.65),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerColor: Colors.white.withValues(alpha: 0.10),
      textTheme: darkTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}