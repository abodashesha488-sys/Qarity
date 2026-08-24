import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_models.dart';
import 'notification_service.dart';

class ObituaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Obituary>> getObituariesList() async {
    final snapshot = await _firestore.collection('obituaries').where('isApproved', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Obituary.fromJson(doc.data(), doc.id)).toList();
  }

  Stream<List<Obituary>> getObituariesStream() {
    return _firestore
        .collection('obituaries')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Obituary.fromJson(doc.data(), doc.id)).toList());
  }

  Future<Obituary?> getObituaryById(String id) async {
    if (id.trim().isEmpty) return null;
    final doc = await _firestore.collection('obituaries').doc(id.trim()).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return Obituary.fromJson(data, doc.id);
  }

  Future<void> addObituary(Obituary obituary) async {
    await _firestore.collection('obituaries').add({
      ...obituary.toJson(),
      'isApproved': false,
    });
    await NotificationService.showLocalNotification(
      title: '⚰️ تعزية',
      body: 'تم إرسال التعزية للمراجعة: ${obituary.name}',
      payload: '/obituaries',
    );
  }
}
