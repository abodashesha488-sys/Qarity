import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/notification_deeplink.dart';
import '../models/data_models.dart';
import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

class ForumService {
  ForumService([FirebaseFirestore? firestore, NotificationInboxService? inbox])
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _inboxOverride = inbox;

  final FirebaseFirestore _firestore;
  final NotificationInboxService? _inboxOverride;

  /// صندوق الوارد العام قابل للتبديل في الاختبارات (Firestore وهمي).
  NotificationInboxService get _inbox =>
      _inboxOverride ?? NotificationInboxService.instance;

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

  /// يسجّل/يلغي إعجاب [userId] على [postId] داخل معاملة واحدة: القراءة ثم
  /// التعديل الذرّيان يمنعان فقدان إعجاب متزامن (was last-write-wins)، ويبقي
  /// `likes` مطابقًا لحجم `likedBy`. يُبلّغ صاحب المنشور فقط عند إعجاب جديد.
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('forum_posts').doc(postId);
    var newlyLiked = false;
    var ownerUid = '';
    var excerpt = '';

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
        final title = (post.data()?['title'] ?? '').toString().trim();
        final content = (post.data()?['content'] ?? '').toString().trim();
        final source = title.isNotEmpty ? title : content;
        excerpt = source.length > 60 ? '${source.substring(0, 60)}…' : source;
      }
    });

    if (newlyLiked) {
      await _notifyPostOwnerOfLike(
          postId: postId, ownerUid: ownerUid, excerpt: excerpt, likerUid: userId);
    }
  }

  /// إشعار إعجاب يصل صاحب المنشور فعلًا: صندوق الوارد الداخلي (يعمل على كل
  /// المنصات) + FCM مباشر لجهازه إن كان له توكن. تتجاهل إعجاب الذات.
  Future<void> _notifyPostOwnerOfLike(
      {required String postId,
      required String ownerUid,
      required String excerpt,
      required String likerUid}) async {
    if (ownerUid.isEmpty || ownerUid == likerUid) return;
    const title = '💗 إعجاب جديد';
    final body =
        excerpt.isEmpty ? 'أعجب أحدهم بمنشورك' : 'أعجب أحدهم بمنشورك: $excerpt';
    try {
      await _inbox.push(
        userId: ownerUid,
        title: title,
        body: body,
        route:
            NotificationDeepLink.encode('/forum/detail', 'forum_posts', postId),
        kind: 'like',
      );
      final udoc =
          await _firestore.collection('users').doc(ownerUid).get();
      final token = udoc.data()?['fcmToken'] as String?;
      if (token != null && token.isNotEmpty) {
        unawaited(RemotePushService.sendToDevice(
          fcmToken: token,
          title: title,
          body: body,
          route: '/forum/detail',
          collection: 'forum_posts',
          itemId: postId,
        ));
      }
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