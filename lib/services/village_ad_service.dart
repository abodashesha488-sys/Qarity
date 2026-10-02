import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/village_ad_model.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

/// خدمة «إعلانات القرية» — إعلانات تجارية وخدمية وإنشائية لأهل القرية.
/// كل إعلان يبدأ غير معتمد ويظهر للقرية بعد موافقة الإدارة، وصاحبه يظل
/// يتحكم فيه تعديلًا وحذفًا بعد الاعتماد.
class VillageAdService {
  final FirebaseFirestore _firestore;
  VillageAdService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('village_ads');

  String? _uid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth غير مهيأ (اختبارات الواجهة).
      return null;
    }
  }

  Future<String> create(VillageAd ad) async {
    final ref = await _col.add(ad.toJson());
    unawaited(RemotePushService.notifyAdmins('village_ads'));
    await NotificationService.showLocalNotification(
      title: '📢 إعلان جديد بانتظار المراجعة',
      body: 'تم إرسال «${ad.title}» للمراجعة',
      payload: '/ads',
    );
    final uid = _uid();
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '📢 تم إرسال إعلانك',
        body: 'تم إرسال «${ad.title}» للمراجعة وسيظهر للقرية بعد موافقة الإدارة',
        route: '/ads',
        kind: 'info',
      ));
    }
    return ref.id;
  }

  /// تعديل بيانات الإعلان — بلا `isApproved` حتى لا يُخفى إعلان معتمد.
  Future<void> update(String id, VillageAd ad) =>
      _col.doc(id).set(ad.toWriteMap(), SetOptions(merge: true));

  Future<void> delete(String id) => _col.doc(id).delete();

  /// إعلانات القرية المعتمدة — المرشَّح على الخادم (شرط القائمة في القواعد
  /// يرفض أي استعلام غير مُصفًّى لغير الأدمن)، والترتيب في الكلاينت لأن
  /// `orderBy('createdAt')` يُسقط أي وثيقة لا تملك الحقل.
  Stream<List<VillageAd>> watchApproved() {
    return _col
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((s) => _sorted(s.docs
            .map((d) => VillageAd.fromJson(d.data(), d.id))
            .toList()));
  }

  /// كل إعلانات المستخدم (المعتمدة والمعلّقة) — الأحدث أولاً.
  Stream<List<VillageAd>> watchMine(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => _sorted(s.docs
            .map((d) => VillageAd.fromJson(d.data(), d.id))
            .toList()));
  }

  Future<VillageAd?> getById(String id) async {
    if (id.isEmpty) return null;
    final snap = await _col.doc(id).get();
    return snap.exists ? VillageAd.fromJson(snap.data() ?? {}, snap.id) : null;
  }

  List<VillageAd> _sorted(List<VillageAd> list) {
    list.sort((a, b) {
      final da = a.createdAt, db = b.createdAt;
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    return list;
  }
}
