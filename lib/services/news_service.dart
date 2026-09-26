import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/data_models.dart';
import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

class NewsService {
  NewsService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// مؤجّل حتى استخدامه فعليًا حتى تُختبر مسارات الأخبار بلا تهيئة Firebase.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<List<NewsItem>> getNewsStream({int? limit}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('news').where('isApproved', isEqualTo: true);
    if (limit != null) {
      query = query.orderBy('createdAt', descending: true).limit(limit);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => NewsItem.fromJson(doc.data(), doc.id)).toList());
  }

  Future<List<NewsItem>> getNewsList({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getNews();
      if (cached != null) {
        return cached.map((json) => NewsItem.fromJson(json, 'cache')).toList();
      }
    }
    final snapshot = await _firestore.collection('news').where('isApproved', isEqualTo: true).get();
    final news = snapshot.docs.map((doc) => NewsItem.fromJson(doc.data(), doc.id)).toList();
    await CacheService.saveNews(news.map((n) => n.toJson()).toList());
    return news;
  }

  /// Live stream for a single news item so detail screens keep
  /// likes / views / comment counters fresh without manual refreshes.
  Stream<NewsItem?> getNewsItemStream(String newsId) {
    return _firestore.collection('news').doc(newsId).snapshots().map(
          (doc) => doc.exists ? NewsItem.fromJson(doc.data() ?? <String, dynamic>{}, doc.id) : null,
        );
  }

  /// Live like state for a news item: the total likes plus whether [userId]
  /// already liked it, so detail screens can render the button without extra
  /// Firestore plumbing in the UI layer.
  Stream<({int likes, bool isLiked})> getNewsLikeStream(String newsId, {String? userId}) {
    return _firestore.collection('news').doc(newsId).snapshots().map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      final likedBy = (data['likedBy'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
      final likes = (data['likes'] as num?)?.toInt() ?? likedBy.length;
      return (likes: likes, isLiked: userId != null && likedBy.contains(userId));
    });
  }

  /// Toggles the like of [userId] on [newsId] and keeps `likes` in sync with
  /// `likedBy`. Returns the new like state. المعاملة تمنع فقدان إعجاب متزامن
  /// (كانت القراءة-ثم-الكتابة last-write-wins) وتُبقي العدّاد بحجم المصفوفة.
  Future<bool> toggleNewsLike(String newsId, String userId) async {
    final docRef = _firestore.collection('news').doc(newsId);
    var nowLiked = false;
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(docRef);
      final likedBy =
          List<String>.from(doc.data()?['likedBy'] as List<dynamic>? ?? []);
      final wasLiked = likedBy.contains(userId);
      nowLiked = !wasLiked;
      tx.update(docRef, {
        'likedBy': wasLiked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
        'likes': wasLiked
            ? (likedBy.length - 1).clamp(0, 1 << 31)
            : likedBy.length + 1,
      });
    });
    return nowLiked;
  }

  Future<void> addComment(String newsId, String userName, String text) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? const <String, dynamic>{};
      final pname = (data['name'] as String? ?? '').trim();
      final gname = (user.displayName ?? '').trim();
      final name = pname.isNotEmpty
          ? pname
          : (gname.isNotEmpty ? gname : userName);
      final mPhoto = (data['photoUrl'] as String? ?? '').trim();
      final photo = mPhoto.isNotEmpty ? mPhoto : user.photoURL;
      await _firestore.collection('news').doc(newsId).collection('comments').add({
        'userId': user.uid,
        'userName': name,
        'userPhotoUrl': photo ?? '',
        'text': text,
        'createdAt': Timestamp.now(),
      });
      await _firestore.collection('news').doc(newsId).update({'comments': FieldValue.increment(1)});
    }
  }

  Stream<QuerySnapshot> getCommentsStream(String newsId) {
    return _firestore.collection('news').doc(newsId).collection('comments').orderBy('createdAt', descending: true).snapshots();
  }

  Future<NewsItem?> getNewsById(String newsId) async {
    final doc = await _firestore.collection('news').doc(newsId).get();
    if (doc.exists) return NewsItem.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    return null;
  }

  /// يزيد عدّاد المشاهدات لخبر عند فتحه.
  Future<void> incrementViews(String newsId) async {
    if (newsId.isEmpty) return;
    try {
      await _firestore.collection('news').doc(newsId)
          .update({'views': FieldValue.increment(1)});
    } catch (_) {
      // لا نكسر تجربة القراءة إذا فشل العدّاد (مثلاً بلا اتصال)
    }
  }

  Future<void> addNews(NewsItem news) async {
    String? uid;
    try {
      uid = _auth.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    await _firestore.collection('news').add({
      ...news.toJson(),
      'isApproved': false,
      'authorId': uid ?? '',
    });
    await CacheService.invalidateNews();
    unawaited(RemotePushService.notifyAdmins('news'));
    await NotificationService.showLocalNotification(
      title: '📰 خبر جديد',
      body: 'تم إرسال الخبر للمراجعة: ${news.title}',
      payload: '/news',
    );
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '📰 تم إرسال طلبك',
        body: 'تم إرسال الخبر "${news.title}" للمراجعة وسيظهر بعد موافقة الإدارة',
        route: '/news',
        kind: 'info',
      ));
    }
  }
}
