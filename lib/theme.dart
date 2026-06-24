import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant, Professional Primary Color (Indigo)
  static const Color primaryColor = Color(0xFF4F46E5);
  // Playful Accent Color (Coral/Amber)
  static const Color accentColor = Color(0xFFFF6B6B);
  
  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF0F172A); // Slate 900
  static const Color darkSurfaceColor = Color(0xFF1E293B);    // Slate 800
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);     // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8);   // Slate 400
  static const Color darkDivider = Color(0xFF334155);

  // Light Theme Colors
  static const Color lightBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);     // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B);   // Slate 500
  static const Color lightDivider = Color(0xFFE2E8F0);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    dividerColor: darkDivider,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: darkSurfaceColor,
      background: darkBackgroundColor,
      onPrimary: darkOnPrimary,
      onSurface: darkTextPrimary,
      onBackground: darkTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackgroundColor,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: darkTextPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: darkTextPrimary,
      ),
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: darkTextPrimary),
      displayMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: darkTextPrimary),
      displaySmall: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: darkTextPrimary),
      headlineMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: darkTextPrimary),
      titleLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
      titleMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, color: darkTextPrimary, height: 1.5),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, color: darkTextSecondary, height: 1.5),
      labelLarge: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: darkSurfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: darkDivider, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: darkOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkDivider, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkDivider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      hintStyle: const TextStyle(color: darkTextSecondary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,
    dividerColor: lightDivider,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: lightSurfaceColor,
      background: lightBackgroundColor,
      onPrimary: lightOnPrimary,
      onSurface: lightTextPrimary,
      onBackground: lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackgroundColor,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: lightTextPrimary,
      ),
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: lightTextPrimary),
      displayMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: lightTextPrimary),
      displaySmall: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: lightTextPrimary),
      headlineMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: lightTextPrimary),
      titleLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.w600, color: lightTextPrimary),
      titleMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, color: lightTextPrimary, height: 1.5),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, color: lightTextSecondary, height: 1.5),
      labelLarge: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: lightTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: lightSurfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lightDivider, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: lightOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightDivider, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightDivider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      hintStyle: const TextStyle(color: lightTextSecondary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500),
    ),
  );
}

