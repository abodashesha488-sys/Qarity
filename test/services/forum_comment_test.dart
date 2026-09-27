import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/forum_service.dart';

void main() {
  group('حذف تعليق المندرة (deleteComment)', () {
    test('يحذف الوثيقة وينقص العدّاد ذرّياً', () async {
      final fake = FakeFirebaseFirestore();
      final postRef = await fake.collection('forum_posts').add({
        'userId': 'owner-uid',
        'title': 'موضوع',
        'content': 'نص',
        'comments': 2,
        'isApproved': true,
      });
      final postId = postRef.id;
      final c1 = await fake
          .collection('forum_posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': 'u1',
        'userName': 'أحمد',
        'text': 'تعليق 1',
        'createdAt': Timestamp.now(),
      });
      await fake
          .collection('forum_posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': 'u2',
        'userName': 'سالم',
        'text': 'تعليق 2',
        'createdAt': Timestamp.now(),
      });

      final svc = ForumService(fake);
      await svc.deleteComment(postId, c1.id);

      final post = await fake.collection('forum_posts').doc(postId).get();
      expect(post.data()?['comments'], 1);
      final deleted = await fake
          .collection('forum_posts')
          .doc(postId)
          .collection('comments')
          .doc(c1.id)
          .get();
      expect(deleted.exists, isFalse);
      final remaining = await fake
          .collection('forum_posts')
          .doc(postId)
          .collection('comments')
          .get();
      expect(remaining.docs, hasLength(1));
      expect(remaining.docs.first['text'], 'تعليق 2');
    });

    test('العدّاد لا يصبح سالباً عند الحذف والعدّاد صفر', () async {
      final fake = FakeFirebaseFirestore();
      final postRef = await fake.collection('forum_posts').add({
        'userId': 'owner-uid',
        'title': 'موضوع',
        'content': 'نص',
        'comments': 0,
        'isApproved': true,
      });
      final commentRef = await fake
          .collection('forum_posts')
          .doc(postRef.id)
          .collection('comments')
          .add({
        'userId': 'u1',
        'userName': 'أحمد',
        'text': 'تعليق يتيم',
        'createdAt': Timestamp.now(),
      });

      final svc = ForumService(fake);
      await svc.deleteComment(postRef.id, commentRef.id);

      final post = await fake.collection('forum_posts').doc(postRef.id).get();
      expect(post.data()?['comments'], 0);
    });

    test('تجاهل وسيطات فارغة بأمان', () async {
      final fake = FakeFirebaseFirestore();
      final svc = ForumService(fake);
      // لا رمي ولا كتابة.
      await svc.deleteComment('', 'x');
      await svc.deleteComment('y', '');
      final posts = await fake.collection('forum_posts').get();
      expect(posts.docs, isEmpty);
    });
  });
}
