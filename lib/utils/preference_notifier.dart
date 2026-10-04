// lib/utils/preference_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Display preferences (paper/blackboard, text size, reduced motion).
/// Changes apply immediately and are saved on this device.
class PreferenceNotifier extends ChangeNotifier {
  static final PreferenceNotifier instance = PreferenceNotifier._();
  PreferenceNotifier._();

  static const _themeKey = 'pref_theme';
  static const _fontKey = 'pref_font_size';
  static const _motionKey = 'pref_reduce_motion';

  static const fontSizes = {'small': 0.9, 'normal': 1.0, 'large': 1.15, 'extraLarge': 1.3};

  ThemeMode _themeMode = ThemeMode.system;
  String _fontSize = 'normal';
  bool _reduceMotion = false;

  ThemeMode get themeMode => _themeMode;
  String get fontSize => _fontSize;
  bool get reduceMotion => _reduceMotion;
  double get fontSizeMultiplier => fontSizes[_fontSize] ?? 1.0;

  static ThemeMode _mode(String? theme) =>
      theme == 'light' ? ThemeMode.light : theme == 'dark' ? ThemeMode.dark : ThemeMode.system;

  /// Reads saved preferences; call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    loadPreferences(
      theme: prefs.getString(_themeKey),
      fontSize: prefs.getString(_fontKey),
      reduceMotion: prefs.getBool(_motionKey),
    );
  }

  void loadPreferences({String? theme, String? fontSize, bool? reduceMotion}) {
    _themeMode = _mode(theme);
    _fontSize = fontSizes.containsKey(fontSize) ? fontSize! : 'normal';
    _reduceMotion = reduceMotion ?? false;
    notifyListeners();
  }

  void updateTheme(String theme) {
    _themeMode = _mode(theme);
    notifyListeners();
    _save((p) => p.setString(_themeKey, theme));
  }

  void updateFontSize(String size) {
    if (!fontSizes.containsKey(size)) return;
    _fontSize = size;
    notifyListeners();
    _save((p) => p.setString(_fontKey, size));
  }

  void updateReduceMotion(bool enabled) {
    _reduceMotion = enabled;
    notifyListeners();
    _save((p) => p.setBool(_motionKey, enabled));
  }

  Future<void> _save(Future<bool> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } on Exception {
      // Still applied for this session.
    }
  }
}
