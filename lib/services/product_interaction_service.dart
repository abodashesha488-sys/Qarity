import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductInteractionService {
  final FirebaseFirestore _firestore;

  static final ProductInteractionService _instance =
      ProductInteractionService._internal();
  factory ProductInteractionService() => _instance;
  ProductInteractionService._internal() : _firestore = FirebaseFirestore.instance;

  /// نسخة للاختبار بـ Firestore وهمي (لا تلمس Singleton الإنتاج).
  ProductInteractionService.withFirestore(FirebaseFirestore firestore)
      : _firestore = firestore;

  Future<void> toggleLike({required String productId, required String userId}) async {
    final productRef = _firestore.collection('market_products').doc(productId);
    final likeRef = productRef.collection('likes').doc(userId);

    // المعاملة تمنع انفصال العدّاد عن المجموعة الفرعية عند ضغطة مزدوجة
    // أو جهازين: الوثيقة والحذف والعدّاد تُلتزم معًا أو تُعاد المحاولة.
    await _firestore.runTransaction((tx) async {
      final like = await tx.get(likeRef);
      if (like.exists) {
        tx.delete(likeRef);
        tx.update(productRef, {'likes': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {'userId': userId, 'createdAt': Timestamp.now()});
        tx.update(productRef, {'likes': FieldValue.increment(1)});
      }
    });
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
    // عدّاد الإعجابات من مستند المنتج نفسه (مستمع مستند واحد رخيص) بدل
    // بثّ مجموعة likes الفرعية كاملة — الحقل يبقى متزامناً عبر toggleLike.
    return _firestore
        .collection('market_products')
        .doc(productId)
        .snapshots()
        .map((doc) => (doc.data()?['likes'] as num?)?.toInt() ?? 0);
  }

  Future<void> addComment({required String productId, required String userName, required String text}) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
    final data = userDoc.data() ?? const <String, dynamic>{};
    final pname = (data['name'] as String? ?? '').trim();
    final gname = (user?.displayName ?? '').trim();
    final name = pname.isNotEmpty ? pname : (gname.isNotEmpty ? gname : userName);
    final mPhoto = (data['photoUrl'] as String? ?? '').trim();
    final photo = mPhoto.isNotEmpty ? mPhoto : (user?.photoURL ?? '');
    await _firestore.collection('market_products').doc(productId).collection('comments').add({
      'userId': user?.uid ?? '',
      'userName': name,
      'userPhotoUrl': photo,
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