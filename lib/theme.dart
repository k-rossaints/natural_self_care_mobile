import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs extraites de ton main.css
  static const Color teal1 = Color(0xFF0AA6B2); // --nsx-teal-1 (Primaire)
  static const Color teal2 = Color(0xFF16C98F); // --nsx-teal-2 (Secondaire)
  static const Color border = Color(0xFF76CDBB); // --nsx-border
  static const Color active = Color(0xFF6CC9AD); // --nsx-active
  static const Color background = Color(0xFFFAFAFA); // --nsx-bg
  
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textGrey = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444); // Pour les précautions

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal1,
        primary: teal1,
        secondary: teal2,
        background: background,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      
      // Configuration de la police (Outfit ou Roboto)
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),

      // Style des cartes par défaut
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        surfaceTintColor: Colors.white, // Évite la teinte rosée du Material 3
      ),

      // Style de l'AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: teal1,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}