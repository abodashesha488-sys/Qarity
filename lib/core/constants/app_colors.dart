import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color secondary = Color(0xFFEF6C00);
  static const Color secondaryLight = Color(0xFFFF9800);
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF43A047);
  static const Color info = Color(0xFF1E88E5);
  static const Color purple = Color(0xFF7B1FA2);
  static const Color teal = Color(0xFF00897B);
  static const Color divider = Color(0xFFE0E0E0);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
    stops: [0.0, 1.0],
  );
}