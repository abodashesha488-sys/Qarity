import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/notification_deeplink.dart';
import 'package:qurity/services/forum_service.dart';
import 'package:qurity/services/notification_inbox_service.dart';
import 'package:qurity/services/product_interaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('D1: إشعار إعجاب المنتدى يصل صاحب المنشور', () {
    test('الإعجاب بمنشور شخص آخر يكتب إشعارًا صحيحًا لصاحبه فقط', () async {
      final fake = FakeFirebaseFirestore();
      final postId = (await fake.collection('forum_posts').add({
        'userId': 'owner-uid',
        'title': 'مطالبة بمساعدة',
        'content': 'نص المنشور',
        'likes': 0,
        'likedBy': <String>[],
        'isApproved': true,
      }))
          .id;
      final svc = ForumService(fake, NotificationInboxService(fake));

      await svc.toggleLike(postId, 'liker-uid');

      final inbox = fake.collection('notifications');
      final docs = (await inbox.get()).docs;
      expect(docs, hasLength(1));
      final n = docs.first.data();
      // الحقول التي ترفضها قواعد Firestore / يستحيل أن يجدها streamFor لولاها
      expect(n['userId'], 'owner-uid');
      expect(n['read'], false);
      expect(n.containsKey('isRead'), isFalse);
      expect(n['kind'], 'like');
      expect(n['title'], '💗 إعجاب جديد');
      expect(n['body'], contains('مطالبة بمساعدة'));
      // المسار موجّه للمنشور نفسه لا لقسم المنتدى
      final deep = NotificationDeepLink.decode(n['route'] as String?);
      expect(deep, isNotNull);
      expect(deep!.route, '/forum/detail');
      expect(deep.collection, 'forum_posts');
      expect(deep.itemId, postId);

      // صاحب المنشور يراه في صندوقه، والمعجب لا يصله إشعار لنفسه
      final forOwner =
          await NotificationInboxService(fake).streamFor('owner-uid').first;
      expect(forOwner, hasLength(1));
      expect(forOwner.first.read, isFalse);
      final forLiker =
          await NotificationInboxService(fake).streamFor('liker-uid').first;
      expect(forLiker, isEmpty);
    });

    test('إلغاء الإعجاب ثم الإعادة لا يترك إشعارًا مزدوجًا ولا يضيّع الأول',
        () async {
      final fake = FakeFirebaseFirestore();
      final postId = (await fake.collection('forum_posts').add({
        'userId': 'owner-uid',
        'title': 'منشور',
        'likes': 0,
        'likedBy': <String>[],
      }))
          .id;
      final svc = ForumService(fake, NotificationInboxService(fake));

      await svc.toggleLike(postId, 'liker-uid'); // إعجاب ⇒ إشعار
      await svc.toggleLike(postId, 'liker-uid'); // إلغاء ⇒ لا إشعار
      expect((await fake.collection('notifications').get()).docs, hasLength(1));

      await svc.toggleLike(postId, 'liker-uid'); // إعادة إعجاب ⇒ إشعار ثانٍ
      expect((await fake.collection('notifications').get()).docs, hasLength(2));
    });

    test('الإعجاب الذاتي لا يولّد إشعارًا', () async {
      final fake = FakeFirebaseFirestore();
      final postId = (await fake.collection('forum_posts').add({
        'userId': 'owner-uid',
        'title': 'منشوري',
        'likes': 0,
        'likedBy': <String>[],
      }))
          .id;
      final svc = ForumService(fake, NotificationInboxService(fake));

      await svc.toggleLike(postId, 'owner-uid');

      expect((await fake.collection('notifications').get()).docs, isEmpty);
      final data = (await fake.collection('forum_posts').doc(postId).get()).data()!;
      expect(data['likes'], 1);
    });
  });

  group('D3: إعجاب المنتدى — likes مطابق لـ likedBy ذرّيًا', () {
    test('مستخدمان: add ثم remove يبقيان العدّاد والقائمة متفقين', () async {
      final fake = FakeFirebaseFirestore();
      final postId = (await fake.collection('forum_posts').add({
        'userId': 'owner-uid',
        'title': 'منشور',
        'likes': 0,
        'likedBy': <String>[],
      }))
          .id;
      final svc = ForumService(fake, NotificationInboxService(fake));

      await svc.toggleLike(postId, 'u1');
      await svc.toggleLike(postId, 'u2');
      var data = (await fake.collection('forum_posts').doc(postId).get()).data()!;
      expect((data['likedBy'] as List).toSet(), {'u1', 'u2'});
      expect(data['likes'], 2);

      await svc.toggleLike(postId, 'u1');
      data = (await fake.collection('forum_posts').doc(postId).get()).data()!;
      expect(data['likedBy'], ['u2']);
      expect(data['likes'], 1);

      // ضغطة مزدوجة من حالة «معجب»: إزالة ثم إضافة ⇒ يبقى الإعجاب واحدًا
      await svc.toggleLike(postId, 'u2');
      await svc.toggleLike(postId, 'u2');
      data = (await fake.collection('forum_posts').doc(postId).get()).data()!;
      expect(data['likedBy'], ['u2']);
      expect(data['likes'], (data['likedBy'] as List).length);
    });
  });

  group('D2: إعجابات المنتجات داخل معاملة (مجموعة فرعية + عدّاد)', () {
    test('إعجاب ثم إلغاء: المستند الفرعي والعدّاد يتزامنان', () async {
      final fake = FakeFirebaseFirestore();
      final productId =
          (await fake.collection('market_products').add({'title': 'منتج', 'likes': 0}))
              .id;
      final product = fake.collection('market_products').doc(productId);
      final likes = product.collection('likes');
      final svc = ProductInteractionService.withFirestore(fake);

      await svc.toggleLike(productId: productId, userId: 'u1');
      expect((await likes.doc('u1').get()).exists, isTrue);
      expect((await product.get()).data()!['likes'], 1);

      await svc.toggleLike(productId: productId, userId: 'u2');
      expect((await product.get()).data()!['likes'], 2);
      expect((await likes.get()).docs, hasLength(2));

      await svc.toggleLike(productId: productId, userId: 'u1');
      expect((await product.get()).data()!['likes'], 1);
      expect((await likes.get()).docs.map((d) => d.id), ['u2']);
    });

    test('العدّاد لا يصبح سالبًا عند إلغاء بلا إعجاب سابق', () async {
      final fake = FakeFirebaseFirestore();
      final productId =
          (await fake.collection('market_products').add({'title': 'منتج', 'likes': 0}))
              .id;
      final product = fake.collection('market_products').doc(productId);
      final svc = ProductInteractionService.withFirestore(fake);

      await svc.toggleLike(productId: productId, userId: 'u1');
      await svc.toggleLike(productId: productId, userId: 'u1');
      await svc.toggleLike(productId: productId, userId: 'u1');
      expect((await product.get()).data()!['likes'], 1);
    });
  });
}
