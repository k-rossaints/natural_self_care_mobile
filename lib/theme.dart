import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs primaires
  static const Color teal1 = Color(0xFF0AA6B2);
  static const Color teal2 = Color(0xFF16C98F);
  static const Color border = Color(0xFF76CDBB);
  static const Color active = Color(0xFF6CC9AD);
  static const Color background = Color(0xFFFAFAFA);

  // Couleurs light
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textGrey = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444);

  // Couleurs dark — neutres, sans teinte teal
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);

  // Teal plus lisible en dark mode
  static const Color tealDark = Color(0xFF4DD9E4);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal1,
        primary: teal1,
        secondary: teal2,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: teal1,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    // On construit un ColorScheme explicite pour éviter les teintes teal sur les surfaces
    const darkColorScheme = ColorScheme.dark(
      primary: teal1,
      onPrimary: Colors.white,
      secondary: teal2,
      onSecondary: Colors.white,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      onSurfaceVariant: darkTextSecondary,
      surfaceContainerLowest: Color(0xFF0E0E0E),
      surfaceContainerLow: Color(0xFF1A1A1A),
      surfaceContainer: Color(0xFF222222),
      surfaceContainerHigh: Color(0xFF2E2E2E),
      surfaceContainerHighest: Color(0xFF363636),
      outline: Color(0xFF555555),
      outlineVariant: Color(0xFF3A3A3A),
      error: danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF3A3A3A), width: 1),
        ),
        color: darkCard,
        surfaceTintColor: darkCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: teal1.withOpacity(0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: tealDark);
          }
          return const IconThemeData(color: darkTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: tealDark, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: darkTextSecondary, fontSize: 12);
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: darkSurface,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF333333),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return teal1;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return teal1.withOpacity(0.3);
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: darkTextSecondary,
        collapsedIconColor: darkTextSecondary,
      ),
    );
  }
}
