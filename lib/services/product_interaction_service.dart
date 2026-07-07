import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductInteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final ProductInteractionService _instance = ProductInteractionService._internal();
  factory ProductInteractionService() => _instance;
  ProductInteractionService._internal();

  Future<void> toggleLike({required String productId, required String userId}) async {
    final productRef = _firestore.collection('market_products').doc(productId);
    final likeRef = productRef.collection('likes').doc(userId);

    final liked = await likeRef.get();
    if (liked.exists) {
      await likeRef.delete();
      await productRef.update({'likes': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'userId': userId, 'createdAt': Timestamp.now()});
      await productRef.update({'likes': FieldValue.increment(1)});
    }
  }

  Stream<bool> hasUserLikedStream({required String productId, required String userId}) {
    return _firestore
        .collection('market_products')
        .doc(productId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<int> getLikeCountStream(String productId) {
    return _firestore
        .collection('market_products')
        .doc(productId)
        .collection('likes')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> addComment({required String productId, required String userName, required String text}) async {
    final auth = FirebaseAuth.instance;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(auth.currentUser?.uid).get();
    final name = userDoc.data()?['name'] as String? ?? auth.currentUser?.displayName ?? userName;
    await _firestore.collection('market_products').doc(productId).collection('comments').add({
      'userId': auth.currentUser?.uid ?? '',
      'userName': name,
      'text': text,
      'createdAt': Timestamp.now(),
    });
    await _firestore.collection('market_products').doc(productId).update({'comments': FieldValue.increment(1)});
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(String productId) {
    return _firestore.collection('market_products').doc(productId).collection('comments').orderBy('createdAt', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<int> getCommentCount(String productId) async {
    final doc = await _firestore.collection('market_products').doc(productId).get();
    return doc.data()?['comments'] as int? ?? 0;
  }
}