import 'package:flutter/material.dart';

class AppTheme {
  static const Color bleuMarine = Color(0xFF1E3A5F);
  static const Color bleuMarineFonce = Color(0xFF142A45);
  static const Color grisClair = Color(0xFFF5F6F8);
  static const Color grisMoyen = Color(0xFFE3E6EB);
  static const Color anthracite = Color(0xFF1B1B1B);
  static const Color rougeAlerte = Color(0xFFC0392B);
  static const Color vertSucces = Color(0xFF2E7D32);
  static const Color orangeAlerte = Color(0xFFE65100);

  // Fonds/textes des badges (stock bas, épuisé, vente à crédit, bénéfice).
  static const Color stockBasBg = Color(0xFFFFE0B2);
  static const Color stockBasFg = orangeAlerte;
  static const Color epuiseBg = Color(0x21C0392B);
  static const Color epuiseFg = rougeAlerte;
  static const Color creditBg = Color(0xFFFFE0B2);
  static const Color creditFg = Color(0xFF8A4A12);
  static const Color beneficeBg = Color(0xFFE5F3E6);
  static const Color beneficeFg = Color(0xFF1E5C22);

  static const double radiusSection = 18;
  static const double radiusChamp = 12;
  static const double radiusBouton = 12;

  /// Ombre douce à deux couches reprise du mockup (rgba(20,30,45,.05/.07)),
  /// utilisée par les cartes et les pastilles flottantes (sélecteur de mois).
  static const List<BoxShadow> ombreDouce = [
    BoxShadow(color: Color(0x0D141E2D), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(color: Color(0x12141E2D), offset: Offset(0, 8), blurRadius: 20),
  ];

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
        elevation: 2,
        shadowColor: bleuMarineFonce.withValues(alpha: 0.18),
        surfaceTintColor: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSection)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: bleuMarine,
        foregroundColor: Colors.white,
        extendedTextStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grisClair,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusChamp), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bleuMarine,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusBouton)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusBouton)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          side: const BorderSide(color: bleuMarine, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusBouton)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? bleuMarine : Colors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.grey.shade600,
          ),
          textStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 13,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          side: const WidgetStatePropertyAll(BorderSide.none),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        shape: const StadiumBorder(),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: anthracite),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: anthracite),
      ),
    );
  }
}
