import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/content_cleanup_service.dart';
import 'package:qurity/services/market_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _doc({
  required String name,
  required String sellerId,
  String? shopId,
  bool isApproved = true,
  int stock = 5,
}) {
  return {
    'name': name,
    'description': 'وصف',
    'price': 10,
    'imageUrl': '',
    'category': 'عام',
    'sellerName': 'بائع',
    'sellerPhone': '0100',
    'sellerId': sellerId,
    if (shopId != null) 'shopId': shopId,
    'isApproved': isApproved,
    'isOnOffer': false,
    'productStatus': 'regular',
    'stock': stock,
    'createdAt': Timestamp.fromDate(DateTime(2026, 9)),
  };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('النموذج: ربط المنتج بمحلّه', () {
    test('بلا ربط ⇒ لا يُكتب الحقل إطلاقًا والسجل القديم يُقرأ بلا خطأ', () {
      final legacy =
          MarketProduct.fromJson(_doc(name: 'قديم', sellerId: 'u1'), 'd1');
      expect(legacy.shopId, isNull);
      expect(legacy.toJson().containsKey('shopId'), isFalse);

      final linked = MarketProduct.fromJson(
          _doc(name: 'مرتبط', sellerId: 'u1', shopId: 's1'), 'd2');
      expect(linked.shopId, 's1');
      expect(linked.toJson()['shopId'], 's1');
    });

    test('المرتبط بمحل لا يظهر في محلٍّ آخر لنفس البائع', () {
      final p = MarketProduct.fromJson(
          _doc(name: 'مرتبط', sellerId: 'u1', shopId: 's1'), 'd2');
      expect(p.belongsToShop(ownerUid: 'u1', shopId: 's1'), isTrue);
      expect(p.belongsToShop(ownerUid: 'u1', shopId: 's2'), isFalse);
    });

    test('غير المرتبط يبقى ملكًا لبائعه في كل محلاته كما كان', () {
      final legacy =
          MarketProduct.fromJson(_doc(name: 'قديم', sellerId: 'u1'), 'd1');
      expect(legacy.belongsToShop(ownerUid: 'u1', shopId: 's1'), isTrue);
      expect(legacy.belongsToShop(ownerUid: 'u1', shopId: 's2'), isTrue);
      expect(legacy.belongsToShop(ownerUid: 'u2', shopId: 's1'), isFalse);
    });
  });

  group('الخدمة: منتجات محلٍّ بعينه', () {
    test('القائمة تجمع بلا-ربط + مرتبط بهذا المحل، وتحجب مرتبط محلٍ غيره',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('market_products')
          .add(_doc(name: 'بلا ربط', sellerId: 'u1'));
      await fake.collection('market_products')
          .add(_doc(name: 'لمحلنا', sellerId: 'u1', shopId: 's1'));
      await fake.collection('market_products')
          .add(_doc(name: 'لمحل آخر', sellerId: 'u1', shopId: 's2'));
      await fake.collection('market_products')
          .add(_doc(name: 'لبائع آخر', sellerId: 'u2', shopId: 's1'));

      final list = await MarketService(firestore: fake)
          .getShopProductsStream(ownerUid: 'u1', shopId: 's1')
          .first;
      expect(list.map((p) => p.name).toSet(), {'بلا ربط', 'لمحلنا'});
    });
  });

  group('حذف المحل ينظّف منتجاته', () {
    test('منتجات المحل وأيتامها تُحذف ومنتجات محلٍ آخر تبقى', () async {
      final fake = FakeFirebaseFirestore();
      final mine = await fake
          .collection('market_products')
          .add(_doc(name: 'لي', sellerId: 'u1', shopId: 's1'));
      final other = await fake
          .collection('market_products')
          .add(_doc(name: 'لمحل آخر', sellerId: 'u1', shopId: 's2'));
      await fake
          .collection('market_products')
          .doc(mine.id)
          .collection('likes')
          .add({'userId': 'u2'});

      await ContentCleanupService.cleanupForDeleted(fake, 'shops', 's1');

      final rest = await fake.collection('market_products').get();
      expect(rest.docs.map((d) => d.id), [other.id]);
      final likes = await fake
          .collection('market_products')
          .doc(mine.id)
          .collection('likes')
          .get();
      expect(likes.docs, isEmpty);
    });

    test('محل بلا منتجات لا يحذف شيئًا ولا يفشل', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('market_products')
          .add(_doc(name: 'لبائع آخر', sellerId: 'u2', shopId: 's9'));
      await ContentCleanupService.cleanupForDeleted(fake, 'shops', 's1');
      expect(
          (await fake.collection('market_products').get()).docs, hasLength(1));
    });
  });

  group('عقد المصدر', () {
    test('صفحة المحل تمرّر معرّف محلها وتقرأ بمجرى المحل وحده', () {
      final src =
          File('lib/features/market/market_tab_shops.dart').readAsStringSync();
      expect(src, contains('kShopIdArgKey: shop.id'));
      expect(src, contains('getShopProductsStream(ownerUid: shop.ownerUid'));
      expect(src, isNot(contains('getSellerProductsStream(shop.ownerUid')));
    });

    test('نموذج الإضافة يطبع الـ shopId المستلم من الوسائط', () {
      final src =
          File('lib/features/market/add_product.dart').readAsStringSync();
      expect(src, contains("const String kShopIdArgKey = 'shopId';"));
      expect(src,
          contains('if (shop is String && shop.isNotEmpty) _shopId = shop;'));
      expect(src, contains('shopId: _shopId,'));
    });

    test('صفحة محل النظارات تمرّر محلها هي الأخرى', () {
      final src = File('lib/features/medical/optical_shop_detail_screen.dart')
          .readAsStringSync();
      expect(src, contains('kShopIdArgKey: shop.id'));
      expect(
          src, contains('getShopProductsStream(ownerUid: id, shopId: shopId)'));
    });
  });
}
