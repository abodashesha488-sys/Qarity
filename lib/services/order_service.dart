import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/data_models.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrder(AppOrder order) async {
    await _firestore.collection('orders').add(order.toJson());
  }

  Stream<List<AppOrder>> getSellerOrdersStream(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppOrder.fromJson(doc.data(), doc.id)).toList())
        .handleError((error, stack) => <AppOrder>[]);
  }

  Stream<List<AppOrder>> getBuyerOrdersStream(String buyerId) {
    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppOrder.fromJson(doc.data(), doc.id)).toList())
        .handleError((error, stack) => <AppOrder>[]);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({'status': status});
  }

  Future<AppOrder?> getOrder(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (doc.exists) return AppOrder.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    return null;
  }
}