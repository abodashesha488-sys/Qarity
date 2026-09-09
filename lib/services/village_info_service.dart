import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/data_models.dart';
import 'cache_service.dart';

class VillageInfoService {
  final CollectionReference _ref = FirebaseFirestore.instance.collection('village_info');

  Stream<VillageInfo?> getInfoStream() {
    return _ref.doc('main').snapshots().map((doc) =>
        doc.exists ? VillageInfo.fromJson(doc.data() as Map<String, dynamic>, doc.id) : null);
  }

  Future<VillageInfo?> getInfo() async {
    final cached = await CacheService.getVillageInfo();
    if (cached != null) {
      return VillageInfo.fromJson(cached, 'main');
    }
    final doc = await _ref.doc('main').get();
    if (doc.exists) {
      final info = VillageInfo.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      await CacheService.saveVillageInfo(info.toJson());
      return info;
    }
    return null;
  }

  Future<void> seedIfEmpty() async {
    final doc = await _ref.doc('main').get();
    if (doc.exists) return;
    await _ref.doc('main').set(VillageInfo.defaults().toJson());
    await CacheService.invalidateVillageInfo();
  }
}
