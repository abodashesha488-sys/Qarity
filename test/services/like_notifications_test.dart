import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/notification_deeplink.dart';
import 'package:qurity/services/forum_service.dart';
import 'package:qurity/services/notification_inbox_service.dart';
import 'package:qurity/services/product_interaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يحاكي عامل Vercel في الإنتاج: التحقق الخادمي من الإعجاب + شكل الكتابة
/// النهائي في `notifications` (معرّف حتمي + userId=المالك + kind=like +
/// مسار أنبوبي). يوثّق عقد التوصيل حتى لا ينفصل العامل عن العميل مستقبلًا.
class _FakeLikeNotifier {
  _FakeLikeNotifier(this.fake, this.likerUid);

  final FirebaseFirestore fake;
  final String likerUid;
  int callCount = 0;

  Future<void> call({required String collection, required String itemId}) async {
    callCount++;
    final post = await fake.collection(collection).doc(itemId).get();
    final postData = post.data() ?? const <String, dynamic>{};
    final owner = (postData['userId'] ?? '').toString();
    final likedBy = (postData['likedBy'] as List<dynamic>?)
            ?.cast<String>() ??
        const <String>[];
    // حماية مزدوجة مثل العامل: لا إشعار للذات ولا لمن لم يُعجب فعلًا.
    if (owner.isEmpty || owner == likerUid) return;
    if (!likedBy.contains(likerUid)) return;
    // النص يُبنى خادميًا: العنوان أولاً ثم المحتوى، مع اقتباس عند 60 حرفًا.
    final titleTxt = ((postData['title'] as String?) ?? '').trim();
    final contentTxt = ((postData['content'] as String?) ?? '').trim();
    final source = titleTxt.isNotEmpty ? titleTxt : contentTxt;
    final excerpt = source.length > 60 ? '${source.substring(0, 60)}…' : source;
    await fake
        .collection('notifications')
        .doc('like_${itemId}_$likerUid')
        .set({
      'userId': owner,
      'title': '💗 إعجاب جديد',
      'body': excerpt.isEmpty
          ? 'أعجب أحدهم بمنشورك'
          : 'أعجب أحدهم بمنشورك: $excerpt',
      'route': '/forum/detail|$collection|$itemId',
      'kind': 'like',
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('D1: إشعار إعجاب المنتدى يصل صاحب المنشور', () {
    test('الإعجاب بمنشور شخص آخر يطلق التوصيل لصاحبه فقط', () async {
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
      final notifier = _FakeLikeNotifier(fake, 'liker-uid');
      final svc = ForumService(fake, notifier.call);

      await svc.toggleLike(postId, 'liker-uid');

      // التوصيل طُلب مرة واحدة فقط (العميل يخطّي الذات والفراغ محليًا).
      expect(notifier.callCount, 1);
      final docs = (await fake.collection('notifications').get()).docs;
      expect(docs, hasLength(1));
      // معرّف حتمي: إعجاب واحد لكل ثنائي (منشور، مُعجب).
      expect(docs.first.id, 'like_${postId}_liker-uid');
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

      // صاحب المنشور يراه في صندوقه، والمعجف لا يصله إشعار لنفسه
      final forOwner =
          await NotificationInboxService(fake).streamFor('owner-uid').first;
      expect(forOwner, hasLength(1));
      expect(forOwner.first.read, isFalse);
      final forLiker =
          await NotificationInboxService(fake).streamFor('liker-uid').first;
      expect(forLiker, isEmpty);
    });

    test('إلغاء الإعجاب ثم الإعادة يُعيد كتابة نفس الإشعار (لا تكرار)',
        () async {
      final fake = FakeFirebaseFirestore();
      final postId = (await fake.collection('forum_posts').add({
        'userId': 'owner-uid',
        'title': 'منشور',
        'likes': 0,
        'likedBy': <String>[],
      }))
          .id;
      final notifier = _FakeLikeNotifier(fake, 'liker-uid');
      final svc = ForumService(fake, notifier.call);

      await svc.toggleLike(postId, 'liker-uid'); // إعجاب ⇒ توصيل
      expect(notifier.callCount, 1);
      await svc.toggleLike(postId, 'liker-uid'); // إلغاء ⇒ لا توصيل
      expect(notifier.callCount, 1);

      // الإعادة تُعيد كتابة المستند الحتمي نفسه، فلا ينمو الصندوق بلا حدود
      await svc.toggleLike(postId, 'liker-uid');
      expect(notifier.callCount, 2);
      final docs = (await fake.collection('notifications').get()).docs;
      expect(docs, hasLength(1));
      expect(docs.first.id, 'like_${postId}_liker-uid');
    });

    test('الإعجاب الذاتي لا يولّد توصيلًا', () async {
      final fake = FakeFirebaseFirestore();
      final postId = (await fake.collection('forum_posts').add({
        'userId': 'owner-uid',
        'title': 'منشوري',
        'likes': 0,
        'likedBy': <String>[],
      }))
          .id;
      final notifier = _FakeLikeNotifier(fake, 'owner-uid');
      final svc = ForumService(fake, notifier.call);

      await svc.toggleLike(postId, 'owner-uid');

      // العميل يتخطى الذات محليًا فلا نداء شبكة أصلاً
      expect(notifier.callCount, 0);
      expect((await fake.collection('notifications').get()).docs, isEmpty);
      final data =
          (await fake.collection('forum_posts').doc(postId).get()).data()!;
      expect(data['likes'], 1);
    });

    test('المنشور بدون مالك لا يطلق التوصيل', () async {
      final fake = FakeFirebaseFirestore();
      final postId = (await fake.collection('forum_posts').add({
        'userId': '',
        'title': 'منشور يتيم',
        'likes': 0,
        'likedBy': <String>[],
      }))
          .id;
      final notifier = _FakeLikeNotifier(fake, 'liker-uid');
      final svc = ForumService(fake, notifier.call);

      await svc.toggleLike(postId, 'liker-uid');

      expect(notifier.callCount, 0);
      expect((await fake.collection('notifications').get()).docs, isEmpty);
    });

    test('عقد الحاقن: التوثيق الخادمي يرفض من لم يُعجب', () async {
      final fake = FakeFirebaseFirestore();
      final postId = (await fake.collection('forum_posts').add({
        'userId': 'owner-uid',
        'title': 'منشور',
        'likes': 0,
        'likedBy': <String>['someone-else'],
      }))
          .id;
      final notifier = _FakeLikeNotifier(fake, 'liker-uid');

      // محاكاة نداء مباشر كما لو أن العميل كذب على الإرسال
      await notifier.call(collection: 'forum_posts', itemId: postId);

      // الحماية الخادمية: liker-uid ليس في likedBy ⇒ لا كتابة
      expect((await fake.collection('notifications').get()).docs, isEmpty);
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
      final svc =
          ForumService(fake, ({required collection, required itemId}) async {});

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
