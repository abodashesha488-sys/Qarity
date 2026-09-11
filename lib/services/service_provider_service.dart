import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_provider_model.dart';

/// خدمة دليل الخدمات — فنيون/خدمات زراعية/خدمات تعليمية (مدخلات مستخدمين + موافقة).
class ServiceProviderService {
  final FirebaseFirestore _firestore;
  ServiceProviderService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('service_providers');

  Future<String> create(ServiceProvider provider) async {
    final ref = await _col.add(provider.toJson());
    return ref.id;
  }

  /// العناصر المعتمدة لفئة معينة.
  Stream<List<ServiceProvider>> getApprovedByCategory(String category) {
    return _col
        .where('category', isEqualTo: category)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => ServiceProvider.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<List<ServiceProvider>> getMine(String userId) async {
    final snap = await _col.where('submittedBy', isEqualTo: userId).get();
    return snap.docs
        .map((d) => ServiceProvider.fromJson(d.data(), d.id))
        .toList();
  }
}
