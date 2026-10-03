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

    test('نصوص السجل سوداء واضحة لا رمادية باهتة', () {
      expect(src, contains('AppColors.textPrimary'));
      expect(src.contains('textTheme.bodySmall'), isFalse,
          reason: 'لا تعليق صغير باهت في بطاقة التفاصيل');
    });
  });
}
