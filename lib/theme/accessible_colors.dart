import 'package:flutter/material.dart';

enum ColorBlindnessMode {
  normal,
  protanopia,
  deuteranopia,
  tritanopia,
  achromatopsia,
}

class AccessibleColors {
  final Color terracotta;
  final Color ivory;
  final Color silver;
  final Color coffee;
  final Color stone;

  const AccessibleColors({
    required this.terracotta,
    required this.ivory,
    required this.silver,
    required this.coffee,
    required this.stone,
  });

  static const AccessibleColors normal = AccessibleColors(
    terracotta: Color(0xFFE44D2E),
    ivory: Color(0xFFF7F3E3),
    silver: Color(0xFFB3B6B7),
    coffee: Color(0xFF0F0F10),
    stone: Color(0xFF5E574D),
  );

  static const AccessibleColors protanopia = AccessibleColors(
    terracotta: Color(0xFF2D7DD2),
    ivory: Color(0xFFF7F3E3),
    silver: Color(0xFFB3B6B7),
    coffee: Color(0xFF0F0F10),
    stone: Color(0xFF57574D),
  );

  static const AccessibleColors deuteranopia = AccessibleColors(
    terracotta: Color(0xFF2D7DD2), // blue accent (green-safe)
    ivory: Color(0xFFF7F3E3),
    silver: Color(0xFFB3B6B7),
    coffee: Color(0xFF0F0F10),
    stone: Color(0xFF5A5A50),
  );

  static const AccessibleColors tritanopia = AccessibleColors(
    // Warm accent (orange-brown instead of blue)
    terracotta: Color(0xFFC97A3D),
    ivory: Color(0xFFF7F3E3),
    silver: Color(0xFFB3B6B7),
    coffee: Color(0xFF0F0F10),
    stone: Color(0xFF5E574D),
  );

  static const AccessibleColors achromatopsia = AccessibleColors(
    // Accent becomes high-contrast gray
    terracotta: Color(0xFF4A4A4A),
    ivory: Color(0xFFF5F5F5),
    silver: Color(0xFFB0B0B0),
    coffee: Color(0xFF1A1A1A),
    stone: Color(0xFF6E6E6E),
  );

  static AccessibleColors get(ColorBlindnessMode mode) {
    switch (mode) {
      case ColorBlindnessMode.normal:
        return normal;
      case ColorBlindnessMode.protanopia:
        return protanopia;
      case ColorBlindnessMode.deuteranopia:
        return deuteranopia;
      case ColorBlindnessMode.tritanopia:
        return tritanopia;
      case ColorBlindnessMode.achromatopsia:
        return achromatopsia;
    }
  }

  // Helper to get formatted name
  static String getName(ColorBlindnessMode mode) {
    switch (mode) {
      case ColorBlindnessMode.normal:
        return "Normal Vision";
      case ColorBlindnessMode.protanopia:
        return "Protanopia (Red-blind)";
      case ColorBlindnessMode.deuteranopia:
        return "Deuteranopia (Green-blind)";
      case ColorBlindnessMode.tritanopia:
        return "Tritanopia (Blue-blind)";
      case ColorBlindnessMode.achromatopsia:
        return "Achromatopsia (Monochromacy)";
    }
  }
}
