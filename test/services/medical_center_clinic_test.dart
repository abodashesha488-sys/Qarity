import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/medical/medical_admin_screen.dart';
import 'package:qurity/models/medical_models.dart';
import 'package:qurity/widgets/clinic_photo_tile.dart';

/// يفتح نموذج عيادة المركز كنافذة سفلية ويرجع بالنتيجة إلى [onResult].
Future<void> _pumpForm(WidgetTester tester, MedicalCenterClinic? existing,
    [void Function(MedicalCenterClinic?)? onResult]) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          key: const Key('open-form'),
          onPressed: () async {
            final result = await showModalBottomSheet<MedicalCenterClinic>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ClinicEditForm(
                  days: const ['السبت', 'الأحد'], existing: existing),
            );
            onResult?.call(result);
          },
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open-form')));
  await tester.pumpAndSettle();
}

void main() {
  group('صورة عيادة المركز الطبي الخيري', () {
    test('الوثيقة القديمة بلا imageUrl تُقرأ فارغة ولا تُفسد بقية الحقول', () {
      final legacy = MedicalCenterClinic.fromJson({
        'name': 'عيادة العيون',
        'specialty': 'عيون',
        'workingHours': '9 ص - 2 م',
        'fees': 20,
      }, 'doc1');
      expect(legacy.imageUrl, '');
      expect(legacy.workingHours, '9 ص - 2 م');
      expect(legacy.isApproved, isTrue);
    });

    test('imageUrl يُقرأ ويُكتب، والنموذج يحمله عبر copyWith', () {
      final withPhoto = MedicalCenterClinic.fromJson({
        'name': 'عيادة العيون',
        'imageUrl': 'https://cdn.test/eye.jpg',
      }, 'doc2');
      expect(withPhoto.imageUrl, 'https://cdn.test/eye.jpg');
      expect(withPhoto.toJson()['imageUrl'], 'https://cdn.test/eye.jpg');
      expect(withPhoto.copyWith(imageUrl: '').imageUrl, '');
    });

    testWidgets('بلا صورة: أيقونة بديلة بلا أي طلب شبكة', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ClinicPhotoTile(imageUrl: '')),
      ));
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.medical_services_rounded), findsOneWidget);
      expect(tester.getSize(find.byType(ClinicPhotoTile)), const Size(84, 84));
    });

    testWidgets('بصورة: تُرسم داخل إطار مقسّح بـcover وبالمقاس المطلوب',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: ClinicPhotoTile(
                imageUrl: 'https://cdn.test/a.jpg', side: 52, radius: 10)),
      ));
      final image = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage));
      expect(image.imageUrl, 'https://cdn.test/a.jpg');
      expect(image.fit, BoxFit.cover);
      expect(image.width, 52);
      // memCacheWidth = side × 3: فكّ الصورة لا يتجاوز ما يُرسم فعلًا.
      expect(image.memCacheWidth, 156);
      expect(find.byType(ClipRRect), findsWidgets);
      expect(tester.getSize(find.byType(CachedNetworkImage)), const Size(52, 52));
    });
  });

  group('مواعيد العمل باختيار وقت', () {
    test('التنسيق المحفوظ يطابق صيغة الوثائق القديمة', () {
      expect(
          formatClinicHours(const TimeOfDay(hour: 9, minute: 0),
              const TimeOfDay(hour: 14, minute: 0)),
          '9 ص - 2 م');
      expect(clinicHourLabel(const TimeOfDay(hour: 9, minute: 30)), '9:30 ص');
      expect(clinicHourLabel(const TimeOfDay(hour: 12, minute: 0)), '12 م');
      expect(clinicHourLabel(const TimeOfDay(hour: 0, minute: 0)), '12 ص');
      expect(clinicHourLabel(const TimeOfDay(hour: 13, minute: 45)), '1:45 م');
    });

    test('قراءة الصيغ القديمة والرقمية بلا فقدان', () {
      expect(
          parseClinicHours('9 ص - 2 م'),
          (start: const TimeOfDay(hour: 9, minute: 0),
              end: const TimeOfDay(hour: 14, minute: 0)));
      expect(
          parseClinicHours('12 م - 3 م'),
          (start: const TimeOfDay(hour: 12, minute: 0),
              end: const TimeOfDay(hour: 15, minute: 0)));
      expect(
          parseClinicHours('9:30 ص - 14:00'),
          (start: const TimeOfDay(hour: 9, minute: 30),
              end: const TimeOfDay(hour: 14, minute: 0)));
      expect(parseClinicHours('صباحًا حتى المساء'), isNull);
      expect(parseClinicHours('9 ص'), isNull);
      expect(parseClinicHours(''), isNull);
      expect(parseClinicHours('13 ص - 2 م'), isNull,
          reason: 'ساعة 13 لا تجتمع مع «ص» — لا يُخترع تقدير');
    });

    test('دورة كاملة: قراءة ثم تنسيق يعيد نفس النص', () {
      for (final stored in ['9 ص - 2 م', '10 ص - 1 م', '12 م - 3 م', '11 ص - 2 م']) {
        final parsed = parseClinicHours(stored)!;
        expect(formatClinicHours(parsed.start, parsed.end), stored);
      }
    });

    test('قرار الحفظ: وقتان = نص جديد، ولا لمس = نص محفوظ، ووقت واحد = مرفوض',
        () {
      const nine = TimeOfDay(hour: 9, minute: 0);
      const two = TimeOfDay(hour: 14, minute: 0);
      expect(resolveClinicHours(start: nine, end: two), '9 ص - 2 م');
      expect(resolveClinicHours(existing: '9 ص - 3 م'), '9 ص - 3 م');
      expect(resolveClinicHours(), '');
      expect(resolveClinicHours(start: nine), isNull);
      expect(resolveClinicHours(end: two), isNull);
      expect(resolveClinicHours(start: nine, end: two, existing: '9 ص - 3 م'),
          '9 ص - 2 م');
    });
  });

  group('نموذج عيادة المركز', () {
    testWidgets('حقلان «من/إلى» يقرآن المواعيد المحفوظة بصيغة مختصرة',
        (tester) async {
      await _pumpForm(
          tester,
          const MedicalCenterClinic(
              id: 'x', name: 'عيادة الأطفال', workingHours: '9 ص - 2 م'));
      expect(find.text('مواعيد العمل'), findsOneWidget);
      expect(find.byKey(const Key('clinic-hours-start')), findsOneWidget);
      expect(find.byKey(const Key('clinic-hours-end')), findsOneWidget);
      expect(find.text('من'), findsOneWidget);
      expect(find.text('إلى'), findsOneWidget);
      expect(find.text('9 ص'), findsOneWidget);
      expect(find.text('2 م'), findsOneWidget);
      // لا خانة كتابة نصية للمواعيد بعد الآن.
      expect(find.textContaining('مثال'), findsNothing);
      expect(find.text('اختر الوقت'), findsNothing);
    });

    testWidgets('الضغط على «من» يفتح منتقي الوقت ويُغلق بلا اختيار دون تغيير',
        (tester) async {
      await _pumpForm(
          tester,
          const MedicalCenterClinic(
              id: 'x', name: 'عيادة الأطفال', workingHours: '9 ص - 2 م'));
      await tester.tap(find.byKey(const Key('clinic-hours-start')));
      await tester.pumpAndSettle();
      expect(find.text('وقت بداية العمل'), findsOneWidget);

      final dialogContext = tester.element(find.text('وقت بداية العمل'));
      Navigator.of(dialogContext).pop();
      await tester.pumpAndSettle();

      expect(find.text('9 ص'), findsOneWidget);
    });

    testWidgets('نص مواعيد غير مفهوم: يبقى محفوظًا ويُعرض تلميحًا ولا يُمسح',
        (tester) async {
      MedicalCenterClinic? result;
      await _pumpForm(
          tester,
          const MedicalCenterClinic(
              id: 'x', name: 'عيادة المركز', workingHours: 'حسب الحضور'),
          (r) => result = r);
      // لم يُقرأ الوقتان ⇒ الحقلان فارغان والتلميح يحفظ النص الأصلي.
      expect(find.text('اختر الوقت'), findsNWidgets(2));
      expect(find.textContaining('المواعيد المحفوظة: حسب الحضور'),
          findsOneWidget);

      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.workingHours, 'حسب الحضور');
      expect(result!.name, 'عيادة المركز');
    });

    testWidgets('الحفظ بلا اسم يرفض برسالة ظاهرة ويبقي النموذج مفتوحًا',
        (tester) async {
      MedicalCenterClinic? result;
      await _pumpForm(
          tester, const MedicalCenterClinic(id: 'x', name: ''),
          (r) => result = r);
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('clinic-name-error')), findsOneWidget);
      expect(find.text('اكتب اسم العيادة أولاً'), findsOneWidget);
      expect(result, isNull);
      expect(find.text('حفظ'), findsOneWidget);

      final nameField = find.byType(TextField).first;
      expect(tester.widget<TextField>(nameField).controller!.text, isEmpty);

      await tester.enterText(nameField, 'عيادة الأسنان');
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(result?.name, 'عيادة الأسنان');
      // لا صورة مختارة ⇒ لا خطأ رفع، والنموذج يُغلق.
      expect(find.byKey(const Key('clinic-photo-error')), findsNothing);
    });

    test('صورة العيادة: حقل صورة واحد في النموذج وخطؤه أحمر ظاهر', () {
      final src =
          File('lib/features/medical/medical_admin_screen.dart').readAsStringSync();
      expect(src.contains('maxImages: 1'), isTrue,
          reason: 'النموذج يقبل صورة واحدة للعيادة');
      expect(src.contains("key: const Key('clinic-photo-error')"), isTrue);
      expect(src.contains('Color(0xFFB71C1C)'), isTrue,
          reason: 'فشل الرفع يُبلَّغ بالأحمر لا بصمتًا');
      expect(src.contains('onError: (msg) => setState'), isTrue,
          reason: 'خطأ الرفع يصل من حقل الصور إلى الحالة الدائمة');
      expect(src.contains('ClinicPhotoPreviewTile(imageUrl: _imageUrl)'), isTrue,
          reason: 'المعاينة ترسم الصورة المختارة قبل الحفظ');
    });

    test('كارت العيادة العام يعتمد البلاطة ووسوم المواعيد والأيام', () {
      final src = File('lib/features/medical/medical_home_screen.dart')
          .readAsStringSync();
      expect(src.contains('ClinicPhotoTile('), isTrue,
          reason: 'البطاقة العامة تعرض صورة العيادة');
      expect(src.contains('_Pill('), isTrue,
          reason: 'المواعيد والأيام والأجر صارت وسومًا تلتفّ بدل أن تفيض');
      expect(src.contains('Wrap('), isTrue);
    });

    test('بوابة الأقسام: بلاطتان في السطر بصور أكبر، والستة الأولى كما هي', () {
      final src = File('lib/features/medical/medical_home_screen.dart')
          .readAsStringSync();
      // تنسيق عرض فقط: عمودان بدل ثلاثة، والصورة تُفكّ بمقاسها الفعلي.
      expect(src.contains('crossAxisCount: 2'), isTrue);
      expect(src.contains('crossAxisCount: 3'), isFalse,
          reason: 'لاعودة لشبكة الثلاثة أعمدة');
      expect(src.contains('cacheWidth: 520'), isTrue,
          reason: 'بلاطة بعرض ~172dp تحتاج ~520px عند DPR 3 لا 280');
      // والأقسام السبعة بمساراتها وصورها لم تمسّ — السابع «المستلزمات الطبية»
      // هو المضاف بهذا الطلب، لا تعديل في شيء من الستة قبله.
      expect(RegExp(r"\('([^']+)', 'assets/images/[^']+'\)", multiLine: true)
          .allMatches(src)
          .length, 7);
    });
  });

  group('عقد صلاحيات مدير المركز الطبي', () {
    test('القواعد: medical_admin لا يذكر إلا في بوابة المركز ومنع الإنشاء', () {
      final rules = File('firestore.rules').readAsStringSync();
      final codeLines = LineSplitter.split(rules)
          .where((l) => !l.trim().startsWith('//') && l.contains('medical_admin'))
          .toList();
      expect(codeLines.length, 2,
          reason: 'مرة في isCenterAdmin ومرة في منع إنشاء الحساب بالدور');

      final centerBlock =
          RegExp(r'match /medical_center_clinics/\{docId\} \{[\s\S]*?\n    \}')
              .firstMatch(rules)!
              .group(0)!;
      expect(centerBlock.contains('isCenterAdmin()'), isTrue);

      for (final collection in [
        'village_clinics',
        'pharmacies',
        'medical_labs',
        'optical_shops',
        'blood_donors',
        'blood_requests',
      ]) {
        final block = RegExp('match /$collection/\\{docId\\} \\{[\\s\\S]*?\\n    \\}')
            .firstMatch(rules)!
            .group(0)!;
        expect(block.contains('isCenterAdmin'), isFalse,
            reason: '$collection لم تعد لمدير المركز');
        expect(block.contains('isAdmin()'), isTrue,
            reason: '$collection بقيت للمدير العام وأدمنه المساعد');
      }
    });

    test('العامل: إرسال القرية كلها للمدير العام وأدمنه المساعد فقط', () {
      final worker = File('api/push.js').readAsStringSync();
      expect(
          worker.contains("const ALLOWED_ROLES = ['admin', 'assistant_admin'];"),
          isTrue);
      expect(worker.contains('medical: true'), isFalse,
          reason: 'لا نوع مراجعة يُبلَّغ له مدير المركز');
      expect(worker.contains(".where('role', '==', 'admin')"), isTrue);
    });

    test('بوابة الواجهة محصورة في تبويب المركز (الفهرس صفر)', () {
      final ui = File('lib/features/medical/medical_home_screen.dart')
          .readAsStringSync();
      expect(
          ui.contains('if (widget.index != 0 || !_isMedicalAdmin) return null;'),
          isTrue,
          reason: 'لا زر إدارة لمدير المركز خارج عيادات المركز الخيري');
    });
  });
}
