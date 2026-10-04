import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/arabic_sort_key.dart';
import '../models/data_models.dart';
import 'cache_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'owner_content_service.dart';
import 'remote_push_service.dart';

class PhoneDirectoryService {
  final FirebaseFirestore _firestore;
  PhoneDirectoryService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// الترتيب الأبجدي العربي مصدره هذه الطبقة وحدها: كل قراءة للدليل ترجع
  /// مرتّبة بالاسم (ثم بالرقم عند التساوي)، بلا `orderBy` على الخادم ولا فهرس
  /// مركّب — فالخادم يُرجع مستنديين لا ترتيب لهما وقد لا يملك الاسم أصلًا.
  static List<PhoneDirectoryEntry> _byArabicName(List<PhoneDirectoryEntry> e) {
    final sorted = <PhoneDirectoryEntry>[...e];
    sorted.sort((a, b) {
      final byName = arabicSortKey(a.name).compareTo(arabicSortKey(b.name));
      if (byName != 0) return byName;
      return arabicSortKey(a.phone).compareTo(arabicSortKey(b.phone));
    });
    return sorted;
  }

  Future<List<PhoneDirectoryEntry>> getApprovedEntriesList({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getPhoneDirectory();
      if (cached != null) {
        return _byArabicName(
            cached.map((json) => PhoneDirectoryEntry.fromJson(json, 'cache')).toList());
      }
    }
    final snapshot = await _firestore.collection('phone_directory').where('isApproved', isEqualTo: true).get();
    final entries = snapshot.docs.map((doc) => PhoneDirectoryEntry.fromJson(doc.data(), doc.id)).toList();
    await CacheService.savePhoneDirectory(entries.map((e) => e.toJson()).toList());
    return _byArabicName(entries);
  }

  Future<List<PhoneDirectoryEntry>> getEntriesList() async {
    final snapshot = await _firestore.collection('phone_directory').get();
    return _byArabicName(snapshot.docs
        .map((doc) => PhoneDirectoryEntry.fromJson(doc.data(), doc.id))
        .toList());
  }

  /// المعتمدة للجميع + إدخالات المستخدم نفسه المعلقة (يراها بوسم «قيد المراجعة»).
  Future<List<PhoneDirectoryEntry>> getVisibleEntriesList(String? userId) async {
    final all = await getEntriesList();
    await CacheService.savePhoneDirectory(
        all.where((e) => e.isApproved).map((e) => e.toJson()).toList());
    return all
        .where((e) => e.isApproved || (userId != null && e.submittedBy == userId))
        .toList();
  }
  
  Stream<List<PhoneDirectoryEntry>> getApprovedEntriesStream() {
    return _firestore
        .collection('phone_directory')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PhoneDirectoryEntry.fromJson(doc.data(), doc.id)).toList());
  }
  
  Stream<List<PhoneDirectoryEntry>> getAllEntriesStream() {
    return _firestore.collection('phone_directory').snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => PhoneDirectoryEntry.fromJson(doc.data(), doc.id)).toList());
  }
  
  Future<void> addPhoneDirectoryEntry(PhoneDirectoryEntry entry) async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    await _firestore.collection('phone_directory').add(entry.toJson());
    await CacheService.invalidatePhoneDirectory();
    unawaited(RemotePushService.notifyAdmins('phone_directory'));
    await NotificationService.showLocalNotification(
      title: '📞 دليل هاتف جديد',
      body: 'تم إرسال "${entry.name}" للمراجعة',
      payload: '/phone-directory',
    );
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '📞 تم إرسال طلبك',
        body: 'تم إرسال "${entry.name}" للمراجعة وسيظهر بعد موافقة الإدارة',
        route: '/phone-directory',
        kind: 'info',
      ));
    }
  }

  /// تعديل مقدّم البيان لبيانه في أي وقت — يعود إلى المراجعة، ولا يلمس
  /// `submittedBy` (تجرّده طبقة المالك المشتركة).
  Future<void> updatePhoneDirectoryEntry(PhoneDirectoryEntry entry) =>
      OwnerContentService.edit(
        _firestore,
        'phone_directory',
        entry.id,
        entry.toJson(),
        label: entry.name,
      );

  /// حذف فوري لمقدّم البيان.
  Future<void> deletePhoneDirectoryEntry(String entryId) =>
      OwnerContentService.remove(_firestore, 'phone_directory', entryId);
}
