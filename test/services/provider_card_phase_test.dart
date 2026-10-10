import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/widgets/full_fit_image.dart';

/// صورة مرفوعة بمقاس معروف النسبة لا تتوفّر في الاختبارات بلا شبكة، فالدليل
/// هنا على السلوكين الذين يراه المستخدم: البديل عند الغياب والفشل، والقواعد
/// الثابتة في المصدر (الطيّ، الحذف، إخفاء المُضيف، لوحة الإدارة).
List<String> _dartFiles([String dir = 'lib']) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .map((f) => f.path.replaceAll(r'\', '/'))
    .toList();

String _read(String path) => File(path).readAsStringSync();

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pumpAndSettle();
}

void main() {
  group('FullFitImage', () {
    testWidgets('بلا رابط: البديل في إطار مربّع وبلا أي صورة شبكية',
        (tester) async {
      await _pump(
          tester,
          FullFitImage(
            imageUrl: '',
            width: 80,
            fallback: Container(key: const Key('بديل'), color: Colors.blue),
          ));

      expect(find.byKey(const Key('بديل')), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      final box = tester.getSize(find.byType(FullFitImage));
      expect(box, const Size(80, 80));
    });

    testWidgets('رابط لا يُحل: الإطار يحتفظ بعرضه وبلا استثناء',
        (tester) async {
      await _pump(
          tester,
          FullFitImage(
            imageUrl: 'https://example.invalid/no-such-image.jpg',
            width: 90,
            fallback: Container(key: const Key('بديل'), color: Colors.blue),
          ));

      // قياس النسبة يفشل في بيئة الاختبار (HTTP محجوب) ⇒ النسبة تسقط إلى 1.0،
      // فالإطار يبقى مربّعًا بعرض الطلب ولا ينهار التخطيط.
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(FullFitImage)), const Size(90, 90));
    });

    testWidgets('مقاس مثبّت: الإطار عند الارتفاع المعلوم ولا قياس للنسبة',
        (tester) async {
      await _pump(
          tester,
          FullFitImage(
            imageUrl: 'https://example.invalid/tall.jpg',
            width: 100,
            fixedHeight: 120,
            fallback: Container(key: const Key('بديل'), color: Colors.blue),
          ));

      // الارتفاع المعلوم يُطاع حرفيًا ولو كانت النسبة ستعطي غيرَه — وهذا جوهر
      // «ثبّت الحجم للجميع في الكروت».
      expect(tester.getSize(find.byType(FullFitImage)), const Size(100, 120));
    });

    test('المقاس المثبّت يُعفي من القياس (عقد المصدر)', () {
      final src = _read('lib/widgets/full_fit_image.dart');
      expect(src, contains('if (widget.fixedHeight != null) return;'),
          reason: 'لا فكّ للصورة ولا كاش نسبة when الارتفاع معلوم — بطاقة القائمة');
      expect(src, contains('if (widget.fixedHeight != null) return widget.fixedHeight!;'),
          reason: 'الارتفاع المثبّت يُطاع قبل فرع الفراغ والفشل');
    });

    test('فشل الصورة يرجع للبديل لا لمربّع فارغ (عقد المصدر)', () {
      final src = _read('lib/widgets/full_fit_image.dart');
      expect(src, contains('errorWidget: (_, __, ___) {'));
      expect(src, contains('return widget.fallback;'),
          reason: 'الرابط الميت يُبدَّل بالبديل المربّع');
      expect(src, contains('.clamp(minRatio, maxRatio)'),
          reason: 'الحصر باقٍ — انتقل إلى دالة الارتفاع المشتركة');
      expect(src,
          contains('minRatio: widget.minRatio, maxRatio: widget.maxRatio'),
          reason: 'الوست يمرّ حدَّيه فلا يفقدهما بالتحويل إلى الدالة العامة');
    });

    test('النسب المتطرفة مقصوصة بين الحدَّين', () {
      // الارتفاع = العرض ÷ النسبة، والنسبة تُقصّ بين minRatio و maxRatio،
      // فأطول إطار مسموح = العرض ÷ minRatio وأقصره = العرض ÷ maxRatio.
      const defaults =
          FullFitImage(imageUrl: '', width: 100, fallback: SizedBox());
      expect(defaults.minRatio, 0.72);
      expect(defaults.maxRatio, 1.5,
          reason: 'لا شريط رفيع ولا مربّع ضخم داخل البطاقة');
      expect(100 / defaults.minRatio, inInclusiveRange(138, 139));
      expect(100 / defaults.maxRatio, 66.66666666666667);
      expect(defaults.radius, 12);
    });
  });

  group('عقد المصدر — صورة السجل كاملة', () {
    const card = 'lib/features/services/service_directory_screen.dart';
    const detail = 'lib/features/services/service_provider_detail_screen.dart';

    test('البطاقة والتفاصيل تمرّان صورة السجل عبر FullFitImage', () {
      for (final path in [card, detail]) {
        final src = _read(path);
        expect(src, contains('FullFitImage('), reason: path);
        expect(src, contains("imageUrl: provider.photoUrl ?? ''"),
            reason: '$path: نفس الحقل يغذّي الصورة الكاملة');
        expect(src.contains('CachedNetworkImage(imageUrl: provider.photoUrl'),
            isFalse,
            reason: '$path: لا تربيع ولا اقتصاص لصورة السجل');
      }
    });

    test('كروت القائمة بمقاس صورة مثبّت، والتفاصيل بقيت بمساحة محسوبة', () {
      // «لا تجعل الكارت يغيّر حجمه بناءً على صورة الفني» = الارتفاع يُمرَّر
      // ثابتًا في البطاقة؛ «ولكنها تتغير في التفاصيل وتظهر بمساحة محسوبة» =
      // شاشة التفاصيل لا تمرّر مقاسًا فتقيس النسبة وترسم بها.
      final cardSrc = _read(card);
      expect(cardSrc, contains('fixedHeight: _kImageSide'),
          reason: 'بطاقة القائمة: مربّع مثبّت لكل السجلات');
      expect(_read(detail).contains('fixedHeight'), isFalse,
          reason: 'التفاصيل تُقاس نسبتها فلا تفقّر المساحة المحسوبة');

      // العرض وحده لا يكفي: بلا تجميد الارتفاع كانت البطاقة تطول وتقصر.
      final cardUses = RegExp('fixedHeight: _kImageSide').allMatches(cardSrc);
      expect(cardUses.length, 1, reason: 'موضع البطاقة وحده في القائمة');
    });

    test('هيدر التفاصيل لا يحمل بانرًا مصوَّرًا، والصورة كاملة في _heroPhoto',
        () {
      final src = _read(detail);
      final start = src.indexOf('MedDetailHeader(');
      expect(start, greaterThan(-1));
      final headerArgs = src.substring(start, src.indexOf('icon:', start));
      expect(headerArgs, contains("imageUrl: ''"),
          reason: 'MedDetailHeader يقصّ بـcover في شريط 210 ثابتًا');
      expect(headerArgs.contains('imageUrl: imageUrl'), isFalse);

      final hero = src.indexOf('Widget _heroPhoto');
      expect(hero, greaterThan(-1));
      final heroSrc = src.substring(hero, src.indexOf('_cardDeco', hero));
      expect(heroSrc, contains('FullFitImage('));
      expect(heroSrc, contains('maxRatio:'),
          reason: 'الصور الممتدة تُرى كاملة بشريط أقصر لا باقتصاص');
      expect(heroSrc, contains('imageUrl.isEmpty'),
          reason: 'سجل بلا صورة ⇒ لا بانر فارغ فوق البطاقات');
    });

    test('cover في صفحة الفئة بقي لصورة الصفة والمعاينة فقط', () {
      final lines = _read(card).split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('BoxFit.cover')) continue;
        final block =
            lines.skip((i - 5).clamp(0, lines.length)).take(7).join('\n');
        expect(block.contains('Image.asset') || block.contains('CircleAvatar'),
            isTrue,
            reason: 'BoxFit.cover عند السطر ${i + 1} بلا مربّع مربوطة به');
      }
    });
  });

  group('عقد المصدر — البطاقة لا تتجاوز خمسة أسطر', () {
    // «عدم تجاوز الكارت حجم 5 أسطر» عند رسم البطاقة: سطر العنوان، سطر
    // التقييم، سطر الرقائق، سطر النبذة، شريط الأزرار. فما كان ينمو بعدد
    // مراحل السجل وأنواع تعليمه (الرقائق) وبسطرين للنبذة هو من يُجمَّد،
    // لا الحشو ولا مقاس الصورة.
    const card = 'lib/features/services/service_directory_screen.dart';
    final src = _read(card);

    test('سطر المواد على سطرٍ واحد والاقتصار عليه صريح', () {
      final start = src.indexOf('List<Widget> _eduTags(ThemeData theme) {');
      expect(start, greaterThan(-1));
      final tags =
          src.substring(start, src.indexOf('List<Widget> _cardChips', start));
      expect(tags, contains('provider.displaySpecialty'),
          reason: 'سطر المواد هو ما كان يلتفّ فيطيل الكارت');
      expect(tags, contains('maxLines: 1'));
      expect(tags, contains('overflow: TextOverflow.ellipsis'));
    });

    test('النبذة سطرٌ واحد في البطاقة التعليمية وسطران لغيرها', () {
      expect(
          src,
          contains('maxLines: provider.isEducational ? 1 : 2'),
          reason: '«5 أسطر» تُحسب على البطاقة التعليمية لا على حرفي');
      // النص الكامل يبقى حيث يُقرأ: تفاصيل السجل ونص المشاركة.
      expect(_read('lib/features/services/service_provider_detail_screen.dart'),
          contains('provider.description'));
      expect(src, contains('provider.description'),
          reason: 'نص المشاركة يبني أسطره من نفس النموذج');
    });

    test('رقائق البطاقة بمعدودٍ معلن يشمل رقيقة العدّ', () {
      expect(src, contains('static const int _kMaxCardChips = 3;'));
      final start = src.indexOf('List<Widget> _cardChips(ThemeData theme) {');
      expect(start, greaterThan(-1));
      final chips =
          src.substring(start, src.indexOf('Widget _tag(ThemeData theme', start));
      // السقف جمعٌ لا حذف: ما خرج عن المعدود يُعلَن رقمًا ظاهرًا.
      expect(chips, contains("'+\$hidden'"),
          reason: 'الباقي يُعدّ ولا يُسقَط في صمت');
      expect(chips, contains('if (total <= _kMaxCardChips)'),
          reason: 'ما لا يتجاوز السقف يُرسم كله كما هو');
      // رقيقة العدّ تأكل خانةً من السقف، فلا يُرسم أبدًا أربعة.
      expect(chips, contains('final keep = private == null ? _kMaxCardChips - 1 : 1;'),
          reason: 'ثلاثة مرسومة فعلًا لا ثلاثة + عدّ');
      expect(chips, contains('leading.take(keep)'));
      // «تدريس خاص» في موضع محفوظ: هو ما تفتحه مرشّحات الصفحة.
      expect(chips, contains('if (private != null) private'));
      expect(chips, contains("'تدريس خاص'"));
    });

    test('مقاس الصورة مثبّت عند ضلعٍ واحد لكل البطاقات', () {
      expect(src, contains('static const double _kImageSide = 104;'));
      // صورة الصفة الافتراضية تلبس نفس الضلع، فالبلا صورة لا تطيل الكارت.
      expect(src, contains('width: _kImageSide'));
      expect(src, contains('height: _kImageSide'));
    });

    test('زرّا الاتصال والمشاركة بقيا على تصميمهما المصمت بمقاس مصغّر', () {
      // لم تكن هذه مصغَّرة في هذه الموجة — هي كذلك منذ التزامٍ سابق؛ العقد
      // هنا يمنع رجوعها ضخمة مع بقاء ألوانها ورموزها كما هي.
      final start = src.indexOf('Widget _miniAction(');
      expect(start, greaterThan(-1));
      final mini = src.substring(start, src.indexOf('_share()', start));
      // المقاس المُصمَّت يُقرأ من سطر الحجة نفسه: المترسّق يضعه في سطرٍ مستقل،
      // فمطابقة «SizedBox(height: 32» لن تطابق أبدًا بلا إعادة تنسيق الكود.
      expect(mini, contains('return SizedBox('));
      expect(mini, contains('height: 32,'));
      expect(mini, contains('VisualDensity.compact'));
      expect(mini, contains('MaterialTapTargetSize.shrinkWrap'));
      expect(mini, contains('FilledButton.icon'), reason: 'نفس تصميم الزر');
      for (final color in ['kCallButtonColor', 'kShareButtonColor']) {
        expect(src, contains('$color,'), reason: '$color يصل الزر كما كان');
      }
      expect(src, contains('Icons.call_rounded'));
      expect(src, contains('Icons.share_rounded'));
    });
  });

  group('عقد المصدر — كارت البحث والمرشّحات', () {
    final src = _read('lib/features/services/service_directory_screen.dart');

    test('مطويّ افتراضيًا والرأس يحمل الشارة والملخص والمسح', () {
      expect(src, contains('bool _filtersOpen = false;'));
      for (final key in [
        "Key('filters-toggle')",
        "Key('filters-count')",
        "Key('filters-clear')",
        "Key('provider-search')"
      ]) {
        expect(src, contains(key), reason: key);
      }
      expect(src, contains('child: _filtersOpen'),
          reason: 'جسم الكارت مشروط بالفتح لا مُزال من الشجرة');
    });

    test('الملخص يُطبع في الرأس حين يُطوى الكارت', () {
      expect(src, contains('_filtersOpen || summary.isEmpty'));
      expect(src, contains("'بحث: \${_search.text.trim()}'"),
          reason: 'كلمة البحث جزء من الملخص فلا تضيع بالطيّ');
    });
  });

  group('عقد المصدر — حذف التعليقات', () {
    const sites = {
      'lib/features/news/view.dart': 'news-comment-delete-',
      'lib/features/forum/post_detail.dart': 'forum-comment-delete-',
      'lib/features/services/service_provider_detail_screen.dart':
          'comment-delete-',
    };

    test('كل مواضع التعليقات: الأدمن أو صاحب التعليق', () {
      sites.forEach((path, keyPrefix) {
        final src = _read(path);
        expect(src, contains('_canModerate'), reason: path);
        expect(src, contains('Future<void> _deleteComment'), reason: path);
        expect(src, contains("key: ValueKey('$keyPrefix"), reason: path);
        expect(RegExp(r'_(currentUid|currentUserId)\.isNotEmpty').hasMatch(src),
            isTrue,
            reason: '$path: مقارنة معرّف الكاتب بالمعرّف الحالي');
        expect(src, contains('حذف التعليق'), reason: path);
      });
    });

    test('الحذف بعد تأكيد ويُبْلَّغ نتيجته بصدق', () {
      for (final path in sites.keys) {
        final src = _read(path);
        expect(src, contains('AlertDialog'), reason: '$path: حوار تأكيد');
        expect(src, contains('تأكد'), reason: '$path: حذف بغير تأكيد ممنوع');
      }
    });
  });

  group('عقد المصدر — اسم المُضيف خارج لوحة الإدارة', () {
    test('لا شاشة مستخدم تعرض «من أضاف البيان»', () {
      // العبارات الحاملة للاسم في الواجهة نصوص داخل سطور برمجية لا شروحات،
      // فالشروح (///) تُتخطّى وإلا اتُّهم تعليق موثّق أنه واجهة.
      final offenders = <String>[];
      for (final path in _dartFiles()) {
        if (path.contains('/features/admin/')) continue;
        for (final line in _read(path).split('\n')) {
          final t = line.trim();
          if (t.startsWith('//')) continue;
          if (t.contains('أضافها') ||
              t.contains('أضافه') ||
              t.contains('اسم المُضيف') ||
              t.contains('المضيف')) {
            offenders.add('$path: $t');
          }
        }
      }
      expect(offenders, isEmpty);
    });

    test('لوحة الإدارة تحتفظ باسم مقدّم البيان', () {
      expect(_read('lib/features/admin/admin_detail.dart'),
          contains("'submittedByName': 'مقدّم البيان'"));
      expect(_read('lib/features/admin/admin_edit.dart'),
          contains('اسم صاحب الإعلان'));
      expect(_read('lib/features/admin/admin_edit.dart'),
          contains('اسم مقدم الطلب'));
    });
  });

  group('عقد المصدر — لوحة الإدارة تعكس التعديلات الأخيرة', () {
    test('بطاقة المراجعة تُظهر صفة السجل التعليمي', () {
      final src = _read('lib/features/admin/admin_dashboard_review.dart');
      expect(src, contains("key: ValueKey('review-edu-kind-\$id')"));
      expect(src, contains('EduKindMark(kind: _eduKind, size: 12)'));
      expect(src, contains('item[\'category\'] != ServiceCategory.educational'),
          reason: 'سجل الحرفيين بلا صفة معروضة');
      expect(src, contains('kind.isEmpty ? kEduKindTeacher : kind'),
          reason: 'السجل القديم بلا providerKind يُعامل كمدرّس');
    });

    test('تفاصيل الإدارة تسمّي حقول الصورة بالعربية', () {
      final src = _read('lib/features/admin/admin_detail.dart');
      for (final label in [
        "'photoUrl': 'صورة السجل'",
        "'imageUrl': 'الصورة'",
        "'imageUrls': 'الصور'"
      ]) {
        expect(src, contains(label), reason: label);
      }
    });

    test('تعديل الإدارة يضم حقول السجل التعليمي ورابط صورته', () {
      final src = _read('lib/features/admin/admin_edit.dart');
      for (final field in [
        "'providerKind'",
        "'eduTypes'",
        "'stages'",
        "'subjects'",
        "'universityNote'",
        "'offersPrivateTutoring'",
        "'photoUrl'"
      ]) {
        expect(src, contains(field), reason: field);
      }
    });
  });

  group('عقد المصدر — خطوط وألوان بطاقة التفاصيل', () {
    final src =
        _read('lib/features/services/service_provider_detail_screen.dart');

    test('أحجام مشتركة بدل التكرار لكل عنصر', () {
      expect(src, contains('const double _kChipText'));
      expect(src, contains('const double _kLabel'));
      expect(src, contains('const double _kBody'));
      final uses = 'fontSize: _k'.allMatches(src).length;
      expect(uses, greaterThanOrEqualTo(6),
          reason: 'الثوابت مستعملة فعلًا لا معرّفة فقط');
    });

    test('نصوص السجل تُقرأ من حبر الثيم فتبقى مقروءة في السمتين', () {
      // الحبر من `colorScheme.onSurface` لا من ثابت مجمّد: في الفاتح هو حبر
      // العائلة الداكن وفي الداكن حبر فاتح، فثابت «أسود» واحد كان يجعل
      // بطاقة التفاصيل غير مقروءة في الوضع الداكن.
      expect(src, contains('theme.colorScheme.onSurface'));
      expect(src.contains('textTheme.bodySmall'), isFalse,
          reason: 'لا تعليق صغير باهت في بطاقة التفاصيل');
    });
  });
}
