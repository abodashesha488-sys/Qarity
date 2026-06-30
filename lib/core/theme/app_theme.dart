import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2E7D32),
      secondary: Color(0xFFEF6C00),
      tertiary: Color(0xFF4CAF50),
      onSecondary: Colors.white,
      onSurface: Color(0xFF1A1A1A),
      outline: Color(0xFFE0E0E0),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 4,
      shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF1A1A1A),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: Color(0xFF2E7D32),
      unselectedItemColor: Color(0xFF666666),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ).copyWith(overlayColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.pressed) ? const Color(0xFF1B5E20) : null)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2E7D32),
        side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A)),
      displayMedium: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
      displaySmall: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
      headlineLarge: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
      headlineMedium: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
      headlineSmall: GoogleFonts.cairo(fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A)),
      titleLarge: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
      titleMedium: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
      titleSmall: GoogleFonts.cairo(fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A)),
      bodyLarge: GoogleFonts.cairo(fontWeight: FontWeight.w400, color: const Color(0xFF1A1A1A)),
      bodyMedium: GoogleFonts.cairo(fontWeight: FontWeight.w400, color: const Color(0xFF666666)),
      bodySmall: GoogleFonts.cairo(fontWeight: FontWeight.w300, color: const Color(0xFF999999)),
      labelLarge: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
      labelMedium: GoogleFonts.cairo(fontWeight: FontWeight.w500, color: const Color(0xFF666666)),
      labelSmall: GoogleFonts.cairo(fontWeight: FontWeight.w400, color: const Color(0xFF999999)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2E7D32))),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF66BB6A),
      secondary: Color(0xFFFF9800),
      tertiary: Color(0xFF81C784),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFE0E0E0),
      outline: Color(0xFF3D3D3D),
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    cardTheme: CardThemeData(
      color: const Color(0xFF121212),
      elevation: 4,
      shadowColor: const Color(0xFF66BB6A).withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Color(0xFFE0E0E0),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF121212),
      selectedItemColor: Color(0xFF66BB6A),
      unselectedItemColor: Color(0xFF999999),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF66BB6A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ).copyWith(overlayColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.pressed) ? const Color(0xFF4CAF50) : null)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF66BB6A),
        side: const BorderSide(color: Color(0xFF66BB6A), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: const Color(0xFFE0E0E0)),
      displayMedium: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: const Color(0xFFE0E0E0)),
      displaySmall: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: const Color(0xFFE0E0E0)),
      headlineLarge: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: const Color(0xFFE0E0E0)),
      headlineMedium: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: const Color(0xFFE0E0E0)),
      headlineSmall: GoogleFonts.cairo(fontWeight: FontWeight.w500, color: const Color(0xFFE0E0E0)),
      titleLarge: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: const Color(0xFFE0E0E0)),
      titleMedium: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: const Color(0xFFE0E0E0)),
      titleSmall: GoogleFonts.cairo(fontWeight: FontWeight.w500, color: const Color(0xFFE0E0E0)),
      bodyLarge: GoogleFonts.cairo(fontWeight: FontWeight.w400, color: const Color(0xFFE0E0E0)),
      bodyMedium: GoogleFonts.cairo(fontWeight: FontWeight.w400, color: const Color(0xFFBBBBBB)),
      bodySmall: GoogleFonts.cairo(fontWeight: FontWeight.w300, color: const Color(0xFF999999)),
      labelLarge: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: const Color(0xFFE0E0E0)),
      labelMedium: GoogleFonts.cairo(fontWeight: FontWeight.w500, color: const Color(0xFFBBBBBB)),
      labelSmall: GoogleFonts.cairo(fontWeight: FontWeight.w400, color: const Color(0xFF999999)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3D3D3D))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF66BB6A))),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
    ),
  );
}