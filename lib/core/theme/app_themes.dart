import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// الثيمات الثلاثة المتاحة للمستخدم، وهي **مصدر قيم المظهر الواحد** في التطبيق.
///
/// كل عائلة هنا مجموعة أرقام لون فقط، و[AppColors.apply] يكتبها في الحقول
/// العامة التي يقرؤها التطبيق كله (أربعٌ ومئتا مرجعًا)، ثم تُبنى [lightTheme]
/// و[darkTheme] من العائلة نفسها. فلا يوجد لون مظهر مكتور في شاشة ولا في ثيم
/// فرع: العائلة تُختار مرة، والبقية يُشتق.
///
/// **الدلالات ليست هنا** (`AppColors.error` و`warning` و`success` و`info`)
/// لأنها معنى لا مظهر، فتبقى واحدة في الثلاث حتى لا ينقلب «حذف» إلى لون دافئ
/// في ثيم التراكوتا.
///
/// ## كيف تُشتق بقية الحقول
/// `ColorScheme` فيه نحو ستين حقلًا، ومليء كل واحد برقم في ثلاث عائلات = مئة
/// وثمانين رقمًا لا يراجعه أحد. لذلك تُذكر هنا القيم التي **يقصدها صاحب الطلب**
/// (الأساس، accent، أرضية الصفحة، البطاقة، النصوص الثلاثة، الفاصل) ويُشتق
/// الباقي من هذه القيم بـ[_mix]، فالاشتقاق تابع للعائلة نفسها ويتغير معها
/// تلقائيًا ولا يتحلّف مع عائلة جديدة.
class AppThemes {
  AppThemes._();

  /// الأخضر البيئي — المظهر الافتراضي، وهو نفسه ما يراه من لا يفتح الإعدادات
  /// ومن يجرّي اختبارًا بلا استدعاء [select].
  static const AppThemeFamily greenEco = AppThemeFamily(
    id: 'green_eco',
    title: 'الأخضر البيئي',
    caption: 'زمردي داكن مع نعناعي فاتح',
    primary: Color(0xFF1B4D3E),
    primaryDark: Color(0xFF0E2A22),
    primaryLight: Color(0xFF256A54),
    secondary: Color(0xFF256A54),
    secondaryLight: Color(0xFF4E9F3D),
    secondaryDark: Color(0xFF1B4D3E),
    headerAccent: Color(0xFFA9E7B0),
    mint: Color(0xFFE3F4DC),
    sage: Color(0xFFEDF3EC),
    page: Color(0xFFF4F6F4),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE8F0E6),
    textPrimary: Color(0xFF102A22),
    textSecondary: Color(0xFF333333),
    textTertiary: Color(0xFF5C6B62),
    divider: Color(0xFFDDE7E1),
    onWarning: Color(0xFF0E2A22),
    darkPrimary: Color(0xFF0B3D2E),
    darkPrimaryContainer: Color(0xFF12332A),
    darkAccent: Color(0xFF34D399),
    darkPage: Color(0xFF0C1512),
    darkSurface: Color(0xFF14201B),
    darkInputFill: Color(0xFF1B2A25),
    darkHairline: Color(0xFF2A3B34),
    darkTextPrimary: Color(0xFFE6F1EA),
    darkTextSecondary: Color(0xFFA9BDB3),
  );

  /// الأزرق العصري — كحلي ليلي مع سماوي مشرق.
  static const AppThemeFamily modernBlue = AppThemeFamily(
    id: 'modern_blue',
    title: 'الأزرق العصري',
    caption: 'كحلي عميق مع سماوي فاتح',
    primary: Color(0xFF0F172A),
    primaryDark: Color(0xFF020617),
    primaryLight: Color(0xFF1D4ED8),
    secondary: Color(0xFF1D4ED8),
    secondaryLight: Color(0xFF0284C7),
    secondaryDark: Color(0xFF0F172A),
    headerAccent: Color(0xFF93C5FD),
    mint: Color(0xFFE0F2FE),
    sage: Color(0xFFEFF5FB),
    page: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF4E5F73),
    divider: Color(0xFFDBE4EC),
    onWarning: Color(0xFF0F172A),
    darkPrimary: Color(0xFF16233B),
    darkPrimaryContainer: Color(0xFF1B2A44),
    darkAccent: Color(0xFF38BDF8),
    darkPage: Color(0xFF0A0F1A),
    darkSurface: Color(0xFF121A2A),
    darkInputFill: Color(0xFF1B2536),
    darkHairline: Color(0xFF2C3A50),
    darkTextPrimary: Color(0xFFE2E8F0),
    darkTextSecondary: Color(0xFFA3B3C6),
  );

  /// التراكوتا الدافئ — طيني محروق مع ذهبي دافئ.
  static const AppThemeFamily warmTerracotta = AppThemeFamily(
    id: 'warm_terracotta',
    title: 'التراكوتا الدافئ',
    caption: 'طيني محروق مع ذهبي رملي',
    primary: Color(0xFF9A3412),
    primaryDark: Color(0xFF7C2D12),
    primaryLight: Color(0xFFC2410C),
    secondary: Color(0xFFC2410C),
    secondaryLight: Color(0xFFD97706),
    secondaryDark: Color(0xFF9A3412),
    headerAccent: Color(0xFFFDE8C4),
    mint: Color(0xFFFEEBC8),
    sage: Color(0xFFF7EDE4),
    page: Color(0xFFFAFAF9),
    surface: Color(0xFFFFFBF7),
    surfaceVariant: Color(0xFFF1E4D8),
    textPrimary: Color(0xFF451A03),
    textSecondary: Color(0xFF78350F),
    textTertiary: Color(0xFF8A5A2B),
    divider: Color(0xFFEADCCB),
    onWarning: Color(0xFF451A03),
    darkPrimary: Color(0xFF4A2314),
    darkPrimaryContainer: Color(0xFF35180E),
    darkAccent: Color(0xFFF59E0B),
    darkPage: Color(0xFF150E0A),
    darkSurface: Color(0xFF211711),
    darkInputFill: Color(0xFF2B1F17),
    darkHairline: Color(0xFF3D2C21),
    darkTextPrimary: Color(0xFFF5E6D3),
    darkTextSecondary: Color(0xFFC9A88A),
  );

  /// الترتيب الذي يراه المستخدم في «تخصيص مظهر التطبيق».
  static const List<AppThemeFamily> all = [
    greenEco,
    modernBlue,
    warmTerracotta,
  ];

  /// الافتراضي لمن لم يختر قطّ، ولمن يُعطى معرّفًا لا يعرفه التطبيق (عائلة
  /// حُذفت من قائمة قديمة) — فالسقوط هنا إلى المظهر الأول لا إلى قائمة فارغة.
  static AppThemeFamily ofId(String? id) =>
      all.firstWhere((f) => f.id == id, orElse: () => greenEco);

  /// العائلة المطبّقة الآن. يقرؤها [ThemeService] للعرض في الإعدادات.
  static AppThemeFamily get current => _current;
  static AppThemeFamily _current = greenEco;

  /// يختار عائلة: يكتب قيمها في [AppColors] ويبني ثيمًا جديدًا في المرة
  /// التالية التي يقرأ فيها `main.dart` الخصتين. لا يُعاد تركيب أي شيء هنا
  /// ولا يُمسّ مكدّس الشاشات — إعادة الرسم تأتي من هوية `ThemeData` الجديدة
  /// التي يلتقطها `AnimatedBuilder` فوق `MaterialApp`.
  static void select(AppThemeFamily family) {
    _current = family;
    AppColors.apply(family);
    _light = null;
    _dark = null;
  }

  static ThemeData? _light;
  static ThemeData? _dark;

  static ThemeData get lightTheme => _light ??= _buildLight(_current);
  static ThemeData get darkTheme => _dark ??= _buildDark(_current);

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static ThemeData _buildLight(AppThemeFamily f) {
    // حدود التحكم تُقاس على حدّها لا على ذوقها: هذا الخط هو إطار كل حقل بحث
    // وبطاقة منبثقة في التطبيق، وبوابة WCAG له 3.0 لا 4.5.
    final outline = _mix(f.textTertiary, f.page, 0.25);
    final enabledBorder = _mix(outline, f.primaryLight, 0.35);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: f.primary,
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: f.mint,
        onPrimaryContainer: f.primaryDark,
        primaryFixed: f.mint,
        primaryFixedDim: f.headerAccent,
        onPrimaryFixed: f.primaryDark,
        onPrimaryFixedVariant: f.primaryDark,
        secondary: f.primaryLight,
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: f.mint,
        onSecondaryContainer: f.primaryDark,
        secondaryFixed: f.mint,
        secondaryFixedDim: f.headerAccent,
        onSecondaryFixed: f.primaryDark,
        onSecondaryFixedVariant: f.primaryDark,
        tertiary: f.primaryLight,
        onTertiary: const Color(0xFFFFFFFF),
        tertiaryContainer: f.mint,
        onTertiaryContainer: f.primaryDark,
        tertiaryFixed: f.mint,
        tertiaryFixedDim: f.headerAccent,
        onTertiaryFixed: f.primaryDark,
        onTertiaryFixedVariant: f.primaryDark,
        error: AppColors.error,
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFFF9DEDC),
        onErrorContainer: const Color(0xFF7F1D1D),
        surface: f.surface,
        onSurface: f.textPrimary,
        surfaceDim: _mix(f.page, f.textPrimary, 0.06),
        surfaceBright: f.surface,
        surfaceContainerLowest: f.surface,
        surfaceContainerLow: _mix(f.page, f.surface, 0.55),
        surfaceContainer: _mix(f.page, f.surface, 0.25),
        surfaceContainerHigh: _mix(f.page, f.sage, 0.5),
        surfaceContainerHighest: f.sage,
        onSurfaceVariant: f.textSecondary,
        outline: outline,
        outlineVariant: f.divider,
        shadow: f.primaryDark,
        scrim: const Color(0xFF000000),
        inverseSurface: f.primaryDark,
        onInverseSurface: f.mint,
        inversePrimary: f.headerAccent,
        surfaceTint: f.primary,
      ),
      scaffoldBackgroundColor: f.page,
      cardTheme: CardThemeData(
        color: f.surface,
        elevation: 3,
        shadowColor: f.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: f.divider),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: f.primary,
        foregroundColor: const Color(0xFFFFFFFF),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: f.primary,
        selectedItemColor: const Color(0xFFFFFFFF),
        unselectedItemColor: f.headerAccent,
      ),
      dividerTheme: DividerThemeData(
        color: f.divider,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: f.primary,
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.pressed)
                  ? f.primaryDark.withValues(alpha: 0.35)
                  : null),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: f.primary,
          side: BorderSide(color: f.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      textTheme: _textTheme(
        heading: f.primary,
        strong: f.textPrimary,
        normal: f.textSecondary,
        faint: f.textTertiary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: f.divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: enabledBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: f.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: f.sage,
        hintStyle: GoogleFonts.tajawal(color: f.textTertiary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// الوضع الداكن لكل عائلة: الأساس أعمق وأقل تشبّعًا من قيمته الفاتحة حتى لا
  /// يلسع على شبه الأسود، و`colorScheme.primary` نفسه هو درجة الـaccent **المشرقة
  /// لا الداكنة** لأن التطبيق يستعمله كتابةً وأيقونةً فوق الأسطح في أكثر من مئتي
  /// موضع، فالبياض فوقه لا يُقرأ.
  static ThemeData _buildDark(AppThemeFamily f) {
    // نفس وصفة الفاتح هنا: خط الحقل المفعّل = حدّ العائلة الداكن مُمزوجًا بدرجة
    // الـaccent، فيقاس فوق `darkInputFill` نفسه لا فوق الصفحة.
    final outline = _mix(f.darkTextSecondary, f.darkHairline, 0.4);
    final enabledBorder = _mix(outline, f.darkAccent, 0.35);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: f.darkAccent,
        onPrimary: f.darkPrimary,
        primaryContainer: f.darkPrimaryContainer,
        onPrimaryContainer: f.headerAccent,
        primaryFixed: f.headerAccent,
        primaryFixedDim: f.darkAccent,
        onPrimaryFixed: f.darkPrimary,
        onPrimaryFixedVariant: f.darkPrimary,
        secondary: f.darkAccent,
        onSecondary: f.darkPrimary,
        secondaryContainer: f.darkPrimaryContainer,
        onSecondaryContainer: f.headerAccent,
        secondaryFixed: f.headerAccent,
        secondaryFixedDim: f.darkAccent,
        onSecondaryFixed: f.darkPrimary,
        onSecondaryFixedVariant: f.darkPrimary,
        tertiary: f.headerAccent,
        onTertiary: f.darkPrimary,
        tertiaryContainer: f.darkPrimaryContainer,
        onTertiaryContainer: f.headerAccent,
        tertiaryFixed: f.headerAccent,
        tertiaryFixedDim: f.headerAccent,
        onTertiaryFixed: f.darkPrimary,
        onTertiaryFixedVariant: f.darkPrimary,
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        errorContainer: const Color(0xFF8C1D18),
        onErrorContainer: const Color(0xFFF9DEDC),
        surface: f.darkSurface,
        onSurface: f.darkTextPrimary,
        surfaceDim: _mix(f.darkPage, f.darkSurface, 0.35),
        surfaceBright: _mix(f.darkSurface, f.darkTextSecondary, 0.18),
        surfaceContainerLowest: f.darkPage,
        surfaceContainerLow: _mix(f.darkPage, f.darkSurface, 0.6),
        surfaceContainer: f.darkSurface,
        surfaceContainerHigh:
            _mix(f.darkSurface, f.darkTextSecondary, 0.10),
        surfaceContainerHighest: f.darkInputFill,
        onSurfaceVariant: f.darkTextSecondary,
        outline: outline,
        outlineVariant: f.darkHairline,
        shadow: const Color(0xFF000000),
        scrim: const Color(0xFF000000),
        inverseSurface: f.darkTextPrimary,
        onInverseSurface: f.darkPage,
        inversePrimary: f.darkPrimary,
        surfaceTint: f.darkAccent,
      ),
      scaffoldBackgroundColor: f.darkPage,
      cardTheme: CardThemeData(
        color: f.darkSurface,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: f.darkHairline),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: f.darkPrimary,
        foregroundColor: const Color(0xFFFFFFFF),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: f.darkPrimary,
        selectedItemColor: const Color(0xFFFFFFFF),
        unselectedItemColor: f.headerAccent,
      ),
      dividerTheme: DividerThemeData(
        color: f.darkHairline,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: f.darkAccent,
          foregroundColor: f.darkPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.pressed)
                  ? Colors.white.withValues(alpha: 0.14)
                  : null),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: f.darkAccent,
          side: BorderSide(
              color: _mix(f.darkHairline, f.darkAccent, 0.45), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      textTheme: _textTheme(
        heading: f.darkAccent,
        strong: f.darkTextPrimary,
        normal: f.darkTextSecondary,
        faint: f.darkTextSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: f.darkHairline, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: enabledBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: f.darkAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF2B8B5), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF2B8B5), width: 2),
        ),
        filled: true,
        fillColor: f.darkInputFill,
        hintStyle: GoogleFonts.tajawal(
            color: f.darkTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// نسيج النص واحد في السمتين: العناوين درجة العائلة، والقوية والأرضية
  /// والهامدة حبر العائلة الداكن/الفاتح — فلا تُترك ترويسة بيضاء على صفحة
  /// بيضاء حين تختار العائلة.
  static TextTheme _textTheme({
    required Color heading,
    required Color strong,
    required Color normal,
    required Color faint,
  }) {
    return TextTheme(
      displayLarge: GoogleFonts.tajawal(
          fontWeight: FontWeight.w800, color: heading),
      displayMedium: GoogleFonts.tajawal(
          fontWeight: FontWeight.w700, color: heading),
      displaySmall: GoogleFonts.tajawal(
          fontWeight: FontWeight.w600, color: heading),
      headlineLarge: GoogleFonts.tajawal(
          fontWeight: FontWeight.w700, color: heading),
      headlineMedium: GoogleFonts.tajawal(
          fontWeight: FontWeight.w600, color: heading),
      headlineSmall: GoogleFonts.tajawal(
          fontWeight: FontWeight.w500, color: heading),
      titleLarge: GoogleFonts.tajawal(
          fontWeight: FontWeight.w700, color: heading),
      titleMedium: GoogleFonts.tajawal(
          fontWeight: FontWeight.w600, color: strong),
      titleSmall: GoogleFonts.tajawal(
          fontWeight: FontWeight.w500, color: strong),
      bodyLarge: GoogleFonts.tajawal(
          fontWeight: FontWeight.w400, color: strong),
      bodyMedium: GoogleFonts.tajawal(
          fontWeight: FontWeight.w400, color: normal),
      bodySmall: GoogleFonts.tajawal(
          fontWeight: FontWeight.w400, color: faint),
      labelLarge: GoogleFonts.tajawal(
          fontWeight: FontWeight.w600, color: heading),
      labelMedium: GoogleFonts.tajawal(
          fontWeight: FontWeight.w500, color: normal),
      labelSmall: GoogleFonts.tajawal(
          fontWeight: FontWeight.w400, color: faint),
    );
  }
}
