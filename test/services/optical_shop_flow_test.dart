import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/market/add_product.dart';
import 'package:qurity/models/medical_models.dart';
import 'package:qurity/services/market_service.dart';
import 'package:qurity/services/medical_service.dart';
import 'package:qurity/services/user_service.dart';

/// تدفق محل النظارات بعد الإنشاء:
///  • الإعلان يبدأ عاديًا، ونوعه يُختار من صفحة المحل
///  • «أضف منتجاً لمحلي» يعرض تخصصات النظارات لا فئات السوق
Future<void> _openAddProduct(
  WidgetTester tester, {
  List<String>? categoryOptions,
}) async {
  final fake = FakeFirebaseFirestore();
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              settings: RouteSettings(
                arguments: categoryOptions == null
                    ? null
                    : <String, dynamic>{
                        kCategoryOptionsArgKey: categoryOptions,
                      },
              ),
              builder: (_) => AddMarketProductScreen(
                userService: UserService(fake),
                marketService: MarketService(firestore: fake),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

List<String?> _dropdownValues(WidgetTester tester) => tester
    .widgetList<DropdownMenuItem<String>>(find.byType(DropdownMenuItem<String>))
    .map((i) => i.value)
    .toList();

/// يفتح قائمة الفئات ثم يقرأ عناصرها (الحقل مغلقًا يعرض المحدد فقط).
Future<Set<String?>> _openCategoryMenu(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  return _dropdownValues(tester).toSet();
}

void main() {
  group('محل النظارات — نوع الإعلان بعد الإنشاء', () {
    test('المحل الجديد إعلان عادي بلا نافذة عرض', () {
      const shop = OpticalShop(id: 's1', name: 'نظارات النور');
      expect(shop.adType, kOpticalAdNormal);
      expect(shop.featuredUntil, isNull);
      expect(shop.isFeaturedAd, isFalse);
      expect(shop.adLiveAt(DateTime(2026, 10)), isFalse);
      // العادي يبقى ظاهرًا في الدليل، فلا يختفي المحل لأنه لم يختر عرضًا.
      expect(shop.visibleAt(DateTime(2026, 10)), isTrue);
    });

    test('الخدمة تحفظه عاديًا ثم تفعّل المميز من صفحة المحل', () async {
      final fake = FakeFirebaseFirestore();
      final svc = OpticalShopService(fake);
      const shop = OpticalShop(
        id: '',
        name: 'نظارات النور',
        submittedBy: 'u1',
        categories: ['نظارات طبية'],
      );
      await svc.create(shop);

      final saved = fake.collection('optical_shops');
      final doc = (await saved.get()).docs.single;
      expect(doc.data()['adType'], kOpticalAdNormal);
      expect(doc.data()['featuredUntil'], isNull);

      await svc.setFeaturedWindow(doc.id, 7);
      final after = (await saved.doc(doc.id).get()).data()!;
      expect(after['adType'], kOpticalAdFeatured);
      expect((after['featuredUntil'] as Timestamp).toDate().isAfter(DateTime.now()),
          isTrue);
    });
  });

  group('«أضف منتجاً لمحلي» — فئات النظارات', () {
    testWidgets('بلا وسائط: فئات السوق المعتادة', (tester) async {
      await _openAddProduct(tester);
      expect(find.text('إضافة منتج'), findsOneWidget);
      final values = await _openCategoryMenu(tester);
      expect(values, contains('خضار وفواكه'));
      expect(values, isNot(contains('عدسات لاصقة')));
    });

    testWidgets('بتخصيصات النظارات: نفس التخصصات التي ظهرت عند إنشاء المحل',
        (tester) async {
      await _openAddProduct(tester, categoryOptions: kOpticalCategories);
      // المحدد افتراضيًا أول التخصصات، لا فئة سوق عامّة.
      expect(find.text('نظارات طبية'), findsWidgets);
      expect(find.text('مواد غذائية'), findsNothing);
      final values = await _openCategoryMenu(tester);
      expect(values, kOpticalCategories.toSet());
      // لا تسرّب فئات السوق العامة إلى قائمة محل النظارات.
      expect(values, isNot(contains('خضار وفواكه')));
    });

    testWidgets('قائمة فارغة مرسلة = تراجع إلى فئات السوق (لا قائمة معطلة)',
        (tester) async {
      await _openAddProduct(tester, categoryOptions: const []);
      expect(await _openCategoryMenu(tester), contains('خضار وفواكه'));
    });
  });
}
