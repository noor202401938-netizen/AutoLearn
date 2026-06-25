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
  ThemeData get theme => Theme.of(context);

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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Preferences saved', style: theme.textTheme.bodyMedium)),
              ],
            ),
            backgroundColor: const Color(0xFF00724e),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e', style: theme.textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Theme & Accessibility', style: theme.textTheme.titleMedium),
        backgroundColor: colorScheme.surface.withOpacity(0.8),
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Container(
        color: colorScheme.surface,
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Theme Section
                  _buildSectionTitle('Theme', colorScheme),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildThemeRadioTile('System Default', 'system', colorScheme),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildThemeRadioTile('Light', 'light', colorScheme),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildThemeRadioTile('Dark', 'dark', colorScheme),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Font Size Section
                  _buildSectionTitle('Font Size', colorScheme),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Current Size', style: theme.textTheme.bodyMedium),
                              Text('${(_fontSizeMultiplier * 100).round()}%', style: theme.textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Slider(
                            value: _fontSizeMultiplier,
                            min: AccessibilityManager.smallFontSize,
                            max: AccessibilityManager.extraLargeFontSize,
                            divisions: 3,
                            activeColor: colorScheme.primary,
                            inactiveColor: colorScheme.primary.withOpacity(0.2),
                            onChanged: (value) {
                              setState(() => _fontSizeMultiplier = value);
                              _savePreferences(showSnackBar: false);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Accessibility Options
                  _buildSectionTitle('Accessibility', colorScheme),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          title: Text('High Contrast', style: theme.textTheme.bodyMedium),
                          subtitle: Text('Increase contrast for better visibility', style: theme.textTheme.bodyMedium),
                          value: _highContrast,
                          activeColor: colorScheme.primary,
                          onChanged: (value) {
                            setState(() => _highContrast = value);
                            _savePreferences(showSnackBar: false);
                          },
                        ),
                        const Divider(height: 1, indent: 24, endIndent: 24),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          title: Text('Reduce Motion', style: theme.textTheme.bodyMedium),
                          subtitle: Text('Minimize animations and transitions', style: theme.textTheme.bodyMedium),
                          value: _reduceMotion,
                          activeColor: colorScheme.primary,
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

  Widget _buildThemeRadioTile(String title, String value, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Theme(
      data: Theme.of(context).copyWith(unselectedWidgetColor: colorScheme.onSurfaceVariant),
      child: RadioListTile<String>(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title, style: theme.textTheme.bodyMedium),
        value: value,
        groupValue: _selectedTheme,
        activeColor: colorScheme.primary,
        onChanged: (val) {
          setState(() => _selectedTheme = val!);
          _savePreferences(showSnackBar: false);
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium,
      ),
    );
  }
}
