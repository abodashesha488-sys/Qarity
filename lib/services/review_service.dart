import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/data_models.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getUserName(String userId) async {
    final user = _auth.currentUser;
    if (user != null && user.uid == userId) {
      return user.displayName ?? user.email?.split('@').first ?? 'مستخدم';
    }
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['name'] as String? ?? data['email'] as String? ?? 'مستخدم';
    }
    return 'مستخدم';
  }

  Future<void> addReview({required String sellerId, required int rating, required String comment, required String userId}) async {
    final userName = await _getUserName(userId);
    final review = Review(
      id: '',
      rating: rating,
      comment: comment,
      sellerId: sellerId,
      userId: userId,
      userName: userName,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('reviews').add(review.toJson());
  }

  Future<double> getSellerAverageRating(String sellerId) async {
    final snapshot = await _firestore.collection('reviews').where('sellerId', isEqualTo: sellerId).get();
    if (snapshot.docs.isEmpty) return 0.0;
    final reviews = snapshot.docs.map((doc) => Review.fromJson(doc.data(), doc.id)).toList();
    return reviews.fold<double>(0.0, (total, r) => total + r.rating) / reviews.length;
  }

  Future<List<Review>> getSellerReviews(String sellerId) async {
    final snapshot = await _firestore.collection('reviews').where('sellerId', isEqualTo: sellerId).get();
    return snapshot.docs.map((doc) => Review.fromJson(doc.data(), doc.id)).toList();
  }

  Future<int> getReviewCount(String sellerId) async {
    final snapshot = await _firestore.collection('reviews').where('sellerId', isEqualTo: sellerId).get();
    return snapshot.docs.length;
  }
}
