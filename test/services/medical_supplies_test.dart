import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/product_categories.dart';
import 'package:qurity/core/constants/promo_placements.dart';
import 'package:qurity/features/medical/medical_home_screen.dart';
import 'package:qurity/routes/app_routes.dart';
import 'package:qurity/services/market_service.dart';
import 'package:qurity/widgets/med_grid_tile.dart';

/// مستند منتج سوق بنفس شكل الكاتب الحقيقي في «إضافة منتج»، حتى يطابق
/// `category` نصَّ الاستعلام الخادمي حرفيًا.
Map<String, dynamic> product({
  required String name,
  String category = kMedicalSuppliesCategory,
  bool approved = true,
  double price = 120,
  int stock = 5,
  String sellerName = 'صيدلية القرية',
  String description = 'وصف المستلزم',
  bool isOnOffer = false,
  double? offerPrice,
  DateTime? at,
}) =>
    {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': '',
      'imageUrls': <String>[],
      'category': category,
      'sellerName': sellerName,
      'sellerPhone': '01000000000',
      'stock': stock,
      'isApproved': approved,
      'isOnOffer': isOnOffer,
      if (offerPrice != null) 'offerPrice': offerPrice,
      'createdAt': Timestamp.fromDate(at ?? DateTime(2026, 5, 10)),
    };

Future<void> pumpSupplies(WidgetTester tester, MarketService service) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar', 'EG'),
    home: MedicalSectionScreen(index: 6, marketService: service),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

/// حقل البحث وحده في شاشة القسم — يُلتقط بالنوع لا بالتلميح لأن التلميح يزول
/// لحظة الكتابة فلا يبقى `widgetWithText` دليلاً ثابتًا.
final Finder _searchField = find.byType(TextField);

void main() {
  group('قسم المستلزمات الطبية: منتجات السوق المعتمدة بتصنيفه وحده', () {
    test('التصنيف مصدر واحد: ثابتٌ واحد يكتبه النموذج ويقرؤه القسم', () {
      expect(kMedicalSuppliesCategory, 'مستلزمات طبية');
      expect(kProductCategories, contains(kMedicalSuppliesCategory));
      final src =
          File('lib/core/constants/product_categories.dart').readAsStringSync();
      // النص الحرفي يظهر مرة واحدة فقط (سطر التعريف)؛ القائمة تُدرج بالثابت.
      expect(RegExp("'مستلزمات طبية'").allMatches(src).length, 1);
    });

    test('التصفية خادمية بمساواة واحدة إضافية، وorderBy لا يُطلَّق مع القسم',
        () {
      final src = File('lib/services/market_service.dart').readAsStringSync();
      final block = src.substring(
          src.indexOf('Stream<List<MarketProduct>> getProductsStream'),
          src.indexOf('Stream<List<MarketProduct>> getSellerProductsStream'));
      expect(block, contains('String? category'));
      expect(block, contains("where('category', isEqualTo: category)"));
      // الفرز الوحيد في هذا التدفّق مقصور على فرع `limit`، والقسم لا يمرّ limit
      // (مثبّت في عقد الشاشة) — فالاستعلام مساواتان بلا فهرس مركّب، ووثيقة بلا
      // `createdAt` لا تختفي منه.
      expect(block, contains('if (limit != null) {'));
      expect(
          block.indexOf('query.orderBy'),
          greaterThan(block.indexOf('if (limit != null) {')),
          reason: 'orderBy لا يسبق بوابة limit');
      final screen = File('lib/features/medical/medical_home_screen.dart')
          .readAsStringSync();
      expect(screen,
          contains('getProductsStream(category: kMedicalSuppliesCategory)'));
      expect(screen, isNot(contains('getProductsStream(limit:')));
    });

    testWidgets('البوابة: البلاطة السابعة بلاطة صورة بـ doctor5.jpg',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: MedicalHomeScreen())));
      await tester.pump(const Duration(milliseconds: 600));

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      String assetOf(Image i) => i.image is ResizeImage
          ? (i.image as ResizeImage).imageProvider.toString()
          : i.image.toString();
      expect(
          images.any((i) =>
              assetOf(i).contains('assets/images/doctor5.jpg') &&
              i.semanticLabel == 'المستلزمات الطبية'),
          isTrue,
          reason: 'بلاطة بصورة القسم وباسمه للإقرأية');
      expect(MedicalHomeScreen.colors.last, kMedicalSuppliesAccent);
    });

    testWidgets('المعتمد بتصنيف القسم يظهر، والمعلّق وغير الطبي يخفى',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('market_products').add(product(name: 'سماعات نظرية'));
      await fs
          .collection('market_products')
          .add(product(name: 'محلول تعقيم', approved: false));
      await fs.collection('market_products')
          .add(product(name: 'خلاط كهربائي', category: 'أدوات منزلية ومنظفات'));
      await pumpSupplies(tester, MarketService(firestore: fs));

      expect(find.text('سماعات نظرية'), findsOneWidget);
      expect(find.text('محلول تعقيم'), findsNothing);
      expect(find.text('خلاط كهربائي'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('الأحدث أولًا وكرتان في السطر بارتفاع الشبكة', (tester) async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('market_products')
          .add(product(name: 'القديم', at: DateTime(2026, 2)));
      await fs.collection('market_products')
          .add(product(name: 'الحديث', at: DateTime(2026, 9)));
      await fs.collection('market_products')
          .add(product(name: 'الأوسط', at: DateTime(2026, 5)));
      await pumpSupplies(tester, MarketService(firestore: fs));

      final tiles = find.byType(MedGridTile);
      expect(tiles, findsNWidgets(3));
      expect(tester.widget<MedGridTile>(tiles.at(0)).title, 'الحديث');
      expect(tester.widget<MedGridTile>(tiles.at(1)).title, 'الأوسط');
      final first = tester.getRect(tiles.at(0));
      final second = tester.getRect(tiles.at(1));
      expect(first.height, 252);
      expect(first.top, second.top, reason: 'كرتان في السطر نفسه');
      expect(first.left, isNot(second.left));
      expect(first.width, lessThan(200));
    });

    testWidgets('السعر شارة: العرض يُخفضه ويوسم النسبة، والنفاد يُعلن',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('market_products').add(product(
            name: 'جهاز ضغط رقمي',
            price: 400,
            isOnOffer: true,
            offerPrice: 300,
            stock: 0,
          ));
      await pumpSupplies(tester, MarketService(firestore: fs));

      expect(find.text('300 ج.م'), findsOneWidget); // الفعلي لا الأصلي
      expect(find.text('400 ج.م'), findsNothing);
      expect(find.text('-25٪ عرض'), findsOneWidget);
      expect(find.text('نفد المخزون'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('البحث يرشّح الاسم والوصف والبائع ولا يُفقد التركيز',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('market_products')
          .add(product(name: 'شاش جهاز', description: 'استبدال فوري'));
      await fs.collection('market_products')
          .add(product(name: 'كمامات', sellerName: 'ورشة النظارات'));
      await pumpSupplies(tester, MarketService(firestore: fs));
      expect(find.byType(MedGridTile), findsNWidgets(2));
      expect(_searchField, findsOneWidget);

      // النصوص تُقاس داخل البطاقات وحدها: `find.text` يرى أيضًا ما كتبته في
      // حقل البحث نفسه (EditableText)، فيصير «اثنان» بلا معنى.
      Finder cardText(String t) =>
          find.descendant(of: find.byType(MedGridTile), matching: find.text(t));

      await tester.enterText(_searchField, 'كمامات');
      await tester.pump();
      expect(cardText('كمامات'), findsOneWidget);
      expect(cardText('شاش جهاز'), findsNothing);

      await tester.enterText(_searchField, 'استبدال');
      await tester.pump();
      expect(cardText('شاش جهاز'), findsOneWidget);
      expect(cardText('كمامات'), findsNothing);

      await tester.enterText(_searchField, 'النظارات');
      await tester.pump();
      expect(cardText('كمامات'), findsOneWidget); // واسم البائع
      // نفس الوست بعد ثلاث إعادة بناء ⇒ التدفق مثبّت والنص باقٍ في الحقل.
      expect(
          tester.widget<TextField>(_searchField).controller!.text, 'النظارات');
    });

    testWidgets('لا مستلزمات معتمدة ⇒ حالة فراغ صادقة لا قائمة كاذبة',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('market_products').add(product(
          name: 'توصيلة كهربا', category: 'أدوات منزلية ومنظفات'));
      await fs
          .collection('market_products')
          .add(product(name: 'محلول مخفي', approved: false));
      await pumpSupplies(tester, MarketService(firestore: fs));
      expect(find.byType(MedGridTile), findsNothing);
      expect(find.text('لا توجد مستلزمات طبية معتمدة بعد'), findsOneWidget);
      expect(find.text('توصيلة كهربا'), findsNothing);
    });

    test('موضع الدعاية والرابط الداخلي للفهرس 6', () {
      expect(promoKeyForRoute(AppRoutes.medicalSection, 6), 'med_supplies');
      expect(
          kPromoPlacements
              .any((p) => p.key == 'med_supplies' && p.group == 'المركز الطبي'),
          isTrue);
      expect(
          kPromoInternalLinks.any((l) =>
              l.route == AppRoutes.medicalSection &&
              l.arg == '6' &&
              l.label.contains('مستلزمات طبية')),
          isTrue);
      expect(PromoInternalLink.decode('/medical/section|6').$2, 6);
    });

    test('زر «+» يفتح «إضافة منتج» بفئة القسم وحدها — بلا مجموعة ثانية', () {
      final src = File('lib/features/medical/medical_home_screen.dart')
          .readAsStringSync();
      expect(
          src, contains("6 => (run: _addSupply, label: 'أضف مستلزمًا طبيًا')"));
      expect(
          src, contains('kCategoryOptionsArgKey: const [kMedicalSuppliesCategory]'));
      expect(src,
          contains('getProductsStream(category: kMedicalSuppliesCategory)'));
      // القسم لا يخترع مجموعة ولا نموذجًا ولا قناة مراجعة.
      expect(src, isNot(contains('medical_supplies')));
      expect(File('firestore.rules').readAsStringSync(),
          isNot(contains('medical_supplies')));
      expect(File('lib/services/admin_service.dart').readAsStringSync(),
          isNot(contains('medical_supplies')));
    });
  });
}
