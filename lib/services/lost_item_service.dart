import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lost_item_model.dart';
import 'remote_push_service.dart';

/// خدمة المفقودات — نشر الأشياء المفقودة/الموجودة في القرية (موافقة مطلوبة).
class LostItemService {
  final FirebaseFirestore _firestore;
  LostItemService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('lost_items');

  Future<String> create(LostItem item) async {
    final ref = await _col.add(item.toJson());
    unawaited(RemotePushService.notifyAdmins('lost_items'));
    return ref.id;
  }

  /// كل الإعلانات المعتمدة — الأحدث أولاً (تصفية النوع محليًا لتجنّب فهرسات مركّبة).
  Stream<List<LostItem>> watchApproved() {
    return _col
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => LostItem.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) {
        final da = a.date ?? a.createdAt;
        final db = b.date ?? b.createdAt;
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });
      return list;
    });
  }

  /// إعلانات المستخدم نفسه (مع غير المعتمدة ليراها فورًا).
  Stream<List<LostItem>> watchMine(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => LostItem.fromJson(d.data(), d.id)).toList());
  }

  Future<void> setResolved(String id, bool value) =>
      _col.doc(id).update({'isResolved': value});
}
