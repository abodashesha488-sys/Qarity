import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agriculture_content_model.dart';

/// مصدر المحتوى الزراعي المنشور، مع إبقاء الشاشات قادرة على fallback محلي.
class AgricultureContentService {
  AgricultureContentService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String?> userRole(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return snapshot.data()?['role'] as String?;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('agriculture_content');

  Stream<List<AgricultureContent>> watchSection(String section) {
    return _collection
        .where('section', isEqualTo: section)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) => _sorted(snapshot.docs));
  }

  Future<List<AgricultureContent>> getSection(String section) async {
    final snapshot = await _collection
        .where('section', isEqualTo: section)
        .where('isPublished', isEqualTo: true)
        .get();
    return _sorted(snapshot.docs);
  }

  Future<String> save(AgricultureContent content) async {
    final ref =
        content.id.isEmpty ? _collection.doc() : _collection.doc(content.id);
    await ref.set(content.toJson(), SetOptions(merge: true));
    return ref.id;
  }

  Future<void> delete(String id) => _collection.doc(id).delete();

  List<AgricultureContent> _sorted(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final result = docs
        .map((doc) => AgricultureContent.fromJson(doc.data(), doc.id))
        .toList();
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }
}
