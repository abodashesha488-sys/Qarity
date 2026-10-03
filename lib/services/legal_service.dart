import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/legal_models.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'owner_content_service.dart';
import 'remote_push_service.dart';

String? _currentUid() {
  try {
    return FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    // FirebaseAuth غير مهيأ (اختبارات الواجهة).
    return null;
  }
}

List<T> _newestFirst<T>(List<T> list, DateTime? Function(T) at) {
  list.sort((a, b) {
    final x = at(a), y = at(b);
    if (x == null || y == null) return 0;
    return y.compareTo(x);
  });
  return list;
}

/// سجل المحامين في «مستشار القرية» (مجموعة lawyers).
/// السجل يبدأ غير معتمد؛ صاحبه يعدّله ويحذفه، والإدارة تعتمده وتعدّله.
class LawyerService {
  final FirebaseFirestore _firestore;
  LawyerService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('lawyers');

  Future<String> create(Lawyer lawyer) async {
    final ref = await _col.add(lawyer.toJson());
    unawaited(RemotePushService.notifyAdmins('lawyers'));
    await NotificationService.showLocalNotification(
      title: '⚖️ تسجيل محامٍ جديد',
      body: 'تم إرسال «${lawyer.name}» للمراجعة',
      payload: '/legal',
    );
    final uid = _currentUid();
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '⚖️ تم إرسال تسجيلك',
        body:
            'تم إرسال «${lawyer.name}» للمراجعة وسيظهر في السجل بعد موافقة الإدارة',
        route: '/legal',
        kind: 'info',
      ));
    }
    return ref.id;
  }

  /// تعديل صاحب السجل لبياناته: يعود إلى المراجعة (البند ٨).
  Future<void> update(String id, Lawyer lawyer) => OwnerContentService.edit(
        _firestore,
        'lawyers',
        id,
        lawyer.toWriteMap(),
        label: lawyer.name,
      );

  Future<void> delete(String id) =>
      OwnerContentService.remove(_firestore, 'lawyers', id);

  /// المحامون المعتمدون — الأحدث أولاً. الشرط على الخادم يوفّر القراءة،
  /// والترتيب كلاينت لأن `orderBy('createdAt')` يُسقط أي وثيقة بلا الحقل.
  Stream<List<Lawyer>> watchApproved() {
    return _col
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((s) => _newestFirst<Lawyer>(
            s.docs.map((d) => Lawyer.fromJson(d.data(), d.id)).toList(),
            (l) => l.createdAt));
  }

  /// سجلات المستخدم نفسه بكل حالاتها (لمتابعة المعلّق منها).
  Stream<List<Lawyer>> watchMine(String userId) {
    return _col
        .where('submittedBy', isEqualTo: userId)
        .snapshots()
        .map((s) => _newestFirst<Lawyer>(
            s.docs.map((d) => Lawyer.fromJson(d.data(), d.id)).toList(),
            (l) => l.createdAt));
  }

  Future<Lawyer?> getById(String id) async {
    if (id.isEmpty) return null;
    final snap = await _col.doc(id).get();
    return snap.exists ? Lawyer.fromJson(snap.data() ?? {}, snap.id) : null;
  }
}

/// استشارات الأهالي القانونية (مجموعة legal_consultations).
class LegalConsultationService {
  final FirebaseFirestore _firestore;
  LegalConsultationService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('legal_consultations');

  Future<String> create(LegalConsultation c) async {
    final ref = await _col.add(c.toJson());
    unawaited(RemotePushService.notifyAdmins('legal_consultations'));
    await NotificationService.showLocalNotification(
      title: '⚖️ استشارة قانونية جديدة',
      body: 'تم إرسال سؤال للمراجعة',
      payload: '/legal',
    );
    final uid = _currentUid();
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '⚖️ تم إرسال استشارتك',
        body:
            'تم إرسال سؤالك للمراجعة وسيظهر للقرية بعد موافقة الإدارة مع رد المستشار',
        route: '/legal',
        kind: 'info',
      ));
    }
    return ref.id;
  }

  /// تعديل صاحب السؤال لسؤاله: يعود للمراجعة ويُفرَّغ الرد (البند ٨).
  Future<void> update(String id, LegalConsultation c) =>
      OwnerContentService.edit(
        _firestore,
        'legal_consultations',
        id,
        c.toWriteMap(),
        label: c.question,
      );

  Future<void> delete(String id) =>
      OwnerContentService.remove(_firestore, 'legal_consultations', id);

  /// الاستشارات المعتمدة — الأحدث أولاً (المرشَّح على الخادم حتى لا تُقرأ
  /// الأسئلة المعلّقة لغير أصحابها).
  Stream<List<LegalConsultation>> watchApproved() {
    return _col
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((s) => _newestFirst<LegalConsultation>(
            s.docs.map((d) => LegalConsultation.fromJson(d.data(), d.id))
                .toList(), (c) => c.createdAt));
  }

  Stream<List<LegalConsultation>> watchMine(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => _newestFirst<LegalConsultation>(
            s.docs
                .map((d) => LegalConsultation.fromJson(d.data(), d.id))
                .toList(), (c) => c.createdAt));
  }
}
