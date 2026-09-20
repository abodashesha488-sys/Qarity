import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/market_extra_models.dart';
import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

class ShopService {
  final FirebaseFirestore _firestore;
  ShopService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('shops');

  Future<String> createShop(Shop shop) async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    final ref = await _col.add(shop.toJson());
    await CacheService.invalidateShops();
    unawaited(RemotePushService.notifyAdmins('shops'));
    await NotificationService.showLocalNotification(
      title: '🏬 محل جديد',
      body: 'تم إرسال "${shop.name}" للمراجعة',
      payload: '/market',
    );
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '🏬 تم إرسال طلبك',
        body: 'تم إرسال "${shop.name}" للمراجعة وسيظهر بعد موافقة الإدارة',
        route: '/market',
        kind: 'info',
      ));
    }
    return ref.id;
  }

  /// المحلات المعتمدة النشطة.
  Stream<List<Shop>> getShopsStream() {
    return _col
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Shop.fromJson(d.data(), d.id)).toList());
  }

  /// للمالك: المعتمدة النشطة أولاً، ثم محلاته هو غير المعتمدة (بوسم «قيد المراجعة»)
  /// حتى يرى المستخدم نتيجة إنشائه فوراً بدل أن يختفي.
  Stream<List<Shop>> getVisibleShopsStream([String? ownerUid]) {
    return _col.snapshots().map((s) {
      final all =
          s.docs.map((d) => Shop.fromJson(d.data(), d.id)).toList();
      final visible = all
          .where((sh) =>
              (sh.isApproved && sh.isActive) ||
              (ownerUid != null && sh.ownerUid == ownerUid))
          .toList();
      int rank(Shop sh) {
        if (sh.isApproved && sh.isActive) return 0;
        if (sh.ownerUid == ownerUid && !sh.isApproved) return 1;
        return 2;
      }
      visible.sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        return (b.createdAt ?? DateTime(1970))
            .compareTo(a.createdAt ?? DateTime(1970));
      });
      return visible;
    });
  }

  /// محلات مستخدم معيّن (لوحتي).
  Future<List<Shop>> getMyShops(String ownerUid) async {
    final snap =
        await _col.where('ownerUid', isEqualTo: ownerUid).get();
    return snap.docs.map((d) => Shop.fromJson(d.data(), d.id)).toList();
  }

  Stream<List<Shop>> getMyShopsStream(String ownerUid) {
    return _col
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((s) => s.docs.map((d) => Shop.fromJson(d.data(), d.id)).toList());
  }

  Future<Shop?> getShop(String id) async {
    if (id.isEmpty) return null;
    final doc = await _col.doc(id).get();
    return doc.exists ? Shop.fromJson(doc.data()!, doc.id) : null;
  }

  Stream<Shop?> getShopStream(String id) {
    return _col.doc(id).snapshots().map(
        (doc) => doc.exists ? Shop.fromJson(doc.data()!, doc.id) : null);
  }

  Future<void> updateShop(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update(data);
    await CacheService.invalidateShops();
  }

  Future<void> setShopActive(String id, bool active) async {
    await _col.doc(id).update({'isActive': active});
    await CacheService.invalidateShops();
  }

  /// هل يملك هذا المستخدم محلاً بالفعل؟
  Future<bool> hasShop(String ownerUid) async {
    final snap = await _col.where('ownerUid', isEqualTo: ownerUid).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<List<Shop>> getApprovedShops({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getShops();
      if (cached != null) {
        return cached.map((json) => Shop.fromJson(json, 'cache')).toList();
      }
    }
    final snap = await _col.where('isApproved', isEqualTo: true).where('isActive', isEqualTo: true).get();
    final shops = snap.docs.map((d) => Shop.fromJson(d.data(), d.id)).toList();
    await CacheService.saveShops(shops.map((s) => s.toJson()).toList());
    return shops;
  }
}
