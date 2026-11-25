import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wassalni_model.dart';
import 'remote_push_service.dart';

/// خدمة إدارة رحلات وحجوزات «وصّلني» (سيارة ملاكي خاصة أو توك توك)
class WassalniService {
  WassalniService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ridesCol =>
      _firestore.collection('wassalni_rides');

  /// توليد رقم رحلة فريد غير متكرر: WAS-YYYYMMDD-XXXX
  static String generateRideNumber() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final rand = (1000 + Random.secure().nextInt(9000)).toString();
    return 'WAS-$y$m$d-$rand';
  }

  /// إنشاء طلب رحلة جديد وإخطار الإدارة والسائقين
  Future<String> createRide({
    required String userId,
    required String userName,
    required String userPhone,
    required WassalniVehicleType vehicleType,
    required String pickupLocation,
    required String dropoffLocation,
    bool isRoundTrip = false,
    String scheduledTimeText = 'الآن فوراً',
    int passengersCount = 1,
    double estimatedFare = 0.0,
    String notes = '',
  }) async {
    final docRef = _ridesCol.doc();
    final ride = WassalniRide(
      id: docRef.id,
      rideNumber: generateRideNumber(),
      userId: userId,
      userName: userName.trim(),
      userPhone: userPhone.trim(),
      vehicleType: vehicleType,
      pickupLocation: pickupLocation.trim(),
      dropoffLocation: dropoffLocation.trim(),
      isRoundTrip: isRoundTrip,
      scheduledTimeText: scheduledTimeText.trim().isEmpty
          ? 'الآن فوراً'
          : scheduledTimeText.trim(),
      passengersCount: passengersCount.clamp(1, 8),
      estimatedFare: estimatedFare,
      notes: notes.trim(),
      createdAt: DateTime.now(),
    );

    await docRef.set(ride.toJson());
    unawaited(RemotePushService.notifyAdmins('wassalni_rides'));
    return docRef.id;
  }

  /// تخصيص سائق وتحديد الأجرة النهائية من الإدارة/المندوب
  Future<void> assignDriver({
    required String rideId,
    required String driverName,
    required String driverPhone,
    String vehicleInfo = '',
    double finalFare = 0.0,
    String driverId = '',
  }) async {
    await _ridesCol.doc(rideId).update({
      'driverId': driverId.trim(),
      'driverName': driverName.trim(),
      'driverPhone': driverPhone.trim(),
      'vehicleInfo': vehicleInfo.trim(),
      if (finalFare > 0) 'finalFare': finalFare,
      'status': WassalniStatus.accepted.code,
    });
  }

  /// تحديث حالة الرحلة
  Future<void> updateStatus(String rideId, WassalniStatus status) async {
    await _ridesCol.doc(rideId).update({
      'status': status.code,
      if (status == WassalniStatus.completed)
        'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// إلغاء الرحلة
  Future<void> cancelRide(String rideId) async {
    await updateStatus(rideId, WassalniStatus.cancelled);
  }

  /// حذف رحلة (للإدارة)
  Future<void> deleteRide(String rideId) async {
    await _ridesCol.doc(rideId).delete();
  }

  /// متابعة رحلات المستخدم الحالي (بحد أقصى 30 رحلة حديثة)
  Stream<List<WassalniRide>> watchMyRides(String userId) {
    return _ridesCol
        .where('userId', isEqualTo: userId)
        .limit(30)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => WassalniRide.fromJson(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// متابعة كل رحلات «وصّلني» للوحة الإدارة والسائقين (بحد أقصى 60 رحلة)
  Stream<List<WassalniRide>> watchAllRides() {
    return _ridesCol.limit(60).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => WassalniRide.fromJson(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
