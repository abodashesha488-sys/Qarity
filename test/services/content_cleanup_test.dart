import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/content_cleanup_service.dart';

void main() {
  group('ContentCleanupService', () {
    test('market_products deletion cleans likes/comments/reviews/alerts',
        () async {
      final fake = FakeFirebaseFirestore();
      final pRef = fake.collection('market_products').doc('p1');
      await pRef.set({'name': 'منتج', 'isApproved': true});
      await pRef.collection('likes').doc('u1').set({'likedAt': 1});
      await pRef.collection('comments').doc('c1').set({'text': 'رائع'});
      await fake
          .collection('product_reviews')
          .add({'productId': 'p1', 'rating': 5, 'userId': 'u2'});
      await fake
          .collection('product_reviews')
          .add({'productId': 'other', 'rating': 4, 'userId': 'u3'});
      await fake
          .collection('stock_alerts')
          .add({'productId': 'p1', 'userId': 'u4'});
      await fake
          .collection('orders')
          .add({'productId': 'p1', 'buyerId': 'u5'});

      await ContentCleanupService.cleanupForDeleted(fake, 'market_products', 'p1');
      await pRef.delete();

      expect((await pRef.collection('likes').get()).docs, isEmpty);
      expect((await pRef.collection('comments').get()).docs, isEmpty);
      final reviews = await fake
          .collection('product_reviews')
          .where('productId', isEqualTo: 'p1')
          .get();
      expect(reviews.docs, isEmpty);
      expect(
          (await fake
                  .collection('stock_alerts')
                  .where('productId', isEqualTo: 'p1')
                  .get())
              .docs,
          isEmpty);
      // الطلبات التاريخية تبقى عمداً
      expect((await fake.collection('orders').get()).docs.length, 1);
      // مراجعات المنتجات الأخرى لا تمس
      expect(
          (await fake
                  .collection('product_reviews')
                  .where('productId', isEqualTo: 'other')
                  .get())
              .docs
              .length,
          1);
    });

    test('obituaries deletion cleans condolences; unknown collections no-op',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('obituaries').doc('o1').set({'name': 'م'});
      await fake
          .collection('condolences')
          .add({'obituaryId': 'o1', 'userId': 'u1', 'message': 'x'});
      await fake
          .collection('condolences')
          .add({'obituaryId': 'o2', 'userId': 'u2', 'message': 'y'});

      await ContentCleanupService.cleanupForDeleted(fake, 'obituaries', 'o1');
      expect(
          (await fake
                  .collection('condolences')
                  .where('obituaryId', isEqualTo: 'o1')
                  .get())
              .docs,
          isEmpty);
      expect(
          (await fake
                  .collection('condolences')
                  .where('obituaryId', isEqualTo: 'o2')
                  .get())
              .docs
              .length,
          1);

      // مجموعة بلا تنظيف معرف → لا رمي ولا آثار جانبية
      await fake.collection('shops').doc('s1').set({'name': 'محل'});
      await ContentCleanupService.cleanupForDeleted(fake, 'shops', 's1');
      expect((await fake.collection('shops').get()).docs.length, 1);
    });
  });
}
