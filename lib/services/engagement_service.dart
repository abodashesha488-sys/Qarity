import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles community engagement: condolences on obituaries and
/// attendance (RSVP) for occasions. These are stored as their own
/// documents so regular signed-in users can write them without
/// requiring admin write access to the parent item.
class EngagementService {
  final FirebaseFirestore _firestore;

  /// Accepts an optional [FirebaseFirestore] so tests can inject an
  /// in-memory fake (e.g. FakeFirebaseFirestore). Defaults to the
  /// production instance.
  EngagementService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ───────────────────────── Condolences ─────────────────────────
  Future<void> addCondolence({
    required String obituaryId,
    required String userId,
    required String userName,
    required String message,
  }) async {
    await _firestore.collection('condolences').add({
      'obituaryId': obituaryId,
      'userId': userId,
      'userName': userName,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> condolencesCount(String obituaryId) {
    return _firestore
        .collection('condolences')
        .where('obituaryId', isEqualTo: obituaryId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Condolence>> condolences(String obituaryId) {
    return _firestore
        .collection('condolences')
        .where('obituaryId', isEqualTo: obituaryId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Condolence.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) =>
          (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  // ───────────────────────── Attendance ─────────────────────────
  /// Uses a deterministic doc id (occasionId_userId) so each user can
  /// attend an occasion at most once without needing a composite index.
  Future<void> attendOccasion({
    required String occasionId,
    required String userId,
    required String userName,
  }) async {
    final ref = _firestore.doc('occasion_attendees/${occasionId}_$userId');
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'occasionId': occasionId,
      'userId': userId,
      'userName': userName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelAttendance({
    required String occasionId,
    required String userId,
  }) async {
    await _firestore.doc('occasion_attendees/${occasionId}_$userId').delete();
  }

  Stream<bool> isAttending(String occasionId, String userId) {
    return _firestore
        .doc('occasion_attendees/${occasionId}_$userId')
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<int> attendeesCount(String occasionId) {
    return _firestore
        .collection('occasion_attendees')
        .where('occasionId', isEqualTo: occasionId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// قائمة أسماء الحاضرين في مناسبة.
  Stream<List<String>> attendeeNames(String occasionId) {
    return _firestore
        .collection('occasion_attendees')
        .where('occasionId', isEqualTo: occasionId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => (d.data()['userName'] ?? 'مستخدم').toString())
            .toList());
  }
}

class Condolence {
  final String id;
  final String obituaryId;
  final String userId;
  final String userName;
  final String message;
  final DateTime? createdAt;

  const Condolence({
    required this.id,
    required this.obituaryId,
    required this.userId,
    required this.userName,
    required this.message,
    this.createdAt,
  });

  factory Condolence.fromJson(Map<String, dynamic> json, String docId) {
    return Condolence(
      id: docId,
      obituaryId: json['obituaryId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'مستخدم',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
    );
  }
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}
