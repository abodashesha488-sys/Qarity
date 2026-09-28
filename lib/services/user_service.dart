import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import '../../models/data_models.dart';
import 'cache_service.dart';

class UserService {
  /// حقن اختياري للنمط المعتمد في المشروع (اختبارات بلا Firebase حقيقي).
  UserService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // كسول عمدًا: بناء الخدمة في اختبار بلا Firebase لا يجب أن يفشل لمجرد
  // أن القرار الحالي لا يحتاج المصادقة.
  firebase_auth.FirebaseAuth get _auth => firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  Stream<firebase_auth.User?> authStateChanges() => _auth.authStateChanges();
  firebase_auth.User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUser(user.uid);
  }

  /// هوية كاتب المحتوى: الاسم من ملف المستخدم (كما عدّله من الإكمال/الملف
  /// الشخصي) أولاً، ثم صورة البروفايل — مع رجوع آمن لقيم Google.
  Future<({String name, String? photo})> resolveAuthor(
      {String fallback = 'مستخدم'}) async {
    final u = _auth.currentUser;
    if (u == null) return (name: fallback, photo: null);
    UserModel? m;
    try {
      m = await getUser(u.uid);
    } catch (_) {}
    final pname = (m?.name ?? '').trim();
    final gname = (u.displayName ?? '').trim();
    final name = pname.isNotEmpty
        ? pname
        : (gname.isNotEmpty
            ? gname
            : (u.email?.split('@').first ?? fallback));
    final mPhoto = (m?.photoUrl ?? '').trim();
    final photo = mPhoto.isNotEmpty ? mPhoto : u.photoURL;
    return (name: name, photo: photo);
  }

  /// هل أكمل المستخدم بياناته الأساسية (اسم + هاتف + النوع)؟
  /// يُستخدم في شاشة الإقلاع وبعد تسجيل الدخول لتوجيه المستخدم لإكمال الملف.
  /// النوع إلزامي: بدونه لا يُسمح بدخول التطبيق.
  static bool isProfileComplete(UserModel? u) =>
      u != null &&
      u.name.trim().isNotEmpty &&
      (u.phone?.trim().isNotEmpty ?? false) &&
      u.gender.trim().isNotEmpty;

  Future<UserModel?> getUser(String uid) async {
    final cached = await CacheService.getUser(uid);
    if (cached != null) {
      return UserModel.fromJson(cached, uid);
    }
    try {
      final doc = await _firestore.collection('users').doc(uid).get().timeout(const Duration(seconds: 10));
      if (doc.exists) {
        final user = UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        await CacheService.saveUser(uid, user.toJson());
        return user;
      }
      return null;
    } catch (e) {
      // لا نُعلّق الواجهة بسبب شبكة/صلاحيات — نرجع null ويتعامل كل شاشة معه.
      debugPrint('getUser($uid) failed: $e');
      return null;
    }
  }

  /// قراءة **لقرار أمني** (تفعيل الحساب/الدور) من الخادم مباشرة، لا من النسخة
  /// المحفوظة محليًا التي بلا مدة انتهاء — وإلا ظلّ جهاز المستخدم المعطَّل
  /// يقرأ نفسه «مفعّلاً» إلى الأبد ولا تصله رسالة التعطيل.
  /// عند تعذّر الشبكة نرجع لنفس getUser (الكاش) حتى لا ينكسر العمل بلا اتصال؛
  /// منع الكتابة الفعلية يظل مفروضًا في قواعد Firestore لا هنا.
  Future<UserModel?> getAuthority(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) {
        // الملف محذوف فعليًا: لا تُعتمد نسخة قديمة من الكاش عليه.
        await CacheService.invalidateUser(uid);
        return null;
      }
      final user =
          UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      await CacheService.saveUser(uid, user.toJson());
      return user;
    } catch (e) {
      debugPrint('getAuthority($uid) fell back to cache: $e');
      return getUser(uid);
    }
  }

  Future<void> saveUserToFirestore(firebase_auth.User user) async {
    final existingUser = await getUser(user.uid);
    if (existingUser != null) {
      // لا نكتب فوق اسم/صورة اختارها المستخدم داخل التطبيق —
      // قيم Google تُستخدم فقط لملء الحقول الفارغة أول مرة.
      final updates = <String, dynamic>{
        'lastLogin': FieldValue.serverTimestamp(),
      };
      var identityChanged = false;
      if ((existingUser.name.trim().isEmpty) &&
          (user.displayName?.trim().isNotEmpty ?? false)) {
        updates['name'] = user.displayName!.trim();
        identityChanged = true;
      }
      if ((existingUser.photoUrl?.trim().isEmpty ?? true) &&
          (user.photoURL?.isNotEmpty ?? false)) {
        updates['photoUrl'] = user.photoURL;
        identityChanged = true;
      }
      if ((existingUser.email.trim().isEmpty) && (user.email?.isNotEmpty ?? false)) {
        updates['email'] = user.email;
        identityChanged = true;
      }
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      if (identityChanged) {
        final merged = existingUser.copyWith(
          name: updates['name'] as String?,
          photoUrl: updates['photoUrl'] as String?,
          email: updates['email'] as String?,
        );
        await CacheService.saveUser(user.uid, merged.toJson());
      }
      return;
    }
    final newUser = UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      joinDate: user.metadata.creationTime ?? DateTime.now(),
    );
    await _firestore.collection('users').doc(user.uid).set(newUser.toJson()).timeout(const Duration(seconds: 10));
  }

  Future<void> signOut() async => await _auth.signOut();
  Future<bool> isAdmin(String uid) async {
    final user = await getUser(uid);
    return user?.isAdmin ?? false;
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.id);
      final data = user.toJson();
      final existingDoc = await docRef.get();
      final existing =
          existingDoc.exists ? (existingDoc.data() ?? <String, dynamic>{}) : null;
      if (existing != null) {
        // Preserve sensitive fields that callers may not supply, so we never
        // accidentally demote an admin or reset account state on a partial update.
        data['role'] = existing['role'] ?? data['role'];
        data['isActive'] = existing['isActive'] ?? data['isActive'];
        data['lastLogin'] = existing['lastLogin'] ?? data['lastLogin'];
      }
      await docRef.set(data, SetOptions(merge: true));
      await CacheService.saveUser(user.id, data);
      // إذا تغيّر الاسم أو الصورة → حدّث كل المحتوى المنسوب للمستخدم.
      if (existing != null) {
        final oldName = (existing['name'] ?? '').toString();
        final oldPhoto = (existing['photoUrl'] ?? '').toString();
        final nameChanged = user.name.trim().isNotEmpty &&
            user.name.trim() != oldName.trim();
        final photoChanged = (user.photoUrl ?? '') != oldPhoto;
        if (nameChanged || photoChanged) {
          unawaited(syncIdentityToContent(
            user.id,
            name: nameChanged ? user.name.trim() : null,
            photoUrl: photoChanged ? user.photoUrl : null,
          ));
        }
      }
    } catch (e) {
      debugPrint('updateUser failed: $e');
      rethrow;
    }
  }

  /// ينشر الاسم/الصورة الجديدين على كل المحتوى المنسوب للمستخدم
  /// (منشورات، تعليقات، مراجعات، منتجات، أخبار، محلات، طلبات دم…).
  /// best-effort: أخطاء أي مجموعة لا توقف الباقي.
  Future<void> syncIdentityToContent(String uid,
      {String? name, String? photoUrl}) async {
    if (name == null && photoUrl == null) return;
    Future<void> fanOut(String collection, String ownerField,
        Map<String, dynamic> values) async {
      try {
        final q = await _firestore
            .collection(collection)
            .where(ownerField, isEqualTo: uid)
            .get();
        if (q.docs.isEmpty) return;
        final batch = _firestore.batch();
        for (final d in q.docs) {
          batch.update(d.reference, values);
        }
        await batch.commit();
      } catch (e) {
        debugPrint('syncIdentityToContent $collection failed: $e');
      }
    }

    final nameFields = <String, (String, String)>{
      'forum_posts': ('userId', 'userName'),
      'news': ('authorId', 'authorName'),
      'market_products': ('sellerId', 'sellerName'),
      'shops': ('ownerUid', 'ownerName'),
      'condolences': ('userId', 'userName'),
      'occasion_attendees': ('userId', 'userName'),
      'product_reviews': ('userId', 'userName'),
      'reviews': ('userId', 'userName'),
      'buy_requests': ('userId', 'userName'),
      'donations': ('userId', 'userName'),
      'blood_requests': ('userId', 'requesterName'),
      'blood_donors': ('userId', 'name'),
      'village_clinics': ('submittedBy', 'submittedByName'),
      'pharmacies': ('submittedBy', 'submittedByName'),
      'medical_labs': ('submittedBy', 'submittedByName'),
      'service_providers': ('submittedBy', 'submittedByName'),
    };
    final jobs = <Future<void>>[];
    if (name != null) {
      nameFields.forEach((col, map) {
        jobs.add(fanOut(col, map.$1, {map.$2: name}));
      });
    }
    if (photoUrl != null) {
      for (final col in ['forum_posts', 'product_reviews', 'condolences', 'reviews']) {
        jobs.add(fanOut(col, 'userId', {'userPhotoUrl': photoUrl}));
      }
    }
    // التعليقات داخل المجموعات الفرعية collectionGroup
    try {
      final q = await _firestore
          .collectionGroup('comments')
          .where('userId', isEqualTo: uid)
          .get();
      if (q.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final d in q.docs) {
          final v = <String, dynamic>{
            if (name != null) 'userName': name,
            if (photoUrl != null) 'userPhotoUrl': photoUrl,
          };
          batch.update(d.reference, v);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('syncIdentityToContent comments failed: $e');
    }
    await Future.wait(jobs);
  }
}
