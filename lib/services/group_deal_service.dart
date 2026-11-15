import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_deal_model.dart';
import 'remote_push_service.dart';

/// نتيجة عملية تسليم البضاعة عبر كود التحقق
class DeliveryVerificationResult {
  final bool isSuccess;
  final String message;
  final DealParticipantModel? participant;

  const DeliveryVerificationResult({
    required this.isSuccess,
    required this.message,
    this.participant,
  });
}

/// تقرير مالي وحسابي شامل للصفقة
class GroupDealFinancialSummary {
  final int targetCount;
  final int confirmedCount;
  final int unconfirmedCount;
  final int deliveredCount;
  final int pendingDeliveryCount;
  final double marketPrice;
  final double dealPrice;
  final double depositAmount;
  final double savingsPerUnit;
  final double totalVillageSavings;
  final double totalConfirmedSales;
  final double totalDepositsCollected;
  final double totalRemainingToCollect;
  final double totalDeliveredValue;

  const GroupDealFinancialSummary({
    required this.targetCount,
    required this.confirmedCount,
    required this.unconfirmedCount,
    required this.deliveredCount,
    required this.pendingDeliveryCount,
    required this.marketPrice,
    required this.dealPrice,
    required this.depositAmount,
    required this.savingsPerUnit,
    required this.totalVillageSavings,
    required this.totalConfirmedSales,
    required this.totalDepositsCollected,
    required this.totalRemainingToCollect,
    required this.totalDeliveredValue,
  });

  factory GroupDealFinancialSummary.calculate(
    GroupDealModel deal,
    List<DealParticipantModel> participants,
  ) {
    int confirmedUnits = 0;
    int unconfirmedUnits = 0;
    int deliveredUnits = 0;
    int pendingDeliveryUnits = 0;

    for (final p in participants) {
      if (p.isConfirmedByAdmin) {
        confirmedUnits += p.quantity;
        if (p.isDelivered) {
          deliveredUnits += p.quantity;
        } else {
          pendingDeliveryUnits += p.quantity;
        }
      } else {
        unconfirmedUnits += p.quantity;
      }
    }

    final savings = deal.savingsPerUnit;
    final totalSavings = confirmedUnits * savings;
    final totalSales = confirmedUnits * deal.dealPrice;
    final totalDeposits = confirmedUnits * deal.depositAmount;
    final totalRemaining = confirmedUnits * (deal.dealPrice - deal.depositAmount);
    final totalDeliveredVal = deliveredUnits * deal.dealPrice;

    return GroupDealFinancialSummary(
      targetCount: deal.targetCount,
      confirmedCount: confirmedUnits,
      unconfirmedCount: unconfirmedUnits,
      deliveredCount: deliveredUnits,
      pendingDeliveryCount: pendingDeliveryUnits,
      marketPrice: deal.marketPrice,
      dealPrice: deal.dealPrice,
      depositAmount: deal.depositAmount,
      savingsPerUnit: savings,
      totalVillageSavings: totalSavings,
      totalConfirmedSales: totalSales,
      totalDepositsCollected: totalDeposits,
      totalRemainingToCollect: totalRemaining,
      totalDeliveredValue: totalDeliveredVal,
    );
  }
}

class GroupDealService {
  GroupDealService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _dealsCol =>
      _firestore.collection('group_deals');

  CollectionReference<Map<String, dynamic>> get _participantsCol =>
      _firestore.collection('deal_participants');

  /// توليد كود تسليم عشوائي مكون من 4 أرقام (1000 - 9999)
  static String generateClaimCode() {
    final rand = Random();
    final code = 1000 + rand.nextInt(9000);
    return code.toString();
  }

  /// بث حي بكافة الصفقات النشطة الجارية حالياً
  Stream<List<GroupDealModel>> watchActiveDeals() {
    return _dealsCol.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => GroupDealModel.fromJson(d.data(), d.id))
          .where((d) => d.isActive && !d.isCompleted && !d.isExpired)
          .toList();
      // ترتيب الصفقات: الأقرب للانتهاء أولاً
      list.sort((a, b) => a.endTime.compareTo(b.endTime));
      return list;
    });
  }

  /// بث حي بكافة الصفقات المنفذة والمكتملة (أرشيف وسجل الصفقات السابقة)
  Stream<List<GroupDealModel>> watchExecutedDeals() {
    return _dealsCol.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => GroupDealModel.fromJson(d.data(), d.id))
          .where((d) => d.isCompleted || d.isExpired)
          .toList();
      list.sort((a, b) => b.endTime.compareTo(a.endTime));
      return list;
    });
  }

  /// بث حي للصفقة الأهم حالياً لعرضها في الداش بورد الرئيسي
  Stream<GroupDealModel?> watchPrimaryFeaturedDeal() {
    return watchActiveDeals().map((deals) {
      if (deals.isEmpty) return null;
      // نختار أول صفقة متاحة للحجز ولم تنتهِ بعد
      return deals.firstWhere(
        (d) => d.isAvailableForBooking,
        orElse: () => deals.first,
      );
    });
  }

  /// بث تفاصيل صفقة معينة
  Stream<GroupDealModel?> watchDeal(String dealId) {
    return _dealsCol.doc(dealId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return GroupDealModel.fromJson(snap.data()!, snap.id);
    });
  }

  /// بث قائمة المشتركين في صفقة معينة (للأدمن والمندوب)
  Stream<List<DealParticipantModel>> watchDealParticipants(String dealId) {
    return _participantsCol
        .where('dealId', isEqualTo: dealId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => DealParticipantModel.fromJson(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// بث حجز المستخدم الحالي لصفقة معينة
  Stream<DealParticipantModel?> watchUserBooking(String dealId, String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _participantsCol
        .where('dealId', isEqualTo: dealId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return DealParticipantModel.fromJson(snap.docs.first.data(), snap.docs.first.id);
    });
  }

  /// تسجيل حجز جديد في الصفقة الجماعية (معاملة ذرية لتحديث العداد الفعلي فورياً)
  Future<String> bookDeal({
    required String dealId,
    required String userId,
    required String userName,
    required String userPhone,
    int quantity = 1,
    String paymentMethod = 'مندوب القرية',
    String notes = '',
  }) async {
    final claimCode = generateClaimCode();
    final cleanQty = quantity.clamp(1, 100);

    final dealRef = _dealsCol.doc(dealId);
    final participantRef = _participantsCol.doc();

    await _firestore.runTransaction((tx) async {
      final dealSnap = await tx.get(dealRef);
      if (!dealSnap.exists) throw Exception('الصفقة غير موجودة');

      final current = (dealSnap.data()?['currentCount'] as num?)?.toInt() ?? 0;
      final target = (dealSnap.data()?['targetCount'] as num?)?.toInt() ?? 1;
      final newCount = current + cleanQty;

      tx.set(participantRef, {
        'dealId': dealId,
        'userId': userId,
        'userName': userName.trim(),
        'userPhone': userPhone.trim(),
        'quantity': cleanQty,
        'paymentMethod': paymentMethod,
        'claimCode': claimCode,
        'isConfirmedByAdmin': false,
        'confirmedAt': null,
        'confirmedBy': '',
        'isDelivered': false,
        'deliveredAt': null,
        'deliveredBy': '',
        'notes': notes.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(dealRef, {
        'currentCount': newCount,
        'isCompleted': newCount >= target,
      });
    });

    // إشعار الأدمن بحجز جديد لمراجعة العربون
    unawaited(RemotePushService.notifyAdmins('group_deals'));

    return claimCode;
  }

  /// تعديل كمية الحجز بواسطة المستخدم قبل اكتمال أو انتهاء الصفقة
  Future<void> updateBookingQuantity({
    required String dealId,
    required String participantId,
    required int oldQuantity,
    required int newQuantity,
    required bool wasConfirmed,
  }) async {
    final diff = newQuantity - oldQuantity;
    if (diff == 0) return;

    final dealRef = _dealsCol.doc(dealId);
    final participantRef = _participantsCol.doc(participantId);

    await _firestore.runTransaction((tx) async {
      final dealSnap = await tx.get(dealRef);
      if (!dealSnap.exists) throw Exception('الصفقة غير موجودة');

      final current = (dealSnap.data()?['currentCount'] as num?)?.toInt() ?? 0;
      final confirmed = (dealSnap.data()?['confirmedCount'] as num?)?.toInt() ?? 0;
      final target = (dealSnap.data()?['targetCount'] as num?)?.toInt() ?? 1;

      final newCurrent = (current + diff).clamp(0, 999999);
      final newConfirmed = wasConfirmed ? (confirmed + diff).clamp(0, newCurrent) : confirmed;

      tx.update(participantRef, {
        'quantity': newQuantity,
      });

      tx.update(dealRef, {
        'currentCount': newCurrent,
        if (wasConfirmed) 'confirmedCount': newConfirmed,
        'isCompleted': newCurrent >= target,
      });
    });
  }

  /// إلغاء حجز المشترك لنفسه قبل تسليم البضاعة
  Future<void> cancelUserBooking({
    required String dealId,
    required String participantId,
    required int quantity,
    required bool wasConfirmed,
  }) async {
    await cancelParticipant(
      dealId: dealId,
      participantId: participantId,
      quantity: quantity,
      wasConfirmed: wasConfirmed,
    );
  }

  /// تأكيد استلام العربون بواسطة الأدمن (معاملة ذرية لزيادة العداد بأمان)
  Future<void> confirmDeposit({
    required String dealId,
    required String participantId,
    required int quantity,
    required String adminUid,
  }) async {
    final dealRef = _dealsCol.doc(dealId);
    final participantRef = _participantsCol.doc(participantId);

    await _firestore.runTransaction((tx) async {
      final dealSnap = await tx.get(dealRef);
      if (!dealSnap.exists) throw Exception('الصفقة غير موجودة');

      final current = (dealSnap.data()?['currentCount'] as num?)?.toInt() ?? 0;
      final confirmed = (dealSnap.data()?['confirmedCount'] as num?)?.toInt() ?? 0;
      final target = (dealSnap.data()?['targetCount'] as num?)?.toInt() ?? 1;
      final newConfirmed = confirmed + quantity;
      final safeCurrent = current < newConfirmed ? newConfirmed : current;

      tx.update(participantRef, {
        'isConfirmedByAdmin': true,
        'confirmedAt': FieldValue.serverTimestamp(),
        'confirmedBy': adminUid,
      });

      tx.update(dealRef, {
        'confirmedCount': newConfirmed,
        'currentCount': safeCurrent,
        'isCompleted': safeCurrent >= target,
      });
    });
  }

  /// إلغاء حجز أو إرجاعه بواسطة الأدمن
  Future<void> cancelParticipant({
    required String dealId,
    required String participantId,
    required int quantity,
    required bool wasConfirmed,
  }) async {
    final dealRef = _dealsCol.doc(dealId);
    final participantRef = _participantsCol.doc(participantId);

    await _firestore.runTransaction((tx) async {
      final dealSnap = await tx.get(dealRef);
      if (dealSnap.exists) {
        final current = (dealSnap.data()?['currentCount'] as num?)?.toInt() ?? 0;
        final confirmed = (dealSnap.data()?['confirmedCount'] as num?)?.toInt() ?? 0;
        final target = (dealSnap.data()?['targetCount'] as num?)?.toInt() ?? 1;

        final newCurrent = (current - quantity).clamp(0, 999999);
        final newConfirmed = wasConfirmed ? (confirmed - quantity).clamp(0, newCurrent) : confirmed;

        tx.update(dealRef, {
          'currentCount': newCurrent,
          if (wasConfirmed) 'confirmedCount': newConfirmed,
          'isCompleted': newCurrent >= target,
        });
      }
      tx.delete(participantRef);
    });
  }

  /// تسليم البضاعة والتحقق من كود الـ 4 أرقام
  Future<DeliveryVerificationResult> verifyAndDeliverByCode({
    required String dealId,
    required String inputCode,
    required String deliveryAgentUid,
  }) async {
    final cleanCode = inputCode.trim();
    if (cleanCode.length != 4) {
      return const DeliveryVerificationResult(
        isSuccess: false,
        message: 'يرجى إدخال كود استلام صحيح مكون من 4 أرقام.',
      );
    }

    final query = await _participantsCol
        .where('dealId', isEqualTo: dealId)
        .where('claimCode', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return const DeliveryVerificationResult(
        isSuccess: false,
        message: 'كود الاستلام غير صحيح أو غير مسجل في هذه الصفقة.',
      );
    }

    final doc = query.docs.first;
    final participant = DealParticipantModel.fromJson(doc.data(), doc.id);

    if (!participant.isConfirmedByAdmin) {
      return DeliveryVerificationResult(
        isSuccess: false,
        message: 'تنبيه: لم يتم تأكيد استلام عربون هذا المشترك من الإدارة بعد!',
        participant: participant,
      );
    }

    if (participant.isDelivered) {
      return DeliveryVerificationResult(
        isSuccess: false,
        message: 'تم تسليم هذا الطلب بالفعل مسبقاً!',
        participant: participant,
      );
    }

    // توثيق التسليم
    await doc.reference.update({
      'isDelivered': true,
      'deliveredAt': FieldValue.serverTimestamp(),
      'deliveredBy': deliveryAgentUid,
    });

    final updatedParticipant = DealParticipantModel.fromJson({
      ...doc.data(),
      'isDelivered': true,
      'deliveredAt': Timestamp.now(),
      'deliveredBy': deliveryAgentUid,
    }, doc.id);

    return DeliveryVerificationResult(
      isSuccess: true,
      message: 'تم التحقق من الكود وتوثيق تسليم (${participant.quantity} حصة) لـ ${participant.userName} بنجاح ✅',
      participant: updatedParticipant,
    );
  }

  /// إنشاء صفقة جديدة من قبل الإدارة
  Future<String> createDeal(GroupDealModel deal) async {
    final uid = _auth.currentUser?.uid ?? '';
    final ref = await _dealsCol.add({
      ...deal.toJson(),
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// تعديل صفقة
  Future<void> updateDeal(GroupDealModel deal) async {
    await _dealsCol.doc(deal.id).update(deal.toJson());
  }

  /// تفعيل أو إيقاف صفقة
  Future<void> toggleDealActive(String dealId, bool isActive) async {
    await _dealsCol.doc(dealId).update({'isActive': isActive});
  }

  /// حذف صفقة نهائياً
  Future<void> deleteDeal(String dealId) async {
    await _dealsCol.doc(dealId).delete();
    final parts = await _participantsCol.where('dealId', isEqualTo: dealId).get();
    for (final doc in parts.docs) {
      await doc.reference.delete();
    }
  }
}
