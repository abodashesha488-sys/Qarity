import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/village_alert.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

/// خدمة التنبيه العاجل والخبر العاجل — وثيقتان في `village_alerts`:
/// `current` للتنبيه الأحمر، و`breaking` للخبر الأصفر. القراءة عامة،
/// والكتابة للأدمن (بقواعد Firestore). نمط الظهور يحدده الأدمن:
/// display (عرض فقط) / push (+ إشعار) / sound (+ صوت واهتزاز)،
/// مع مدة صلاحية تلقائية اختيارية تُخفي التنبيه بعد انتهائها.
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

  Future<void> enableAlert(String message,
          {String mode = VillageAlertMode.push, DateTime? expiresAt}) =>
      _enable(
        doc: docId,
        message: message,
        mode: mode,
        expiresAt: expiresAt,
        pushTitle: '🚨 تنبيه عاجل — قرية أبوديشيشة',
        localTitle: '🚨 تم تفعيل تنبيه القرية العاجل',
      );

  Future<void> updateAlertText(String message) =>
      _updateText(docId, message);

  Future<void> renotifyAlert() => _renotify(docId,
      pushTitle: '🚨 تنبيه عاجل — قرية أبوديشيشة',
      localTitle: '🚨 تم تحديث تنبيه القرية العاجل');

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

  Future<void> enableBreaking(String message,
          {String mode = VillageAlertMode.push, DateTime? expiresAt}) =>
      _enable(
        doc: breakingDocId,
        message: message,
        mode: mode,
        expiresAt: expiresAt,
        pushTitle: '🟨 خبر عاجل — قرية أبوديشيشة',
        localTitle: '🟨 تم تفعيل خبر عاجل للقرية',
      );

  Future<void> updateBreakingText(String message) =>
      _updateText(breakingDocId, message);

  Future<void> renotifyBreaking() => _renotify(breakingDocId,
      pushTitle: '🟨 خبر عاجل — قرية أبوديشيشة',
      localTitle: '🟨 تم تحديث الخبر العاجل');

  Future<void> disableBreaking() => _disable(breakingDocId);

  // ─────────── الآلية المشتركة ───────────

  String _topic(String doc) =>
      doc == breakingDocId ? breakingTopic : alertTopic;

  Future<void> _enable({
    required String doc,
    required String message,
    required String mode,
    required DateTime? expiresAt,
    required String pushTitle,
    required String localTitle,
  }) async {
    final text = message.trim();
    if (text.isEmpty) throw Exception('اكتب النص أولاً');
    await _doc(doc).set({
      'message': text,
      'isActive': true,
      'mode': mode,
      'expiresAt':
          expiresAt == null ? null : Timestamp.fromDate(expiresAt),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (mode == VillageAlertMode.display) return;
    _fanOut(
        doc: doc,
        text: text,
        pushTitle: pushTitle,
        localTitle: localTitle,
        withSound: mode == VillageAlertMode.sound);
  }

  /// تحديث النص بصمت — لا إشعارات. البانر يتحدث لدى الجميع مباشرة،
  /// وإن كان النمط «صوت» يقرع الجرس مرة واحدة لكل نسخة جديدة من النص.
  Future<void> _updateText(String doc, String message) async {
    final text = message.trim();
    if (text.isEmpty) throw Exception('اكتب النص أولاً');
    await _doc(doc).update({
      'message': text,
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _renotify(String doc,
      {required String pushTitle, required String localTitle}) async {
    final snap = await _doc(doc).get();
    if (!snap.exists) throw Exception('لا يوجد تنبيه مفعّل');
    final alert = VillageAlert.fromJson(snap.data()!);
    if (!alert.isActive || alert.message.isEmpty) {
      throw Exception('لا يوجد تنبيه مفعّل');
    }
    if (alert.mode == VillageAlertMode.display) {
      throw Exception('النمط الحالي «عرض فقط» — اختر نمطًا بالإشعارات أولًا');
    }
    _fanOut(
        doc: doc,
        text: alert.message,
        pushTitle: pushTitle,
        localTitle: localTitle,
        withSound: alert.mode == VillageAlertMode.sound);
  }

  void _fanOut({
    required String doc,
    required String text,
    required String pushTitle,
    required String localTitle,
    required bool withSound,
  }) {
    RemotePushService.send(
      topic: _topic(doc),
      title: pushTitle,
      body: text,
      route: '/',
      alert: withSound,
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
