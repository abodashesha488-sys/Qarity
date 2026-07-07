import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_models.dart';

class ObituaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Obituary>> getObituariesList() async {
    final snapshot = await _firestore.collection('obituaries').where('isApproved', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Obituary.fromJson(doc.data(), doc.id)).toList();
  }

  Future<void> addObituary(Obituary obituary) async {
    await _firestore.collection('obituaries').add({
      ...obituary.toJson(),
      'isApproved': false,
    });
  }
}
