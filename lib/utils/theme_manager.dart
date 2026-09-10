import 'package:flutter/material.dart';

// Cyprus & Sand Palette
const Color kCyprus = Color(0xFF004741);
const Color kSand = Color(0xFFF0EDE4);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: kCyprus,
  colorScheme: const ColorScheme.light(
    primary: kCyprus,
    secondary: Color(0xFF2E635C),
    surface: kSand,
    onPrimary: kSand,
    onSurface: Color(0xFF0A2421),
  ),
  scaffoldBackgroundColor: kSand,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Color(0xFF0A2421)),
  ),
);

const ColorScheme darkColorScheme = ColorScheme.dark(
  primary: Color(0xFF2CB7A9),
  secondary: Color(0xFF2E635C),
  surface: Color(0xFF071514),
  onPrimary: Color(0xFF071514),
  onSurface: kSand,
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF2CB7A9),
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: const Color(0xFF071514),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: kSand),
  ),
);
