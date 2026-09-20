import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/data_models.dart';
import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

class ObituaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Obituary>> getObituariesList({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getObituaries();
      if (cached != null) {
        return cached.map((json) => Obituary.fromJson(json, 'cache')).toList();
      }
    }
    final snapshot = await _firestore.collection('obituaries').where('isApproved', isEqualTo: true).get();
    final obituaries = snapshot.docs.map((doc) => Obituary.fromJson(doc.data(), doc.id)).toList();
    await CacheService.saveObituaries(obituaries.map((o) => o.toJson()).toList());
    return obituaries;
  }

  Stream<List<Obituary>> getObituariesStream() {
    return _firestore
        .collection('obituaries')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Obituary.fromJson(doc.data(), doc.id)).toList());
  }

  Future<Obituary?> getObituaryById(String id) async {
    if (id.trim().isEmpty) return null;
    final doc = await _firestore.collection('obituaries').doc(id.trim()).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return Obituary.fromJson(data, doc.id);
  }

  Future<void> addObituary(Obituary obituary) async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    await _firestore.collection('obituaries').add({
      ...obituary.toJson(),
      'isApproved': false,
      'submittedBy': uid ?? '',
    });
    await CacheService.invalidateObituaries();
    unawaited(RemotePushService.notifyAdmins('obituaries'));
    await NotificationService.showLocalNotification(
      title: '⚰️ تعزية',
      body: 'تم إرسال التعزية للمراجعة: ${obituary.name}',
      payload: '/obituaries',
    );
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '⚰️ تم إرسال طلبك',
        body: 'تم إرسال التعزية "${obituary.name}" للمراجعة وستظهر بعد موافقة الإدارة',
        route: '/obituaries',
        kind: 'info',
      ));
    }
  }
}
