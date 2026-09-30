import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/village/village_content_admin.dart';
import 'package:qurity/models/village_content_models.dart';
import 'package:qurity/services/village_content_service.dart';
import 'package:qurity/services/village_extended_service.dart';

/// شاشات محتوى «تعرف على القرية» التي تُبنى فوق القالب العام.
const _kVillageScreens = [
  'village_achievements_screen.dart',
  'village_agriculture_history_screen.dart',
  'village_archive_list_screen.dart',
  'village_before_after_screen.dart',
  'village_development_timeline_screen.dart',
  'village_digital_archive_screen.dart',
  'village_education_history_screen.dart',
  'village_family_screen.dart',
  'village_heritage_screen.dart',
  'village_landmarks_screen.dart',
  'village_map_screen.dart',
  'village_memorial_screen.dart',
  'village_notable_people_screen.dart',
];

/// كود فعلي فقط: تُحذف أسطر التعليقات حتى لا يُحسب ذكر `orderBy` في التوثيق.
List<String> _codeLines(File file) => file
    .readAsLinesSync()
    .map((l) => l.trim())
    .where((l) => !l.startsWith('//') && !l.startsWith('*'))
    .toList();

void main() {
  group('قراءة محتوى القرية: لا بيان يُفقد بسبب حقل ترتيب ناقص', () {
    test('الشخصيات البارزة تُقرأ رغم أن نموذجها لا يكتب sortOrder إطلاقًا',
        () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageExtendedService(fake);
      await svc.saveNotablePerson(const VillageNotablePerson(
          fullName: 'الشيخ أحمد العزب', field: 'العمدة'));
      await svc.saveNotablePerson(const VillageNotablePerson(
          fullName: 'الحاج محمد', field: 'المعلم'));

      final items = await svc.watchNotablePeople().first;
      expect(items.map((e) => e.fullName), hasLength(2));
      expect(items.map((e) => e.fullName),
          containsAll(['الشيخ أحمد العزب', 'الحاج محمد']));

      // الإثبات أن الحقل الغائب هو سبب الاختفاء السابق: لا sortOrder في الوثيقة.
      final raw =
          (await fake.collection('village_notable_people').doc(items.first.id).get())
              .data()!;
      expect(raw, isNot(contains('sortOrder')));
    });

    test('شخصيات الذاكرة تُقرأ رغم غياب sortOrder', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageExtendedService(fake);
      await svc.saveMemorialPerson(const VillageMemorialPerson(
          fullName: 'العمدة عبدالباسط', field: 'العمدة'));
      final items = await svc.watchMemorialPeople().first;
      expect(items.map((e) => e.fullName), ['العمدة عبدالباسط']);
    });

    test('حقبة بلا sortOrder تُقرأ ولا تُسقط الحقبات المكتَّبة', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageContentService(fake);
      final col = fake.collection('village_history');
      await col.doc('with-order').set({'title': 'مرتَّبة', 'narrative': 'ا', 'sortOrder': 1});
      await col.doc('no-order').set({'title': 'بلا ترتيب', 'narrative': 'ب'});

      final eras = await svc.watchEras().first;
      expect(eras.map((e) => e.title), ['بلا ترتيب', 'مرتَّبة']);
    });

    test('صورة أرشيف بلا createdAt تُقرأ ولا تُسقط بقية الأرشيف', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageContentService(fake);
      final col = fake.collection('village_archive_photos');
      await col.doc('no-date').set({'title': 'موثقة'});
      await col.doc('dated').set({'title': 'بتاريخ', 'createdAt': Timestamp.now()});

      final photos = await svc.watchArchivePhotos().first;
      expect(photos.map((e) => e.title).toSet(), {'موثقة', 'بتاريخ'});
    });

    test('المنشآت بلا sortOrder تُقرأ وتصنيفها يظهر في الإدارة', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageContentService(fake);
      await fake.collection('village_institutions').doc('legacy').set(
          {'name': 'المدرسة الابتدائية', 'type': 'schools'});
      final items = await svc.watchInstitutions().first;
      expect(items.map((e) => e.name), ['المدرسة الابتدائية']);
    });

    test('العائلات تُقرأ وتُحذف بمعرّفها (مسار كان ميتًا)', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageExtendedService(fake);
      await svc.saveFamily(const VillageFamily(name: 'عائلة العزب'));
      var families = await svc.watchFamilies().first;
      expect(families, hasLength(1));

      await svc.deleteFamily(families.single.id);
      families = await svc.watchFamilies().first;
      expect(families, isEmpty);
    });
  });

  group('لوحة الإدارة العامة (زر «إدارة»)', () {
    Future<void> openSheet(WidgetTester tester, {
      required List<VillageFamily> items,
      required Future<void> Function(String id) remove,
    }) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => manageVillageContent<VillageFamily>(
                  context,
                  title: 'عائلات القرية',
                  accent: const Color(0xFF795548),
                  stream: Stream.value(items),
                  nameOf: (f) => f.name,
                  remove: remove,
                  formBuilder: (ctx, editing) =>
                      const SizedBox(height: 120),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('عناصر النموذج الموسّع تُعرض ولها زر تعديل وحذف',
        (tester) async {
      await openSheet(
        tester,
        items: const [VillageFamily(id: 'f1', name: 'عائلة العزب')],
        remove: (_) async {},
      );
      expect(find.text('إدارة — عائلات القرية'), findsOneWidget);
      expect(find.text('عائلة العزب'), findsOneWidget);
      expect(find.byTooltip('تعديل'), findsOneWidget);
      expect(find.byTooltip('حذف'), findsOneWidget);
    });

    testWidgets('الحذف يطلب تأكيدًا ثم ينادي remove بمعرّف العنصر',
        (tester) async {
      final removed = <String>[];
      await openSheet(
        tester,
        items: const [VillageFamily(id: 'f1', name: 'عائلة العزب')],
        remove: (id) async => removed.add(id),
      );

      await tester.tap(find.byTooltip('حذف'));
      await tester.pumpAndSettle();
      expect(find.text('تأكيد الحذف'), findsOneWidget);
      expect(removed, isEmpty);

      await tester.tap(find.text('حذف').last);
      await tester.pumpAndSettle();
      expect(removed, ['f1']);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('إلغاء التأكيد لا يحذف شيئًا', (tester) async {
      final removed = <String>[];
      await openSheet(
        tester,
        items: const [VillageFamily(id: 'f1', name: 'عائلة العزب')],
        remove: (id) async => removed.add(id),
      );
      await tester.tap(find.byTooltip('حذف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(removed, isEmpty);
    });

    testWidgets('فشل الحذف يُبلَّغ بصدق بدل الصمت', (tester) async {
      await openSheet(
        tester,
        items: const [VillageFamily(id: 'f1', name: 'عائلة العزب')],
        remove: (_) async => throw Exception('permission-denied'),
      );
      await tester.tap(find.byTooltip('حذف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف').last);
      await tester.pumpAndSettle();
      expect(find.text('تعذّر الحذف — تحقق من الاتصال أو من صلاحياتك.'),
          findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('القائمة الفارغة تدعو للإضافة بدل الفراغ', (tester) async {
      await openSheet(tester, items: const [], remove: (_) async {});
      expect(find.text('لا توجد عناصر بعد — أضف أول عنصر ＋'), findsOneWidget);
    });

    test('نص فشل رفع الصورة يحتفظ بسبب الخدمة ويضيف مخرج المتابعة', () {
      final text = villageUploadFailureAr(
          Exception('تعذّر رفع الصورة (رمز 500) — أعد المحاولة'));
      expect(text, 'تعذّر رفع الصورة (رمز 500) — أعد المحاولة — يمكنك المتابعة بلا صورة.');
      expect(text, isNot(contains('Exception')));
      expect(villageUploadFailureAr(StateError('boom')), contains('boom'));
    });
  });

  group('عقود المصدر', () {
    test('لا استعلام مرتّب في خدمات محتوى القرية', () {
      for (final name in [
        'village_content_service.dart',
        'village_extended_service.dart',
      ]) {
        final lines = _codeLines(File('lib/services/$name'));
        expect(lines.any((l) => l.contains('orderBy(')), isFalse,
            reason: '$name رتّب في الخادم: أي وثيقة بلا الحقل المرتَّب عليه '
                'تختفي عن الأدمن بعد إضافتها');
      }
    });

    test('كل شاشات القرية تُثبّت تدفقها مرة واحدة في الحالة', () {
      for (final name in _kVillageScreens) {
        final src = File('lib/features/village/$name').readAsStringSync();
        expect(src, contains('streamFactory:'),
            reason: '$name ما زالت تمرر stream مباشرة — التدفق يُعاد إنشاؤه في '
                'كل بناء فتُسقط الاشتراكات ويفقد حقل البحث تركيزه');
        expect(src, isNot(contains('stream: _service')),
            reason: '$name تمرر تدفقًا غير مثبت');
      }
      final scaffold =
          File('lib/features/village/village_section_scaffold.dart')
              .readAsStringSync();
      expect(scaffold, contains('late final Stream<List<T>> _stream'),
          reason: 'القالب العام يجب أن يبني التدفق مرة واحدة في الحالة');
    });

    test('لا شاشة تُرمي استثناءً في نموذج إدارتها', () {
      for (final name in _kVillageScreens) {
        final src = File('lib/features/village/$name').readAsStringSync();
        expect(src, isNot(contains('UnsupportedError')),
            reason: '$name: formBuilder يرمي استثناءً — زر «إدارة» يُسقط الشاشة');
      }
    });

    test('كل نموذج حفظ يعرض سطر الفشل الخاص به', () {
      for (final name in [
        'village_content_admin.dart',
        'village_extended_admin.dart',
      ]) {
        final src = File('lib/features/village/$name').readAsStringSync();
        final saves = 'await '.allMatches(src).length;
        final errors = 'villageFormError(_error)'.allMatches(src).length;
        expect(errors, greaterThanOrEqualTo(5),
            reason: '$name: سطر الفشل الأحمر ناقص في بعض النماذج');
        expect(errors, lessThanOrEqualTo(saves),
            reason: '$name: villageFormError بلا نموذج حفظ مقابل');
        expect(src, contains('_error = null;'),
            reason: '$name: يجب مسح الخطأ قبل أي محاولة حفظ جديدة');
      }
    });
  });
}
