import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'cache_service.dart';
import 'image_upload_service.dart';

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
      case 'shops':
        // منتجات المحل وثائق مستقلة في market_products تحمل shopId؛ حذف المحل
        // يمسحها هي الأخرى وصورها مع أيتامها بالكامل، ويلغي كاش المنتجات والمحلات.
        await _deleteShopProducts(fs, docId);
        break;
    }
  }

  static Future<void> _deleteShopProducts(
      FirebaseFirestore fs, String shopId) async {
    String? ownerUid;
    try {
      final shopDoc = await fs.collection('shops').doc(shopId).get();
      if (shopDoc.exists) {
        ownerUid = shopDoc.data()?['ownerUid'] as String?;
      }
    } catch (_) {}

    final docMap = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    try {
      final snap = await fs
          .collection('market_products')
          .where('shopId', isEqualTo: shopId)
          .get();
      for (final doc in snap.docs) {
        docMap[doc.id] = doc;
      }
    } catch (e) {
      debugPrint('shop products lookup ($shopId) failed: $e');
    }

    if (ownerUid != null && ownerUid.isNotEmpty) {
      try {
        final snapOwner = await fs
            .collection('market_products')
            .where('sellerId', isEqualTo: ownerUid)
            .get();
        for (final doc in snapOwner.docs) {
          final data = doc.data();
          final linkedShop = data['shopId'] as String?;
          if (linkedShop == shopId || linkedShop == null || linkedShop.isEmpty) {
            docMap[doc.id] = doc;
          }
        }
      } catch (_) {}
    }

    final docs = docMap.values.toList();
    final uploader = ImageUploadService();

    for (final d in docs) {
      await cleanupForDeleted(fs, 'market_products', d.id);
      try {
        final data = d.data();
        if (data != null) {
          final urls = <String>[
            ...((data['imageUrls'] as List?)?.whereType<String>() ??
                const <String>[]),
            if ((data['imageUrl'] ?? '') is String &&
                (data['imageUrl'] as String).isNotEmpty)
              data['imageUrl'] as String,
          ];
          for (final url in urls.toSet()) {
            try {
              await uploader.deleteImage(url);
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    for (var i = 0; i < docs.length; i += 400) {
      final chunk = docs.skip(i).take(400).toList();
      final batch = fs.batch();
      for (final d in chunk) {
        batch.delete(d.reference);
      }
      try {
        await batch.commit();
      } catch (e) {
        debugPrint('shop products batch delete ($shopId) fallback: $e');
        for (final d in chunk) {
          try {
            await d.reference.delete();
          } catch (_) {}
        }
      }
    }

    try {
      await CacheService.invalidateProducts();
      await CacheService.invalidate('market_products');
      await CacheService.invalidateShops();
      await CacheService.invalidate('shops');
    } catch (_) {}
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
