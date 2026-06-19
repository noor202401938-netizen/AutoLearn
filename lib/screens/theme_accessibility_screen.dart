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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Theme & Accessibility', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Theme Section
                  _buildSectionTitle('Theme'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Theme(
                          data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white.withOpacity(0.5)),
                          child: RadioListTile<String>(
                            title: const Text('System Default', style: TextStyle(color: Colors.white)),
                            value: 'system',
                            groupValue: _selectedTheme,
                            activeColor: Theme.of(context).colorScheme.secondary,
                            onChanged: (value) {
                              setState(() => _selectedTheme = value!);
                              _savePreferences(showSnackBar: false);
                            },
                          ),
                        ),
                        Theme(
                          data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white.withOpacity(0.5)),
                          child: RadioListTile<String>(
                            title: const Text('Light', style: TextStyle(color: Colors.white)),
                            value: 'light',
                            groupValue: _selectedTheme,
                            activeColor: Theme.of(context).colorScheme.secondary,
                            onChanged: (value) {
                              setState(() => _selectedTheme = value!);
                              _savePreferences(showSnackBar: false);
                            },
                          ),
                        ),
                        Theme(
                          data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white.withOpacity(0.5)),
                          child: RadioListTile<String>(
                            title: const Text('Dark', style: TextStyle(color: Colors.white)),
                            value: 'dark',
                            groupValue: _selectedTheme,
                            activeColor: Theme.of(context).colorScheme.secondary,
                            onChanged: (value) {
                              setState(() => _selectedTheme = value!);
                              _savePreferences(showSnackBar: false);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Font Size Section
                  _buildSectionTitle('Font Size'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current: ${(_fontSizeMultiplier * 100).round()}%', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                          Slider(
                            value: _fontSizeMultiplier,
                            min: AccessibilityManager.smallFontSize,
                            max: AccessibilityManager.extraLargeFontSize,
                            divisions: 3,
                            activeColor: Theme.of(context).colorScheme.secondary,
                            inactiveColor: Colors.white.withOpacity(0.2),
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('High Contrast', style: TextStyle(color: Colors.white)),
                          subtitle: Text('Increase contrast for better visibility', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                          value: _highContrast,
                          activeColor: Theme.of(context).colorScheme.secondary,
                          onChanged: (value) {
                            setState(() => _highContrast = value);
                            _savePreferences(showSnackBar: false);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Reduce Motion', style: TextStyle(color: Colors.white)),
                          subtitle: Text('Minimize animations and transitions', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                          value: _reduceMotion,
                          activeColor: Theme.of(context).colorScheme.secondary,
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
          color: Colors.white,
        ),
      ),
    );
  }
}

