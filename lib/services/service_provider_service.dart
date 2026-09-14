import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_provider_model.dart';
import 'remote_push_service.dart';

/// خدمة دليل الخدمات — فنيون/خدمات زراعية/خدمات تعليمية (مدخلات مستخدمين + موافقة).
class ServiceProviderService {
  final FirebaseFirestore _firestore;
  ServiceProviderService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('service_providers');

  CollectionReference<Map<String, dynamic>> _comments(String providerId) =>
      _col.doc(providerId).collection('comments');

  Future<String> create(ServiceProvider provider) async {
    final ref = await _col.add(provider.toJson());
    unawaited(RemotePushService.notifyAdmins('service_providers'));
    return ref.id;
  }

  /// العناصر المعتمدة لفئة معينة — المميز منها أولاً.
  Stream<List<ServiceProvider>> getApprovedByCategory(String category) {
    return _col
        .where('category', isEqualTo: category)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => ServiceProvider.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) {
        if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  Future<List<ServiceProvider>> getMine(String userId) async {
    final snap = await _col.where('submittedBy', isEqualTo: userId).get();
    return snap.docs
        .map((d) => ServiceProvider.fromJson(d.data(), d.id))
        .toList();
  }

  /// متابعة بيان واحد (لشاشة التفاصيل — يتحدث متوسط التقييم مباشرة).
  Stream<ServiceProvider?> watchProvider(String id) {
    return _col.doc(id).snapshots().map((d) =>
        d.exists ? ServiceProvider.fromJson(d.data()!, d.id) : null);
  }

  // ───────────────── التقييمات والتعليقات ─────────────────
  Stream<List<ServiceProviderComment>> getCommentsStream(String providerId) {
    return _comments(providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ServiceProviderComment.fromJson(d.data(), d.id))
            .toList());
  }

  /// إضافة تعليق + تقييم، وتحديث متوسط تقييم البيان داخل معاملة واحدة.
  /// إذا كان للمستخدم تقييم سابق على نفس البيان يُستبدل.
  Future<void> addComment(ServiceProviderComment comment) async {
    final providerRef = _col.doc(comment.providerId);
    final existing = await _comments(comment.providerId)
        .where('userId', isEqualTo: comment.userId)
        .get();

    await _firestore.runTransaction((tx) async {
      final doc = await providerRef.get();
      final current = doc.exists
          ? ServiceProvider.fromJson(doc.data()!, doc.id)
          : null;
      var sum = (current?.rating ?? 0) * (current?.ratingCount ?? 0);
      var count = current?.ratingCount ?? 0;

      for (final d in existing.docs) {
        tx.delete(d.reference);
      }
      if (existing.docs.isNotEmpty && current != null) {
        final removedTotal =
            existing.docs.fold<int>(0, (s, d) => s + ((d.data()['rating'] as num?)?.toInt() ?? 0));
        sum -= removedTotal;
        count -= existing.docs.length;
      }

      final newRef = _comments(comment.providerId).doc();
      tx.set(newRef, comment.toJson());
      sum += comment.rating;
      count += 1;
      final newRating = count <= 0 ? 0.0 : (sum / count);
      tx.update(providerRef, {
        'rating': newRating,
        'ratingCount': count,
      });
    });
  }

  /// تقييم المستخدم الحالي لهذا البيان (إن وُجد) لملء النجوم مسبقاً.
  Future<ServiceProviderComment?> getUserComment(
      String providerId, String userId) async {
    final snap = await _comments(providerId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ServiceProviderComment.fromJson(snap.docs.first.data(),
        snap.docs.first.id);
  }

  Future<void> deleteComment(
      String providerId, String commentId, int rating) async {
    final providerRef = _col.doc(providerId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(providerRef);
      if (!doc.exists) return;
      final current = ServiceProvider.fromJson(doc.data()!, doc.id);
      var sum = current.rating * current.ratingCount - rating;
      var count = current.ratingCount - 1;
      if (count < 0) {
        count = 0;
        sum = 0;
      }
      tx.delete(_comments(providerId).doc(commentId));
      tx.update(providerRef, {
        'rating': count == 0 ? 0.0 : (sum / count),
        'ratingCount': count,
      });
    });
  }
}
