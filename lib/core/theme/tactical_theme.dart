import 'package:flutter/material.dart';

class TacticalTheme {
  // Core Tactical Colors
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color red500 = Color(0xFFEF4444);
  static const Color emerald500 = Color(0xFF10B981);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: slate900,
      colorScheme: const ColorScheme.dark(
        primary: amber500,
        onPrimary: slate900,
        secondary: amber500,
        surface: slate800,
        error: red500,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: slate900,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: amber500,
        foregroundColor: slate900,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate900,
        labelStyle: const TextStyle(color: slate400),
        hintStyle: const TextStyle(color: slate700),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: slate700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: amber500, width: 1.5),
        ),
      ),
    );
  }
}
