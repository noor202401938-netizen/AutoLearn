import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors from Stitch
  static const Color primary = Color(0xFF4231C0);
  static const Color primaryContainer = Color(0xFF5B4ED9);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  static const Color secondary = Color(0xFF6B38D4);
  static const Color secondaryContainer = Color(0xFF8455EF);
  
  static const Color tertiary = Color(0xFF00573A);
  static const Color tertiaryContainer = Color(0xFF00724E);
  static const Color onTertiaryContainer = Color(0xFF6DFABC); // Used for success/progress highlights (Emerald)
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  
  // Surfaces
  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF121C2A);
  
  static const Color surface = Color(0xFFFFFFFF); // surface-container-lowest
  static const Color onSurface = Color(0xFF121C2A);
  static const Color onSurfaceVariant = Color(0xFF474554);
  
  static const Color outline = Color(0xFF787586);
  static const Color outlineVariant = Color(0xFFC8C4D7);
  
  // Custom Gradients (Lift-and-Glow concept)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
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
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        error: error,
        background: background,
        surface: surface,
        onPrimary: onPrimary,
        onSecondary: onPrimary,
        onSurface: onSurface,
        onBackground: onBackground,
        onError: onError,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: _buildTextTheme(onSurface, onSurfaceVariant),
      appBarTheme: _buildAppBarTheme(background, onSurface),
      cardTheme: _buildCardTheme(surface, outlineVariant),
      elevatedButtonTheme: _buildElevatedButtonTheme(primary, onPrimary),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primary, outlineVariant),
      inputDecorationTheme: _buildInputDecorationTheme(surface, outlineVariant, primary, onSurfaceVariant),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(surface, primary, onSurfaceVariant),
    );
  }

  // Define a dark theme as well to prevent runtime errors, though the design system is light-dominant.
  // Using inverted colors for the dark mode equivalent.
  static ThemeData get darkTheme {
    const Color darkBg = Color(0xFF121C2A);
    const Color darkSurface = Color(0xFF1F2937); // Slate 800
    const Color darkOnSurface = Color(0xFFF8F9FF);
    const Color darkOnSurfaceVariant = Color(0xFFC8C4D7);
    const Color darkOutlineVariant = Color(0xFF474554);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryContainer,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryContainer,
        primaryContainer: primary,
        secondary: secondaryContainer,
        secondaryContainer: secondary,
        tertiary: onTertiaryContainer,
        tertiaryContainer: tertiary,
        error: error,
        background: darkBg,
        surface: darkSurface,
        onPrimary: onPrimary,
        onSecondary: onPrimary,
        onSurface: darkOnSurface,
        onBackground: darkOnSurface,
        onError: onError,
        outline: outlineVariant,
        outlineVariant: darkOutlineVariant,
      ),
      textTheme: _buildTextTheme(darkOnSurface, darkOnSurfaceVariant),
      appBarTheme: _buildAppBarTheme(darkBg, darkOnSurface),
      cardTheme: _buildCardTheme(darkSurface, darkOutlineVariant),
      elevatedButtonTheme: _buildElevatedButtonTheme(primaryContainer, onPrimary),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primaryContainer, darkOutlineVariant),
      inputDecorationTheme: _buildInputDecorationTheme(darkSurface, darkOutlineVariant, primaryContainer, darkOnSurfaceVariant),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(darkSurface, primaryContainer, darkOnSurfaceVariant),
    );
  }

  static TextTheme _buildTextTheme(Color onSurf, Color onSurfVar) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'Geist', fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -0.04 * 48, color: onSurf, height: 1.1),
      displayMedium: TextStyle(fontFamily: 'Geist', fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.03 * 36, color: onSurf, height: 1.1),
      headlineMedium: TextStyle(fontFamily: 'Geist', fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.02 * 32, color: onSurf, height: 1.2),
      headlineSmall: TextStyle(fontFamily: 'Geist', fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.01 * 24, color: onSurf, height: 1.2),
      bodyLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w400, color: onSurf, height: 1.6),
      bodyMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: onSurfVar, height: 1.5),
      bodySmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: onSurfVar, height: 1.5),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.02 * 14, color: onSurf, height: 1.0),
      labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05 * 12, color: onSurf, height: 1.0),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color bg, Color onSurf) {
    return AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: onSurf),
      titleTextStyle: TextStyle(
        fontFamily: 'Geist',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 20,
        color: onSurf,
      ),
    );
  }

  static CardTheme _buildCardTheme(Color surf, Color outlineVar) {
    return CardTheme(
      color: surf,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outlineVar, width: 1),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Color btnColor, Color onBtnColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: onBtnColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.02 * 14,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(Color btnColor, Color outlineVar) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: btnColor,
        side: BorderSide(color: outlineVar, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.02 * 14,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(Color surf, Color outlineVar, Color focusedColor, Color hintColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: surf,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: outlineVar, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: outlineVar, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: focusedColor, width: 2),
      ),
      hintStyle: GoogleFonts.inter(color: hintColor),
      labelStyle: GoogleFonts.inter(color: hintColor),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(Color surf, Color selected, Color unselected) {
    return BottomNavigationBarThemeData(
      backgroundColor: surf,
      selectedItemColor: selected,
      unselectedItemColor: unselected,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }
}
