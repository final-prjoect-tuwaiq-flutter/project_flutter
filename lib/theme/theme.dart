import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAF9F6),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF4B6E),
      brightness: Brightness.light,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );

  static final ButtonStyle blackCtaButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1E1E24),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}
