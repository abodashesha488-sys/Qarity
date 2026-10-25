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

  Future<void> addComment({
    required String productId,
    required String userName,
    required String text,
    String? parentId,
    String? replyToUser,
  }) async {
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
      'likes': 0,
      'likedBy': <String>[],
      if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
      if (replyToUser != null && replyToUser.isNotEmpty) 'replyToUser': replyToUser,
      'createdAt': Timestamp.now(),
    });
    await _firestore.collection('market_products').doc(productId).update({'comments': FieldValue.increment(1)});
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(String productId) {
    return _firestore
        .collection('market_products')
        .doc(productId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// تعديل نص التعليق (للصاحب أو الأدمن)
  Future<void> editComment({
    required String productId,
    required String commentId,
    required String newText,
  }) async {
    if (productId.isEmpty || commentId.isEmpty || newText.trim().isEmpty) return;
    await _firestore
        .collection('market_products')
        .doc(productId)
        .collection('comments')
        .doc(commentId)
        .update({
      'text': newText.trim(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// التفاعل مع التعليق بالإعجاب أو إلغائه
  Future<void> toggleCommentLike({
    required String productId,
    required String commentId,
    required String userId,
  }) async {
    if (productId.isEmpty || commentId.isEmpty || userId.isEmpty) return;
    final ref = _firestore
        .collection('market_products')
        .doc(productId)
        .collection('comments')
        .doc(commentId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? <String, dynamic>{};
      final likedBy = (data['likedBy'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      tx.update(ref, {
        'likedBy': likedBy,
        'likes': likedBy.length,
      });
    });
  }

  /// حذف تعليق وإنقاص عداد تعليقات المنتج
  Future<void> deleteComment({
    required String productId,
    required String commentId,
  }) async {
    if (productId.isEmpty || commentId.isEmpty) return;
    final productRef = _firestore.collection('market_products').doc(productId);
    final commentRef = productRef.collection('comments').doc(commentId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(productRef);
      final count = ((snap.data()?['comments'] as num?)?.toInt() ?? 0);
      tx.delete(commentRef);
      tx.update(productRef, {'comments': count > 0 ? count - 1 : 0});
    });
  }

  Future<int> getCommentCount(String productId) async {
    final doc = await _firestore.collection('market_products').doc(productId).get();
    return doc.data()?['comments'] as int? ?? 0;
  }
}