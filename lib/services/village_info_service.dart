import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/data_models.dart';

class VillageInfoService {
  final CollectionReference _ref = FirebaseFirestore.instance.collection('village_info');

  Stream<VillageInfo?> getInfoStream() {
    return _ref.doc('main').snapshots().map((doc) =>
        doc.exists ? VillageInfo.fromJson(doc.data() as Map<String, dynamic>, doc.id) : null);
  }

  Future<VillageInfo?> getInfo() async {
    final doc = await _ref.doc('main').get();
    return doc.exists ? VillageInfo.fromJson(doc.data() as Map<String, dynamic>, doc.id) : null;
  }

  Future<void> seedIfEmpty() async {
    final doc = await _ref.doc('main').get();
    if (doc.exists) return;
    await _ref.doc('main').set(VillageInfo.defaults().toJson());
  }
}
