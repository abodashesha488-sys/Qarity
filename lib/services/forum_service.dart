import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/data_models.dart';
import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'owner_content_service.dart';
import 'remote_push_service.dart';

/// توصيل إشعار الإعجاب لصاحب المنشور. قابل للحقن في الاختبارات؛ الإنتاج
/// يستخدم عامل Vercel عبر `RemotePushService.notifyLikeOwner` (admin SDK
/// يتجاوز قواعد الأمان، ويتحقق أن المُرسل داخل likedBy فعلًا).
typedef LikeNotifier = Future<void> Function({
  required String collection,
  required String itemId,
});

class ForumService {
  ForumService([
    FirebaseFirestore? firestore,
    LikeNotifier? likeNotifier,
  ])  : _firestore = firestore ?? FirebaseFirestore.instance,
        _likeNotifier = likeNotifier ?? RemotePushService.notifyLikeOwner;

  final FirebaseFirestore _firestore;
  final LikeNotifier _likeNotifier;

  Stream<List<ForumPost>> getPostsStream({int? limit}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('forum_posts')
        .where('isApproved', isEqualTo: true);
    if (limit != null) {
      query = query.orderBy('createdAt', descending: true).limit(limit);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) => ForumPost.fromJson(doc.data(), doc.id)).toList());
  }

  /// Live stream for a single post so the detail screen shows fresh
  /// like / comment / view counters.
  Stream<ForumPost?> getPostStream(String postId) {
    return _firestore.collection('forum_posts').doc(postId).snapshots().map(
          (doc) => doc.exists ? ForumPost.fromJson(doc.data() ?? <String, dynamic>{}, doc.id) : null,
        );
  }

  /// يزيد عدّاد المشاهدات لمنشور عند فتحه.
  Future<void> incrementViews(String postId) async {
    if (postId.isEmpty) return;
    try {
      await _firestore.collection('forum_posts').doc(postId)
          .update({'views': FieldValue.increment(1)});
    } catch (_) {
      // لا نكسر التجربة إذا فشل العدّاد
    }
  }

  Future<void> addPost(ForumPost post) async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    await _firestore.collection('forum_posts').add({
      ...post.toJson(),
      'isApproved': false,
      'userId': uid ?? '',
    });
    await CacheService.invalidateForumPosts();
    unawaited(RemotePushService.notifyAdmins('forum_posts'));
    await NotificationService.showLocalNotification(
      title: '💬 منشور جديد',
      body: 'تم إرسال المنشور للمراجعة',
      payload: '/forum',
    );
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '💬 تم إرسال طلبك',
        body: 'تم إرسال منشورك للمراجعة وسيظهر بعد موافقة الإدارة',
        route: '/forum',
        kind: 'info',
      ));
    }
  }

  /// تعديل صاحب المنشور لمنشوره في أي وقت؛ يعود إلى المراجعة بلا لمس نسبه
  /// (`userId`/`userName`/`userPhotoUrl`) — وهو ما ترفضه `firestore.rules`.
  /// عدّادات التفاعل (`likes`/`likedBy`/`views`/`comments`) تُجرَّد من الرقعة
  /// في طبقة المالك المشتركة فلا تُكتب قيمًا قديمة فوق ما جمعته الوثيقة.
  Future<void> updatePost(ForumPost post) => OwnerContentService.edit(
        _firestore,
        'forum_posts',
        post.id,
        post.toJson(),
        label: post.title,
      );

  /// حذف فوري لصاحب المنشور: تعليقاته ثم صورته ثم وثيقته.
  Future<void> deletePost(String postId) =>
      OwnerContentService.remove(_firestore, 'forum_posts', postId);

  /// يسجّل/يلغي إعجاب [userId] على [postId] داخل معاملة واحدة: القراءة ثم
  /// التعديل الذرّيان يمنعان فقدان إعجاب متزامن (was last-write-wins)، ويبقي
  /// `likes` مطابقًا لحجم `likedBy`. يُبلّغ صاحب المنشور فقط عند إعجاب جديد.
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('forum_posts').doc(postId);
    var newlyLiked = false;
    var ownerUid = '';

    await _firestore.runTransaction((tx) async {
      final post = await tx.get(postRef);
      final likedBy =
          List<String>.from(post.data()?['likedBy'] as List<dynamic>? ?? []);
      final wasLiked = likedBy.contains(userId);
      final count = wasLiked
          ? (likedBy.length - 1).clamp(0, 1 << 31)
          : likedBy.length + 1;
      tx.update(postRef, {
        'likedBy': wasLiked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
        'likes': count,
      });
      if (!wasLiked) {
        newlyLiked = true;
        ownerUid = (post.data()?['userId'] ?? '').toString();
      }
    });

    if (newlyLiked) {
      await _notifyPostOwnerOfLike(
          postId: postId, ownerUid: ownerUid, likerUid: userId);
    }
  }

  /// يوصّل إشعار الإعجاب لصاحب المنشور عبر عامل Vercel. قواعد Firestore
  /// ترفض أن يكتب مستخدم إشعاراً موجّهاً لآخر، لذا التوصيل كله خادمي (admin
  /// SDK يتجاوز القواعد، ويتحقق من وجود المُعجب في likedBy). تتجاهل الإعجاب
  /// الذاتي محلياً (والخادم يتحقق منها أيضاً كحماية مزدوجة) وتتجاهل المنشور
  /// بلا مالك. الإشعار اختياري: فشله لا يكسر الإعجاب نفسه.
  Future<void> _notifyPostOwnerOfLike(
      {required String postId,
      required String ownerUid,
      required String likerUid}) async {
    if (ownerUid.isEmpty || ownerUid == likerUid) return;
    try {
      await _likeNotifier(collection: 'forum_posts', itemId: postId);
    } catch (_) {
      // الإشعار اختياري: لا يكسر الإعجاب نفسه
    }
  }

  Future<void> addComment(String postId, String userName, String text) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final userDoc = await _firestore.collection('users').doc(user?.uid).get();
    final data = userDoc.data() ?? const <String, dynamic>{};
    final pname = (data['name'] as String? ?? '').trim();
    final gname = (user?.displayName ?? '').trim();
    final name = pname.isNotEmpty ? pname : (gname.isNotEmpty ? gname : userName);
    final mPhoto = (data['photoUrl'] as String? ?? '').trim();
    final photo = mPhoto.isNotEmpty ? mPhoto : (user?.photoURL ?? '');
    await _firestore.collection('forum_posts').doc(postId).collection('comments').add({'userId': auth.currentUser?.uid ?? '', 'userName': name, 'userPhotoUrl': photo, 'text': text, 'createdAt': Timestamp.now()});
    await _firestore.collection('forum_posts').doc(postId).update({'comments': FieldValue.increment(1)});
  }

  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore.collection('forum_posts').doc(postId).collection('comments').orderBy('createdAt', descending: true).snapshots();
  }

  /// يحذف تعليقاً (للأدمن/الأدمن المساعد أو صاحب التعليق) وينقص عدّاد
  /// تعليقات المنشور ذرّياً داخل معاملة واحدة، مع منع أصبح السالب.
  Future<void> deleteComment(String postId, String commentId) async {
    if (postId.isEmpty || commentId.isEmpty) return;
    final postRef = _firestore.collection('forum_posts').doc(postId);
    final commentRef = postRef.collection('comments').doc(commentId);
    await _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      final count = ((postSnap.data()?['comments'] as num?)?.toInt() ?? 0);
      tx.delete(commentRef);
      tx.update(postRef, {'comments': count > 0 ? count - 1 : 0});
    });
  }

  Future<List<ForumPost>> getLatestPosts({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getForumPosts();
      if (cached != null) {
        return cached.map((json) => ForumPost.fromJson(json, 'cache')).toList();
      }
    }
    final snapshot = await _firestore.collection('forum_posts').where('isApproved', isEqualTo: true).orderBy('createdAt', descending: true).limit(20).get();
    final posts = snapshot.docs.map((doc) => ForumPost.fromJson(doc.data(), doc.id)).toList();
    await CacheService.saveForumPosts(posts.map((p) => p.toJson()).toList());
    return posts;
  }
}