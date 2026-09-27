import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/news_service.dart';

void main() {
  group('حذف تعليق الأخبار (deleteComment)', () {
    test('يحذف الوثيقة وينقص العدّاد ذرّياً', () async {
      final fake = FakeFirebaseFirestore();
      final newsRef = await fake.collection('news').add({
        'title': 'خبر',
        'comments': 2,
        'views': 5,
        'isApproved': true,
      });
      final newsId = newsRef.id;
      final c1 = await fake
          .collection('news')
          .doc(newsId)
          .collection('comments')
          .add({
        'userId': 'u1',
        'userName': 'أحمد',
        'text': 'تعليق 1',
        'createdAt': Timestamp.now(),
      });
      await fake.collection('news').doc(newsId).collection('comments').add({
        'userId': 'u2',
        'userName': 'سالم',
        'text': 'تعليق 2',
        'createdAt': Timestamp.now(),
      });

      final svc = NewsService(fake);
      await svc.deleteComment(newsId, c1.id);

      final news = await fake.collection('news').doc(newsId).get();
      expect(news.data()?['comments'], 1);
      expect(news.data()?['views'], 5); // لم تُمسّ المشاهدات
      final deleted = await fake
          .collection('news')
          .doc(newsId)
          .collection('comments')
          .doc(c1.id)
          .get();
      expect(deleted.exists, isFalse);
      final remaining = await fake
          .collection('news')
          .doc(newsId)
          .collection('comments')
          .get();
      expect(remaining.docs, hasLength(1));
      expect(remaining.docs.first['text'], 'تعليق 2');
    });

    test('العدّاد لا يصبح سالباً عند الحذف والعدّاد صفر', () async {
      final fake = FakeFirebaseFirestore();
      final newsRef =
          await fake.collection('news').add({'title': 'خبر', 'comments': 0});
      final commentRef = await fake
          .collection('news')
          .doc(newsRef.id)
          .collection('comments')
          .add({
        'userId': 'u1',
        'userName': 'أحمد',
        'text': 'تعليق يتيم',
        'createdAt': Timestamp.now(),
      });

      final svc = NewsService(fake);
      await svc.deleteComment(newsRef.id, commentRef.id);

      final news = await fake.collection('news').doc(newsRef.id).get();
      expect(news.data()?['comments'], 0);
    });

    test('تجاهل وسيطات فارغة بأمان', () async {
      final fake = FakeFirebaseFirestore();
      final svc = NewsService(fake);
      await svc.deleteComment('', 'x');
      await svc.deleteComment('y', '');
      final news = await fake.collection('news').get();
      expect(news.docs, isEmpty);
    });
  });
}
