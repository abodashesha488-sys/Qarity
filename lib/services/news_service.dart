import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/data_models.dart';
import 'cache_service.dart';
import 'notification_service.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<NewsItem>> getNewsStream() {
    return _firestore.collection('news').where('isApproved', isEqualTo: true).snapshots().map((snapshot) =>
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

  Future<void> likeNews(String newsId, {String? userId}) async {
    final doc = await _firestore.collection('news').doc(newsId).get();
    final likedBy = List<String>.from(doc.data()?['likedBy'] as List<dynamic>? ?? []);
    if (userId != null && !likedBy.contains(userId)) {
      likedBy.add(userId);
      await _firestore.collection('news').doc(newsId).update({'likes': FieldValue.increment(1), 'likedBy': likedBy});
    } else if (userId == null) {
      await _firestore.collection('news').doc(newsId).update({'likes': FieldValue.increment(1)});
    }
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
  /// `likedBy`. Returns the new like state.
  Future<bool> toggleNewsLike(String newsId, String userId) async {
    final docRef = _firestore.collection('news').doc(newsId);
    final doc = await docRef.get();
    final likedBy = List<String>.from(doc.data()?['likedBy'] as List<dynamic>? ?? []);
    final wasLiked = likedBy.contains(userId);
    if (wasLiked) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }
    await docRef.update({'likes': likedBy.length, 'likedBy': likedBy});
    return !wasLiked;
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
    await _firestore.collection('news').add({
      ...news.toJson(),
      'isApproved': false,
    });
    await CacheService.invalidateNews();
    await NotificationService.showLocalNotification(
      title: '📰 خبر جديد',
      body: 'تم إرسال الخبر للمراجعة: ${news.title}',
      payload: '/news',
    );
  }
}
