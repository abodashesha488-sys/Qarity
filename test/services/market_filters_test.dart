import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/market_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _product({
  required String name,
  required String category,
  required String sellerId,
  required double price,
  bool isApproved = true,
  bool isFeatured = false,
  bool isOnOffer = false,
  String productStatus = 'regular',
  int stock = 5,
  DateTime? createdAt,
}) {
  return {
    'name': name,
    'description': 'وصف',
    'price': price,
    'imageUrl': '',
    'category': category,
    'sellerName': 'بائع',
    'sellerPhone': '0100',
    'sellerId': sellerId,
    'isApproved': isApproved,
    'isFeatured': isFeatured,
    'isOnOffer': isOnOffer,
    'productStatus': productStatus,
    'stock': stock,
    'createdAt': createdAt == null
        ? null
        : Timestamp.fromDate(createdAt),
  };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<FakeFirebaseFirestore> seed() async {
    final fake = FakeFirebaseFirestore();
    final products = <Map<String, dynamic>>[
      _product(
          name: 'لبن',
          category: 'ألبان',
          sellerId: 's1',
          price: 30,
          isOnOffer: true,
          createdAt: DateTime(2026, 9)),
      _product(
          name: 'جبنة',
          category: 'ألبان',
          sellerId: 's1',
          price: 60,
          isFeatured: true,
          createdAt: DateTime(2026, 9, 5)),
      _product(
          name: 'زبادي',
          category: 'ألبان',
          sellerId: 's2',
          price: 15,
          productStatus: 'used',
          createdAt: DateTime(2026, 9, 3)),
      _product(
          name: 'بطيخ',
          category: 'خضار وفاكهة',
          sellerId: 's1',
          price: 45,
          isOnOffer: true,
          createdAt: DateTime(2026, 9, 7)),
      _product(
          name: 'مانجو',
          category: 'خضار وفاكهة',
          sellerId: 's2',
          price: 90,
          stock: 0,
          createdAt: DateTime(2026, 9, 2)),
      _product(
          name: 'قيد المراجعة',
          category: 'ألبان',
          sellerId: 's1',
          price: 10,
          isApproved: false,
          createdAt: DateTime(2026, 9, 9)),
    ];
    for (final p in products) {
      await fake.collection('market_products').add(p);
    }
    return fake;
  }

  Future<void> warmCache(MarketService svc) => svc.getProductsList(forceRefresh: true);

  Future<void> clearServer(FakeFirebaseFirestore fake) async {
    final snap = await fake.collection('market_products').get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  group('فلاتر السوق: تطابق الكاش مع الخادم', () {
    test('مسار الكاش يطبّق كل الفلاتر (category/sellerId/isOnOffer/isFeatured)',
        () async {
      final fake = await seed();
      final svc = MarketService(firestore: fake);

      final fromServer = await svc.getProductsList(
        forceRefresh: true,
        category: 'ألبان',
        sellerId: 's1',
        isOnOffer: true,
        isFeatured: false,
      );
      expect(fromServer.map((p) => p.name).toList(), ['لبن']);

      // كاش عام + خادم فارغ ⇒ أي نتيجة جاءت فلازم من الكاش
      await warmCache(svc);
      await clearServer(fake);

      final fromCache = await svc.getProductsList(
        category: 'ألبان',
        sellerId: 's1',
        isOnOffer: true,
        isFeatured: false,
      );
      expect(fromCache.map((p) => p.name).toList(), fromServer.map((p) => p.name).toList());
    });

    test('فلتر حالة المنتج يعمل في مسار الكاش', () async {
      final fake = await seed();
      final svc = MarketService(firestore: fake);

      final server = await svc.getProductsList(
          forceRefresh: true, category: 'ألبان', productStatus: 'used');
      expect(server.map((p) => p.name).toSet(), {'زبادي'});

      await warmCache(svc);
      await clearServer(fake);

      final cache = await svc.getProductsList(
          category: 'ألبان', productStatus: 'used');
      expect(cache.map((p) => p.name).toSet(), {'زبادي'});
    });

    test('استعلام مفلتر لا يضيّق الكاش لبقية الشاشات', () async {
      final fake = await seed();
      final svc = MarketService(firestore: fake);

      await svc.getProductsList(forceRefresh: true, category: 'ألبان');
      final all = await svc.getProductsList();

      // كل المعتمدون لا غيرهم: 5 products (السادس قيد المراجعة)
      expect(all.length, 5);
      expect(all.map((p) => p.category).toSet(),
          {'ألبان', 'خضار وفاكهة'});
    });

    test('الفرز الافتراضي «الأحدث» يعمل في غياب sortBy', () async {
      final fake = await seed();
      final svc = MarketService(firestore: fake);

      final fresh = await svc.getProductsList(forceRefresh: true);
      final cached = await svc.getProductsList();

      final expected = ['قيد المراجعة', 'بطيخ', 'جبنة', 'زبادي', 'مانجو', 'لبن']
          .where((n) => n != 'قيد المراجعة')
          .toList();
      expect(fresh.map((p) => p.name).toList(), expected);
      expect(cached.map((p) => p.name).toList(), expected);
    });

    test('خيارات التصنيف والفرز المعروضة تطابق ما يفهمه الفرز', () {
      expect(MarketService.sortOptions,
          containsAll(['الأحدث', 'الأعلى تقييماً', 'أقل سعر']));
    });
  });
}
