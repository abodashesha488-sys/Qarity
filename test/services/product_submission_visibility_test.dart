import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/product_categories.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/market_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مستند منتج سوق بنفس شكل الكاتب الحقيقي، حتى يطابق `category` و`isApproved`
/// ما تكتبه `addProduct` فعلًا.
Map<String, dynamic> product({
  required String name,
  String category = 'خضار وفواكه',
  bool approved = true,
  String sellerId = 'u1',
  String? shopId,
  DateTime? at,
}) =>
    {
      'name': name,
      'description': 'وصف $name',
      'price': 50,
      'imageUrl': '',
      'imageUrls': <String>[],
      'category': category,
      'sellerName': 'بائع القرية',
      'sellerPhone': '01000000000',
      'sellerId': sellerId,
      if (shopId != null) 'shopId': shopId,
      'stock': 10,
      'isApproved': approved,
      'isOnOffer': false,
      'createdAt': Timestamp.fromDate(at ?? DateTime(2026, 5, 10)),
    };

String src(String path) => File(path).readAsStringSync();

/// جسم دالة `addProduct` من الملف (من رأسها إلى أول `Stream<` بعدها) —
/// لأن الملفات CRLF فلا يصلح عقدٌ متعدد الأسطر بـ`contains`.
String addProductBody(String file) {
  final from = file.indexOf('Future<void> addProduct(');
  final to = file.indexOf('Stream<List<MarketProduct>>', from);
  return file.substring(from, to);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('مصدر كتابة واحد لكل ما يُضاف من المستخدم', () {
    test('الثلاثة مواضع تفتح شاشة إضافة السوق نفسها', () {
      // تبويب «المحلات» داخل السوق، و«نظارات طبية»، و«مستلزمات طبية».
      expect(src('lib/features/market/market_tab_shops.dart'),
          contains('AppRoutes.marketAdd'));
      expect(src('lib/features/medical/optical_shop_detail_screen.dart'),
          contains('AppRoutes.marketAdd'));
      expect(src('lib/features/medical/medical_home_screen.dart'),
          contains('AppRoutes.marketAdd'));
    });

    test('كاتب واحد في كل lib هو MarketService.addProduct', () {
      final writers = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('.addProduct('))
          .map((f) => f.path.replaceAll('\\', '/'))
          .toList();
      expect(writers, ['lib/features/market/add_product.dart'],
          reason: 'لا مسار موازٍ يكتب منتجًا في مجموعة أخرى');
    });

    test('الكاتب يفرض المراجعة ولا يسمع لما زعمه النموذج', () {
      final body = addProductBody(src('lib/services/market_service.dart'));
      expect(body, contains("'isApproved': false,"));
      // الرقعة تُكتب فوق ما جاء في النموذج، فلا يمكن لواجهة أن تُمرّر اعتمادًا.
      expect(body.indexOf("'isApproved': false,"),
          greaterThan(body.indexOf('...product.toJson()')));
    });

    test('قواعد Firestore ترفض أي إنشاء حمل اعتمادًا', () {
      final rules = src('firestore.rules');
      final block = rules.substring(
          rules.indexOf('match /market_products/{docId}'),
          rules.indexOf('match /market_products/{docId}') + 700);
      expect(block,
          contains('allow create: if accountActive() && '
              'request.resource.data.isApproved == false;'));
    });

    test('رسالة النجاح صادقة: المنتج يظهر بعد موافقة الإدارة', () {
      final add = src('lib/features/market/add_product.dart');
      expect(add, contains('يظهر المنتج في سوق القرية بعد موافقة الإدارة'));
      expect(add, isNot(contains("'تمت الإضافة بنجاح'")),
          reason: 'لا وعد بالظهور لمن لم يُعتمد بعد');
      expect(add, contains('أُعيد للمراجعة'));
    });
  });

  group('البوابة هي الاعتماد لا التوجيه', () {
    late FakeFirebaseFirestore fs;
    late MarketService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fs = FakeFirebaseFirestore();
      service = MarketService(firestore: fs);
    });

    test('السوق والعامة يريان المعتمد فقط، وصاحب المنتج يرى معلّقه', () async {
      final col = fs.collection('market_products');
      await col.add(product(name: 'طماطم'));
      await col.add(product(name: 'مانجو', approved: false));

      final public = (await service.getProductsStream().first).map((p) => p.name);
      expect(public, ['طماطم']);

      final mine =
          (await service.getSellerProductsStream('u1').first).map((p) => p.name);
      expect(mine.toSet(), {'طماطم', 'مانجو'},
          reason: 'المعلّق يبقى ظاهرًا لصاحبه لا يختفي كما كان يُشتكى');
    });

    test('«آخر المنتجات» في الرئيسية: معتمدة فقط والأحدث أولًا', () async {
      final col = fs.collection('market_products');
      await col.add(product(name: 'قدم', at: DateTime(2026)));
      await col.add(product(name: 'حديث', at: DateTime(2026, 9)));
      await col.add(
          product(name: 'معلّق', approved: false, at: DateTime(2026, 10)));

      final home = (await service.getProductsStream(limit: 8).first)
          .map((p) => p.name)
          .toList();
      expect(home, ['حديث', 'قدم']);
    });

    test('«مستلزمات طبية» و«نظارات» يريان ما يراه السوق من بوابة واحدة', () async {
      final col = fs.collection('market_products');
      await col.add(product(name: 'كمامات', category: kMedicalSuppliesCategory));
      await col.add(product(
          name: 'كمامات معلّقة',
          category: kMedicalSuppliesCategory,
          approved: false));
      await col.add(product(name: 'جبن'));

      final supplies = (await service
              .getProductsStream(category: kMedicalSuppliesCategory)
              .first)
          .map((p) => p.name);
      expect(supplies, ['كمامات']);
    });

    test('منتج يُضاف الآن: مكتوب في نفس مجموعة السوق ومحجوب للاعتماد', () async {
      await service.addProduct(const MarketProduct(
        id: '',
        name: 'فلفل',
        description: 'من الحقل',
        price: 20,
        imageUrl: '',
        category: kMedicalSuppliesCategory,
        sellerName: 'بائع القرية',
        sellerPhone: '01000000000',
        stock: 10,
        isApproved: true,
      ));

      final docs = await fs.collection('market_products').get();
      expect(docs.docs, hasLength(1));
      expect(docs.docs.single.data()['isApproved'], false,
          reason: 'الاعتماد قرار إداري لا كتابة من الجهاز');
      expect(docs.docs.single.data()['category'], kMedicalSuppliesCategory,
          reason: 'نفس مجموعة سوق القرية، فلا مجموعة موازية تُخفى فيها');

      expect(await service.getProductsStream().first, isEmpty);
      expect(
          await service.getProductsStream(category: kMedicalSuppliesCategory).first,
          isEmpty);

      // وبعد قرار الإدارة يظهر في السوق وفي قسمه الطبي معًا.
      await docs.docs.single.reference.update({'isApproved': true});
      expect((await service.getProductsStream().first).single.name, 'فلفل');
      expect(
          (await service
                  .getProductsStream(category: kMedicalSuppliesCategory)
                  .first)
              .single
              .name,
          'فلفل');
    });
  });
}
