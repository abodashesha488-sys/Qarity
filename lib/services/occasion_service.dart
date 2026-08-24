import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_models.dart';
import 'notification_service.dart';

class OccasionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<Occasion>> getOccasionsList() async {
    final snapshot = await _firestore.collection('occasions').where('isApproved', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Occasion.fromJson(doc.data(), doc.id)).toList();
  }

  Stream<List<Occasion>> getOccasionsStream() {
    return _firestore
        .collection('occasions')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Occasion.fromJson(doc.data(), doc.id)).toList());
  }

  Future<void> addOccasion(Occasion occasion) async {
    await _firestore.collection('occasions').add({
      ...occasion.toJson(),
      'isApproved': false,
    });
    await NotificationService.showLocalNotification(
      title: '🎉 مناسبة جديدة',
      body: 'تم إرسال المناسبة للمراجعة: ${occasion.title}',
      payload: '/occasions',
    );
  }
}
