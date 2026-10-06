import 'package:flutter/material.dart';

/// عائلة ألوان واحدة: القيم التي **تتبدل** حين يختار المستخدم ثيمًا آخر.
///
/// الحقول هنا بيانات فقط لا منطق: كل قيمة منها لها نظير mutable في [AppColors]
/// ينسخه [AppColors.apply]، فالحقول تبقى أسماء وصفية واحدة لا مصفوفة مفاتيح
/// ضمنية يغلط فيها أحد. الدلالات (الأحمر للحذف، العنبري للمعلّق، الأخضر للنجاح،
/// الأزرق للمعلومات) ليست في هذا الصنف لأنها — عملاً بقاعدة التدقيق — **معنى**
/// لا **مظهر**، فتبقى واحدة في العائلات الثلاث لئلا ينقلب «حذف» إلى لون دافئ
/// في ثيم التراكوتا ويظن المستخدم أنه نجاح.
class AppThemeFamily {
  const AppThemeFamily({
    required this.id,
    required this.title,
    required this.caption,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
    required this.secondaryLight,
    required this.secondaryDark,
    required this.headerAccent,
    required this.mint,
    required this.sage,
    required this.page,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.onWarning,
    required this.darkPrimary,
    required this.darkPrimaryContainer,
    required this.darkAccent,
    required this.darkPage,
    required this.darkSurface,
    required this.darkInputFill,
    required this.darkHairline,
    required this.darkTextPrimary,
    required this.darkTextSecondary,
  });

  /// المعرّف المحفوظ في `SharedPreferences` — نص ثابت لا ترتيب قائمة، فإضافة
  /// عائلة رابعة أو إعادة ترتيب `AppThemes.all` لا تُبدّل مظهر من اختار سابقًا.
  final String id;

  /// الاسم الذي يراه المستخدم في «تخصيص مظهر التطبيق».
  final String title;

  /// سطر واحد يسمّي درجة اللون لا أرقامها: المستخدم يقارن الانطباع لا الـhex.
  final String caption;

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondary;
  final Color secondaryLight;
  final Color secondaryDark;
  final Color headerAccent;
  final Color mint;
  final Color sage;
  final Color page;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color onWarning;
  final Color darkPrimary;
  final Color darkPrimaryContainer;
  final Color darkAccent;
  final Color darkPage;
  final Color darkSurface;
  final Color darkInputFill;
  final Color darkHairline;
  final Color darkTextPrimary;
  final Color darkTextSecondary;

  /// دوائر الاختيار في الإعدادات: الأساس thenaccent ثم التخضير ثم أرضية الصفحة
  /// — وهي أربع قيم من العائلة نفسها، فاللوّاح لا يكذب على المظهر المطبَّق.
  List<Color> get swatch => [primary, secondaryLight, mint, page];
}

/// مصدر الألوان الواحد في التطبيق.
///
/// الحقول التالية لعائلة الثيم **mutable عن قصد**: كل ملفات التطبيق تقرأها
/// بـ`AppColors.primary` (أربعٌ ومئتا مرجعًا في ثلاثة وسبعين ملفًا)، فاختيار
/// ثيم من الإعدادات يكتب هذه القيم مرة واحدة في [apply] ثم يُعاد رسم الشجرة
/// كلها، بدل تعديل مواضع القراءة واحدًا واحدًا. القيم الافتراضية هي عائلة
/// الزمردي، ولذلك من لا يمسّ الإعدادات — ومن يجرّي اختبارًا بلا `apply` — يرى
/// التطبيق كما هو اليوم حرفيًا.
///
/// أما **الدلالات** (`error` و`warning` و`warningInk` و`success` و`info`
/// و`purple` و`teal`) فبقيت `const` ولا تتبدل مع العائلة ولا مع الوضع الداكن:
/// معانيها ثابتة (حذف/معلّق/نجاح) وتغييرها مع المظهر يكذب على المستخدم، وهي
/// أيضًا العقد المجمّدة في الاختبارات.
///
/// **الصدق على هذه القائمة:** تسعةٌ وعشرون حقلًا في [AppThemeFamily]، والمارّة
/// من المواضع التي تقرأ من هنا مباشرةً قليلة قياسًا بالقائمة: `primary` (53)
/// و`onWarning` (15) و`headerAccent` (4) و`primaryGradient` (5) و`primaryDark`
/// (2) و`darkPrimary` (2)، و`textPrimary` لا يقرأه كود التطبيق لكنه مقروء في
/// **أربعة** عقود اختبارات. الباقي (نحو اثنتين وعشرين قيمة) تكتبه [apply] ولا
/// يقرأه `lib/` إطلاقًا، لأن مسارها الفعلي إلى الشاشة هو `ColorScheme`:
/// `_buildLight`/`_buildDark` في `app_themes.dart` تأخذ **حقول العائلة** نفسها
/// (`f.mint`، `f.sage`، `f.page`…) فتصل متبدّلة عبر `Theme.of(context)`. أبقيتها
/// عمدًا لأنها سجلّ العائلة المقروء بلا استيراد ملف الثيم، وحذفها كان سيسقط
/// تلك العقود الأربعة — فذلك قرار صاحبها لا قرار هنا، وهي معلَنة لا منسية.
class AppColors {
  AppColors._();

  // ===== الزمردي: هوية التطبيق =====
  /// الشريط العلوي والأزرار الرئيسية والعناوين البارزة — البياض فوقه يجتاز 4.5
  /// في كل عائلة (الزمردي 9.64، الكحلي 17.85، التراكوتا 7.31) فلا حاجة لضبطه.
  static Color primary = const Color(0xFF1B4D3E);

  /// طرف التدرج الداكن (هيدر، أشرطة، بطاقات داكنة)
  static Color primaryDark = const Color(0xFF0E2A22);

  /// تعبئة تفاعلية على سطح فاتح (شارات، أزرار أيقونة، أزرار إرسال)
  static Color primaryLight = const Color(0xFF256A54);

  static Color secondary = const Color(0xFF256A54);

  /// الأخضر المشرق: أيقونات تفاعلية وشرائط — **رسومي فقط** فوق الأساسي الداكن
  /// (نسبته على البياض 3.19–4.10 حسب العائلة فلا يُستخدم كتابةً فوق الهيدر؛
  /// للكتابة فوقه [headerAccent]، وكتابةً على الصفحة يمرّ عبر [readableInk]).
  static Color secondaryLight = const Color(0xFF4E9F3D);
  static Color secondaryDark = const Color(0xFF1B4D3E);

  /// كتابة/أيقونات فوق [primary] — 6.77 في الزمردي، و9.90 كحليًّا و6.09 دافئًا
  static Color headerAccent = const Color(0xFFA9E7B0);

  // ===== التخضيرات الخفيفة: أرضيات الأزرار الفرعية والشرائح =====
  /// خلفية خفيفة للأزرار الفرعية والشرائح — مع [primary] 6.24–15.56 حسب
  /// العائلة، ومع النص الداكن فوقها 12.75 على الأقل في الثلاث.
  static Color mint = const Color(0xFFE3F4DC);

  /// تظليل البطاقات وأرضيات الأقسام
  static Color sage = const Color(0xFFEDF3EC);

  /// خلفية الصفحات العامة — فاتح نظيف مميّل للعائلة، والنص الداكن فوقه 13.9
  /// على الأقل في الثلاث.
  static Color page = const Color(0xFFF4F6F4);

  static Color background = const Color(0xFFFFFFFF);
  static Color surface = const Color(0xFFFFFFFF);
  static Color surfaceVariant = const Color(0xFFE8F0E6);

  // ===== النصوص على الفاتح =====
  static Color textPrimary = const Color(0xFF102A22);
  static Color textSecondary = const Color(0xFF333333);
  static Color textTertiary = const Color(0xFF5C6B62);

  // ===== الدلالات =====
  /// أحمر هادئ: للحذف والخروج الخطير فقط (ليس للأخطاء العامة ولا للتنبيه الحي).
  /// توحيدٌ للقيمة التي كانت `#E53935` هنا و`#B71C1C` في مواضع النماذج.
  static const Color error = Color(0xFFB71C1C);

  /// العنبري: الحالة الوسيطة (معلّق/بانتظار مراجعة/قيد الرفع) لا الخطأ.
  static const Color warning = Color(0xFFFF9800);

  /// حبر العنبري وحده: البياض فوقه 2.16 وحبر الشريط الفاتح 1.84–1.88 فالاثنان
  /// خارج الحدّ، أما حبر العائلة الداكن فيجتاز على العنبري (الزمردي 7.10،
  /// الكحلي 8.28، الدافئ 6.95) — لذا قيمته من العائلة لا ثابتة: يبقى داكنًا
  /// عديم التشبّع بالنسبة نفسها في الثلاث.
  static Color onWarning = const Color(0xFF0E2A22);

  /// العنبري حبرًا لا أرضيةً: العنبري نفسه كتابةً 2.16 على البياض و1.84–1.88 على
  /// النعناعي، وهذا البرونزي يجتاز 6.33–6.52 على البياض و5.56–5.68 على الفستقي،
  /// ويرفعه [inkOn] في الداكن إلى 10.02 على الأقل على البطاقة الداكنة فتبقى
  /// الدلالة واحدة في السمتين. يُستعمل لسطور «قيد المراجعة» لا للأرضيات.
  static const Color warningInk = Color(0xFF8D4E00);

  /// أخضر عشبي صريح للنجاح المؤكَّد — كان `#6F4E37` أي نفس لون الهوية فلا يُميَّز.
  static const Color success = Color(0xFF047857);

  static const Color info = Color(0xFF1E88E5);
  static const Color purple = Color(0xFF7B1FA2);
  static const Color teal = Color(0xFF00897B);

  /// فاصل البطاقات — من العائلة لأنه درجة محايدة مائلة للمظهر: الفاصل الكحلي
  /// أزرق باهت والدافئ رمليّ باهت، فإبقاؤه زمرديًا في ثيم التراكوتا يُبقي
  /// «بردًا» في صفحة دافئة.
  static Color divider = const Color(0xFFDDE7E1);

  // ===== قيم الوضع الداكن (يستعملها app_theme وحده) =====
  /// زمردي مختلف عن الفاتح كما طُلب: أعمق وأقل تشبّعًا حتى لا يلسع على الأسود.
  static Color darkPrimary = const Color(0xFF0B3D2E);
  static Color darkPrimaryContainer = const Color(0xFF12332A);
  static Color darkAccent = const Color(0xFF34D399);
  static Color darkPage = const Color(0xFF0C1512);
  static Color darkSurface = const Color(0xFF14201B);
  static Color darkInputFill = const Color(0xFF1B2A25);

  /// الحدّ الفاصل: فصل البطاقة عن الصفحة 1.09–1.11 فقط، فلا تكفي الخلفية وحدها؛
  /// هذا الخط نفسه يجتاز 1.32–1.51 على البطاقة الداكنة و1.44–1.67 على الصفحة،
  /// أي أنه تمييز بصري لا بوابة تباين — ولحقول الإدخال اشتقاق أقوى في الثيم.
  static Color darkHairline = const Color(0xFF2A3B34);
  static Color darkTextPrimary = const Color(0xFFE6F1EA);
  static Color darkTextSecondary = const Color(0xFFA9BDB3);

  /// يكتب العائلة كاملةً في الحقول أعلاه — **السطر الوحيد الذي يعرف قيم
  /// الثيمات**، فلا يبقى أي لون مظهر مبعثرًا في ملف آخر. يُنادى مرة واحدة عند
  /// الإقلاع (من [ThemeService.loadTheme]) ومرة عند كل اختيار في الإعدادات،
  /// ثم يتكفّل `AnimatedBuilder` فوق `MaterialApp` بإعادة رسم الشجرة بالقيم
  /// الجديدة بلا إعادة تشغيل ولا إعادة تركيب المكدّس.
  static void apply(AppThemeFamily f) {
    primary = f.primary;
    primaryDark = f.primaryDark;
    primaryLight = f.primaryLight;
    secondary = f.secondary;
    secondaryLight = f.secondaryLight;
    secondaryDark = f.secondaryDark;
    headerAccent = f.headerAccent;
    mint = f.mint;
    sage = f.sage;
    page = f.page;
    background = f.surface;
    surface = f.surface;
    surfaceVariant = f.surfaceVariant;
    textPrimary = f.textPrimary;
    textSecondary = f.textSecondary;
    textTertiary = f.textTertiary;
    divider = f.divider;
    onWarning = f.onWarning;
    darkPrimary = f.darkPrimary;
    darkPrimaryContainer = f.darkPrimaryContainer;
    darkAccent = f.darkAccent;
    darkPage = f.darkPage;
    darkSurface = f.darkSurface;
    darkInputFill = f.darkInputFill;
    darkHairline = f.darkHairline;
    darkTextPrimary = f.darkTextPrimary;
    darkTextSecondary = f.darkTextSecondary;
    primaryGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, primaryDark],
      stops: const [0.0, 1.0],
    );
  }

  /// تدرّج الهيدر والبطاقات الداكنة — طرفاه [primary] و[primaryDark]، لذا
  /// يُعاد بناؤه في [apply] لا يبقى `const` (لو بقي لتجمّد على الزمردي).
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
    stops: const [0.0, 1.0],
  );

  /// لون التمييز نفسه حبرًا لا أرضيةً: يبقى كما هو في الفاتح، وفي الداكن يُرفع
  /// سطوعه على نظام HSL (وهو رتيب على ثابتَي اللون والتشبّع) إلى 0.70 كحدّ أدنى،
  /// فكل تمييز القرية — من `#311B92` إعلانات القرية 1.36 إلى `#EF6C00` الحرفيين —
  /// يجتاز 4.5 على الأرضية الداكنة. لا يُستعمل هذا على التظليلات ولا الأيقونات
  /// الرسومية فوق الهيدر.
  static Color inkOn(Color accent, Brightness brightness) {
    if (brightness == Brightness.light) return accent;
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withLightness(hsl.lightness < 0.70 ? 0.70 : hsl.lightness)
        .toColor();
  }

  /// نسبة التباين بين حبر وأرضية، بالترتيب الصاعد دائمًا.
  static double contrastRatio(Color ink, Color floor) {
    final a = ink.computeLuminance();
    final b = floor.computeLuminance();
    return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
  }

  /// حبرُ تمييزٍ مضمونُ القراءة فوق أرضية السمَت: يترك درجة القسم كما هي إن
  /// اجتازت الحدّ، وإلا زحزح **السطوع وحده** على HSL (ثابتا اللون والتشبّع
  /// محفوظان فلا يتغيّر معنى القسم) — تُظلم في الفاتح وتُنار في الداكن — حتى
  /// يبلغ النسبة المطلوبة. الحدّ الافتراضي 4.5 وهو سقف النص العادي؛ للأرقام
  /// الكبيرة والأيقونات الرسومية يُمرّر 3.0.
  ///
  /// لا يُستعمل هذا على أرضيات الأزرار ولا على التظليلات والحدود ذات الشفافية،
  /// بل على الكتابة والأيقونات فقط، لأن [inkOn] وحده يعجز عن القيمة الفاتحة في
  /// الفاتح (العنبري `#FF9800` 2.16 على البياض فلا تُقرأ مطلقًا).
  static Color readableInk(Color accent, Brightness brightness,
      {double minRatio = 4.5}) {
    final dark = brightness == Brightness.dark;
    final floor = dark ? darkSurface : surface;
    var current = inkOn(accent, brightness);
    if (contrastRatio(current, floor) >= minRatio) return current;
    final hsl = HSLColor.fromColor(current);
    var lightness = hsl.lightness;
    // اثنان وأربعون خطوة بمقدار 0.02 تكفي الوصول إلى أي حدّ على الطرفين:
    // السطوع 0.02 داكنٌ كالفحم و0.98 أبيضٌ شبه صافٍ، فالاثنان يجتازان 4.5.
    for (var i = 0; i < 42; i++) {
      lightness = (lightness + (dark ? 0.02 : -0.02)).clamp(0.0, 1.0);
      current = hsl.withLightness(lightness).toColor();
      if (contrastRatio(current, floor) >= minRatio) return current;
    }
    return current;
  }

  /// أرضيةٌ **مصمتة** بلون التمييز يُكتب فوقها البياض: يترك درجة القسم كما هي
  /// إن اجتاز البياضُ عليها الحدّ، وإلا زحزح **السطوع وحده** نزولًا (اللون
  /// والتشبّع محفوظان) حتى يجتازه. للأيقونات والشرائط الرسومية، والحدّ الافتراضي
  /// 3.0 هو سقف الرسم لا النص.
  ///
  /// السبب: الدرج الفاتحة لا تقبل البياض حبرًا — العنبري `#FFC107` 1.63،
  /// برتقالي `#FF9800` 2.16، السماوي `#00BCD4` 2.30، الأخضر `#4CAF50` 2.78 —
  /// فالتظليل وحده لا يكفي لأن الأرضية هنا مصمتة لا شفافة، وتغيير الحبر إلى
  /// داكن يكذب على بقية الشرائط المصمتة في التطبيق. ما يُشتق من هذه الأرضية
  /// أغمقُ منها حتمًا (تدرّج نحو الأسود) فيبقى البياض مجتازًا على طرفَيه، فلا
  /// حاجة لقياس الطرف الداكن.
  static Color readablePlate(Color accent, {double minRatio = 3.0}) {
    var current = accent;
    if (contrastRatio(Colors.white, current) >= minRatio) return current;
    final hsl = HSLColor.fromColor(accent);
    var lightness = hsl.lightness;
    for (var i = 0; i < 42; i++) {
      lightness = (lightness - 0.02).clamp(0.0, 1.0);
      current = hsl.withLightness(lightness).toColor();
      if (contrastRatio(Colors.white, current) >= minRatio) return current;
    }
    return current;
  }
}
