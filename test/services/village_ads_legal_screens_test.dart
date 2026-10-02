import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/legal_reference_egypt.dart';
import 'package:qurity/features/ads/village_ad_detail_screen.dart';
import 'package:qurity/features/ads/village_ads_screen.dart';
import 'package:qurity/features/legal/lawyer_detail_screen.dart';
import 'package:qurity/features/legal/legal_advisor_screen.dart';
import 'package:qurity/models/legal_models.dart';
import 'package:qurity/models/village_ad_model.dart';
import 'package:qurity/services/legal_service.dart';
import 'package:qurity/services/village_ad_service.dart';

/// واجهتا «إعلانات القرية» و«مستشار القرية»: ما يراه الأهالي فعلًا — المعتمد
/// فقط في العامة، والمرجع القانوني بلا شبكة، وصفر فيضان على مقاس الهاتف.
void main() {
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532); // 390×844 منطقيًا
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// البطاقات تدخل بتدرّج `flutter_animate` مؤجّل، والستريم يصل بعد إطار،
  /// فالضخّ الزمني (لا pumpAndSettle الذي لا يستقر مع المؤشرات) هو الدليل.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 2));
    // `flutter_animate` يؤجّل بمؤقّر صفري عند البناء، وآخر ضخّ يُطفيهِ وإلا
    // انتهى الاختبار بـ«Pending timers».
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull, reason: 'صفر استثناء/صفر فيضان');
  }

  /// شريط المرشّحات أفقي وكسول: البلاطة الأخيرة لا تُبنى إلا بعد سحب.
  final Finder chipsStrip = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal);

  /// تسمية داخل بلاطة مرشّح، لا داخل بطاقة إعلان (نص النوع مكرر هناك).
  Finder kindChip(String label) => find.descendant(
      of: find.byType(ChoiceChip), matching: find.text(label));


  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    usePhone(tester);
    await tester.pumpWidget(MaterialApp(home: screen));
    await settle(tester);
  }

  /// شاشات التفاصيل تقرأ نموذجها من وسائط المسار، فلا مناص من دفعها فعليًا.
  Future<void> pushDetail(WidgetTester tester, Widget screen, Object args) async {
    usePhone(tester);
    var pushed = false;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        if (!pushed) {
          pushed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => screen,
                    settings: RouteSettings(arguments: args)));
          });
        }
        return const SizedBox.shrink();
      }),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  }

  group('إعلانات القرية', () {
    testWidgets('الدليل العام: المعتمد فقط، والمعلّق لا يظهر لأحد', (tester) async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('village_ads').add({
        'title': 'محل بلاطات الأمل',
        'kind': 'إنشائية',
        'businessName': 'بلاطات الأمل',
        'isApproved': true,
        'userId': 'u2',
        'createdAt': DateTime(2026, 10),
      });
      await fake.collection('village_ads').add({
        'title': 'إعلاني المعلّق',
        'kind': 'خدمية',
        'isApproved': false,
        'userId': 'u1',
        'createdAt': DateTime(2026, 10, 2),
      });
      await pumpScreen(
          tester, VillageAdsScreen(service: VillageAdService(fake)));
      expect(find.text('إعلانات القرية'), findsOneWidget);
      expect(find.text('محل بلاطات الأمل'), findsOneWidget);
      expect(find.text('إعلاني المعلّق'), findsNothing);
    });

    testWidgets('البحث يصفّي لحظيًا، وبلا نتيجة يقول ذلك', (tester) async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('village_ads').add({
        'title': 'معرض ستائر النور',
        'kind': 'تجارية',
        'isApproved': true,
        'createdAt': DateTime(2026, 10),
      });
      await pumpScreen(
          tester, VillageAdsScreen(service: VillageAdService(fake)));
      await tester.enterText(find.byKey(const Key('ads-search')), 'ستائر');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('معرض ستائر النور'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('ads-search')), 'لا شيء هنا');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('معرض ستائر النور'), findsNothing);
      expect(find.text('لا توجد إعلانات مطابقة'), findsOneWidget);
    });

    testWidgets('شريحة النوع تحصر الإعلانات في نوعها', (tester) async {
      final fake = FakeFirebaseFirestore();
      final now = DateTime(2026, 10);
      await fake.collection('village_ads').add({
        'title': 'محل بقالة',
        'kind': 'تجارية',
        'isApproved': true,
        'createdAt': now,
      });
      await fake.collection('village_ads').add({
        'title': 'سبّاب وعزل أسطح',
        'kind': 'إنشائية',
        'isApproved': true,
        'createdAt': now.add(const Duration(days: 1)),
      });
      await pumpScreen(
          tester, VillageAdsScreen(service: VillageAdService(fake)));
      expect(find.text('محل بقالة'), findsOneWidget);
      expect(find.text('سبّاب وعزل أسطح'), findsOneWidget);

      await tester.dragUntilVisible(
          kindChip('إنشائية'), chipsStrip.first, const Offset(-150, 0));
      await settle(tester);
      await tester.tap(find.descendant(
          of: find.byType(ChoiceChip), matching: find.text('إنشائية')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('سبّاب وعزل أسطح'), findsOneWidget);
      expect(find.text('محل بقالة'), findsNothing);
    });

    testWidgets('«إعلاناتي» بلا جلسة تقول سجّل الدخول — لا قائمة فارغة كاذبة', (tester) async {
      await pumpScreen(tester,
          VillageAdsScreen(service: VillageAdService(FakeFirebaseFirestore())));
      await tester.dragUntilVisible(find.byKey(const Key('ads-mine-toggle')),
          chipsStrip.first, const Offset(-150, 0));
      await settle(tester);
      await tester.tap(find.byKey(const Key('ads-mine-toggle')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('سجّل الدخول لترى إعلاناتك'), findsOneWidget);
    });

    testWidgets('التفاصيل: العنوان والوصف والتواصل، ولا أزرار مالك بلا جلسة', (tester) async {
      final ad = VillageAd.fromJson({
        'title': 'مصنع طوب جوّال',
        'kind': 'إنشائية',
        'businessName': 'مصنع الجوالة',
        'description': 'طوب إنترلوك ومبلّط بأيدٍ من القرية، والتسليم في نفس '
            'الأسبوع للكميات الكبيرة داخل أبوديشيشة والقرى المجاورة.',
        'phone': '01000000000',
        'location': 'الطرف البحري',
        'isApproved': true,
        'userId': 'u2',
        'createdAt': DateTime(2026, 10),
      }, 'ad1');
      await pushDetail(tester,
          VillageAdDetailScreen(service: VillageAdService(FakeFirebaseFirestore())),
          ad);
      expect(find.text('مصنع طوب جوّال'), findsWidgets);
      expect(find.textContaining('طوب إنترلوك'), findsOneWidget);
      expect(find.text('اتصال'), findsOneWidget);
      expect(find.text('واتساب'), findsOneWidget);
      // لا جلسة ⇒ لا «تعديل إعلاني»/«حذف إعلاني»: التحكم للمالك والإدارة.
      expect(find.text('تعديل إعلاني'), findsNothing);
      expect(find.text('حذف إعلاني'), findsNothing);
    });

    testWidgets('لا فيضان على مقاس الهاتف لأطول إعلان', (tester) async {
      final fake = FakeFirebaseFirestore();
      final long = 'نصّ طويل جدًا ' * 12;
      await fake.collection('village_ads').add({
        'title': 'ورشة نجارة وتفصيل أثاث خشبي بالطابق الأرضي من المنزل البحري',
        'kind': 'خدمية',
        'businessName': long,
        'description': long,
        'location': long,
        'phone': '01000000000',
        'isApproved': true,
        'userId': 'u1',
        'createdAt': DateTime(2026, 10),
      });
      await pumpScreen(
          tester, VillageAdsScreen(service: VillageAdService(fake)));
      await tester.drag(
          find.byWidgetPredicate((w) =>
              w is ListView && w.scrollDirection == Axis.vertical),
          const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  });

  group('مستشار القرية', () {
    testWidgets('تبويبات ثلاثة، وسجل المحامين يخفي غير المعتمد', (tester) async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('lawyers').add({
        'name': 'أ/سمير عبدالباسط',
        'specializations': ['أحوال شخصية', 'تنفيذ أحكام'],
        'phone': '01111111111',
        'isApproved': true,
        'submittedBy': 'l1',
        'createdAt': DateTime(2026, 9),
      });
      await fake.collection('lawyers').add({
        'name': 'أ/معلّق في الانتظار',
        'isApproved': false,
        'submittedBy': 'l2',
        'createdAt': DateTime(2026, 10),
      });
      await pumpScreen(tester, LegalAdvisorScreen(
          lawyers: LawyerService(fake),
          consultations: LegalConsultationService(fake)));
      expect(find.text('مستشار القرية'), findsOneWidget);
      expect(find.text('المحامون'), findsOneWidget);
      expect(find.text('الاستشارات'), findsOneWidget);
      expect(find.text('معلومات قانونية'), findsOneWidget);
      expect(find.text('أ/سمير عبدالباسط'), findsOneWidget);
      expect(find.text('أ/معلّق في الانتظار'), findsNothing);
    });

    testWidgets('تبويب الاستشارات: السؤال المعتمد، والمعلّق محجوب', (tester) async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('legal_consultations').add({
        'question': 'ما مدة رفع دعوى الجبابة؟',
        'answer': 'الواجب سؤال محامٍ يطلع على الأوراق.',
        'category': 'أحوال شخصية',
        'isApproved': true,
        'userId': 'u2',
        'createdAt': DateTime(2026, 10),
      });
      await fake.collection('legal_consultations').add({
        'question': 'سؤال معلّق خاص',
        'isApproved': false,
        'userId': 'u2',
        'createdAt': DateTime(2026, 10, 2),
      });
      await pumpScreen(tester, LegalAdvisorScreen(
          lawyers: LawyerService(fake),
          consultations: LegalConsultationService(fake)));
      await tester.tap(find.text('الاستشارات'));
      await settle(tester);
      expect(find.text('ما مدة رفع دعوى الجبابة؟'), findsOneWidget);
      expect(find.text('سؤال معلّق خاص'), findsNothing);
    });

    testWidgets('المرجع القانوني ثابت: التنبيه ثم الموضوعات، وبلا زر إضافة', (tester) async {
      await pumpScreen(tester, LegalAdvisorScreen(
          lawyers: LawyerService(FakeFirebaseFirestore()),
          consultations: LegalConsultationService(FakeFirebaseFirestore())));
      expect(find.byKey(const Key('header-add')), findsOneWidget);
      await tester.tap(find.text('معلومات قانونية'));
      await settle(tester);
      expect(find.text(kLegalReferenceTopics.first.title), findsWidgets);
      expect(find.textContaining('ليست بديلًا'), findsWidgets);
      // المرجع بيانات مضمّنة: لا إضافة ولا نموذج ولا شاشة كتابة فيه.
      expect(find.byKey(const Key('header-add')), findsNothing);
    });

    testWidgets('صفحة المحامي: الاسم والتخصصات والتواصل', (tester) async {
      final lawyer = Lawyer.fromJson({
        'name': 'أ/كرم السيد',
        'specializations': ['قضايا جنائية', 'أراضي وريفيات'],
        'phone': '01222222222',
        'address': 'أبو ديشيشة — أمام المسجد الكبير',
        'isApproved': true,
        'submittedBy': 'l1',
      }, 'l1');
      await pushDetail(tester,
          LawyerDetailScreen(service: LawyerService(FakeFirebaseFirestore())),
          lawyer);
      expect(find.text('أ/كرم السيد'), findsWidgets);
      expect(find.textContaining('قضايا جنائية'), findsWidgets);
      expect(find.text('اتصال'), findsOneWidget);
    });
  });
}
