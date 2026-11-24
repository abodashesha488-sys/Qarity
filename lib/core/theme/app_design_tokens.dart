import 'package:flutter/material.dart';

/// ثوابت المسافات الموحدة في نظام التصميم.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

/// ثوابت أنصاف الأقطار الموحدة للبطاقات والأزرار.
abstract final class AppRadii {
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double pill = 999.0;
}

/// ظلال موحدة قابلة لإعادة الاستخدام تدعم الوضعين الفاتح والداكن.
abstract final class AppShadows {
  static List<BoxShadow> card({required Color accent, required bool isDark}) =>
      [
        BoxShadow(
          color: (isDark ? Colors.black : accent)
              .withValues(alpha: isDark ? 0.28 : 0.08),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ];

  static List<BoxShadow> floatingBar(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];
}

/// امتداد ثيم موحد يوفر دلالات الألوان المخصصة للواجهات الحديثة
/// دون الاعتماد على الحقول الساكنة المتغيرة قدر الإمكان.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.accentSoft,
    required this.cardBorder,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.navBarBackground,
    required this.navBarActivePill,
  });

  final Color accentSoft;
  final Color cardBorder;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color navBarBackground;
  final Color navBarActivePill;

  static const AppThemeTokens lightFallback = AppThemeTokens(
    accentSoft: Color(0xFFE3F4DC),
    cardBorder: Color(0xFFDDE7E1),
    shimmerBase: Color(0xFFE5EAE6),
    shimmerHighlight: Color(0xFFF5F8F6),
    navBarBackground: Color(0xFF1B4D3E),
    navBarActivePill: Color(0xFF256A54),
  );

  static const AppThemeTokens darkFallback = AppThemeTokens(
    accentSoft: Color(0xFF12332A),
    cardBorder: Color(0xFF2A3B34),
    shimmerBase: Color(0xFF1B2A25),
    shimmerHighlight: Color(0xFF273B34),
    navBarBackground: Color(0xFF0B3D2E),
    navBarActivePill: Color(0xFF165B46),
  );

  static AppThemeTokens of(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeTokens>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.dark
        ? darkFallback
        : lightFallback;
  }

  @override
  AppThemeTokens copyWith({
    Color? accentSoft,
    Color? cardBorder,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? navBarBackground,
    Color? navBarActivePill,
  }) {
    return AppThemeTokens(
      accentSoft: accentSoft ?? this.accentSoft,
      cardBorder: cardBorder ?? this.cardBorder,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      navBarActivePill: navBarActivePill ?? this.navBarActivePill,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      navBarBackground:
          Color.lerp(navBarBackground, other.navBarBackground, t)!,
      navBarActivePill:
          Color.lerp(navBarActivePill, other.navBarActivePill, t)!,
    );
  }
}
