import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/obituaries/add.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/obituary_service.dart';
import 'package:qurity/widgets/document_field_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «سجل العزاء» بعد اعتماد الأدمن: وثيقة واحدة لا تُفرغ الصفحة، ومرشّح الصلاة
/// بجوار كل موعد. الأول يمسّ طبقة القراءة ومحرّر لوحة الإدارة (سبب العلة)،
/// والثاني حقلان نصّيان لا هجرة ولا فهرس ولا قواعد.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Map<String, dynamic> docOf({Object? name, Object? relatives}) {
    return {
      'name': name ?? 'الشيخ صبري',
      'gender': kObituaryGenderMale,
      'dateOfDeath': '2026-10-03',
      'funeralLocation': 'مسجد القرية الكبير',
      'funeralTime': '10:30 ص',
      'isApproved': true,
      if (relatives != null) 'relatives': relatives,
    };
  }

  group('قراءة السجل لا تُفرغ الصفحة', () {
    test('relatives التالفة (نصوص مفصولة بدل خرائط) تُتخطى وبقية البيان يُعرض',
        () {
      // شكل الوثيقة الذي أنتجه مُحرّر لوحة الإدارة قبل الإصلاح.
      final o = Obituary.fromJson(
        docOf(relatives: [
          '{phone: null',
          'name: د . محمد عبدالغني',
          'id: rel_1791046254287_0',
          'type: paternalCousins',
          'order: 0}',
        ]),
        'bUkbr3gojBVAdgUWFDfn',
      );
      expect(o.name, 'الشيخ صبري');
      expect(o.funeralTime, '10:30 ص');
      expect(o.relatives, isEmpty);
    });

    test('العناصر الصحيحة تُقرأ والمجهولة تُتخطى، وغير القائمة لا يرمي', () {
      final mixed = Obituary.fromJson(
        docOf(relatives: [
          {'id': 'r1', 'name': 'أحمد', 'type': 'paternalCousins', 'order': 0},
          'نص لا أكثر',
          42,
        ]),
        'x',
      );
      expect(mixed.relatives.length, 1);
      expect(mixed.relatives.single.name, 'أحمد');

      for (final bad in ['نص', 7, {'id': 'r'}]) {
        final o = Obituary.fromJson(docOf(relatives: bad), 'x');
        expect(o.relatives, isEmpty, reason: 'relatives = $bad');
      }
    });

    test('الستريم يتخطى الوثيقة التي لا تُقرأ ولا يُسقط بقية القائمة', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('obituaries').add(docOf(name: 'سليم'));
      // `name` رقمًا ⇒ التحويل إلى String يرمي: هذا هو «الوثيقة التالفة».
      await fake.collection('obituaries').add(docOf(name: 42));

      final svc = ObituaryService(fake);
      final live = await svc.getObituariesStream().first;
      expect(live.length, 1);
      expect(live.single.name, 'سليم');

      final once = await svc.getObituariesList(forceRefresh: true);
      expect(once.length, 1);
      expect(once.single.id, isNotEmpty);

      expect(await svc.getObituaryById(once.single.id), isNotNull);
    });

    test('getObituaryById على وثيقة تالفة يرجع null لا استثناء', () async {
      final fake = FakeFirebaseFirestore();
      final broken = await fake.collection('obituaries').add(docOf(name: 42));
      final svc = ObituaryService(fake);
      expect(await svc.getObituaryById(broken.id), isNull);
    });
  });

  group('محرّر لوحة الإدارة: قائمة الخرائط لا تُسطَّر', () {
    test('relatives تُشتق للقراءة فقط، وقائمة النصوص تبقى قابلة للتحرير', () {
      final specs = deriveMissingFields({
        'relatives': [
          {'id': 'r1', 'name': 'أحمد', 'type': 'paternalCousins'}
        ],
        'subjects': ['فيزياء', 'كيمياء'],
        'nested': [
          ['a']
        ],
      }, {});
      DocFieldSpec of(String key) => specs.singleWhere((s) => s.key == key);
      expect(of('relatives').kind, DocFieldKind.readOnly);
      expect(of('nested').kind, DocFieldKind.readOnly);
      expect(of('subjects').kind, DocFieldKind.list);
    });

    test('الحفظ لا يكتب relatives أبدًا فيبقى أصلها في الوثيقة', () {
      final item = {
        'relatives': [
          {'id': 'r1', 'name': 'أحمد', 'type': 'paternalCousins', 'order': 0}
        ],
        'name': 'الشيخ صبري',
      };
      final specs = deriveMissingFields(item, {'name'});
      final editor = DocumentEditor()..seed(specs, item);
      final data = editor.collect(specs);
      expect(data.containsKey('relatives'), isFalse);
      editor.dispose();
    });

    test('عقد المصدر: قائمة العزاء تُسمّي الصلاتين ولا تتركهما للاشتقاق', () {
      final src = File('lib/features/admin/admin_edit.dart').readAsStringSync();
      expect(src, contains("DocFieldSpec('funeralPrayer'"));
      expect(src, contains("DocFieldSpec('condolencePrayer'"));
      final detail =
          File('lib/features/admin/admin_detail.dart').readAsStringSync();
      expect(detail, contains("'funeralPrayer': 'صلاة الجنازة المحددة'"));
      expect(detail, contains("'condolencePrayer': 'صلاة العزاء المحددة'"));
    });
  });

  group('مرشّح الصلاة', () {
    test('القيم الخمس بترتيبها كما طُلبت', () {
      expect(kObituaryPrayers, [
        'صلاة الظهر',
        'صلاة العصر',
        'صلاة المغرب',
        'صلاة العشاء',
        'صلاة الفجر',
      ]);
    });

    test('الموعد والصلاة في نص واحد، وكل منهما بمفرده يظهر كما هو', () {
      expect(obituaryTimeWithPrayer('10:30 ص', 'صلاة الظهر'),
          '10:30 ص — صلاة الظهر');
      expect(obituaryTimeWithPrayer('10:30 ص', ''), '10:30 ص');
      expect(obituaryTimeWithPrayer('', 'صلاة المغرب'), 'صلاة المغرب');
      expect(obituaryTimeWithPrayer('', ''), '');
    });

    test('الحقلان يُكتبان ويُقرآن، والسجل القديم بلا الحقلين فارغ', () {
      const o = Obituary(
        id: 'o1',
        name: 'فلان',
        age: '',
        dateOfDeath: '2026-10-03',
        funeralTime: '10:30 ص',
        funeralPrayer: 'صلاة الظهر',
        condolenceTime: '8 م',
        condolencePrayer: 'صلاة المغرب',
      );
      final json = o.toJson();
      expect(json['funeralPrayer'], 'صلاة الظهر');
      expect(json['condolencePrayer'], 'صلاة المغرب');
      final back = Obituary.fromJson(json, 'o1');
      expect(back.funeralPrayer, 'صلاة الظهر');
      expect(back.condolencePrayer, 'صلاة المغرب');

      final legacy = Obituary.fromJson(
          {'name': 'فلان', 'dateOfDeath': '2026-01-01', 'funeralTime': '9 ص'},
          'old');
      expect(legacy.funeralPrayer, '');
      expect(legacy.condolencePrayer, '');
      expect(legacy.funeralTime, '9 ص');
    });

    testWidgets('اختيار الصلاة يظهر بجوار الوقت في الموضعين', (tester) async {
      // نافذة طويلة كي يبني `ListView` كل الأقسام (يُبني المرئي فقط).
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
      // أقسام النموذج تدخل بحركات `flutter_animate` فكل حركة تؤجّل مهمة.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      for (final pair in const [
        ['funeral-time-field', 'funeral-prayer-field'],
        ['condolence-time-field', 'condolence-prayer-field'],
      ]) {
        final time = find.byKey(Key(pair[0]));
        final prayer = find.byKey(Key(pair[1]));
        expect(time, findsOne);
        expect(prayer, findsOne);

        // «بجوار الوقت» حرفيًا: نفس الـ`Row`، لا سطر تحته.
        final row = find.ancestor(
                of: time, matching: find.byType(Row))
            .first;
        expect(
            find.descendant(of: row, matching: prayer),
            findsOne,
            reason: '${pair[1]} ليس في صف ${pair[0]}');
        expect(tester.getCenter(prayer).dx, isNot(tester.getCenter(time).dx));

        // القيم من الزرّ المرسوم نفسه، لا من قائمة مغلقة.
        final button = tester.widget<DropdownButton<String>>(
          find.descendant(of: prayer, matching: find.byType(DropdownButton<String>)),
        );
        expect(button.items!.map((i) => i.value).toList(),
            ['', ...kObituaryPrayers]);
        expect(button.value, '');
        expect(find.descendant(of: prayer, matching: find.text('بدون')),
            findsOne);
      }

      // المعاينة والإرسال يمرّان بالقيمتين معًا فلا تكذب المعاينة.
      final src = File('lib/features/obituaries/add.dart').readAsStringSync();
      expect('funeralPrayer: _funeralPrayer'.allMatches(src).length, 2);
      expect('condolencePrayer: _condolencePrayer'.allMatches(src).length, 2);
      expect(src, contains('_funeralPrayer = e.funeralPrayer;'));
      expect(src, contains('_condolencePrayer = e.condolencePrayer;'));
      final detail =
          File('lib/features/obituaries/detail.dart').readAsStringSync();
      expect(detail, contains('obituaryTimeWithPrayer('));
      final card =
          File('lib/widgets/obituary_share_card.dart').readAsStringSync();
      expect(card, contains('obituaryTimeWithPrayer(o.funeralTime'));
      expect(card, contains('obituaryTimeWithPrayer(o.condolenceTime'));
    });
  });
}
