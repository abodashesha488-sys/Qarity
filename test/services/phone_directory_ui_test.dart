import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/arabic_sort_key.dart';
import 'package:qurity/core/utils/contact_links.dart';
import 'package:qurity/features/phone/directory.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/services/phone_directory_service.dart';
import 'package:qurity/widgets/whatsapp_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات الأجزاء المعدّلة في «دليل الهاتف» فقط: أيقونة الاتصال الخضراء،
/// فتح البطاقة بالنقر على الاسم، زر واتساب برمز واتساب ومراسلة مباشرة،
/// والترتيب الأبجدي العربي.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('مفتاح الترتيب العربي', () {
    test('يوحّد صور الألف والهمزة', () {
      expect(arabicSortKey('أحمد'), arabicSortKey('احمد'));
      expect(arabicSortKey('آدم'), arabicSortKey('ادم'));
      expect(arabicSortKey('إسماعيل'), arabicSortKey('اسماعيل'));
    });

    test('يوحّد التاء المربوطة والألف المقصورة والواو والياء المهموزتين', () {
      expect(arabicSortKey('مدرسة'), arabicSortKey('مدرسه'));
      expect(arabicSortKey('سعى'), arabicSortKey('سعي'));
      expect(arabicSortKey('مسئول'), arabicSortKey('مسيول'));
      expect(arabicSortKey('سؤدد'), arabicSortKey('سودد'));
    });

    test('يزيل التشكيل والتطويل وعلامات أخرى', () {
      expect(arabicSortKey('مُحَمَّد'), 'محمد');
      expect(arabicSortKey('محمـد'), 'محمد');
    });

    test('يستعمل الرقم كمراتب ثانوي عند تساوي الاسمين', () async {
      final fake = FakeFirebaseFirestore();
      final svc = PhoneDirectoryService(fake);
      await fake.collection('phone_directory').doc('b').set({
        'name': 'سالم', 'phone': '0122', 'title': '', 'isApproved': true
      });
      await fake.collection('phone_directory').doc('a').set({
        'name': 'سالم', 'phone': '0100', 'title': '', 'isApproved': true
      });
      final list = await svc.getVisibleEntriesList(null);
      expect(list.map((e) => e.id), ['a', 'b']);
    });
  });

  group('الخدمة تُرجع الدليل مرتّبًا أبجديًا', () {
    Future<FakeFirebaseFirestore> seed() async {
      final fake = FakeFirebaseFirestore();
      // الإدخال بالعكس وبصور ألف مختلفة ليثبت الترتيب لا مصادفة الإدخال.
      await fake.collection('phone_directory').doc('t').set({
        'name': 'توفيق', 'phone': '0133', 'title': '', 'isApproved': true
      });
      await fake.collection('phone_directory').doc('i').set({
        'name': 'إسماعيل', 'phone': '0122', 'title': '', 'isApproved': true
      });
      await fake.collection('phone_directory').doc('a').set({
        'name': 'آدم', 'phone': '0111', 'title': '', 'isApproved': true
      });
      await fake.collection('phone_directory').doc('h').set({
        'name': 'أحمد', 'phone': '0100', 'title': '', 'isApproved': true
      });
      return fake;
    }

    test('getVisibleEntriesList: أحمد ثم آدم ثم إسماعيل ثم توفيق', () async {
      final svc = PhoneDirectoryService(await seed());
      final names = (await svc.getVisibleEntriesList(null)).map((e) => e.name);
      expect(names, ['أحمد', 'آدم', 'إسماعيل', 'توفيق']);
    });

    test('getApprovedEntriesList مرتّبة كذلك وتُخفي غير المعتمد', () async {
      final fake = await seed();
      await fake.collection('phone_directory').doc('p').set({
        'name': 'أبكر', 'phone': '0144', 'title': '', 'isApproved': false
      });
      final svc = PhoneDirectoryService(fake);
      final names = (await svc.getApprovedEntriesList(forceRefresh: true))
          .map((e) => e.name);
      expect(names, ['أحمد', 'آدم', 'إسماعيل', 'توفيق']);
    });

    test('لا ترتيب على الخادم: لا orderBy في الخدمة ولا فهرس للدليل', () {
      final service =
          File('lib/services/phone_directory_service.dart').readAsStringSync();
      expect(service, isNot(contains('orderBy(')));
      expect(service, contains('_byArabicName('));
      final indexes =
          File('firestore.indexes.json').readAsStringSync();
      expect(indexes, isNot(contains('phone_directory')));
    });
  });

  group('صفحة دليل الهاتف', () {
    const entryId = 'c1';

    Future<FakeFirebaseFirestore> seedPage(
        {String phone = '01001234567'}) async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('phone_directory').doc(entryId).set({
        'name': 'الشيخ صبري',
        'phone': phone,
        'secondaryPhone': '01112223334',
        'title': 'إمام',
        'job': 'إمام',
        'address': 'شارع المسجد',
        'isApproved': true,
      });
      await fake.collection('phone_directory').doc('c2').set({
        'name': 'أحمد',
        'phone': '01223334455',
        'title': '',
        'isApproved': true,
      });
      return fake;
    }

    Future<void> openPage(WidgetTester tester,
        {String phone = '01001234567'}) async {
      final svc = PhoneDirectoryService(await seedPage(phone: phone));
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(textDirection: TextDirection.rtl,
            child: PhoneDirectoryScreen(embedded: true, service: svc)),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('أيقونة الاتصال في الصفّ خضراء', (tester) async {
      await openPage(tester);
      final button = tester.widget<IconButton>(
          find.byKey(const Key('phone-row-call-$entryId')));
      expect(button.style?.backgroundColor?.resolve({}), kCallButtonColor);
      expect(button.icon, isA<Icon>());
    });

    testWidgets('النقر على اسم السجل يفتح بطاقته', (tester) async {
      await openPage(tester);
      expect(find.byKey(const Key('phone-card-call')), findsNothing);
      await tester.tap(find.byKey(const Key('phone-row-name-$entryId')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('phone-card-call')), findsOneWidget);
      expect(find.text('الشيخ صبري'), findsWidgets);
      expect(find.text('01001234567'), findsOneWidget);
    });

    testWidgets('البطاقة: اتصال أخضر + واتساب بأخضره ورمزه', (tester) async {
      await openPage(tester);
      await tester.tap(find.byKey(const Key('phone-row-name-$entryId')));
      await tester.pumpAndSettle();

      final call = tester.widget<FilledButton>(
          find.byKey(const Key('phone-card-call')));
      expect(call.style?.backgroundColor?.resolve({}), kCallButtonColor);

      final wa = tester.widget<FilledButton>(
          find.byKey(const Key('phone-card-whatsapp')));
      expect(wa.style?.backgroundColor?.resolve({}), kWhatsAppGreen);
      expect(find.descendant(
          of: find.byKey(const Key('phone-card-whatsapp')),
          matching: find.byType(WhatsAppMark)), findsOneWidget);
      expect(wa.onPressed, isNotNull);
    });

    testWidgets('الرقم غير الصالح يُعطّل واتساب بكلمة صادقة لا اختفاء',
        (tester) async {
      await openPage(tester, phone: '123');
      await tester.tap(find.byKey(const Key('phone-row-name-$entryId')));
      await tester.pumpAndSettle();
      final wa = tester.widget<FilledButton>(
          find.byKey(const Key('phone-card-whatsapp')));
      expect(wa.onPressed, isNull);
      final tip = tester.widget<Tooltip>(find.ancestor(
          of: find.byKey(const Key('phone-card-whatsapp')),
          matching: find.byType(Tooltip)));
      expect(tip.message, 'الرقم غير صالح للمراسلة على واتساب');
    });

    testWidgets('العنوان المبني للمراسلة هو عنوان مصر الموحّد', (tester) async {
      await openPage(tester);
      expect(egyptianWhatsAppUrl('01001234567'), 'https://wa.me/201001234567');
    });

    /// منفذ url_launcher وهمي على القناة نفسها (`plugins.flutter.io/url_launcher`)
    /// بلا插件 في بيئة الاختبار: الردود تصل في نفس الدورة اللحظية المزيفة،
    /// فمسار الفشل يُختَبَر لا يُنتظر. الاستجابة الآن تُقرأ من `launchUrl` نفسه
    /// بعد أن زالت بوّابة `canLaunchUrl` — فـ`false` تعني «الفتح رُفض».
    void stubLauncher(WidgetTester tester, {bool launchable = false, bool throwOnLaunch = false}) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async {
          if (throwOnLaunch) throw PlatformException(code: 'no-handler');
          return launchable;
        },
      );
    }

    Future<void> openCard(WidgetTester tester, {String phone = '01001234567'}) async {
      await openPage(tester, phone: phone);
      await tester.tap(find.byKey(const Key('phone-row-name-$entryId')));
      await tester.pumpAndSettle();
    }

    testWidgets('فشل المراسلة داخل البطاقة يُعلن فيها أحمر', (tester) async {
      stubLauncher(tester); // canLaunch == false ⇒ لا واتساب على هذا الجهاز
      await openCard(tester);
      expect(find.byKey(const Key('phone-card-error')), findsNothing);
      await tester.tap(find.byKey(const Key('phone-card-whatsapp')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final error = tester.widget<Text>(find.byKey(const Key('phone-card-error')));
      expect(error.data, 'واتساب غير متاح على هذا الجهاز.');
      expect(error.style?.color, const Color(0xFFB71C1C));
    });

    testWidgets('استثناء المشغّل يُعلن هو الآخر في البطاقة', (tester) async {
      stubLauncher(tester, throwOnLaunch: true);
      await openCard(tester);
      await tester.tap(find.byKey(const Key('phone-card-call')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('phone-card-error')), findsOneWidget);
      expect(find.text('تعذّر بدء المكالمة — أعد المحاولة.'), findsOneWidget);
    });

    testWidgets('رقم فارغ: كلمة صادقة في البطاقة لا شريط خلفها', (tester) async {
      await openCard(tester, phone: '');
      await tester.tap(find.byKey(const Key('phone-card-call')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('لا يوجد رقم هاتف في هذا البيان.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('القائمة تعرض الأسماء أبجديًا على الشاشة', (tester) async {
      await openPage(tester);
      final names = ['أحمد', 'الشيخ صبري'];
      final ys = names
          .map((n) => tester
              .getTopLeft(find.text(n, skipOffstage: false).first)
              .dy)
              .toList();
      expect(ys[0], lessThan(ys[1]));
    });

    testWidgets('دليل الصفحة لا يبني رابط واتساب بنفسه', (tester) async {
      final page = File('lib/features/phone/directory.dart').readAsStringSync();
      // لا نصّ رابط ولا بناء عنوان هنا: `egyptianWhatsAppUrl` مصدر وحيد.
      expect(page, isNot(contains('https://wa.me')));
      expect(page, contains('egyptianWhatsAppUrl('));
      expect(page, contains('WhatsAppMark('));
      expect(page, contains('kCallButtonColor'));
    });
  });

  group('رمز واتساب المرسوم', () {
    testWidgets('يُرسم بالمقاس المطلوب ويُلون بلونه', (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: Center(
              child: WhatsAppMark(
                  size: 30, color: Color(0xFF123456)))));
      final paint = tester.widget<CustomPaint>(find.byWidgetPredicate(
          (w) => w is CustomPaint && w.size == const Size.square(30)));
      expect(paint.size, const Size.square(30));
      expect(paint.painter, isNotNull);
    });
  });
}
