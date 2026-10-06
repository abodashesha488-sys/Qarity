import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import 'navigator_key.dart';

class AppHelpers {
  AppHelpers._();

  /// أرضية شريط الإشعارات هنا ألوان ثابتة داكنة في السمتين (`primary` و
  /// `success` و`error` والرمادي المحايد)، بينما حبر الشريط الافتراضي يُقرأ من
  /// `onInverseSurface` وهو في الوضع الداكن حبرٌ داكن ⇒ يُثبَّت البياض وإلا صار
  /// النص شبه أسودَ على أرضيته. في الفاتح البياض هو الحبر نفسه عمليًا.
  static const TextStyle _snackInk =
      TextStyle(color: Colors.white, fontWeight: FontWeight.w600);

  static void showToast(String message, {bool isError = false}) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message, style: _snackInk),
          backgroundColor: isError ? AppColors.error : const Color(0xFF323232),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _snackInk),
        backgroundColor: isError ? AppColors.error : isSuccess ? AppColors.success : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void hapticLight() => HapticFeedback.lightImpact();
  static void hapticMedium() => HapticFeedback.mediumImpact();

  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd', 'ar').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return '${diff.inHours} ساعة';
    if (diff.inDays < 7) return '${diff.inDays} يوم';
    return '${date.day}/${date.month}/${date.year}';
  }

  static Color colorFromString(String text) {
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.45).toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}