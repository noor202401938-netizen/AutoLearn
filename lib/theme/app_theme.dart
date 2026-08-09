import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Mockup Color Palette
  static const Color primary = Color(0xFF2A4E36);          // Forest Green
  static const Color primaryLight = Color(0xFF3B6449);     // Soft Forest Green
  static const Color primaryContainer = Color(0xFFE9EDE9); // Light Mint/Sage Green
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF8A9A86);        // Sage/Olive
  static const Color secondaryDark = Color(0xFF6B7B67);
  static const Color secondaryContainer = Color(0xFFF1F4F0);

  static const Color accent = Color(0xFFD4AF37);           // Soft Gold/Amber Accent

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color background = Color(0xFFFAF9F5);       // Warm Cream Background
  static const Color onBackground = Color(0xFF1E221F);     // Deep Charcoal Text

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F1EC);   // Slightly deeper warm cream
  static const Color onSurface = Color(0xFF1E221F);
  static const Color onSurfaceVariant = Color(0xFF5C635E); // Soft slate gray

  static const Color outline = Color(0xFFD1D7D2);          // Sage outline
  static const Color outlineVariant = Color(0xFFE1E5E2);

  static const Color textPrimary = Color(0xFF1E221F);
  static const Color textSecondary = Color(0xFF5C635E);
  static const Color textDisabled = Color(0xFF9EA39F);

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
      appBarTheme: _buildAppBarTheme(background, onSurface),
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
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
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
    // Elegant Dark Green-Slate Theme matching the dark mode style
    const Color darkBg = Color(0xFF141A16);
    const Color darkSurface = Color(0xFF1C241F);
    const Color darkSurfaceVariant = Color(0xFF243028);
    const Color darkOnSurface = Color(0xFFFAF9F5);
    const Color darkOnSurfaceVariant = Color(0xFFA1A8A2);
    const Color darkOutline = Color(0xFF334237);
    const Color darkOutlineVariant = Color(0xFF243028);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        primaryContainer: Color(0xFF1C3524),
        secondary: secondary,
        secondaryContainer: Color(0xFF243528),
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
        selectedColor: const Color(0xFF1C3524),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
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
      displayLarge: GoogleFonts.lora(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          color: onSurf,
          height: 1.15),
      displayMedium: GoogleFonts.lora(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: onSurf,
          height: 1.2),
      headlineLarge: GoogleFonts.lora(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: onSurf,
          height: 1.2),
      headlineMedium: GoogleFonts.lora(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: onSurf,
          height: 1.25),
      headlineSmall: GoogleFonts.lora(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: onSurf,
          height: 1.3),
      titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.18,
          color: onSurf,
          height: 1.35),
      titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.16,
          color: onSurf,
          height: 1.4),
      titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.14,
          color: onSurf,
          height: 1.4),
      bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.16,
          color: onSurf,
          height: 1.6),
      bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.14,
          color: onSurfVar,
          height: 1.6),
      bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.12,
          color: onSurfVar,
          height: 1.5),
      labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.28,
          color: onSurf,
          height: 1.0),
      labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.24,
          color: onSurfVar,
          height: 1.0),
      labelSmall: GoogleFonts.plusJakartaSans(
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
      titleTextStyle: GoogleFonts.lora(
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
