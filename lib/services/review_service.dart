import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/data_models.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<({String name, String? photo})> _getAuthor(String userId) async {
    // الاسم والصورة من ملف المستخدم (users/{uid}) أولاً — كما عدّله المستخدم.
    String name = 'مستخدم';
    String? photo;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final pname = (data['name'] as String? ?? '').trim();
        if (pname.isNotEmpty) name = pname;
        final pphoto = (data['photoUrl'] as String? ?? '').trim();
        if (pphoto.isNotEmpty) photo = pphoto;
      }
    } catch (_) {}
    if (photo == null) {
      final user = _auth.currentUser;
      if (user != null && user.uid == userId && (user.photoURL ?? '').isNotEmpty) {
        photo = user.photoURL;
      }
    }
    if (name == 'مستخدم') {
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        final g = (user.displayName ?? '').trim();
        if (g.isNotEmpty) name = g;
      }
    }
    return (name: name, photo: photo);
  }

  Future<void> addReview({required String sellerId, required int rating, required String comment, required String userId}) async {
    final author = await _getAuthor(userId);
    final review = Review(
      id: '',
      rating: rating,
      comment: comment,
      sellerId: sellerId,
      userId: userId,
      userName: author.name,
      userPhotoUrl: author.photo,
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
    final snapshot = await _firestore
        .collection('reviews')
        .where('sellerId', isEqualTo: sellerId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
