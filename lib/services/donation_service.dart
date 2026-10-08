import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/notification_deeplink.dart';
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

  static String? viewerUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static List<Donation> visibleToViewer(List<Donation> items, String? uid) {
    final mine = uid != null && uid.isNotEmpty;
    return items
        .where((d) => d.isApproved || (mine && d.userId == uid))
        .toList();
  }

  Future<String> create(Donation donation) async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    // الاعتماد قرار إداري محض: تُجبر الوثيقة على التعليق مهما حمل نموذج الجهاز،
    // فالقواعد ترفض ذلك على الخادم لكن الكاش المحلي لا يمرّ بها.
    final ref = await _col.add(donation.toJson()..['isApproved'] = false);
    await CacheService.invalidateDonations();
    unawaited(RemotePushService.notifyAdmins('donations'));
    await NotificationService.showLocalNotification(
      title: '🎁 تبرع جديد',
      body: 'تم إرسال "${donation.title}" للمراجعة',
      payload: NotificationDeepLink.encode('/market', 'donations', ref.id),
    );
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '🎁 تم إرسال طلبك',
        body: 'تم إرسال التبرع "${donation.title}" للمراجعة وسيظهر بعد موافقة الإدارة',
        route: NotificationDeepLink.encode('/market', 'donations', ref.id),
        kind: 'info',
      ));
    }
    return ref.id;
  }

  static List<Donation> _availableVisible(List<Donation> items, String? uid) =>
      visibleToViewer(items.where((d) => d.isAvailable).toList(), uid)
        ..sort(_newestFirst);

  Future<List<Donation>> getAvailableDonations({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getDonations();
      if (cached != null) {
        return _availableVisible(
            cached.map((json) => Donation.fromJson(json, 'cache')).toList(),
            viewerUid());
      }
    }
    final snap = await _col.get();
    final fetched =
        snap.docs.map((d) => Donation.fromJson(d.data(), d.id)).toList();
    await CacheService.saveDonations(fetched.map((d) => d.toJson()).toList());
    return _availableVisible(fetched, viewerUid());
  }

  Stream<List<Donation>> getAvailableDonationsStream() {
    final uid = viewerUid();
    // لا where('status', …) على الخادم: قاعدة Firestore تُسقط صامتًا أي وثيقة لا
    // تملك الحقل المُصفَّى عليه، فيغيب معلّق أو مُعتمَد عن التبويب بلا أي خطأ،
    // بينما لوحة الإدارة — التي تقرأ المجموعة كاملة — تُظهره.
    return _col.snapshots().map((s) {
      final all = s.docs.map((d) => Donation.fromJson(d.data(), d.id)).toList();
      // الكاش يُكتب من الستريم نفسه: فرع OfflineStreamBuilder عند انقطاع الشبكة
      // يقرأ CacheService.getDonations() وحده، وبلا كتابة هنا يعرض «لا توجد
      // تبرعات مخزنة» رغم موافقة الإدارة. الكتالوج كاملًا لا المرشَّح.
      unawaited(
          CacheService.saveDonations(all.map((d) => d.toJson()).toList()));
      return _availableVisible(all, uid);
    });
  }

  static int _newestFirst(Donation a, Donation b) =>
      (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970));

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
