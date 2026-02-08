import 'package:flutter/material.dart';
import '../theme/accessible_colors.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class ThemeService with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ColorBlindnessMode _colorMode = ColorBlindnessMode.normal;
  double _fontScale = 1.0;
  String? _userId;

  ThemeMode get themeMode => _themeMode;
  ColorBlindnessMode get colorMode => _colorMode;
  double get fontScale => _fontScale;
  String? get userId => _userId;

  AccessibleColors get currentColors => AccessibleColors.get(_colorMode);

  void setUserId(String? id) {
    _userId = id;
  }

  void loadFromUser(UserModel user) {
    if (user.colorMode != null) {
      _colorMode = ColorBlindnessMode.values.firstWhere(
        (e) => e.toString().split('.').last == user.colorMode,
        orElse: () => ColorBlindnessMode.normal,
      );
    }
    if (user.fontScale != null) {
      _fontScale = user.fontScale!.clamp(0.8, 1.4);
    }
    _userId = user.id;
    // Don't notify or save here to avoid loops, just update state
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setColorMode(ColorBlindnessMode mode) {
    _colorMode = mode;
    notifyListeners();
    _savePreferences();
  }

  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.8, 1.4);
    notifyListeners();
    _savePreferences();
  }

  void reset() {
    _themeMode = ThemeMode.system;
    _colorMode = ColorBlindnessMode.normal;
    _fontScale = 1.0;
    _userId = null;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    if (_userId == null || _userId == 'visitor') return;

    try {
      await FirebaseFirestore.instance.collection('user').doc(_userId).update({
        'colorMode': _colorMode.toString().split('.').last,
        'fontScale': _fontScale,
      });
    } catch (e) {
      debugPrint("Error saving theme preferences: $e");
    }
  }
}
