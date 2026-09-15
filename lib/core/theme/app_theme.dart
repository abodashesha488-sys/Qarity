import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6F4E37),
      secondary: Color(0xFFEF6C00),
      tertiary: Color(0xFF6F4E37),
      onSecondary: Colors.white,
      onSurface: Color(0xFF6F4E37),
      outline: Color(0xFFE0E0E0),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5DC),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 4,
      shadowColor: const Color(0xFF6F4E37).withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF6F4E37),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: Color(0xFF6F4E37),
      unselectedItemColor: Color(0xFF8B7355),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ).copyWith(overlayColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.pressed) ? const Color(0xFF6F4E37) : null)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6F4E37),
        side: const BorderSide(color: Color(0xFF6F4E37), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.tajawal(fontWeight: FontWeight.w800, color: const Color(0xFF6F4E37)),
      displayMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w700, color: const Color(0xFF6F4E37)),
      displaySmall: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: const Color(0xFF6F4E37)),
      headlineLarge: GoogleFonts.tajawal(fontWeight: FontWeight.w700, color: const Color(0xFF6F4E37)),
      headlineMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: const Color(0xFF6F4E37)),
      headlineSmall: GoogleFonts.tajawal(fontWeight: FontWeight.w500, color: const Color(0xFF6F4E37)),
      titleLarge: GoogleFonts.tajawal(fontWeight: FontWeight.w700, color: const Color(0xFF6F4E37)),
      titleMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: const Color(0xFF6F4E37)),
      titleSmall: GoogleFonts.tajawal(fontWeight: FontWeight.w500, color: const Color(0xFF6F4E37)),
      bodyLarge: GoogleFonts.tajawal(fontWeight: FontWeight.w400, color: const Color(0xFF6F4E37)),
      bodyMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w400, color: const Color(0xFF8B7355)),
      bodySmall: GoogleFonts.tajawal(fontWeight: FontWeight.w300, color: const Color(0xFF999999)),
      labelLarge: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: const Color(0xFF6F4E37)),
      labelMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w500, color: const Color(0xFF8B7355)),
      labelSmall: GoogleFonts.tajawal(fontWeight: FontWeight.w400, color: const Color(0xFF999999)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6F4E37))),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6F4E37),
      secondary: Color(0xFFFF9800),
      tertiary: Color(0xFF6F4E37),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF6F4E37),
      outline: Color(0xFFE0E0E0),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5DC),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 4,
      shadowColor: const Color(0xFF6F4E37).withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF6F4E37),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: Color(0xFF6F4E37),
      unselectedItemColor: Color(0xFF8B7355),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ).copyWith(overlayColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.pressed) ? const Color(0xFF6F4E37) : null)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6F4E37),
        side: const BorderSide(color: Color(0xFF6F4E37), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.tajawal(fontWeight: FontWeight.w800, color: const Color(0xFF6F4E37)),
      displayMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w700, color: const Color(0xFF6F4E37)),
      displaySmall: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: const Color(0xFF6F4E37)),
      headlineLarge: GoogleFonts.tajawal(fontWeight: FontWeight.w700, color: const Color(0xFF6F4E37)),
      headlineMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: const Color(0xFF6F4E37)),
      headlineSmall: GoogleFonts.tajawal(fontWeight: FontWeight.w500, color: const Color(0xFF6F4E37)),
      titleLarge: GoogleFonts.tajawal(fontWeight: FontWeight.w700, color: const Color(0xFF6F4E37)),
      titleMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: const Color(0xFF6F4E37)),
      titleSmall: GoogleFonts.tajawal(fontWeight: FontWeight.w500, color: const Color(0xFF6F4E37)),
      bodyLarge: GoogleFonts.tajawal(fontWeight: FontWeight.w400, color: const Color(0xFF6F4E37)),
      bodyMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w400, color: const Color(0xFF8B7355)),
      bodySmall: GoogleFonts.tajawal(fontWeight: FontWeight.w300, color: const Color(0xFF8B7355)),
      labelLarge: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: const Color(0xFF6F4E37)),
      labelMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w500, color: const Color(0xFF8B7355)),
      labelSmall: GoogleFonts.tajawal(fontWeight: FontWeight.w400, color: const Color(0xFF8B7355)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6F4E37))),
      filled: true,
      fillColor: const Color(0xFFF5F5DC),
    ),
  );
}