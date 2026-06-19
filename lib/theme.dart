import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors from Stitch Design System
  static const Color primaryColor = Color(0xFF6C63FF);
  
  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF13121B);
  static const Color darkSurfaceColor = Color(0xFF1F1F28);
  static const Color darkOnPrimary = Color(0xFFE4E1EE);
  static const Color darkTextPrimary = Color(0xFFE4E1EE);
  static const Color textSecondary = Color(0xFF918FA1);

  // Light Theme Colors
  static const Color lightBackgroundColor = Color(0xFFF8F9FA);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111827);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
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
      iconTheme: IconThemeData(color: darkTextPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: darkTextPrimary),
      displayMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: darkTextPrimary),
      displaySmall: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: darkTextPrimary),
      headlineMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: darkTextPrimary),
      headlineSmall: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: darkTextPrimary),
      titleLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: darkTextPrimary),
      bodyLarge: TextStyle(fontFamily: 'Inter', color: darkTextPrimary),
      bodyMedium: TextStyle(fontFamily: 'Inter', color: textSecondary),
    ),
    cardTheme: CardThemeData(
      color: darkSurfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: darkOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
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
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
      ),
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: lightTextPrimary),
      displayMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: lightTextPrimary),
      displaySmall: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: lightTextPrimary),
      headlineMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: lightTextPrimary),
      headlineSmall: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: lightTextPrimary),
      titleLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: lightTextPrimary),
      bodyLarge: TextStyle(fontFamily: 'Inter', color: lightTextPrimary),
      bodyMedium: TextStyle(fontFamily: 'Inter', color: textSecondary),
    ),
    cardTheme: CardThemeData(
      color: lightSurfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: lightOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
