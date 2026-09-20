import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/market_extra_models.dart';
import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

class BuyRequestService {
  final FirebaseFirestore _firestore;
  BuyRequestService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('buy_requests');

  Future<String> create(BuyRequest request) async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    final ref = await _col.add(request.toJson());
    await CacheService.invalidateBuyRequests();
    unawaited(RemotePushService.notifyAdmins('buy_requests'));
    await NotificationService.showLocalNotification(
      title: '📝 طلب شراء جديد',
      body: 'تم إرسال "${request.title}" للمراجعة',
      payload: '/market',
    );
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '📝 تم إرسال طلبك',
        body: 'تم إرسال طلب الشراء "${request.title}" للمراجعة وسيظهر بعد موافقة الإدارة',
        route: '/market',
        kind: 'info',
      ));
    }
    return ref.id;
  }

  Future<List<BuyRequest>> getOpenRequests({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getBuyRequests();
      if (cached != null) {
        return cached.map((json) => BuyRequest.fromJson(json, 'cache')).toList();
      }
    }
    final snap = await _col.where('status', isEqualTo: 'open').get();
    final requests = snap.docs.map((d) => BuyRequest.fromJson(d.data(), d.id)).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
    await CacheService.saveBuyRequests(requests.map((r) => r.toJson()).toList());
    return requests;
  }

  Stream<List<BuyRequest>> getOpenRequestsStream() {
    return _col
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((s) => s.docs
            .map((d) => BuyRequest.fromJson(d.data(), d.id))
            .toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(1970))
              .compareTo(a.createdAt ?? DateTime(1970))));
  }

  Stream<List<BuyRequest>> getMyRequestsStream(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => BuyRequest.fromJson(d.data(), d.id))
            .toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(1970))
              .compareTo(a.createdAt ?? DateTime(1970))));
  }

  Future<void> close(String id) async {
    await _col.doc(id).update({'status': 'closed'});
    await CacheService.invalidateBuyRequests();
  }

  Future<void> reopen(String id) async {
    await _col.doc(id).update({'status': 'open'});
    await CacheService.invalidateBuyRequests();
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
    await CacheService.invalidateBuyRequests();
  }
}
