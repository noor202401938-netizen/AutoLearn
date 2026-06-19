import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  colorScheme: const ColorScheme.light(
    primary: Colors.blueAccent,
    secondary: Colors.teal,
  ),
  scaffoldBackgroundColor: Colors.white,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black87),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.tealAccent,
  colorScheme: const ColorScheme.dark(
    primary: Colors.tealAccent,
    secondary: Colors.amber,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white70),
  ),
);
