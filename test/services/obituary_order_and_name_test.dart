import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/obituaries/list.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/widgets/obituary_share_card.dart';

/// «سجل العزاء» بموجة ٢٠٢٦-١٠-٠٥: القائمة تُرتَّب بتاريخ الوفاة من الحديث إلى
/// القديم (في الكلاينت لا على الخادم)، واسم المتوفى في بطاقة المشاركة لا يأخذ
/// أكثر من سطر واحد مهما طال.
void main() {
  Obituary obit(
    String id, {
    String name = 'فلان',
    String dateOfDeath = '',
    DateTime? createdAt,
  }) =>
      Obituary(
        id: id,
        name: name,
        age: '',
        dateOfDeath: dateOfDeath,
        funeralDate: dateOfDeath,
        funeralLocation: 'مسجد القرية',
        condolenceLocation: 'منزل العائلة',
        createdAt: createdAt,
      );

  group('قراءة تاريخ الوفاة', () {
    test('الصيغتان المكتوبتان في السجلات تُقرآن، والفارغ وغير المقروء لا', () {
      expect(obituaryDeathDate('2026-10-01'), DateTime(2026, 10));
      expect(obituaryDeathDate('2026/10/01'), DateTime(2026, 10));
      expect(obituaryDeathDate('  2026/09/28  '), DateTime(2026, 9, 28));
      expect(obituaryDeathDate(''), isNull);
      expect(obituaryDeathDate('   '), isNull);
      expect(obituaryDeathDate('أمس'), isNull);
    });
  });

  group('الترتيب بتاريخ الوفاة حديثًا أولًا', () {
    test('الأحدث وفاةً يسبق الأقدم، مهما كان ترتيب الوصول', () {
      final list = [
        obit('old', dateOfDeath: '2026/09/20'),
        obit('new', dateOfDeath: '2026/10/01'),
        obit('mid', dateOfDeath: '2026/09/28'),
      ]..sort(compareObituaryByDeathDate);
      expect(list.map((o) => o.id), ['new', 'mid', 'old']);
    });

    test('تساوي تاريخ الوفاة يحسمه تاريخ الإنشاء (الأحدث أولًا كما كان)', () {
      final list = [
        obit('a',
            dateOfDeath: '2026/10/01', createdAt: DateTime(2026, 10, 1, 9)),
        obit('b',
            dateOfDeath: '2026/10/01', createdAt: DateTime(2026, 10, 1, 17)),
      ]..sort(compareObituaryByDeathDate);
      expect(list.map((o) => o.id), ['b', 'a']);
    });

    test('السجل بلا تاريخ وفاة يبقى بعد ذوي التواريخ، وداخلهم يحسم الإنشاء', () {
      final list = [
        obit('no_date_1', createdAt: DateTime(2026, 10, 4)),
        obit('dated', dateOfDeath: '2026/01/05'),
        obit('no_date_2', createdAt: DateTime(2026, 10, 2)),
      ]..sort(compareObituaryByDeathDate);
      expect(list.map((o) => o.id), ['dated', 'no_date_1', 'no_date_2']);
    });

    test('تاريخ وفاة غير مقروء لا يُفقد السجل ولا يُقدَّم على الصحيح', () {
      final list = [
        obit('garbage', dateOfDeath: 'غير محدد'),
        obit('good', dateOfDeath: '2026/09/30'),
      ]..sort(compareObituaryByDeathDate);
      expect(list.map((o) => o.id), ['good', 'garbage']);
    });
  });

  group('اسم المتوفى في بطاقة المشاركة', () {
    ui.Image solid(int w, int h) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
          ui.Paint()..color = const Color(0xFF123456));
      return recorder.endRecording().toImageSync(w, h);
    }

    Widget cardOf(Obituary o) => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: ObituaryShareCard(
                obituary: o,
                background: solid(60, 80),
                photo: solid(40, 50),
                width: 340,
              ),
            ),
          ),
        );

    const longName =
        'الفاضل الحاج عبد الرحمن محمد السيد أحمد أبو ديشيشة العبد الله';

    testWidgets('الاسم الطويل سطر واحد داخل FittedBox، وبلا فيضان',
        (tester) async {
      await tester.pumpWidget(cardOf(obit('o1', name: longName)));
      expect(tester.takeException(), isNull);

      final name = find.text(longName);
      expect(name, findsOneWidget);
      expect(
        find.descendant(of: find.byType(FittedBox), matching: name),
        findsOneWidget,
        reason: 'الاسم يمرّ بمقياس يصغّره بدل أن يلتفّ على أسطر',
      );
      expect(tester.widget<Text>(name).maxLines, 1);

      // السطر الواحد يعني أن ارتفاع النص أقل من سطرَين بمقاسه الأصلي (٢٦).
      final box = tester.getSize(name);
      expect(box.height, lessThan(52.0),
          reason: 'ارتفاع الاسم في حدود سطر واحد لا سطرَين');
    });

    testWidgets('الاسم القصير لا يُصغَّر: يبقى بمقاسه الأصلي', (tester) async {
      await tester.pumpWidget(cardOf(obit('o2', name: 'محمد')));
      expect(tester.takeException(), isNull);
      final box = tester.getSize(find.text('محمد'));
      // سطر بمقاس ٢٦ وارتفاع ١٫٣٥ ≈ ٣٥، فأي صعود فوق ٤٠ يعني التفافًا.
      expect(box.height, lessThan(40.0));
      expect(box.width, lessThan(120.0), reason: 'لم يُشدّ إلى عرض البطاقة');
    });
  });

  group('عقود المصدر', () {
    final list = File('lib/features/obituaries/list.dart').readAsStringSync();
    final card =
        File('lib/widgets/obituary_share_card.dart').readAsStringSync();

    test('القائمة تفرز بالمقارنة الواحدة ولا تفرز على الخادم', () {
      expect(list, contains('list.sort(compareObituaryByDeathDate)'));
      expect(list, isNot(contains('orderBy(')),
          reason: 'الفرز الخادمي يُسقط أي سجل لا يملك الحقل المرتَّب عليه');
    });

    test('اسم البطاقة محصور بسطر واحد يُقاس لا يلتفّ', () {
      final i = card.indexOf('FittedBox(');
      expect(i, greaterThan(-1), reason: 'الاسم داخل مقياس');
      final around = card.substring(i, i + 260);
      expect(around, contains('BoxFit.scaleDown'));
      expect(around, contains('maxLines: 1'));
    });
  });
}
