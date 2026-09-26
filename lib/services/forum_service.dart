import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/data_models.dart';
import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('forum_posts').doc(postId);
    final post = await postRef.get();
    final likedBy = List<String>.from(post.data()?['likedBy'] as List<dynamic>? ?? []);
    final wasLiked = likedBy.contains(userId);
    if (wasLiked) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
      _sendLikeNotification(postId, post.data()?['content'] as String? ?? 'منشور جديد');
    }
    await postRef.update({'likes': likedBy.length, 'likedBy': likedBy});
  }

  Future<void> _sendLikeNotification(String postId, String postTitle) async {
    try {
      // بوابة الإخطار هي تسجيل الدخول (وليس توكن FCM): هكذا يبقى صندوق
      // الوارد داخل التطبيق يعمل على الويب/القناة التي لا توكن فيها.
      if (FirebaseAuth.instance.currentUser != null) {
        await _firestore.collection('notifications').add({
          'type': 'like',
          'targetId': postId,
          'title': 'إعجاب جديد',
          'body': 'أعجب أحدهم بمنشورك: $postTitle',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Silently fail - notification is optional
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