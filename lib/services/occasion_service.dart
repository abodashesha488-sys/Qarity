import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/data_models.dart';
import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

class OccasionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<Occasion>> getOccasionsList({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getOccasions();
      if (cached != null) {
        return cached.map((json) => Occasion.fromJson(json, 'cache')).toList();
      }
    }
    final snapshot = await _firestore.collection('occasions').where('isApproved', isEqualTo: true).get();
    final occasions = snapshot.docs.map((doc) => Occasion.fromJson(doc.data(), doc.id)).toList();
    await CacheService.saveOccasions(occasions.map((o) => o.toJson()).toList());
    return occasions;
  }

  Stream<List<Occasion>> getOccasionsStream() {
    return _firestore
        .collection('occasions')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Occasion.fromJson(doc.data(), doc.id)).toList());
  }

  Future<Occasion?> getOccasionById(String id) async {
    if (id.trim().isEmpty) return null;
    final doc = await _firestore.collection('occasions').doc(id.trim()).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return Occasion.fromJson(data, doc.id);
  }

  Future<void> addOccasion(Occasion occasion) async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    await _firestore.collection('occasions').add({
      ...occasion.toJson(),
      'isApproved': false,
      'submittedBy': uid ?? '',
    });
    await CacheService.invalidateOccasions();
    unawaited(RemotePushService.notifyAdmins('occasions'));
    await NotificationService.showLocalNotification(
      title: 'مناسبة جديدة',
      body: 'تم إرسال المناسبة للمراجعة: ${occasion.title}',
      payload: '/occasions',
    );
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '🎉 تم إرسال طلبك',
        body: 'تم إرسال المناسبة "${occasion.title}" للمراجعة وستظهر بعد موافقة الإدارة',
        route: '/occasions',
        kind: 'info',
      ));
    }
  }
}
