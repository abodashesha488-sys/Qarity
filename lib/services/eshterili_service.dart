import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/eshterili_model.dart';
import 'group_deal_service.dart';

/// خدمة إدارة طلبات ومحاسبة «إشتريلي»
class EshteriliService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('eshterili_orders');

  /// توليد كود استلام سري عشوائي من 4 أرقام
  static String generateClaimCode() => GroupDealService.generateClaimCode();

  /// توليد رقم طلب/فاتورة فريد غير متكرر: ESH-YYYYMMDD-XXXX
  static String generateOrderNumber() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final rand = (1000 + Random.secure().nextInt(9000)).toString();
    return 'ESH-$y$m$d-$rand';
  }

  /// إنشاء طلب شراء جديد من المستخدم
  Future<String> createOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required String itemsDescription,
    required double estimatedBudget,
    required String storeOrArea,
    required String deliveryAddress,
    String notes = '',
  }) async {
    final docRef = _ordersCol.doc();
    final claimCode = generateClaimCode();
    final orderNumber = generateOrderNumber();

    final order = EshteriliOrder(
      id: docRef.id,
      orderNumber: orderNumber,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      itemsDescription: itemsDescription.trim(),
      estimatedBudget: estimatedBudget,
      storeOrArea: storeOrArea.trim(),
      deliveryAddress: deliveryAddress.trim(),
      claimCode: claimCode,
      notes: notes.trim(),
      createdAt: DateTime.now(),
    );

    await docRef.set(order.toJson());
    return docRef.id;
  }

  /// تسعير الطلب من قبل الإدارة أو المندوب
  Future<void> priceOrder({
    required String orderId,
    required double itemCost,
    required double serviceFee,
    required double deliveryFee,
    String assignedAgentId = '',
    String assignedAgentName = '',
    String assignedAgentPhone = '',
    String notes = '',
  }) async {
    final updateData = <String, dynamic>{
      'itemCost': itemCost,
      'serviceFee': serviceFee,
      'deliveryFee': deliveryFee,
      'totalAmount': itemCost + serviceFee + deliveryFee,
      'status': EshteriliStatus.pricedWaitingApproval.code,
    };
    if (assignedAgentId.isNotEmpty) updateData['assignedAgentId'] = assignedAgentId;
    if (assignedAgentName.isNotEmpty) updateData['assignedAgentName'] = assignedAgentName;
    if (assignedAgentPhone.isNotEmpty) updateData['assignedAgentPhone'] = assignedAgentPhone;
    if (notes.isNotEmpty) updateData['notes'] = notes;

    await _ordersCol.doc(orderId).update(updateData);
  }

  /// موافقة المستخدم على التسعير وبدء التنفيذ
  Future<void> approvePricedOrder(String orderId) async {
    await _ordersCol.doc(orderId).update({
      'status': EshteriliStatus.inProgress.code,
    });
  }

  /// إلغاء الطلب
  Future<void> cancelOrder(String orderId) async {
    await _ordersCol.doc(orderId).update({
      'status': EshteriliStatus.cancelled.code,
    });
  }

  /// تأكيد التسليم للعميل بمطابقة كود الاستلام من جهاز المندوب
  Future<bool> verifyAndDeliverOrder({
    required String orderId,
    required String inputCode,
    required String agentUid,
  }) async {
    final docRef = _ordersCol.doc(orderId);
    final snap = await docRef.get();
    if (!snap.exists) return false;

    final data = snap.data();
    final realCode = (data?['claimCode'] as String?) ?? '';

    if (realCode.trim() != inputCode.trim()) {
      return false; // الكود غير مطابق
    }

    await docRef.update({
      'status': EshteriliStatus.completed.code,
      'deliveredAt': FieldValue.serverTimestamp(),
      'deliveredBy': agentUid,
    });
    return true;
  }

  /// متابعة طلبات المستخدم الحالي
  Stream<List<EshteriliOrder>> watchMyOrders(String userId) {
    return _ordersCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => EshteriliOrder.fromJson(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// متابعة كل طلبات إشتريلي للوحة الإدارة
  Stream<List<EshteriliOrder>> watchAllOrders() {
    return _ordersCol.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => EshteriliOrder.fromJson(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// حذف طلب
  Future<void> deleteOrder(String orderId) async {
    await _ordersCol.doc(orderId).delete();
  }
}
