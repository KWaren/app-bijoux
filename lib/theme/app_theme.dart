import 'package:flutter/material.dart';

class AppTheme {
  static const Color bleuMarine = Color(0xFF1E3A5F);
  static const Color bleuMarineFonce = Color(0xFF142A45);
  static const Color grisClair = Color(0xFFF5F6F8);
  static const Color grisMoyen = Color(0xFFE3E6EB);
  static const Color anthracite = Color(0xFF1B1B1B);
  static const Color rougeAlerte = Color(0xFFC0392B);
  static const Color vertSucces = Color(0xFF2E7D32);

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: bleuMarine,
      brightness: Brightness.light,
    ).copyWith(
      primary: bleuMarine,
      secondary: bleuMarineFonce,
      surface: Colors.white,
      error: rougeAlerte,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: grisClair,
      appBarTheme: const AppBarTheme(
        backgroundColor: bleuMarine,
        foregroundColor: Colors.white,
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
        backgroundColor: bleuMarine,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: grisMoyen,
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
          backgroundColor: bleuMarine,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: anthracite),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: anthracite),
      ),
    );
  }
}
