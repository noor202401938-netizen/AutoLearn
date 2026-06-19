// lib/screens/theme_accessibility_screen.dart
import 'package:flutter/material.dart';
import '../business_logic/accessibility_manager.dart';
import '../repository/user_preferences_repository.dart';
import '../utils/preference_notifier.dart';

class ThemeAccessibilityScreen extends StatefulWidget {
  const ThemeAccessibilityScreen({super.key});

  @override
  State<ThemeAccessibilityScreen> createState() =>
      _ThemeAccessibilityScreenState();
}

class _ThemeAccessibilityScreenState extends State<ThemeAccessibilityScreen> {
  final AccessibilityManager _accessibilityManager = AccessibilityManager();
  final UserPreferencesRepository _preferencesRepository =
      UserPreferencesRepository();
  final PreferenceNotifier _preferenceNotifier = PreferenceNotifier.instance;

  String _selectedTheme = 'system';
  double _fontSizeMultiplier = 1.0;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user != null) {
        final prefs = await _preferencesRepository.getUserPreferences(user.uid);
        setState(() {
          _selectedTheme = prefs['theme'] ?? 'system';
          _fontSizeMultiplier =
              _parseFontSize(prefs['fontSize'] ?? 'normal');
          _highContrast = prefs['highContrast'] ?? false;
          _reduceMotion = prefs['reduceMotion'] ?? false;
        });
      } else {
        _fontSizeMultiplier = await _accessibilityManager.getFontSizeMultiplier();
        _highContrast = await _accessibilityManager.getHighContrast();
        _reduceMotion = await _accessibilityManager.getReduceMotion();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _parseFontSize(String size) {
    switch (size) {
      case 'small':
        return AccessibilityManager.smallFontSize;
      case 'large':
        return AccessibilityManager.largeFontSize;
      case 'extraLarge':
        return AccessibilityManager.extraLargeFontSize;
      default:
        return AccessibilityManager.normalFontSize;
    }
  }

  String _fontSizeToString(double multiplier) {
    if (multiplier <= AccessibilityManager.smallFontSize) return 'small';
    if (multiplier >= AccessibilityManager.extraLargeFontSize) {
      return 'extraLarge';
    }
    if (multiplier >= AccessibilityManager.largeFontSize) return 'large';
    return 'normal';
  }

  Future<void> _savePreferences({bool showSnackBar = true}) async {
    try {
      // Apply changes immediately to PreferenceNotifier
      _preferenceNotifier.updateTheme(_selectedTheme);
      _preferenceNotifier.updateFontSize(_fontSizeToString(_fontSizeMultiplier));
      _preferenceNotifier.updateHighContrast(_highContrast);
      _preferenceNotifier.updateReduceMotion(_reduceMotion);

      // Save to persistent storage
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user != null) {
        await _preferencesRepository.saveUserPreferences(
          userId: user.uid,
          theme: _selectedTheme,
          fontSize: _fontSizeToString(_fontSizeMultiplier),
          highContrast: _highContrast,
          reduceMotion: _reduceMotion,
        );
      } else {
        await _accessibilityManager.setFontSizeMultiplier(_fontSizeMultiplier);
        await _accessibilityManager.setHighContrast(_highContrast);
        await _accessibilityManager.setReduceMotion(_reduceMotion);
      }

      if (mounted && showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme & Accessibility'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Section
                  _buildSectionTitle('Theme'),
                  Card(
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('System Default'),
                          value: 'system',
                          groupValue: _selectedTheme,
                          onChanged: (value) {
                            setState(() => _selectedTheme = value!);
                            _savePreferences(showSnackBar: false);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Light'),
                          value: 'light',
                          groupValue: _selectedTheme,
                          onChanged: (value) {
                            setState(() => _selectedTheme = value!);
                            _savePreferences(showSnackBar: false);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Dark'),
                          value: 'dark',
                          groupValue: _selectedTheme,
                          onChanged: (value) {
                            setState(() => _selectedTheme = value!);
                            _savePreferences(showSnackBar: false);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Font Size Section
                  _buildSectionTitle('Font Size'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current: ${(_fontSizeMultiplier * 100).round()}%'),
                          Slider(
                            value: _fontSizeMultiplier,
                            min: AccessibilityManager.smallFontSize,
                            max: AccessibilityManager.extraLargeFontSize,
                            divisions: 3,
                            label: '${(_fontSizeMultiplier * 100).round()}%',
                            onChanged: (value) {
                              setState(() => _fontSizeMultiplier = value);
                              _savePreferences(showSnackBar: false);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Accessibility Options
                  _buildSectionTitle('Accessibility'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('High Contrast'),
                          subtitle: const Text('Increase contrast for better visibility'),
                          value: _highContrast,
                          onChanged: (value) {
                            setState(() => _highContrast = value);
                            _savePreferences(showSnackBar: false);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Reduce Motion'),
                          subtitle: const Text('Minimize animations and transitions'),
                          value: _reduceMotion,
                          onChanged: (value) {
                            setState(() => _reduceMotion = value);
                            _savePreferences(showSnackBar: false);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

