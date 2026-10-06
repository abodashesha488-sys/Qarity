import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/app_colors.dart';
import 'package:qurity/core/theme/app_theme.dart';
import 'package:qurity/core/theme/app_themes.dart';
import 'package:qurity/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات موجة مبدّل الثيمات: العقد بين العائلة ThemeData، و[AppColors] المكتوبة
/// وقت الاختيار، والاختيار المحفوظ في SharedPreferences، وبوّابات التباين.
///
/// التباين كله **محسوب هنا** من `AppColors.contrastRatio` على القيم الحيّة، لا
/// أرقام مجمّدة من تقرير: المجمّد يكذب أولما تتغيّر درجة في ملف العائلة.
void main() {
  // [AppColors] مكتوب فيها على مستوى الملف (توكنات متغيّرة)، فكل اختبار يقيس
  // عليها يجب أن يختار عائلته صراحةً، ثم تُرجَع العائلة الافتراضية وإلا سرَب
  // الأخضر البيئي من اختبار إلى آخر في نفس الملف وانقلبت العقود سقوطًا عشوائيًا.
  setUp(() {
    AppThemes.select(AppThemes.greenEco);
  });

  tearDown(() {
    AppThemes.select(AppThemes.greenEco);
  });

  ThemeData lightOf(AppThemeFamily f) {
    AppThemes.select(f);
    return AppTheme.lightTheme;
  }

  ThemeData darkOf(AppThemeFamily f) {
    AppThemes.select(f);
    return AppTheme.darkTheme;
  }

  group('عائلات الثيمات الثلاث', () {
    test('لكل عائلة معرّف وعنوان ووصف، ولا يتكرر معرّف', () {
      expect(AppThemes.all, hasLength(3));
      final ids = AppThemes.all.map((f) => f.id).toList();
      expect(ids.toSet(), hasLength(3));
      for (final f in AppThemes.all) {
        expect(f.id, isNotEmpty);
        expect(f.title, isNotEmpty);
        expect(f.caption, isNotEmpty);
      }
      expect(ids, containsAll(['green_eco', 'modern_blue', 'warm_terracotta']));
    });

    test('الأخضر البيئي يحمل ألوان المستخدم الحرفية (فاتح + داكن زمردي مغاير)',
        () {
      const f = AppThemes.greenEco;
      expect(f.primary, const Color(0xFF1B4D3E));
      expect(f.primaryDark, const Color(0xFF0E2A22));
      expect(f.secondaryLight, const Color(0xFF4E9F3D));
      expect(f.page, const Color(0xFFF4F6F4));
      expect(f.surface, const Color(0xFFFFFFFF));
      expect(f.textPrimary, const Color(0xFF102A22));
      expect(f.textSecondary, const Color(0xFF333333));
      expect(f.mint, const Color(0xFFE3F4DC));
      expect(f.sage, const Color(0xFFEDF3EC));
      // الوضع الداكن قيمة زمردية **مغايرة** لا نفس الفتحة: الأساس أعمق والـaccent
      // أفتح، وإلا لسعت نفس الدرجة على شبه الأسود.
      expect(f.darkPrimary, const Color(0xFF0B3D2E));
      expect(f.darkAccent, const Color(0xFF34D399));
      expect(f.darkSurface, const Color(0xFF14201B));
      expect(f.darkAccent, isNot(equals(f.primary)));
      expect(f.darkPrimary, isNot(equals(f.primary)));
      final hue = HSLColor.fromColor(f.darkAccent).hue;
      expect(hue, greaterThan(120));
      expect(hue, lessThan(185));
    });

    test('الأزرق الحديث يحمل ألوان المستخدم الحرفية (فاتح + داكن)', () {
      const f = AppThemes.modernBlue;
      expect(f.primary, const Color(0xFF0F172A));
      expect(f.primaryDark, const Color(0xFF020617));
      expect(f.secondaryLight, const Color(0xFF0284C7));
      expect(f.page, const Color(0xFFF8FAFC));
      expect(f.surface, const Color(0xFFFFFFFF));
      expect(f.textPrimary, const Color(0xFF1E293B));
      expect(f.textSecondary, const Color(0xFF475569));
      expect(f.mint, const Color(0xFFE0F2FE));
      expect(f.darkPrimary, const Color(0xFF16233B));
      expect(f.darkAccent, const Color(0xFF38BDF8));
      expect(f.darkSurface, const Color(0xFF121A2A));
      expect(f.darkAccent, isNot(equals(f.primary)));
    });

    test('التراكوتا الدافئة تحمل ألوان المستخدم الحرفية (فاتح + داكن)', () {
      const f = AppThemes.warmTerracotta;
      expect(f.primary, const Color(0xFF9A3412));
      expect(f.primaryDark, const Color(0xFF7C2D12));
      expect(f.secondaryLight, const Color(0xFFD97706));
      expect(f.page, const Color(0xFFFAFAF9));
      expect(f.textPrimary, const Color(0xFF451A03));
      expect(f.textSecondary, const Color(0xFF78350F));
      expect(f.mint, const Color(0xFFFEEBC8));
      expect(f.darkPrimary, const Color(0xFF4A2314));
      expect(f.darkAccent, const Color(0xFFF59E0B));
      expect(f.darkSurface, const Color(0xFF211711));
      expect(f.darkAccent, isNot(equals(f.primary)));
    });

    test('البلاطات المعروضة في الحوار = الأساس + المميّز + النعناع + الأرضية', () {
      for (final f in AppThemes.all) {
        expect(f.swatch, <Color>[f.primary, f.secondaryLight, f.mint, f.page]);
      }
    });

    test('معرّف مجهول أو غائب يسقط إلى الأخضر البيئي (عائلة حُذفت لا تعذّر)', () {
      expect(AppThemes.ofId(null), same(AppThemes.greenEco));
      expect(AppThemes.ofId(''), same(AppThemes.greenEco));
      expect(AppThemes.ofId('desert_gold'), same(AppThemes.greenEco));
      for (final f in AppThemes.all) {
        expect(AppThemes.ofId(f.id), same(f));
      }
    });
  });

  group('الاختيار الفوري والتخزين', () {
    test('select يكتب العائلة في AppColors ويبدّل تدرّج الأساس', () {
      for (final f in AppThemes.all) {
        AppThemes.select(f);
        expect(AppColors.primary, f.primary);
        expect(AppColors.primaryDark, f.primaryDark);
        expect(AppColors.primaryLight, f.primaryLight);
        expect(AppColors.headerAccent, f.headerAccent);
        expect(AppColors.mint, f.mint);
        expect(AppColors.sage, f.sage);
        expect(AppColors.page, f.page);
        expect(AppColors.surface, f.surface);
        expect(AppColors.textPrimary, f.textPrimary);
        expect(AppColors.textSecondary, f.textSecondary);
        expect(AppColors.divider, f.divider);
        expect(AppColors.onWarning, f.onWarning);
        expect(AppColors.darkPrimary, f.darkPrimary);
        expect(AppColors.darkAccent, f.darkAccent);
        expect(AppColors.darkSurface, f.darkSurface);
        expect(AppColors.darkPage, f.darkPage);
        expect(AppColors.primaryGradient.colors, <Color>[f.primary, f.primaryDark]);
      }
    });

    test('select يُبطل ThemeData المجمّدة فلا تبقى الشاشة على العائلة القديمة',
        () {
      AppThemes.select(AppThemes.greenEco);
      final beforeLight = AppTheme.lightTheme;
      final beforeDark = AppTheme.darkTheme;
      // نفس العائلة مرتين: التجميد مقصود، فلا rebuilding بلا داعٍ.
      expect(AppTheme.lightTheme, same(beforeLight));
      expect(AppTheme.darkTheme, same(beforeDark));

      AppThemes.select(AppThemes.warmTerracotta);
      expect(identical(AppTheme.lightTheme, beforeLight), isFalse);
      expect(identical(AppTheme.darkTheme, beforeDark), isFalse);
      expect(AppTheme.lightTheme.colorScheme.primary,
          AppThemes.warmTerracotta.primary);
    });

    test('اختيار العائلة يُشعر المستمعات (إعادة رسم بلا إعادة تشغيل)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = ThemeService();
      await service.loadTheme();
      var calls = 0;
      void listener() => calls++;
      service.addListener(listener);
      await service.setFamily(AppThemes.modernBlue);
      service.removeListener(listener);
      expect(calls, 1);
      expect(service.family, same(AppThemes.modernBlue));
    });

    test('العائلة تُكتب في SharedPreferences وتُقرأ من القرص عند الإقلاع',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = ThemeService();
      await service.loadTheme();
      await service.setFamily(AppThemes.warmTerracotta);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_family_id'), 'warm_terracotta');

      // إقلاع جديد: القيم على القرص وحدها تقرر — لا حالة الكائنsingleton.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_family_id': 'modern_blue',
        'dark_mode': true,
      });
      await service.loadTheme();
      expect(service.family, same(AppThemes.modernBlue));
      expect(service.themeMode, ThemeMode.dark);
      expect(service.isDarkMode, isTrue);
      // التكتب في AppColors سبق أي شاشة: فلا يرى المستخدم الأخضر ثم يقفز.
      expect(AppColors.primary, AppThemes.modernBlue.primary);
      expect(AppColors.darkSurface, AppThemes.modernBlue.darkSurface);
    });

    test('الوضع الداكن مستقل عن العائلة ويُحفظ في مفتاحه', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = ThemeService();
      await service.loadTheme();
      expect(service.themeMode, ThemeMode.light);
      await service.toggleTheme();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dark_mode'), isTrue);
      expect(service.themeMode, ThemeMode.dark);
      // العائلة لم تمسّها التبديلة: تركيبتان مستقلتان كما طلب المستخدم.
      expect(prefs.getString('theme_family_id'), isNull);
      expect(service.family, same(AppThemes.greenEco));
      await service.toggleTheme();
      expect(service.themeMode, ThemeMode.light);
    });

    test('تركيبة محفوظة قديمة (عائلة + داكن) تُقرأ معًا من أول إقلاع', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_family_id': 'warm_terracotta',
        'dark_mode': true,
      });
      final service = ThemeService();
      await service.loadTheme();
      expect(service.family, same(AppThemes.warmTerracotta));
      expect(service.themeMode, ThemeMode.dark);
      expect(AppTheme.darkTheme.scaffoldBackgroundColor,
          AppThemes.warmTerracotta.darkPage);
    });
  });

  group('عقد ThemeData لكل عائلة', () {
    test('الفاتح: الأساس والكتابة والأرضيات والكرت والشريط العلوي وشريط التنقل',
        () {
      for (final f in AppThemes.all) {
        final theme = lightOf(f);
        final scheme = theme.colorScheme;
        expect(scheme.brightness, Brightness.light);
        expect(scheme.primary, f.primary);
        expect(scheme.onPrimary, const Color(0xFFFFFFFF));
        expect(scheme.surface, f.surface);
        expect(scheme.onSurface, f.textPrimary);
        expect(scheme.onSurfaceVariant, f.textSecondary);
        expect(scheme.secondaryContainer, f.mint);
        expect(scheme.surfaceContainerHighest, f.sage);
        expect(theme.scaffoldBackgroundColor, f.page);
        expect(theme.cardTheme.color, f.surface);
        expect(
            (theme.cardTheme.shape as RoundedRectangleBorder).side.color,
            f.divider);
        expect(theme.appBarTheme.backgroundColor, f.primary);
        expect(theme.appBarTheme.foregroundColor, const Color(0xFFFFFFFF));
        expect(theme.bottomNavigationBarTheme.backgroundColor, f.primary);
        expect(theme.bottomNavigationBarTheme.selectedItemColor,
            const Color(0xFFFFFFFF));
        expect(theme.bottomNavigationBarTheme.unselectedItemColor,
            f.headerAccent);
        expect(theme.dividerTheme.color, f.divider);
        expect(theme.elevatedButtonTheme.style!.backgroundColor!.resolve(const <WidgetState>{}),
            f.primary);
        expect(theme.elevatedButtonTheme.style!.foregroundColor!.resolve(const <WidgetState>{}),
            const Color(0xFFFFFFFF));
        expect(theme.textTheme.titleLarge!.color, f.primary);
        expect(theme.textTheme.bodyMedium!.color, f.textSecondary);
      }
    });

    test('الداكن: قيمة العائلة الداكنة لا الفاتحة — الأساس أعمق والـaccent أفتح',
        () {
      for (final f in AppThemes.all) {
        final theme = darkOf(f);
        final scheme = theme.colorScheme;
        expect(scheme.brightness, Brightness.dark);
        // `primary` نفسه درجة الـaccent المشرقة: التطبيق يستعمله كتابةً وأيقونةً.
        expect(scheme.primary, f.darkAccent);
        expect(scheme.onPrimary, f.darkPrimary);
        expect(scheme.surface, f.darkSurface);
        expect(scheme.onSurface, f.darkTextPrimary);
        expect(scheme.onSurfaceVariant, f.darkTextSecondary);
        expect(scheme.surfaceContainerHighest, f.darkInputFill);
        expect(theme.scaffoldBackgroundColor, f.darkPage);
        expect(theme.cardTheme.color, f.darkSurface);
        expect(
            (theme.cardTheme.shape as RoundedRectangleBorder).side.color,
            f.darkHairline);
        expect(theme.appBarTheme.backgroundColor, f.darkPrimary);
        expect(theme.appBarTheme.foregroundColor, const Color(0xFFFFFFFF));
        expect(theme.bottomNavigationBarTheme.backgroundColor, f.darkPrimary);
        expect(theme.bottomNavigationBarTheme.unselectedItemColor,
            f.headerAccent);
        expect(theme.dividerTheme.color, f.darkHairline);
        expect(theme.elevatedButtonTheme.style!.backgroundColor!.resolve(const <WidgetState>{}),
            f.darkAccent);
        expect(theme.textTheme.titleLarge!.color, f.darkAccent);
        expect(theme.textTheme.bodyMedium!.color, f.darkTextSecondary);
      }
    });

    test('حدود الحقول تُبنى من الوصفة المعلنة وترسب فوق أرضية الحقل نفسها', () {
      for (final f in AppThemes.all) {
        final light = lightOf(f);
        final lightOutline = Color.lerp(f.textTertiary, f.page, 0.25)!;
        expect(light.colorScheme.outline, lightOutline);
        expect(light.inputDecorationTheme.fillColor, f.sage);
        final lightEnabled =
            (light.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
                .borderSide;
        expect(lightEnabled.color, Color.lerp(lightOutline, f.primaryLight, 0.35));

        final dark = darkOf(f);
        final darkOutline = Color.lerp(f.darkTextSecondary, f.darkHairline, 0.4)!;
        expect(dark.colorScheme.outline, darkOutline);
        expect(dark.inputDecorationTheme.fillColor, f.darkInputFill);
        final darkEnabled =
            (dark.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
                .borderSide;
        expect(darkEnabled.color, Color.lerp(darkOutline, f.darkAccent, 0.35));
      }
      AppThemes.select(AppThemes.greenEco);
    });
  });

  group('الدلالات لا تتبع العائلة', () {
    test('الخطأ والتحذير والنجاح والأزرق والبنفسجي والتركوازي ثابتة', () {
      for (final f in AppThemes.all) {
        AppThemes.select(f);
        expect(AppColors.error, const Color(0xFFB71C1C));
        expect(AppColors.warning, const Color(0xFFFF9800));
        expect(AppColors.warningInk, const Color(0xFF8D4E00));
        expect(AppColors.success, const Color(0xFF047857));
        expect(AppColors.info, const Color(0xFF1E88E5));
        expect(AppColors.purple, const Color(0xFF7B1FA2));
        expect(AppColors.teal, const Color(0xFF00897B));
      }
    });

    test('colorScheme.error يرث الدلالة الثابتة في السمتين', () {
      for (final f in AppThemes.all) {
        expect(lightOf(f).colorScheme.error, AppColors.error);
        expect(darkOf(f).colorScheme.error, const Color(0xFFF2B8B5));
      }
    });
  });

  group('بوّابات التباين (WCAG محسوبة من القيم الحيّة)', () {
    test('البياض حبرًا فوق شريط العائلة العلئي يجتاز نصّ العادي', () {
      for (final f in AppThemes.all) {
        expect(AppColors.contrastRatio(const Color(0xFFFFFFFF), f.primary),
            greaterThanOrEqualTo(4.5));
      }
    });

    test('درجة الأساس حبرًا فوق أرضية الوضع الداكن تُرفع حتى تجتاز 4.5', () {
      for (final f in AppThemes.all) {
        AppThemes.select(f);
        final ink = AppColors.readableInk(f.primary, Brightness.dark);
        expect(AppColors.contrastRatio(ink, f.darkSurface),
            greaterThanOrEqualTo(4.5));
        // الزحزحة سطوعًا وحده: معنى القسم (لونه وتشبّعه) محفوظ.
        final before = HSLColor.fromColor(f.primary);
        final after = HSLColor.fromColor(ink);
        expect((after.hue - before.hue).abs(), lessThan(0.5));
        expect(after.saturation, closeTo(before.saturation, 0.02));
        expect(after.lightness, greaterThanOrEqualTo(before.lightness));
      }
    });

    test('حدود التحكم تجتاز سقف الرسم 3.0 على أرضيتها الفعلية في السمتين', () {
      for (final f in AppThemes.all) {
        final light = lightOf(f);
        // الحدّ يُقاس فوق صفحة الفاتح لا فوق الأرضية المكتوبة، وبوّابته 3.0.
        expect(AppColors.contrastRatio(light.colorScheme.outline, f.surface),
            greaterThanOrEqualTo(3.0));
        final lightEnabled =
            (light.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
                .borderSide.color;
        expect(AppColors.contrastRatio(lightEnabled, f.sage),
            greaterThanOrEqualTo(3.0));

        final dark = darkOf(f);
        expect(AppColors.contrastRatio(dark.colorScheme.outline, f.darkSurface),
            greaterThanOrEqualTo(3.0));
        final darkEnabled =
            (dark.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
                .borderSide.color;
        expect(AppColors.contrastRatio(darkEnabled, f.darkInputFill),
            greaterThanOrEqualTo(3.0));
      }
    });

    test('درجة الهيدر المميزة تُقرأ فوق الأساس الفاتح والداكن معًا', () {
      for (final f in AppThemes.all) {
        expect(AppColors.contrastRatio(f.headerAccent, f.primary),
            greaterThanOrEqualTo(4.5));
        expect(AppColors.contrastRatio(f.headerAccent, f.darkPrimary),
            greaterThanOrEqualTo(4.5));
      }
    });

    test('حبر العائلة الفاتح يجتاز 4.5 فوق الكرت وفوق الصفحة', () {
      for (final f in AppThemes.all) {
        expect(AppColors.contrastRatio(f.textPrimary, f.surface),
            greaterThanOrEqualTo(4.5));
        expect(AppColors.contrastRatio(f.textSecondary, f.surface),
            greaterThanOrEqualTo(4.5));
        expect(AppColors.contrastRatio(f.textTertiary, f.surface),
            greaterThanOrEqualTo(4.5));
        expect(AppColors.contrastRatio(f.textPrimary, f.page),
            greaterThanOrEqualTo(4.5));
        // الأساس نفسه أيقونةً وكتابةً فوق الكرت.
        expect(AppColors.contrastRatio(f.primary, f.surface),
            greaterThanOrEqualTo(4.5));
      }
    });

    test('حبر العائلة الداكن يجتاز 4.5 فوق أرضية الوضع الداكن', () {
      for (final f in AppThemes.all) {
        expect(AppColors.contrastRatio(f.darkTextPrimary, f.darkSurface),
            greaterThanOrEqualTo(4.5));
        expect(AppColors.contrastRatio(f.darkTextSecondary, f.darkSurface),
            greaterThanOrEqualTo(4.5));
        expect(AppColors.contrastRatio(f.darkAccent, f.darkSurface),
            greaterThanOrEqualTo(4.5));
      }
    });

    test('الفاصل فصلٌ بصري لا حدّ تباين — معلَن فلا يُبوَّب خطأً', () {
      // 1.27–1.31 على الكرت: لا يدّعي أحد أنه يقرأ نصًا بلونه، والعقد هنا أنه
      // **لا يجتاز** 3.0 كي لا يُستعمل حبرًا يومًا.
      for (final f in AppThemes.all) {
        expect(AppColors.contrastRatio(f.divider, f.surface),
            lessThan(3.0));
        expect(AppColors.contrastRatio(f.darkHairline, f.darkSurface),
            lessThan(3.0));
      }
    });

    test('readableInk لا يغيّر درجةً اجتازت الحدّ أصلًا', () {
      for (final f in AppThemes.all) {
        AppThemes.select(f);
        // الحبر الداكن الأصلي فوق أرضية فاتحة يجتاز، فيُرجَع كما هو حرفيًا.
        expect(AppColors.readableInk(f.textPrimary, Brightness.light),
            f.textPrimary);
      }
    });
  });

  group('عقود المصدر', () {
    test('حوار «تخصيص مظهر التطبيق» يبني الثلاث ويربط الاختيار بالخدمة', () {
      final source = File('lib/features/settings/index.dart').readAsStringSync();
      expect(source, contains("'تخصيص مظهر التطبيق'"));
      expect(source, contains('...AppThemes.all.map('));
      expect(source, contains('class _ThemeFamilyCard extends StatelessWidget {'));
      expect(source, contains('_themeService.setFamily(f)'));
      expect(source, contains('AppColors.readableInk('));
      // الحدّ كامل الشفافية: زائرة بلا شفافية تقيس 1.7 ولا تُرى.
      expect(source, contains('color: selected ? ink : scheme.outline'));
      expect(source, contains('Border.all(color: scheme.outline)'));
      expect(source, isNot(contains('outline.withValues')));
    });

    test('الخدمة تحفظ في مفتاح العائلة وتكتب قبل الإشعار', () {
      final source = File('lib/services/theme_service.dart').readAsStringSync();
      expect(source, contains("'theme_family_id'"));
      expect(source, contains('AppThemes.ofId('));
      expect(source, contains('AppThemes.select(_family)'));
      expect(source, contains('AppThemes.select(family)'));
      expect(source, contains('prefs.setBool(_darkKey, value)'));
    });

    test('main: التحميل قبل runApp وإعادة الرسم بحوار لا بإعادة تركيب المكدّس',
        () {
      final source = File('lib/main.dart').readAsStringSync();
      expect(source, contains('await ThemeService().loadTheme();'));
      expect(source.indexOf('await ThemeService().loadTheme();'),
          lessThan(source.indexOf('runApp(const QarityApp())')));
      expect(source, contains('return AnimatedBuilder('));
      expect(source, contains('animation: ThemeService(),'));
      expect(source, contains('theme: AppTheme.lightTheme'));
      expect(source, contains('darkTheme: AppTheme.darkTheme'));
      expect(source, contains('themeMode: ThemeService().themeMode'));
      // ValueKey على MaterialApp يُسقط شجرة الـNavigator كلها: خارج السور.
      expect(source, isNot(contains('ValueKey')));
    });

    test('الواجهة القديمة تنيب عن AppThemes فلا مسارَ ثيم ثانٍ', () {
      final source = File('lib/core/theme/app_theme.dart').readAsStringSync();
      expect(source, contains('static ThemeData get lightTheme => AppThemes.lightTheme;'));
      expect(source, contains('static ThemeData get darkTheme => AppThemes.darkTheme;'));
    });
  });
}
