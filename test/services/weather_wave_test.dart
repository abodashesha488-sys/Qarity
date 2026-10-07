import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/app_colors.dart';
import 'package:qurity/core/theme/app_themes.dart';
import 'package:qurity/services/weather_service.dart';

/// أربع طلبات حرفية: «صورة الهيدر العلوي للشاشة الرئيسية يجب ان تكون " heder.jpg "» /
/// «الصورة "0.jpg" تستخدم كهيدر لصفحة " تعرف علي القرية وكل محتوياتها"» /
/// «في الشاشة الرئيسية كارت " الطقس " يجب ان يكون باللون " #D1F4BE " مع تنسيق افضل
/// لعرض الطقس بنفس مساحه الكارت دون تغيير» / «صفحه " الطقس" يجب ان يعاد تنسيقها بشكل
/// أفضل ومنظم واستخدام ايقونات الطقس كما هي من مزود الخدمة».
///
/// الطلبان الأول والثاني **موضعيان** (أي أصل يسكن أي شاشة)، والثالث **هندسي** (لون
/// أرضية معجمّد ومساحة لا تتحرك)، والرابع **سلوكي** (الحالة العربية تُشتق من مفتاح
/// أيقونة المزود، لا من نص إنجليزي خام). لذلك يثبت هذا الملف الأمرين معًا: عقد مصدر
/// سطرٌ بسطر، ودالة `WeatherFormat.conditionAr` فعلًا لا قولًا.
void main() {
  String src(String path) => File(path).readAsStringSync();

  group('هيدر الشاشة الرئيسية', () {
    test('صورة الهيدر هي `heder.jpg`، وبلا أي حجاب فوقها', () {
      final home = src('lib/features/home/home.dart');
      expect(home, contains("Image.asset('assets/images/heder.jpg'"));
      expect(home, isNot(contains("Image.asset('assets/images/heder2.jpg'")));
    });

    test('عقد الهيدر القديم لم يتزحزح: جسم `53.0` وسطر الوقت والتاريخ متمركز', () {
      final home = src('lib/features/home/home.dart');
      expect(home, contains('const double kHeroBodyHeight = 53.0;'));
      expect(home, contains("ValueKey('header-clock-date-line')"));
    });

    test('بلاطة الشبكة ما زالت `About.jpg` — فهي بلاطة لا هيدر', () {
      final home = src('lib/features/home/home.dart');
      expect(
        home,
        contains(
          "_ServiceItem('تعرف على القرية', AppRoutes.about, "
          "'assets/images/About.jpg')",
        ),
      );
    });
  });

  group('صورة `0.jpg` كهيدر لـ«تعرف على القرية» وكل محتوياتها', () {
    test('الصفحة الرئيسية للقسم', () {
      final about = src('lib/features/village/about.dart');
      expect(about, contains("'assets/images/0.jpg'"));
      expect(about, isNot(contains('About.jpg')));
    });

    test('بطاقة تعريف القرية (فرعي الصورة كلها)', () {
      final profile = src('lib/features/village/village_profile_screen.dart');
      expect(
        RegExp(r'assets/images/0\.jpg').allMatches(profile).length,
        2,
      );
      expect(profile, isNot(contains('About.jpg')));
    });

    test('رأس كل قسم فرعي: `VillageSectionHeader` يرسمها فيسري «وكل محتوياتها»', () {
      final ornament = src('lib/widgets/village_ornament.dart');
      expect(ornament, contains("Image.asset('assets/images/0.jpg'"));
      expect(ornament, isNot(contains('About.jpg')));
      // الهوية تبقى بلون القسم فوق الصورة، وبلا صورة يسقط إلى `ColoredBox` لا إلى فراغ.
      expect(ornament, contains('ColoredBox(color: accent)'));
      expect(ornament, contains('accent.withValues(alpha: 0.78)'));
    });

    test('أصل الصورة مسجّل في الحزمة (المجلد كاملًا يُجمَّع)', () {
      expect(File('assets/images/0.jpg').lengthSync(), greaterThan(1000));
      expect(File('assets/images/heder.jpg').lengthSync(), greaterThan(1000));
      expect(File('assets/images/About.jpg').lengthSync(), greaterThan(1000));
    });
  });

  group('كارت الطقس في الشاشة الرئيسية', () {
    test('أرضيته `#D1F4BE` وحبره يُحسم بالتباين لا بالأبيض', () {
      final bar = src('lib/widgets/village_weather_bar.dart');
      expect(bar, contains('const floor = Color(0xFFD1F4BE);'));
      expect(bar, contains('final ink = AppColors.textPrimary;'));
      // علّة موثّقة: `readableInk(floor, …)` يقيس نسبة التباين على أرضية **الثيم**
      // (`surface` في الفاتح، `darkSurface` في الداكن) لا على الأرضية التي يُمرَّر
      // اسمها وسيطًا. ففي الوضع الداكن يردّ الحارس حبرًا فاتحًا لأن تباينه محسوب فوق
      // أخضر داكن — ويُرمى ذلك الحبر فوق أرضية الكارت الفاتحة نفسها فتسقط النسبة إلى
      // 1.00 (نص لا يُرى إطلاقًا). حبر هذه البطاقة سطر مباشر من عائلة الألوان لأن
      // أرضيتها معرّفة حرفيًا ولا تتبع الثيم.
      expect(bar, isNot(contains('readableInk(floor')));
      // لا أسود فوق أخضر فاتح: الأحبار المغشّاة تُشتق من الحبر المحسوب.
      expect(
        bar,
        contains('Color.alphaBlend(ink.withValues(alpha: 0.78), floor)'),
      );
    });

    test('حبر كل عائلة ألوان يجتاز 4.5 فوق `#D1F4BE` — لا نصّ لا يُرى في الداكن', () {
      const floor = Color(0xFFD1F4BE);
      for (final family in [
        AppThemes.greenEco,
        AppThemes.modernBlue,
        AppThemes.warmTerracotta,
      ]) {
        AppColors.apply(family);
        final ink = AppColors.textPrimary;
        expect(
          AppColors.contrastRatio(ink, floor),
          greaterThanOrEqualTo(4.5),
          reason: 'حبر «${family.id}» غير مقروء على أرضية الكارت',
        );
        final muted = Color.alphaBlend(ink.withValues(alpha: 0.78), floor);
        expect(
          AppColors.contrastRatio(muted, floor),
          greaterThanOrEqualTo(4.5),
          reason: 'سطر التفاصيل المغشّى لعائلة «${family.id}» غير مقروء',
        );
      }
      AppColors.apply(AppThemes.greenEco); // رجوع للعائلة الافتراضية
    });

    test('مساحته لم تتغير: نفس الحشو الخارجي ونفس الحدّ الأدنى للارتفاع', () {
      final bar = src('lib/widgets/village_weather_bar.dart');
      expect(
        RegExp(r'EdgeInsets\.fromLTRB\(14, 2, 14, 6\)').allMatches(bar).length,
        2,
      );
      expect(
        RegExp(r'BoxConstraints\(minHeight: 58\)').allMatches(bar).length,
        2,
      );
    });

    test('صورة الخلفية الداكنة وحجابها الأسود خرجا من الكارت', () {
      final bar = src('lib/widgets/village_weather_bar.dart');
      expect(bar, isNot(contains('wither.jpg')));
    });

    test('الكارت يفوّض للحالة العربية المشتركة ولا يعيد اختراعها', () {
      final bar = src('lib/widgets/village_weather_bar.dart');
      expect(
        bar,
        contains('WeatherFormat.conditionAr(iconId, description)'),
      );
      expect(bar, isNot(contains('_conditionAr(')));
      expect(bar, contains('WeatherFormat.iconUrl(iconId)'));
      expect(bar, contains('WeatherFormat.iconGlyph(iconId)'));
      // الرابط لا يُكتب في الواجهة: كل مواضع العرض تستدعي `iconUrl` وحدها.
      expect(bar, isNot(contains('openweathermap.org/img')));
    });
  });

  group('صفحة الطقس: أيقونات المزود وتنسيق الأقسام', () {
    test('الحالة تُقرأ من مفتاح أيقونة المزود (سلوكًا، لا نصًا في الواجهة)', () {
      expect(WeatherFormat.conditionAr('01d', 'clear sky'), 'مشمس');
      expect(WeatherFormat.conditionAr('02n', 'few clouds'), 'غائم جزئيًا');
      expect(WeatherFormat.conditionAr('03d', 'scattered clouds'), 'غائم');
      expect(WeatherFormat.conditionAr('04d', 'broken clouds'), 'غائم كليًا');
      expect(WeatherFormat.conditionAr('09d', 'shower rain'), 'ممطر');
      expect(WeatherFormat.conditionAr('10d', 'rain'), 'ممطر');
      expect(WeatherFormat.conditionAr('11d', 'thunderstorm'), 'عاصفة رعدية');
      expect(WeatherFormat.conditionAr('13d', 'snow'), 'ثلوج');
      expect(WeatherFormat.conditionAr('50d', 'mist'), 'ضباب');
    });

    test('مفتاح مجهول يرجع لوصف المزود العربي المُنقَّح، وغياب الاثنين صادق', () {
      expect(WeatherFormat.conditionAr('99d', '  غائم جزئيًا '), 'غائم جزئيًا');
      expect(WeatherFormat.conditionAr(null, 'وصف من المزود'), 'وصف من المزود');
      expect(WeatherFormat.conditionAr('99d', ''), '—');
      expect(WeatherFormat.conditionAr(null, null), '—');
      expect(WeatherFormat.conditionAr('1', 'خبر'), 'خبر');
    });

    test('روابط الأيقونات من المزود نفسه، بالمقاسين الكبير والصغير', () {
      expect(
        WeatherFormat.iconUrl('10d'),
        'https://openweathermap.org/img/wn/10d@2x.png',
      );
      expect(
        WeatherFormat.iconUrl('10d', big: true),
        'https://openweathermap.org/img/wn/10d@4x.png',
      );
    });

    test('رمز الرجوع لكل حالة رمزٌ مختلف — سحابة واحدة كانت تُخفي اختلاف الطقس', () {
      expect(WeatherFormat.iconGlyph('01d'), Icons.wb_sunny_rounded);
      expect(WeatherFormat.iconGlyph('02d'), Icons.wb_cloudy_rounded);
      expect(WeatherFormat.iconGlyph('03d'), Icons.cloud_rounded);
      expect(WeatherFormat.iconGlyph('04d'), Icons.cloud_queue_rounded);
      expect(WeatherFormat.iconGlyph('09d'), Icons.water_drop_rounded);
      expect(WeatherFormat.iconGlyph('10n'), Icons.water_drop_rounded);
      expect(WeatherFormat.iconGlyph('11d'), Icons.thunderstorm_rounded);
      expect(WeatherFormat.iconGlyph('13d'), Icons.ac_unit_rounded);
      expect(WeatherFormat.iconGlyph('50d'), Icons.blur_on_rounded);
      expect(WeatherFormat.iconGlyph('99d'), Icons.cloud_rounded);
      expect(WeatherFormat.iconGlyph(null), Icons.cloud_rounded);
      // الحالات الستّ المتمايزة لا تسقط في رمز واحد.
      expect(
        {
          WeatherFormat.iconGlyph('01d'),
          WeatherFormat.iconGlyph('03d'),
          WeatherFormat.iconGlyph('09d'),
          WeatherFormat.iconGlyph('11d'),
          WeatherFormat.iconGlyph('13d'),
          WeatherFormat.iconGlyph('50d'),
        }.length,
        6,
      );
      // التسمية والرمز من سلة واحدة: مفتاح يقول «ممطر» لا يجوز أن يرمز بضباب.
      for (final id in ['01d', '02d', '03d', '04d', '09d', '11d', '13d', '50d']) {
        final labelled = WeatherFormat.conditionAr(id, '');
        expect(labelled == '—', false, reason: 'التسمية سقطت للمفتاح $id');
      }
    });

    test('صفحة الطقس: الهيرو بالمقاس الكبير، ورموز الرجوع في مواضعها الأربعة', () {
      final w = src('lib/features/weather/weather_detail_screen.dart');
      expect(
        w,
        contains("WeatherFormat.iconUrl(weather['icon'], big: true)"),
      );
      expect(
        RegExp(r'WeatherFormat\.iconGlyph\(').allMatches(w).length,
        4,
      );
    });

    test('رابط أيقونات المزود حرفٌ واحد في كل `lib` — داخل `iconUrl` وحدها', () {
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      final hits = <String>[];
      for (final f in files) {
        final count = RegExp(r'openweathermap\.org/img')
            .allMatches(f.readAsStringSync())
            .length;
        if (count > 0) hits.add('${f.path}::$count');
      }
      expect(hits.length, 1);
      expect(hits.single, endsWith('weather_service.dart::1'));
    });

    test('الشاشة مقسّمة بعناوين، وكل لوحاتها من زخرفة واحدة', () {
      final w = src('lib/features/weather/weather_detail_screen.dart');
      expect(w, contains('Widget _sectionTitle(String title, {String? note})'));
      expect(w, contains("_sectionTitle('الآن في القرية')"));
      expect(w, contains("_sectionTitle('تفاصيل الحالة')"));
      expect(w, contains("_sectionTitle('الطقس اليوم')"));
      expect(w, contains("_sectionTitle('الأيام القادمة'"));
      expect(w, contains("_sectionTitle('توقع الساعات القادمة')"));
      expect(w, contains('BoxDecoration get _panel'));
      // `decoration: _panel,` خمسة مواضع (البطاقات + صفوف الأيام + اللوح الأفقي + حالة الفراغ)
      expect(
        RegExp(r'decoration: _panel,').allMatches(w).length,
        5,
      );
    });

    test('لا نص إنجليزي خام يصل للمستخدم — الرمز الإنجليزي كان العلّة', () {
      final w = src('lib/features/weather/weather_detail_screen.dart');
      expect(w, isNot(contains("weather['main']")));
      expect(
        RegExp(r'WeatherFormat\.iconUrl\(').allMatches(w).length,
        greaterThanOrEqualTo(4),
      );
      expect(w, contains('WeatherFormat.conditionAr('));
    });
  });
}
