import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/market_extra_models.dart';
import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

class DonationService {
  final FirebaseFirestore _firestore;
  DonationService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('donations');

  Future<String> create(Donation donation) async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    final ref = await _col.add(donation.toJson());
    await CacheService.invalidateDonations();
    unawaited(RemotePushService.notifyAdmins('donations'));
    await NotificationService.showLocalNotification(
      title: '🎁 تبرع جديد',
      body: 'تم إرسال "${donation.title}" للمراجعة',
      payload: '/market',
    );
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '🎁 تم إرسال طلبك',
        body: 'تم إرسال التبرع "${donation.title}" للمراجعة وسيظهر بعد موافقة الإدارة',
        route: '/market',
        kind: 'info',
      ));
    }
    return ref.id;
  }

  Future<List<Donation>> getAvailableDonations({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getDonations();
      if (cached != null) {
        return cached.map((json) => Donation.fromJson(json, 'cache')).toList();
      }
    }
    final snap = await _col.where('status', isEqualTo: 'available').get();
    final donations = snap.docs.map((d) => Donation.fromJson(d.data(), d.id)).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
    await CacheService.saveDonations(donations.map((d) => d.toJson()).toList());
    return donations;
  }

  Stream<List<Donation>> getAvailableDonationsStream() {
    return _col
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((s) => s.docs
            .map((d) => Donation.fromJson(d.data(), d.id))
            .toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(1970))
              .compareTo(a.createdAt ?? DateTime(1970))));
  }

  Stream<List<Donation>> getMyDonationsStream(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Donation.fromJson(d.data(), d.id))
            .toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(1970))
              .compareTo(a.createdAt ?? DateTime(1970))));
  }

  Future<void> markDonated(String id) async {
    await _col.doc(id).update({'status': 'donated'});
    await CacheService.invalidateDonations();
  }

  Future<void> markAvailable(String id) async {
    await _col.doc(id).update({'status': 'available'});
    await CacheService.invalidateDonations();
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
    await CacheService.invalidateDonations();
  }
}
