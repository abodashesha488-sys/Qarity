import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/data_models.dart';
import 'cache_service.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Stream<List<ForumPost>> getPostsStream() {
    return _firestore.collection('forum_posts').where('isApproved', isEqualTo: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => ForumPost.fromJson(doc.data(), doc.id)).toList());
  }

  Future<void> addPost(ForumPost post) async {
    await _firestore.collection('forum_posts').add({
      ...post.toJson(),
      'isApproved': false,
    });
    await CacheService.invalidateForumPosts();
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
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('notifications').add({
          'type': 'like',
          'postId': postId,
          'title': postTitle,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Silently fail - notification is optional
    }
  }

  Future<void> addComment(String postId, String userName, String text) async {
    final auth = FirebaseAuth.instance;
    final userDoc = await _firestore.collection('users').doc(auth.currentUser?.uid).get();
    final name = userDoc.data()?['name'] as String? ?? auth.currentUser?.displayName ?? userName;
    await _firestore.collection('forum_posts').doc(postId).collection('comments').add({'userId': auth.currentUser?.uid ?? '', 'userName': name, 'text': text, 'createdAt': Timestamp.now()});
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