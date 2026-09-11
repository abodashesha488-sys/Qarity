import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> isAdminUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (e) {
      debugPrint('isAdminUser error: $e');
      return false;
    }
  }

  /// هل هذا المستخدم «مدير المركز الطبي» أو مدير عام؟
  /// مدير المركز الطبي مسؤول عن محتوى المركز الخيري ومراجعة المدخلات الطبية.
  Future<bool> isMedicalAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final role = doc.data()?['role'] as String?;
      return role == 'medical_admin' || role == 'admin';
    } catch (e) {
      debugPrint('isMedicalAdmin error: $e');
      return false;
    }
  }

  Stream<int> getPendingNewsCount() => _pendingCount('news');
  Stream<int> getPendingProductsCount() => _pendingCount('market_products');
  Stream<int> getPendingObituariesCount() => _pendingCount('obituaries');
  Stream<int> getPendingOccasionsCount() => _pendingCount('occasions');
  Stream<int> getPendingForumPostsCount() => _pendingCount('forum_posts');
  Stream<int> getPendingPhoneDirectoryCount() => _pendingCount('phone_directory');

  Future<int> getPendingCountFuture(String collection) async {
    final comp = _pendingCount(collection);
    return comp.first;
  }

  Stream<int> _pendingCount(String collection) {
    return _firestore
        .collection(collection)
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<List<Map<String, dynamic>>> getPendingNewsStream() => _pendingStream('news');
  Stream<List<Map<String, dynamic>>> getApprovedNewsStream() => _approvedStream('news');
  Stream<List<Map<String, dynamic>>> getAllNewsStream() => _allStream('news');
  Stream<List<Map<String, dynamic>>> getPendingProductsStream() => _pendingStream('market_products');
  Stream<List<Map<String, dynamic>>> getApprovedProductsStream() => _approvedStream('market_products');
  Stream<List<Map<String, dynamic>>> getAllProductsStream() => _allStream('market_products');
  Stream<List<Map<String, dynamic>>> getPendingObituariesStream() => _pendingStream('obituaries');
  Stream<List<Map<String, dynamic>>> getPendingOccasionsStream() => _pendingStream('occasions');
  Stream<List<Map<String, dynamic>>> getPendingForumPostsStream() => _pendingStream('forum_posts');

  Future<void> approveNews(String docId) => approveItem('news', docId);
  Future<void> rejectNews(String docId) => rejectItem('news', docId);
  Future<void> deleteNews(String docId) => deleteItem('news', docId);

  Future<void> approveProduct(String docId) => approveItem('market_products', docId);
  Future<void> rejectProduct(String docId) => rejectItem('market_products', docId);
  Future<void> deleteProduct(String docId) => deleteItem('market_products', docId);

  Future<void> approveObituary(String docId) => approveItem('obituaries', docId);
  Future<void> rejectObituary(String docId) => rejectItem('obituaries', docId);
  Future<void> deleteObituary(String docId) => deleteItem('obituaries', docId);

  Future<void> approveOccasion(String docId) => approveItem('occasions', docId);
  Future<void> rejectOccasion(String docId) => rejectItem('occasions', docId);
  Future<void> deleteOccasion(String docId) => deleteItem('occasions', docId);

  Future<void> approveForumPost(String docId) => approveItem('forum_posts', docId);
  Future<void> rejectForumPost(String docId) => rejectItem('forum_posts', docId);
  Future<void> deleteForumPost(String docId) => deleteItem('forum_posts', docId);

  Stream<List<Map<String, dynamic>>> getActivityLogStream({int limit = 100}) {
    return _firestore
        .collection('activity_log')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<Map<String, int>> getStatistics() async {
    final counts = <String, int>{};
    final collections = [
      'users',
      'news',
      'market_products',
      'obituaries',
      'occasions',
      'forum_posts',
      'activity_log',
    ];
    for (final collection in collections) {
      try {
        final snapshot = await _firestore.collection(collection).count().get();
        counts[collection] = snapshot.count ?? 0;
      } catch (e) {
        counts[collection] = 0;
      }
    }
    return counts;
  }

  Future<int> getActiveUsersCount() async {
    try {
      final snapshot = await _firestore.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('market_products')
          .where('isApproved', isEqualTo: true)
          .get();
      final docs = snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      docs.sort((a, b) => _toMillis(b['createdAt']).compareTo(_toMillis(a['createdAt'])));
      return docs.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getServiceRequestsStats() async {
    try {
      final snapshot = await _firestore
          .collection('service_requests')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getOccasionsStats() async {
    try {
      final snapshot = await _firestore
          .collection('occasions')
          .where('isApproved', isEqualTo: true)
          .get();
      final docs = snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      docs.sort((a, b) => _toMillis(b['createdAt']).compareTo(_toMillis(a['createdAt'])));
      return docs.take(10).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAdmins() async {
    final snapshot = await _firestore.collection('users').where('role', isEqualTo: 'admin').get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  /// قائمة كل المستخدمين لإدارتهم من لوحة التحكم (تغيير الأدوار / الحذف).
  /// بدون orderBy في Firestore لتجنّب إخفاء من لا يملك createdAt.
  Stream<List<Map<String, dynamic>>> getAllUsersStream() {
    return _firestore.collection('users').snapshots().map((s) {
      final list =
          s.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      list.sort((a, b) => _toMillis(b['createdAt'])
          .compareTo(_toMillis(a['createdAt'])));
      return list;
    });
  }

  /// نشر عنصر مباشرة من الأدمن (متجاوزاً المراجعة) عبر إضافة مع isApproved=true.
  Future<String> publishContent(String collection, Map<String, dynamic> data) async {
    final ref = await _firestore.collection(collection).add({
      ...data,
      'isApproved': true,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': _auth.currentUser?.uid,
    });
    _invalidateContentCache(collection);
    final title = (data['title'] ?? data['name'] ?? ref.id).toString();
    await _logActivity(
      action: 'publish',
      targetCollection: collection,
      targetDocId: ref.id,
      targetTitle: title,
    );
    _announceApproval(collection, title);
    return ref.id;
  }

  Future<void> setUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).set({'role': role}, SetOptions(merge: true));
    await CacheService.invalidateUser(uid);
    await _logActivity(action: 'set_role', targetCollection: 'users', targetDocId: uid, targetTitle: role);
    if (role == 'seller') {
      final udoc = await _firestore.collection('users').doc(uid).get();
      final st = udoc.data()?['sellerType'] as String?;
      if (st != null) await _syncSellerTypeToContent(uid, st);
    }
  }

  /// تعيين الدور + نوع البائع معاً من لوحة التحكم.
  Future<void> updateUserAccess(String uid, {String? role, String? sellerType}) async {
    final updates = <String, dynamic>{};
    if (role != null) updates['role'] = role;
    if (sellerType != null) updates['sellerType'] = sellerType;
    if (updates.isEmpty) return;
    await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    await CacheService.invalidateUser(uid);
    await _logActivity(
      action: 'set_role',
      targetCollection: 'users',
      targetDocId: uid,
      targetTitle: [role, sellerType].where((e) => e != null).join(' / '),
    );
    if (sellerType != null) {
      await _syncSellerTypeToContent(uid, sellerType);
    }
  }

  /// يفعّل لون البائع الجديد فوراً على كل منتجاته ومحلاته (بدون انتظار إعادة نشر).
  Future<void> _syncSellerTypeToContent(String uid, String sellerType) async {
    try {
      final products = await _firestore
          .collection('market_products')
          .where('sellerId', isEqualTo: uid)
          .get();
      final shops = await _firestore
          .collection('shops')
          .where('ownerUid', isEqualTo: uid)
          .get();
      final ops = products.docs.length + shops.docs.length;
      final batch = _firestore.batch();
      for (final d in products.docs) {
        batch.update(d.reference, {'sellerType': sellerType});
      }
      for (final d in shops.docs) {
        batch.update(d.reference, {'ownerSellerType': sellerType});
      }
      // ملف البائع نفسه (يظهر في قائمة البائعين)
      final profile =
          await _firestore.collection('seller_profiles').doc(uid).get();
      if (profile.exists) {
        batch.update(profile.reference, {'sellerType': sellerType});
      }
      if (ops == 0 && !profile.exists) return;
      await batch.commit();
    } catch (e) {
      debugPrint('syncSellerTypeToContent failed: $e');
    }
  }

  /// إصلاح تأسيسي: المنتجات القديمة أُنشئت قبل وجود sellerType.
  /// تستدعيها لوحة الأدمن مرة واحدة عند الفتح (best-effort، للمدير فقط عملياً).
  Future<void> backfillSellerTypes() async {
    try {
      final sellerTypeCache = <String, String?>{};
      Future<String?> typeFor(String uid) async {
        if (sellerTypeCache.containsKey(uid)) return sellerTypeCache[uid];
        final udoc = await _firestore.collection('users').doc(uid).get();
        final t = udoc.data()?['sellerType'] as String?;
        sellerTypeCache[uid] = t;
        return t;
      }

      Future<void> backfillCol(
          String collection, String ownerField, String targetField) async {
        final snap = await _firestore.collection(collection).get();
        final missing = snap.docs
            .where((d) =>
                (d.data()[targetField] as String?) == null &&
                (d.data()[ownerField] ?? '').toString().isNotEmpty)
            .toList();
        if (missing.isEmpty) return;
        final batch = _firestore.batch();
        for (final d in missing) {
          final t = await typeFor((d.data()[ownerField] ?? '').toString());
          if (t != null) batch.update(d.reference, {targetField: t});
        }
        await batch.commit();
      }

      await backfillCol('market_products', 'sellerId', 'sellerType');
      await backfillCol('shops', 'ownerUid', 'ownerSellerType');
      await backfillCol('seller_profiles', 'userId', 'sellerType');
    } catch (e) {
      debugPrint('backfillSellerTypes failed: $e');
    }
  }

  Future<void> removeAdmin(String uid) async {
    await _firestore.collection('users').doc(uid).set({'role': 'user'}, SetOptions(merge: true));
    await _logActivity(action: 'remove_admin', targetCollection: 'users', targetDocId: uid);
  }

  /// تعطيل/تفعيل حساب مستخدم من لوحة التحكم (المعطّل يفقد واجهة الأدمن).
  Future<void> setUserActive(String uid, bool active) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set({'isActive': active}, SetOptions(merge: true));
    await CacheService.invalidateUser(uid);
    await _logActivity(
      action: active ? 'enable_user' : 'disable_user',
      targetCollection: 'users',
      targetDocId: uid,
    );
  }

  Future<void> updateItem(String collection, String docId, Map<String, dynamic> data) => _update(collection, docId, data);
  Future<void> updateNews(String docId, Map<String, dynamic> data) => _update('news', docId, data);
  Future<void> updateProduct(String docId, Map<String, dynamic> data) => _update('market_products', docId, data);
  Future<void> updateObituary(String docId, Map<String, dynamic> data) => _update('obituaries', docId, data);
  Future<void> updateOccasion(String docId, Map<String, dynamic> data) => _update('occasions', docId, data);
  Future<void> updateForumPost(String docId, Map<String, dynamic> data) => _update('forum_posts', docId, data);

  Future<void> _update(String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Stream<List<Map<String, dynamic>>> _allStream(String collection) {
    return _firestore
        .collection(collection)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  /// تدفقات عامة تُستخدم في لوحة التحكم المعاد تصميمها.
  Stream<List<Map<String, dynamic>>> itemsStream(String collection, {bool pendingOnly = false}) {
    if (!pendingOnly) return _allStream(collection);
    if (collection == 'seller_requests') return getPendingSellerRequestsStream();
    return _pendingStream(collection);
  }

  Stream<List<Map<String, dynamic>>> _pendingStream(String collection) {
    return _firestore
        .collection(collection)
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Stream<List<Map<String, dynamic>>> _approvedStream(String collection) {
    return _firestore
        .collection(collection)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> approveItem(String collection, String docId) async {
    if (collection.isEmpty || docId.isEmpty) {
      throw Exception('بيانات غير صالحة: معرّف العنصر أو المجموعة فارغ');
    }
    final doc = await _firestore.collection(collection).doc(docId).get();
    final title = doc.data()?['title'] as String? ??
        doc.data()?['name'] as String? ??
        doc.data()?['content'] as String? ??
        doc.id;
    await _firestore.collection(collection).doc(docId).update({
      'isApproved': true,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': _auth.currentUser?.uid,
    });
    _invalidateContentCache(collection);
    try {
      await _logActivity(
        action: 'approve',
        targetCollection: collection,
        targetDocId: docId,
        targetTitle: title,
      );
    } catch (_) {}
    _announceApproval(collection, title.toString());
    // إشعار شخصي لمقدم المحتوى: تمت الموافقة على منشورك.
    _notifySubmitter(collection, doc.data(), approved: true);
  }

  /// حقل المالك/المقدم لكل مجموعة (لإشعاره شخصياً ولcascade الاسم).
  static const Map<String, String> _submitterFieldByCollection = {
    'news': 'authorId',
    'market_products': 'sellerId',
    'obituaries': 'submittedBy',
    'occasions': 'submittedBy',
    'forum_posts': 'userId',
    'shops': 'ownerUid',
    'buy_requests': 'userId',
    'donations': 'userId',
    'village_clinics': 'submittedBy',
    'pharmacies': 'submittedBy',
    'service_providers': 'submittedBy',
    'blood_requests': 'userId',
    'blood_donors': 'userId',
    'service_requests': 'userId',
  };

  Future<void> _notifySubmitter(
      String collection, Map<String, dynamic>? data,
      {required bool approved}) async {
    try {
      final field = _submitterFieldByCollection[collection];
      if (field == null || data == null) return;
      final uid = (data[field] ?? '').toString();
      if (uid.isEmpty) return;
      final label = _labelForCollection(collection);
      final title = approved ? '✅ تمت الموافقة' : '⚠️ ملاحظة من الإدارة';
      final body = approved
          ? 'تمت الموافقة على $label الخاص بك وهو منشور الآن'
          : 'لم يُقبل $label الخاص بك بعد المراجعة — يمكنك التعديل وإعادة الإرسال';
      final route = _routeForCollection(collection);
      // 1) صندوق الإشعارات داخل التطبيق (يعمل على كل المنصات)
      await NotificationInboxService.instance.push(
        userId: uid,
        title: title,
        body: body,
        route: route,
        kind: approved ? 'approve' : 'reject',
      );
      // 2) FCM مباشر لجهاز المستخدم إن وُجد توكن (أندرويد غالباً)
      final udoc = await _firestore.collection('users').doc(uid).get();
      final token = udoc.data()?['fcmToken'] as String?;
      if (token != null && token.isNotEmpty) {
        RemotePushService.sendToDevice(
          fcmToken: token,
          title: title,
          body: body,
          route: route,
        );
      }
    } catch (e) {
      debugPrint('notifySubmitter failed: $e');
    }
  }

  static String _routeForCollection(String c) {
    switch (c) {
      case 'news':
        return '/news';
      case 'market_products':
      case 'shops':
      case 'buy_requests':
      case 'donations':
        return '/market';
      case 'obituaries':
        return '/obituaries';
      case 'occasions':
        return '/occasions';
      case 'forum_posts':
        return '/forum';
      case 'service_providers':
        return '/services';
      case 'village_clinics':
      case 'pharmacies':
      case 'medical_center_clinics':
      case 'blood_requests':
      case 'blood_donors':
        return '/medical';
      default:
        return '/';
    }
  }

  static String _labelForCollection(String c) {
    switch (c) {
      case 'news':
        return 'الخبر';
      case 'market_products':
        return 'المنتج';
      case 'obituaries':
        return 'النعي';
      case 'occasions':
        return 'المناسبة';
      case 'forum_posts':
        return 'المنشور';
      case 'shops':
        return 'المحل';
      case 'village_clinics':
        return 'العيادة';
      case 'medical_center_clinics':
        return 'عيادة المركز الخيري';
      case 'service_providers':
        return 'الإضافة في دليل الخدمات';
      case 'pharmacies':
        return 'الصيدلية';
      case 'blood_requests':
        return 'طلب التبرع';
      case 'blood_donors':
        return 'تسجيل المتبرع';
      case 'donations':
        return 'التبرع';
      case 'buy_requests':
        return 'الطلب';
      default:
        return 'المحتوى';
    }
  }

  /// إشعار عام بعد الموافقة/النشر — Push للمواضيع + محلي على جهاز الأدمن.
  void _announceApproval(String collection, String itemTitle) {
    final topic = kPushTopicForCollection[collection];
    final (title, body, route) = _pushMessageFor(collection, itemTitle);
    if (topic != null) {
      RemotePushService.send(topic: topic, title: title, body: body, route: route);
    }
    NotificationService.showLocalNotification(
      title: title,
      body: body,
      payload: route,
    );
  }

  static (String title, String body, String route) _pushMessageFor(
      String collection, String item) {
    final preview = item.length > 60 ? '${item.substring(0, 60)}…' : item;
    return switch (collection) {
      'news' => ('📰 خبر جديد', preview, '/news'),
      'obituaries' => ('⚰️ تعزية', preview, '/obituaries'),
      'occasions' => ('🎉 مناسبة جديدة', preview, '/occasions'),
      'market_products' => ('🛒 منتج جديد', preview, '/market'),
      'forum_posts' => ('💬 منشور جديد', preview, '/forum'),
      'service_requests' => ('🔔 طلب خدمة', preview, '/services'),
      'service_providers' => ('🧰 خدمة جديدة في الدليل', preview, '/services'),
      'shops' => ('🏬 محل جديد في السوق', preview, '/market'),
      'medical_center_clinics' => (
            '🏥 عيادة جديدة بالمركز الطبي الخيري',
            preview,
            '/medical'
          ),
      'village_clinics' || 'pharmacies' || 'blood_requests' || 'blood_donors' =>
        ('🩺 خدمات طبية', preview, '/medical'),
      _ => ('محتوى جديد', preview, '/'),
    };
  }

  Future<void> rejectItem(String collection, String docId) async {
    if (collection.isEmpty || docId.isEmpty) {
      throw Exception('بيانات غير صالحة: معرّف العنصر أو المجموعة فارغ');
    }
    final snapshot =
        await _firestore.collection(collection).doc(docId).get();
    await _firestore.collection(collection).doc(docId).update({
      'isApproved': false,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': _auth.currentUser?.uid,
    });
    _invalidateContentCache(collection);
    try {
      await _logActivity(
        action: 'reject',
        targetCollection: collection,
        targetDocId: docId,
      );
    } catch (_) {}
    _notifySubmitter(collection, snapshot.data(), approved: false);
  }

  Future<void> deleteItem(String collection, String docId) async {
    if (collection.isEmpty || docId.isEmpty) {
      throw Exception('بيانات غير صالحة: معرّف العنصر أو المجموعة فارغ');
    }
    final doc = await _firestore.collection(collection).doc(docId).get();
    final title = doc.data()?['title'] as String? ??
        doc.data()?['name'] as String? ??
        doc.data()?['content'] as String? ??
        doc.id;
    await _firestore.collection(collection).doc(docId).delete();
    _invalidateContentCache(collection);
    try {
      await _logActivity(
        action: 'delete',
        targetCollection: collection,
        targetDocId: docId,
        targetTitle: title,
      );
    } catch (_) {}
  }

  void _invalidateContentCache(String collection) {
    if (collection == 'market_products') {
      CacheService.invalidateProducts();
    } else if (collection == 'news') {
      CacheService.invalidateNews();
    } else if (collection == 'forum_posts') {
      CacheService.invalidateForumPosts();
    }
  }

  Future<void> _logActivity({
    required String action,
    required String targetCollection,
    required String targetDocId,
    String? targetTitle,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'unknown';
    await _firestore.collection('activity_log').add({
      'adminId': uid,
      'action': action,
      'targetCollection': targetCollection,
      'targetDocId': targetDocId,
      if (targetTitle != null) 'targetTitle': targetTitle,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  int _toMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return 0;
  }

  // Seller Requests — حالة الطلب تُحدَّد بالـ status ('pending' / 'approved' / 'rejected')
  // وليس بحقل isApproved، لذا نستخدم عدّاداً مخصصاً هنا.
  Stream<int> getPendingSellerRequestsCount() =>
      _firestore
          .collection('seller_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((s) => s.docs.length);

  Future<Map<String, int>> fetchPendingCounts() async {
    final results = await Future.wait([
      _pendingCount('news').first,
      _pendingCount('market_products').first,
      _pendingCount('obituaries').first,
      _pendingCount('occasions').first,
      _pendingCount('forum_posts').first,
      _statusPendingCount('seller_requests'),
      _pendingCount('phone_directory').first,
      _pendingCount('village_clinics').first,
      _pendingCount('pharmacies').first,
      _pendingCount('blood_requests').first,
      _pendingCount('blood_donors').first,
      _pendingCount('shops').first,
      _pendingCount('service_providers').first,
      _pendingCount('medical_center_clinics').first,
    ]);
    return {
      'news': results[0],
      'market_products': results[1],
      'obituaries': results[2],
      'occasions': results[3],
      'forum_posts': results[4],
      'seller_requests': results[5],
      'phone_directory': results[6],
      'village_clinics': results[7],
      'pharmacies': results[8],
      'blood_requests': results[9],
      'blood_donors': results[10],
      'shops': results[11],
      'service_providers': results[12],
      'medical_center_clinics': results[13],
    };
  }

  Future<int> _statusPendingCount(String collection) async {
    try {
      final snap = await _firestore
          .collection(collection)
          .where('status', isEqualTo: 'pending')
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Stream<List<Map<String, dynamic>>> getPendingSellerRequestsStream() {
    return _firestore
        .collection('seller_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getAllSellerRequestsStream() {
    return _firestore
        .collection('seller_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> approveSellerRequest(String docId, {String? notes}) async {
    final adminId = _auth.currentUser?.uid ?? 'unknown';
    await _firestore.collection('seller_requests').doc(docId).update({
      'status': 'approved',
      'adminNotes': notes,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminId,
    });

    // Create seller profile
    final requestDoc = await _firestore.collection('seller_requests').doc(docId).get();
    if (requestDoc.exists) {
      final data = requestDoc.data()!;
      final reqType = (data['requestedSellerType'] as String?) ?? 'regular';
      final profile = {
        'userId': data['userId'],
        'name': data['shopName'],
        'bio': data['shopDescription'],
        'phone': data['userPhone'],
        'address': data['shopAddress'],
        'categories': data['categories'] ?? [],
        'sellerType': reqType,
        'rating': 0.0,
        'reviewCount': 0,
        'totalProducts': 0,
        'totalSales': 0,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('seller_profiles').doc(data['userId']).set(profile);

      // Apply the requested seller type + promote user to seller
      await _firestore
          .collection('users')
          .doc(data['userId'])
          .set({'role': 'seller', 'sellerType': reqType}, SetOptions(merge: true));
      await CacheService.invalidateUser(data['userId'] as String);
      _notifySellerRequest(data['userId'] as String?, approved: true);
    }

    await _logActivity(
      action: 'approve',
      targetCollection: 'seller_requests',
      targetDocId: docId,
      targetTitle: 'طلب متجر',
    );
  }

  Future<void> rejectSellerRequest(String docId, {String? notes}) async {
    final adminId = _auth.currentUser?.uid ?? 'unknown';
    final reqSnap =
        await _firestore.collection('seller_requests').doc(docId).get();
    await _firestore.collection('seller_requests').doc(docId).update({
      'status': 'rejected',
      'adminNotes': notes,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminId,
    });

    await _logActivity(
      action: 'reject',
      targetCollection: 'seller_requests',
      targetDocId: docId,
      targetTitle: 'طلب متجر',
    );
    _notifySellerRequest(
        reqSnap.data()?['userId'] as String?, approved: false);
  }

  /// إشعار شخصي لصاحب طلب البائعية عند القبول/الرفض.
  Future<void> _notifySellerRequest(String? uid,
      {required bool approved}) async {
    if (uid == null || uid.isEmpty) return;
    try {
      final title = approved ? '🎉 مبروك، أصبحت بائعاً' : '⚠️ بخصوص طلب البائعية';
      final body = approved
          ? 'تمت الموافقة على طلبك لفتح متجر — أصبحت الآن قادراً على إضافة منتجاتك ومحلك'
          : 'لم يُقبل طلب فتح المتجر — راجع السبب في ملفك الشخصي وأعد المحاولة';
      await NotificationInboxService.instance.push(
        userId: uid,
        title: title,
        body: body,
        route: '/profile',
        kind: approved ? 'approve' : 'reject',
      );
      final udoc = await _firestore.collection('users').doc(uid).get();
      final token = udoc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) return;
      await RemotePushService.sendToDevice(
        fcmToken: token,
        title: title,
        body: body,
        route: '/profile',
      );
    } catch (e) {
      debugPrint('notifySellerRequest failed: $e');
    }
  }

  // Seller Profiles
  Stream<List<Map<String, dynamic>>> getAllSellerProfilesStream() {
    return _firestore
        .collection('seller_profiles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Product Reviews
  Stream<List<Map<String, dynamic>>> getAllReviewsStream() {
    return _firestore
        .collection('product_reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}
