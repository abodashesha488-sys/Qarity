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

  static String? viewerUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static List<BuyRequest> visibleToViewer(
      List<BuyRequest> items, String? uid) {
    final mine = uid != null && uid.isNotEmpty;
    return items
        .where((r) => r.isApproved || (mine && r.userId == uid))
        .toList();
  }

  Future<String> create(BuyRequest request) async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    // الاعتماد قرار إداري محض: تُجبر الوثيقة على التعليق مهما حمل نموذج الجهاز،
    // فالقواعد ترفض ذلك على الخادم لكن الكاش المحلي لا يمرّ بها.
    final ref = await _col.add(request.toJson()..['isApproved'] = false);
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
        return visibleToViewer(
            cached.map((json) => BuyRequest.fromJson(json, 'cache')).toList(),
            viewerUid());
      }
    }
    final snap = await _col.where('status', isEqualTo: 'open').get();
    final fetched =
        snap.docs.map((d) => BuyRequest.fromJson(d.data(), d.id)).toList();
    await CacheService.saveBuyRequests(fetched.map((r) => r.toJson()).toList());
    return visibleToViewer([...fetched]..sort(_newestFirst), viewerUid());
  }

  Stream<List<BuyRequest>> getOpenRequestsStream() {
    final uid = viewerUid();
    return _col
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((s) {
      final all =
          s.docs.map((d) => BuyRequest.fromJson(d.data(), d.id)).toList();
      // الكاش يُكتب من الستريم نفسه: فرع OfflineStreamBuilder عند انقطاع الشبكة
      // يقرأ CacheService.getBuyRequests() وحده، وبلا كتابة هنا يعرض «لا توجد
      // طلبات مخزنة» رغم موافقة الإدارة. الكتالوج كاملًا لا المرشَّح.
      unawaited(
          CacheService.saveBuyRequests(all.map((r) => r.toJson()).toList()));
      return visibleToViewer(all, uid)..sort(_newestFirst);
    });
  }

  static int _newestFirst(BuyRequest a, BuyRequest b) =>
      (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970));

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
