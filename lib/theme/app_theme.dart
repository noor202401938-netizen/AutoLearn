import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF4231C0);
  static const Color primaryLight = Color(0xFF6C5CE7);
  static const Color primaryContainer = Color(0xFFE8E5FF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF00B894);
  static const Color secondaryDark = Color(0xFF009975);
  static const Color secondaryContainer = Color(0xFFD4F5EB);

  static const Color accent = Color(0xFF6C5CE7);

  static const Color error = Color(0xFFE74C3C);
  static const Color errorContainer = Color(0xFFFFEAEA);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF9B1C1C);

  static const Color background = Color(0xFFF7F8FC);
  static const Color onBackground = Color(0xFF1A1D2E);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F1F6);
  static const Color onSurface = Color(0xFF1A1D2E);
  static const Color onSurfaceVariant = Color(0xFF6E7191);

  static const Color outline = Color(0xFFD1D5E0);
  static const Color outlineVariant = Color(0xFFE8EAF0);

  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6E7191);
  static const Color textDisabled = Color(0xFFB0B3C5);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        tertiary: accent,
        error: error,
        errorContainer: errorContainer,
        surface: background,
        onPrimary: onPrimary,
        onSecondary: onPrimary,
        onSurface: onSurface,
        onError: onError,
        outline: outline,
        outlineVariant: outlineVariant,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
      ),
      textTheme: _buildTextTheme(onSurface, onSurfaceVariant),
      appBarTheme: _buildAppBarTheme(surface, onSurface),
      cardTheme: _buildCardTheme(surface, outlineVariant),
      elevatedButtonTheme: _buildElevatedButtonTheme(primary, onPrimary),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primary, outline),
      inputDecorationTheme: _buildInputDecorationTheme(
          surface, outline, primary, onSurfaceVariant),
      bottomNavigationBarTheme:
          _buildBottomNavigationBarTheme(surface, primary, onSurfaceVariant),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryContainer,
        labelStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    const Color darkBg = Color(0xFF0F1020);
    const Color darkSurface = Color(0xFF1A1D2E);
    const Color darkSurfaceVariant = Color(0xFF252840);
    const Color darkOnSurface = Color(0xFFF0F1F6);
    const Color darkOnSurfaceVariant = Color(0xFF9B9EBF);
    const Color darkOutline = Color(0xFF363A54);
    const Color darkOutlineVariant = Color(0xFF252840);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        primaryContainer: Color(0xFF2D2370),
        secondary: secondary,
        secondaryContainer: Color(0xFF003D2E),
        tertiary: accent,
        error: Color(0xFFFF6B6B),
        errorContainer: Color(0xFF4A1515),
        surface: darkBg,
        surfaceContainerHighest: darkSurfaceVariant,
        onPrimary: onPrimary,
        onSecondary: onPrimary,
        onSurface: darkOnSurface,
        onError: onPrimary,
        outline: darkOutline,
        outlineVariant: darkOutlineVariant,
        onSurfaceVariant: darkOnSurfaceVariant,
      ),
      textTheme: _buildTextTheme(darkOnSurface, darkOnSurfaceVariant),
      appBarTheme: _buildAppBarTheme(darkBg, darkOnSurface),
      cardTheme: _buildCardTheme(darkSurface, darkOutline),
      elevatedButtonTheme: _buildElevatedButtonTheme(primaryLight, onPrimary),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primaryLight, darkOutline),
      inputDecorationTheme: _buildInputDecorationTheme(
          darkSurface, darkOutline, primaryLight, darkOnSurfaceVariant),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(
          darkSurface, primaryLight, darkOnSurfaceVariant),
      dividerTheme: const DividerThemeData(
        color: darkOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVariant,
        selectedColor: const Color(0xFF2D2370),
        labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkOnSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: darkOutline),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color onSurf, Color onSurfVar) {
    return TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Geist',
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.6,
          color: onSurf,
          height: 1.1),
      displayMedium: TextStyle(
          fontFamily: 'Geist',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.28,
          color: onSurf,
          height: 1.15),
      headlineLarge: TextStyle(
          fontFamily: 'Geist',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.84,
          color: onSurf,
          height: 1.2),
      headlineMedium: TextStyle(
          fontFamily: 'Geist',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.72,
          color: onSurf,
          height: 1.25),
      headlineSmall: TextStyle(
          fontFamily: 'Geist',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: onSurf,
          height: 1.3),
      titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.18,
          color: onSurf,
          height: 1.35),
      titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.16,
          color: onSurf,
          height: 1.4),
      titleSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.14,
          color: onSurf,
          height: 1.4),
      bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.16,
          color: onSurf,
          height: 1.6),
      bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.14,
          color: onSurfVar,
          height: 1.6),
      bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.12,
          color: onSurfVar,
          height: 1.5),
      labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.28,
          color: onSurf,
          height: 1.0),
      labelMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.24,
          color: onSurfVar,
          height: 1.0),
      labelSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.55,
          color: onSurfVar,
          height: 1.0),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color bg, Color onSurf) {
    return AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: onSurf),
      titleTextStyle: TextStyle(
        fontFamily: 'Geist',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: onSurf,
      ),
    );
  }

  static CardThemeData _buildCardTheme(Color surf, Color outlineVar) {
    return CardThemeData(
      color: surf,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outlineVar, width: 1),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
      Color btnColor, Color onBtnColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: onBtnColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
      Color btnColor, Color outlineColor) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: btnColor,
        side: BorderSide(color: outlineColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
      Color surf, Color outlineColor, Color focusedColor, Color hintColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: surf,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outlineColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outlineColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusedColor, width: 2),
      ),
      hintStyle: TextStyle(fontFamily: 'Inter', color: hintColor),
      labelStyle: TextStyle(fontFamily: 'Inter', color: hintColor),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(
      Color surf, Color selected, Color unselected) {
    return BottomNavigationBarThemeData(
      backgroundColor: surf,
      selectedItemColor: selected,
      unselectedItemColor: unselected,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}
