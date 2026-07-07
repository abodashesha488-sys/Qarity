import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/data_models.dart';
import 'cache_service.dart';

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

  Future<void> addComment(String newsId, String userName, String text) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final name = userDoc.data()?['name'] as String? ?? user.displayName ?? userName;
      await _firestore.collection('news').doc(newsId).collection('comments').add({
        'userId': user.uid,
        'userName': name,
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

  Future<void> addNews(NewsItem news) async {
    await _firestore.collection('news').add({
      ...news.toJson(),
      'isApproved': false,
    });
    await CacheService.invalidateNews();
  }
}
