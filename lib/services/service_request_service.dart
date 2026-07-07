import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/data_models.dart';

class ServiceRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ServiceRequest>> getServiceRequestsList({String? userId}) async {
    try {
      Query query = _firestore.collection('service_requests').orderBy('createdAt', descending: true);
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ServiceRequest.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ServiceRequest?> getServiceRequest(String id) async {
    try {
      final doc = await _firestore.collection('service_requests').doc(id).get();
      if (doc.exists) return ServiceRequest.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> createServiceRequest(ServiceRequest request) async {
    await _firestore.collection('service_requests').add(request.toJson());
  }

  Future<void> updateServiceRequestStatus(String id, String status, {String? assignedTo, String? notes}) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (notes != null) 'notes': notes,
    };
    await _firestore.collection('service_requests').doc(id).update(data);
  }

  Future<void> updateServiceRequest(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('service_requests').doc(id).update(data);
  }

  Future<void> deleteServiceRequest(String id) async {
    await _firestore.collection('service_requests').doc(id).delete();
  }
}
