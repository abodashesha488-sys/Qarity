import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/obituaries/add.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/widgets/obituary_share_card.dart';

/// «قرابة أخرى — اكتبها بنفسك»: نوع القرابة واسم القريب يُدخَلان مكتوبين،
/// فيُخزَّن النوع نصًا ويظهر في كل مواضع العرض بعنوانه الحرفي. المجموعات
/// الاثنتا عشرة والتسميات التراثية والسجلات القديمة تبقى كما هي.
void main() {
  Relative typed(String type, String name, {int order = 0}) => Relative(
      id: 'id_$type$name',
      name: name,
      type: RelativeType.other,
      typeLabel: type,
      order: order);

  Relative inGroup(RelativeType group, String name, {int order = 0}) =>
      Relative(id: 'id_$name', name: name, type: group, order: order);

  Obituary obitOf(
          {String gender = kObituaryGenderMale,
          List<Relative> relatives = const []}) =>
      Obituary(
        id: 'o1',
        name: 'فلان',
        age: '',
        gender: gender,
        dateOfDeath: '2026-09-28',
        funeralDate: '2026-09-29',
        funeralLocation: 'مسجد القرية الكبير',
        burialLocation: 'مدخل القرية',
        condolenceLocation: 'منزل العائلة',
        cardBackground: 'azaa2',
        relatives: relatives,
      );

  ui.Image solidImage(int w, int h) {
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
              background: solidImage(60, 80),
              photo: solidImage(40, 50),
              width: 340,
            ),
          ),
        ),
      );

  group('النموذج: نوع القرابة المكتوب', () {
    test('الحقل يُقرأ فارغًا عند غيابه ويُكتب دائمًا', () {
      final legacy = Relative.fromJson({
        'id': 'r1',
        'name': 'أحمد',
        'type': 'other',
        'phone': null,
        'order': 0,
      });
      expect(legacy.typeLabel, '');

      final written = typed('جار', 'أحمد').toJson();
      expect(written['typeLabel'], 'جار');
      expect(Relative.fromJson(written).typeLabel, 'جار');
      // السجل القديم يُعاد كتابته بالحقل الفارغ، فلا يختفي ولا يُختَرع له نوع.
      expect(legacy.toJson()['typeLabel'], '');
    });

    test('relativeSections: قسم لكل نوع حرفي وأسماءه في سطر واحد', () {
      final o = obitOf(relatives: [
        typed('جار', 'أحمد'),
        typed('عمّ والد', 'سليمان', order: 1),
        typed('جار', 'محمد', order: 2),
      ]);
      final sections = o.relativeSections;
      expect(sections.map((s) => s.label).toList(), ['جار', 'عمّ والد']);
      expect(sections.first.names, ['أحمد', 'محمد']);
      expect(sections.first.namesLine, 'أحمد، محمد');
    });

    test('المجموعات المفهرسة لا تتأثر: المكتوب لا يسكن «أخرى»', () {
      final o = obitOf(relatives: [
        inGroup(RelativeType.children, 'وليد'),
        typed('جار', 'أحمد'),
      ]);
      expect(o.namesOf(RelativeType.children), ['وليد']);
      expect(o.namesOf(RelativeType.other), isEmpty);
      // ترتيب العرض: المجموعات الاثنتا عشرة ثم المكتوبة ثم التراثية.
      expect(o.relativeSections.map((s) => s.label).toList(),
          ['والد كلاً من', 'جار']);
    });

    test('النوع المكتوب لا يُصرَّف بالنوع: يبقى كما كتبه صاحبه', () {
      final o = obitOf(
          gender: kObituaryGenderFemale,
          relatives: [typed('عم', 'رجب'), inGroup(RelativeType.paternalUncles, 'عايدة')]);
      final labels = o.relativeSections.map((s) => s.label).toList();
      expect(labels, containsAllInOrder(['عمّة كلاً من', 'عم']));
    });

    test('نوع بمسافات وحده لا يصنع قسمًا مكتوبًا، ويسقط تحت «أخرى» القديمة', () {
      // بلا نوعٍ مكتوب يرجع المفتاح `type` وحده، فهو سجل تراثي لا إدخال جديد،
      // والقراءة المتسامحة لا تخترع له عنوانًا.
      final blankType = obitOf(relatives: [typed('   ', 'أحمد')]);
      expect(blankType.customRelativeSections, isEmpty);
      expect(blankType.relativeSections.map((s) => s.label).toList(), ['أخرى']);

      final blankName = obitOf(relatives: [typed('جار', '   ')]);
      expect(blankName.relativeSections, isEmpty);
      expect(blankName.hasRelatives, isFalse);
    });

    test('قائمة خام تُقرأ عربية: المكتوب حرفيًا والمفهرس مصروف', () {
      final raw = [
        typed('جار', 'أحمد').toJson(),
        inGroup(RelativeType.paternalUncles, 'سليم').toJson(),
      ];
      expect(obituaryRelativesReadable(raw, gender: kObituaryGenderFemale),
          'جار: أحمد | عمّة كلاً من: سليم');
      expect(obituaryRelativesReadable(const []), 'لا يوجد');
      // قائمة نصوص مفصولة (بقايا محرّر قديم) لا ترمي بل تُقال «لا يوجد».
      expect(obituaryRelativesReadable(['أحمد، سليم']), 'لا يوجد');
    });
  });

  group('بطاقة المشاركة: العنوان الحرفي كما كُتب', () {
    testWidgets('نوعان مكتوبان يظهران بعنوانيهما مع مجموعة مفهرسة',
        (tester) async {
      await tester.pumpWidget(cardOf(obitOf(relatives: [
        inGroup(RelativeType.children, 'وليد'),
        typed('جار', 'أحمد'),
        typed('خطيب الابنة', 'محمود'),
      ])));
      await tester.pump();

      expect(find.textContaining('جار: أحمد', findRichText: true), findsOne);
      expect(find.textContaining('خطيب الابنة: محمود', findRichText: true),
          findsOne);
      expect(find.textContaining('والد كلاً من: وليد', findRichText: true),
          findsOne);
      // المكتوب لا يسقط تحت «أخرى».
      expect(find.textContaining('أخرى', findRichText: true), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('سجل قديم بتسمية تراثية يبقى تحت «أخرى»', (tester) async {
      await tester.pumpWidget(cardOf(obitOf(relatives: [
        const Relative(id: 'r', name: 'فلان', type: RelativeType.other),
      ])));
      await tester.pump();

      expect(find.textContaining('أخرى: فلان', findRichText: true), findsOne);
      expect(tester.takeException(), isNull);
    });
  });

  group('نموذج الإضافة: الكتلة الثالثة عشرة', () {
    Future<void> openForm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 12000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AddObituaryScreen(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      // `flutter_animate` يبدأ مؤقّته في مؤجَّل يُصرَف أثناء الضخّ أعلاه، فلا
      // يُحرَّك المؤشَّر إلا في الإطار التالي: بدونه تبقى البطاقات بشفافية
      // صفر، و`AnimatedOpacity` عند صفر لا يستقبل اللمس أصلًا.
      await tester.pump(const Duration(milliseconds: 900));
    }

    testWidgets('الحقلان وزر الإضافة ظاهران حتى قبل اختيار النوع',
        (tester) async {
      await openForm(tester);
      expect(find.byKey(const Key('relative-custom-type')), findsOne);
      expect(find.byKey(const Key('relative-custom-name')), findsOne);
      expect(find.byKey(const Key('relative-custom-add')), findsOne);
      expect(find.text('قرابة أخرى — اكتبها بنفسك'), findsOne);
      expect(tester.takeException(), isNull);
    });

    testWidgets('نقص النوع ونقص الاسم مرفوضان برسالة صريحة، والإدخال لا يضيع',
        (tester) async {
      await openForm(tester);
      final messenger = ScaffoldMessenger.of(tester.element(find.byType(Form)));

      await tester.enterText(find.byKey(const Key('relative-custom-name')), 'أحمد');
      await tester.tap(find.byKey(const Key('relative-custom-add')));
      await tester.pump();
      expect(find.text('اكتب نوع القرابة أولاً'), findsOne);
      // الاسم ما زال في الحقل: لم يُمسح لأنه لم يُرفض خطأ الكاتب.
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('relative-custom-name')))
              .controller!
              .text,
          'أحمد');
      expect(find.text('جار: أحمد'), findsNothing);

      messenger.clearSnackBars();
      await tester.enterText(find.byKey(const Key('relative-custom-type')), 'جار');
      await tester.enterText(find.byKey(const Key('relative-custom-name')), '');
      await tester.tap(find.byKey(const Key('relative-custom-add')));
      await tester.pump();
      expect(find.text('اكتب اسم القريب أولاً'), findsOne);
      // النوع ما زال في الحقل للسبب نفسه.
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('relative-custom-type')))
              .controller!
              .text,
          'جار');
      expect(find.text('جار: أحمد'), findsNothing);
    });

    testWidgets('الإضافة تصنع رقيقة «النوع: الاسم» وتفرّغ الحقلين',
        (tester) async {
      await openForm(tester);

      await tester.enterText(find.byKey(const Key('relative-custom-type')), 'جار');
      await tester.enterText(find.byKey(const Key('relative-custom-name')), 'أحمد');
      await tester.tap(find.byKey(const Key('relative-custom-add')));
      await tester.pump();

      expect(find.text('جار: أحمد'), findsOne);
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('relative-custom-type')))
              .controller!
              .text,
          isEmpty);
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('relative-custom-name')))
              .controller!
              .text,
          isEmpty);

      // النوع نفسه يقبل اسمًا ثانيًا، والاسم المكرر تحت نفس النوع يُرفض.
      await tester.enterText(find.byKey(const Key('relative-custom-type')), 'جار');
      await tester.enterText(find.byKey(const Key('relative-custom-name')), 'محمد');
      await tester.tap(find.byKey(const Key('relative-custom-add')));
      await tester.pump();
      expect(find.text('جار: محمد'), findsOne);

      final messenger = ScaffoldMessenger.of(tester.element(find.byType(Form)));
      messenger.clearSnackBars();
      await tester.enterText(find.byKey(const Key('relative-custom-type')), 'جار');
      await tester.enterText(find.byKey(const Key('relative-custom-name')), 'أحمد');
      await tester.tap(find.byKey(const Key('relative-custom-add')));
      await tester.pump();
      expect(find.text('«أحمد» مضاف بالفعل تحت «جار»'), findsOne);
      expect(find.text('جار: أحمد'), findsOne);
    });

    testWidgets('حذف رقيقة يسقط إدخالها وحده', (tester) async {
      await openForm(tester);
      for (final name in ['أحمد', 'محمد']) {
        await tester.enterText(find.byKey(const Key('relative-custom-type')), 'جار');
        await tester.enterText(find.byKey(const Key('relative-custom-name')), name);
        await tester.tap(find.byKey(const Key('relative-custom-add')));
        await tester.pump();
      }
      expect(find.byType(InputChip), findsNWidgets(2));

      final chip = find.ancestor(
          of: find.text('جار: أحمد'), matching: find.byType(InputChip));
      await tester.tap(find.descendant(of: chip, matching: find.byIcon(Icons.clear)));
      await tester.pump();

      expect(find.text('جار: أحمد'), findsNothing);
      expect(find.text('جار: محمد'), findsOne);
      expect(tester.takeException(), isNull);
    });
  });

  group('عقود المصدر', () {
    final add =
        File('C:/Users/elera/Desktop/Qarity/lib/features/obituaries/add.dart')
            .readAsStringSync();
    final detail = File(
            'C:/Users/elera/Desktop/Qarity/lib/features/admin/admin_detail.dart')
        .readAsStringSync();
    final editor = File(
            'C:/Users/elera/Desktop/Qarity/lib/widgets/document_field_editor.dart')
        .readAsStringSync();

    test('الكتلة تُدرَج بعد المجموعات الاثنتي عشرة في بطاقة الأقارب', () {
      expect(add, contains('_CustomRelativeEditor('));
      expect(add, contains("key: const ValueKey('rel-group-custom')"));
      expect(add, contains('entries: _customRelatives'));
      expect(add.indexOf('_CustomRelativeEditor('),
          greaterThan(add.indexOf('for (final group in kObituaryRelativeGroups)')));
    });

    test('المُضيف يمرّر النوع المكتوب دائمًا عند الإضافة', () {
      expect(add, contains('typeLabel: type,'));
      expect(add, contains('type: RelativeType.other,'));
    });

    test('لوحة الإدارة تسمي القرابة المكتوبة ولا تطبع الخرائط الخام', () {
      expect(detail, contains("final custom = (r['typeLabel'] ?? '').toString().trim();"));
      expect(editor, contains("'relatives': 'أقارب المتوفى'"));
      expect(editor, contains('obituaryRelativesReadable(v)'));
      // الحقل يبقى للقراءة فقط: لا يُضاف إلى قائمة قابلة للكتابة.
      expect(editor, contains('case DocFieldKind.readOnly:'));
    });
  });
}
