// lib/business_logic/accessibility_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityManager {
  static const String _fontSizeKey = 'accessibility_font_size';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _reduceMotionKey = 'accessibility_reduce_motion';

  // Font size multipliers
  static const double smallFontSize = 0.85;
  static const double normalFontSize = 1.0;
  static const double largeFontSize = 1.15;
  static const double extraLargeFontSize = 1.3;

  // Get font size multiplier
  Future<double> getFontSizeMultiplier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? normalFontSize;
  }

  // Set font size multiplier
  Future<void> setFontSizeMultiplier(double multiplier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, multiplier);
  }

  // Get high contrast setting
  Future<bool> getHighContrast() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_highContrastKey) ?? false;
  }

  // Set high contrast
  Future<void> setHighContrast(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, enabled);
  }

  // Get reduce motion setting
  Future<bool> getReduceMotion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reduceMotionKey) ?? false;
  }

  // Set reduce motion
  Future<void> setReduceMotion(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, enabled);
  }
}

