import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/village_alert.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

/// خدمة التنبيه العاجل والخبر العاجل — وثيقتان في `village_alerts`:
/// `current` للتنبيه الأحمر، و`breaking` للخبر الأصفر. القراءة عامة،
/// والكتابة للأدمن (بقواعد Firestore). التفعيل يرسل FCM فورياً للموضوع.
class AlertService {
  final FirebaseFirestore _firestore;
  AlertService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String docId = 'current';
  static const String breakingDocId = 'breaking';
  static const String alertTopic = 'village_alerts';
  static const String breakingTopic = 'village_breaking';

  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      _firestore.collection('village_alerts').doc(id);

  VillageAlert? _map(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return null;
    final alert = VillageAlert.fromJson(doc.data()!);
    return alert.isLive ? alert : null;
  }

  // ─────────── التنبيه العاجل (الأحمر) ───────────
  Stream<VillageAlert?> watchLiveAlert() => _doc(docId).snapshots().map(_map);

  Future<VillageAlert?> getLiveAlert() async => _map(await _doc(docId).get());

  Future<VillageAlert> getAlert() async {
    final doc = await _doc(docId).get();
    return doc.exists
        ? VillageAlert.fromJson(doc.data()!)
        : const VillageAlert();
  }

  Future<void> enableAlert(String message) => _enable(
        doc: docId,
        topic: alertTopic,
        message: message,
        pushTitle: '🚨 تنبيه عاجل — قرية أبوديشيشة',
        localTitle: '🚨 تم تفعيل تنبيه القرية العاجل',
      );

  Future<void> disableAlert() => _disable(docId);

  // ─────────── الخبر العاجل (الأصفر) ───────────
  Stream<VillageAlert?> watchLiveBreaking() =>
      _doc(breakingDocId).snapshots().map(_map);

  Future<VillageAlert?> getLiveBreaking() async =>
      _map(await _doc(breakingDocId).get());

  Future<VillageAlert> getBreaking() async {
    final doc = await _doc(breakingDocId).get();
    return doc.exists
        ? VillageAlert.fromJson(doc.data()!)
        : const VillageAlert();
  }

  Future<void> enableBreaking(String message) => _enable(
        doc: breakingDocId,
        topic: breakingTopic,
        message: message,
        pushTitle: '🟨 خبر عاجل — قرية أبوديشيشة',
        localTitle: '🟨 تم تفعيل خبر عاجل للقرية',
      );

  Future<void> disableBreaking() => _disable(breakingDocId);

  // ─────────── آلية مشتركة ───────────
  Future<void> _enable({
    required String doc,
    required String topic,
    required String message,
    required String pushTitle,
    required String localTitle,
  }) async {
    final text = message.trim();
    if (text.isEmpty) throw Exception('اكتب النص أولاً');
    await _doc(doc).set({
      'message': text,
      'isActive': true,
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    RemotePushService.send(
      topic: topic,
      title: pushTitle,
      body: text,
      route: '/',
    );
    NotificationService.showLocalNotification(
      title: localTitle,
      body: text,
      payload: '/',
    );
  }

  Future<void> _disable(String doc) async {
    await _doc(doc).set({
      'isActive': false,
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
