import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// تنظيف اليتيم بعد حذف عنصر: Firestore لا يحذف cascading، فتنظّف هذه
/// الخدمة المجموعات الفرعية والمرتبطة بالعنصر المحذوف.
/// best-effort دائماً: أي فشل (شبكة/صلاحيات) لا يطيح الحذف الرئيسي.
/// الطلبات (orders) وسجل النشاط والإشعارات تُعمَّد بقاؤها لسجل تاريخي.
class ContentCleanupService {
  ContentCleanupService._();

  static Future<void> cleanupForDeleted(
      FirebaseFirestore fs, String collection, String docId) async {
    switch (collection) {
      case 'market_products':
        await _deleteAll(
            fs, fs.collection('market_products').doc(docId).collection('likes'),
            '$collection/likes');
        await _deleteAll(
            fs,
            fs
                .collection('market_products')
                .doc(docId)
                .collection('comments'),
            '$collection/comments');
        await _deleteAll(
            fs,
            fs.collection('product_reviews').where('productId', isEqualTo: docId),
            'product_reviews');
        await _deleteAll(
            fs,
            fs.collection('stock_alerts').where('productId', isEqualTo: docId),
            'stock_alerts');
        break;
      case 'news':
        await _deleteAll(
            fs, fs.collection('news').doc(docId).collection('comments'),
            '$collection/comments');
        break;
      case 'forum_posts':
        await _deleteAll(
            fs,
            fs.collection('forum_posts').doc(docId).collection('comments'),
            '$collection/comments');
        break;
      case 'service_providers':
        await _deleteAll(
            fs,
            fs
                .collection('service_providers')
                .doc(docId)
                .collection('comments'),
            '$collection/comments');
        break;
      case 'obituaries':
        await _deleteAll(
            fs,
            fs.collection('condolences').where('obituaryId', isEqualTo: docId),
            'condolences');
        break;
      case 'occasions':
        await _deleteAll(
            fs,
            fs
                .collection('occasion_attendees')
                .where('occasionId', isEqualTo: docId),
            'occasion_attendees');
        break;
    }
  }

  static Future<void> _deleteAll(
      FirebaseFirestore fs, Query query, String label) async {
    try {
      final snap = await query.get();
      final docs = snap.docs;
      // حذف دفعي (batch) بدل حذف فردي — كتابة واحدة لكل 400 مستند.
      for (var i = 0; i < docs.length; i += 400) {
        final batch = fs.batch();
        for (final d in docs.skip(i).take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('content cleanup ($label) failed: $e');
    }
  }
}
