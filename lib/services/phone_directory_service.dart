import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_models.dart';

class PhoneDirectoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<PhoneDirectoryEntry>> getEntriesList() async {
    final snapshot = await _firestore.collection('phone_directory').get();
    return snapshot.docs.map((doc) => PhoneDirectoryEntry.fromJson(doc.data(), doc.id)).toList();
  }
}
