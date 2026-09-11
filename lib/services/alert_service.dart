import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/village_alert.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

/// خدمة التنبيه العاجل — القراءة عامة، والكتابة للأدمن (بقواعد Firestore).
class AlertService {
  final FirebaseFirestore _firestore;
  AlertService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String docId = 'current';
  static const String alertTopic = 'village_alerts';

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('village_alerts').doc(docId);

  VillageAlert? _map(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return null;
    final alert = VillageAlert.fromJson(doc.data()!);
    return alert.isLive ? alert : null;
  }

  /// التدفق الحي للتنبيه الفعّال (null عند عدم وجود تنبيه → حكمة اليوم).
  Stream<VillageAlert?> watchLiveAlert() =>
      _doc.snapshots().map(_map);

  Future<VillageAlert?> getLiveAlert() async {
    final doc = await _doc.get();
    return _map(doc);
  }

  /// حالة التنبيه كما هي في Firestore (مع المعطّل) — لإدارة اللوحة.
  Future<VillageAlert> getAlert() async {
    final doc = await _doc.get();
    return doc.exists ? VillageAlert.fromJson(doc.data()!) : const VillageAlert();
  }

  /// تفعيل التنبيه: حفظ + إرسال FCM فوري لجميع مشتركين `village_alerts`.
  Future<void> enableAlert(String message) async {
    final text = message.trim();
    if (text.isEmpty) throw Exception('اكتب نص التنبيه أولاً');
    await _doc.set({
      'message': text,
      'isActive': true,
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    RemotePushService.send(
      topic: alertTopic,
      title: '🚨 تنبيه عاجل — قرية أبوديشيشة',
      body: text,
      route: '/',
    );
    NotificationService.showLocalNotification(
      title: '🚨 تم تفعيل تنبيه القرية العاجل',
      body: text,
      payload: '/',
    );
  }

  /// إيقاف التنبيه — تعود المساحة تلقائياً لعرض «حكمة اليوم».
  Future<void> disableAlert() async {
    await _doc.set({
      'isActive': false,
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
