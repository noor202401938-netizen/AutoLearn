// lib/utils/preference_notifier.dart
import 'package:flutter/material.dart';

class PreferenceNotifier extends ChangeNotifier {
  static final PreferenceNotifier instance = PreferenceNotifier._();
  PreferenceNotifier._();

  ThemeMode _themeMode = ThemeMode.system;
  String _fontSize = 'normal';
  bool _highContrast = false;
  bool _reduceMotion = false;

  ThemeMode get themeMode => _themeMode;
  String get fontSize => _fontSize;
  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;

  double get fontSizeMultiplier {
    switch (_fontSize) {
      case 'small':
        return 0.85;
      case 'large':
        return 1.15;
      case 'extraLarge':
        return 1.3;
      default:
        return 1.0;
    }
  }

  void updateTheme(String theme) {
    _themeMode = theme == 'light'
        ? ThemeMode.light
        : theme == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    notifyListeners();
  }

  void updateFontSize(String fontSize) {
    _fontSize = fontSize;
    notifyListeners();
  }

  void updateHighContrast(bool enabled) {
    _highContrast = enabled;
    notifyListeners();
  }

  void updateReduceMotion(bool enabled) {
    _reduceMotion = enabled;
    notifyListeners();
  }

  void loadPreferences({
    String? theme,
    String? fontSize,
    bool? highContrast,
    bool? reduceMotion,
  }) {
    bool changed = false;

    if (theme != null) {
      final newThemeMode = theme == 'light'
          ? ThemeMode.light
          : theme == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
      if (_themeMode != newThemeMode) {
        _themeMode = newThemeMode;
        changed = true;
      }
    }

    if (fontSize != null && _fontSize != fontSize) {
      _fontSize = fontSize;
      changed = true;
    }

    if (highContrast != null && _highContrast != highContrast) {
      _highContrast = highContrast;
      changed = true;
    }

    if (reduceMotion != null && _reduceMotion != reduceMotion) {
      _reduceMotion = reduceMotion;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }
}

