import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/data_models.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getUserName(String userId) async {
    // الاسم من ملف المستخدم (users/{uid}.name) أولاً — كما عدّله المستخدم.
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final pname = (data['name'] as String? ?? '').trim();
      if (pname.isNotEmpty) return pname;
    }
    final user = _auth.currentUser;
    if (user != null && user.uid == userId) {
      final g = (user.displayName ?? '').trim();
      if (g.isNotEmpty) return g;
    }
    final data = doc.data() ?? const <String, dynamic>{};
    return (data['email'] as String?)?.trim().isNotEmpty == true
        ? data['email'] as String
        : 'مستخدم';
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
