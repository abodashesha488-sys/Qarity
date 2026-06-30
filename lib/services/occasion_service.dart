import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_models.dart';

class OccasionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<Occasion>> getOccasionsList() async {
    final snapshot = await _firestore.collection('occasions').where('isApproved', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Occasion.fromJson(doc.data(), doc.id)).toList();
  }
}
