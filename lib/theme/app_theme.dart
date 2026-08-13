import 'package:flutter/material.dart';

class AppTheme {
  static const Color or = Color(0xFFC9A227);
  static const Color orFonce = Color(0xFF9C7A1E);
  static const Color beige = Color(0xFFF3EAD8);
  static const Color beigeFonce = Color(0xFFE3D5B8);
  static const Color noir = Color(0xFF1B1B1B);
  static const Color rougeAlerte = Color(0xFFB3261E);

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: or,
      brightness: Brightness.light,
    ).copyWith(
      primary: or,
      secondary: orFonce,
      surface: Colors.white,
      error: rougeAlerte,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: beige,
      appBarTheme: const AppBarTheme(
        backgroundColor: noir,
        foregroundColor: beige,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: or,
        foregroundColor: noir,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: beigeFonce,
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: or,
          foregroundColor: noir,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: noir),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: noir),
      ),
    );
  }
}
