import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/agriculture_consultation_model.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'owner_content_service.dart';
import 'remote_push_service.dart';

/// خدمة الاستشارات الزراعية (مجموعة agriculture_consultations).
class AgricultureConsultationService {
  final FirebaseFirestore _firestore;
  AgricultureConsultationService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('agriculture_consultations');

  String? _currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<String> create(AgricultureConsultation c) async {
    final ref = await _col.add(c.toJson());
    unawaited(RemotePushService.notifyAdmins('agriculture_consultations'));
    await NotificationService.showLocalNotification(
      title: '🌱 استشارة زراعية جديدة',
      body: 'تم إرسال استشارة زراعية للمراجعة',
      payload: '/services/agricultural-advisor',
    );
    final uid = _currentUid();
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '🌱 تم إرسال استشارتك الزراعية',
        body:
            'تم إرسال استشارتك الزراعية للمراجعة وسيتم الرد عليها من قبل المستشار الزراعي.',
        route: '/services/agricultural-advisor',
        kind: 'info',
      ));
    }
    return ref.id;
  }

  /// تعديل صاحب السؤال لسؤاله: يعود للمراجعة ويُفرَّغ الرد.
  Future<void> update(String id, AgricultureConsultation c) =>
      OwnerContentService.edit(
        _firestore,
        'agriculture_consultations',
        id,
        c.toWriteMap(),
        label: c.question,
      );

  Future<void> delete(String id) =>
      OwnerContentService.remove(_firestore, 'agriculture_consultations', id);

  /// الاستشارات المعتمدة — الأحدث أولاً.
  Stream<List<AgricultureConsultation>> watchApproved() {
    return _col
        .snapshots()
        .map((s) => _newestFirst<AgricultureConsultation>(
            s.docs
                .map((d) => AgricultureConsultation.fromJson(d.data(), d.id))
                .where((c) => c.isApproved)
                .toList(),
            (c) => c.createdAt))
        .asBroadcastStream();
  }

  Stream<List<AgricultureConsultation>> watchMine(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => _newestFirst<AgricultureConsultation>(
            s.docs
                .map((d) => AgricultureConsultation.fromJson(d.data(), d.id))
                .toList(),
            (c) => c.createdAt))
        .asBroadcastStream();
  }

  /// كل الاستشارات (المعتمدة والواردة) لأدمن الزراعة والإدارة.
  Stream<List<AgricultureConsultation>> watchAll() {
    return _col
        .snapshots()
        .map((s) => _newestFirst<AgricultureConsultation>(
            s.docs
                .map((d) => AgricultureConsultation.fromJson(d.data(), d.id))
                .toList(),
            (c) => c.createdAt))
        .asBroadcastStream();
  }

  /// الرد على الاستشارة الزراعية وحفظه مع اعتمادها من قبل أدمن الزراعة أو الإدارة.
  Future<void> submitAnswer(
    String id,
    String answer, {
    bool approve = true,
    String? answeredByName,
  }) async {
    final trimmed = answer.trim();
    await _col.doc(id).update({
      'answer': trimmed,
      'isApproved': approve,
      if (answeredByName != null && answeredByName.isNotEmpty)
        'answeredByName': answeredByName,
      'answeredAt': FieldValue.serverTimestamp(),
    });
    try {
      final snap = await _col.doc(id).get();
      final data = snap.data();
      final targetUid = data?['userId'] as String?;
      final question = data?['question'] as String? ?? '';
      if (targetUid != null && targetUid.isNotEmpty) {
        unawaited(NotificationInboxService.instance.push(
          userId: targetUid,
          title: '🌱 تم الرد على استشارتك الزراعية',
          body: trimmed.isNotEmpty
              ? 'ورد رد المستشار الزراعي على استشارتك: «$question»'
              : 'تمت مراجعة استشارتك الزراعية',
          route: '/services/agricultural-advisor',
          kind: 'info',
        ));
      }
    } catch (_) {
      // إرسال الإشعار لا يعطل الرد إن فشل
    }
  }

  /// متابعة الردود التعقيبية للاستشارة بالترتيب الزمني.
  Stream<List<ConsultationReply>> watchReplies(String consultationId) {
    return _col
        .doc(consultationId)
        .collection('replies')
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => ConsultationReply.fromJson(d.data(), d.id, consultationId))
          .toList();
      list.sort((a, b) {
        final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
      return list;
    }).asBroadcastStream();
  }

  /// إضافة رد تعقيبي على الاستشارة (سواء من السائل أو المستشار).
  Future<String> addReply(String consultationId, ConsultationReply reply) async {
    final ref = await _col
        .doc(consultationId)
        .collection('replies')
        .add(reply.toJson());

    // إرسال إشعار للطرف الآخر
    try {
      final snap = await _col.doc(consultationId).get();
      final data = snap.data();
      final ownerUid = data?['userId'] as String? ?? '';
      final question = data?['question'] as String? ?? '';

      if (reply.isAdvisor) {
        // المستشار رد -> نرسل إشعاراً لصاحب الاستشارة
        if (ownerUid.isNotEmpty && ownerUid != reply.authorId) {
          unawaited(NotificationInboxService.instance.push(
            userId: ownerUid,
            title: '🌱 تعقيب جديد من المستشار الزراعي',
            body: 'أضاف المستشار الزراعي رداً جديداً على استشارتك: «$question»',
            route: '/services/agricultural-advisor',
            kind: 'info',
          ));
        }
      } else {
        // المستخدم رد -> نرسل إشعاراً للإدارة وأدمن الزراعة
        unawaited(RemotePushService.notifyAdmins('agriculture_consultations'));
      }
    } catch (_) {}

    return ref.id;
  }

  /// حذف رد تعقيبي
  Future<void> deleteReply(String consultationId, String replyId) =>
      _col.doc(consultationId).collection('replies').doc(replyId).delete();

  static List<T> _newestFirst<T>(
    List<T> items,
    DateTime? Function(T) dateOf,
  ) {
    final list = List<T>.from(items);
    list.sort((a, b) {
      final da = dateOf(a);
      final db = dateOf(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }
}

