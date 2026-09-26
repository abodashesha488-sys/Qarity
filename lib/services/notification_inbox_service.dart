import 'package:cloud_firestore/cloud_firestore.dart';

/// إشعارات شخصية داخل التطبيق (تعمل على كل المنصات حتى بدون FCM/web-push).
/// تُكتب عند موافقة/رفض أدمن على محتوى مستخدم، ويقرؤها المستخدم من الجرس.
class UserNotification {
  final String id;
  final String title;
  final String body;
  final String? route;
  final bool read;
  final DateTime createdAt;
  final String? kind; // approve | reject | info

  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    this.route,
    required this.read,
    required this.createdAt,
    this.kind,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json, String id) {
    final ts = json['createdAt'];
    return UserNotification(
      id: id,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      route: json['route'] as String?,
      read: json['read'] == true,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : (ts is String ? DateTime.tryParse(ts) ?? DateTime.now() : DateTime.now()),
      kind: json['kind'] as String?,
    );
  }
}

class NotificationInboxService {
  NotificationInboxService._();
  static final NotificationInboxService instance = NotificationInboxService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('notifications');

  /// إضافة إشعار شخصي لمستخدم (يستدعيها الأدمن عند الموافقة/الرفض، أو النظام).
  Future<void> push({
    required String userId,
    required String title,
    required String body,
    String? route,
    String? kind,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _col.add({
        'userId': userId,
        'title': title,
        'body': body,
        'route': route,
        'kind': kind,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // لا نفشل العملية الرئيسية بسبب الإشعار
      // ignore: avoid_print
      print('notification push failed: $e');
    }
  }

  Stream<List<UserNotification>> streamFor(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    // آخر 50 إشعاراً فقط (orderBy+limit) — المجموعة تنمو بلا حدود وكان
    // المستمع يحمّلها كلها عند كل فتح للجرس/الصندوق.
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) {
        var m = d.data();
        // createdAt قد يكون null فور الكتابة قبل مزامنة الخادم
        m = {...m, 'createdAt': m['createdAt'] ?? Timestamp.now()};
        return UserNotification.fromJson(m, d.id);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<int> unreadCount(String userId) {
    if (userId.isEmpty) return Stream.value(0);
    // بثّ حي (لا يوجد count().snapshots() في الـSDK) لكن بسقف 100 مستند:
    // الشارة تعرض «99+» أصلاً، فكان تحميل كل غير المقروء هدراً — خاصة أن
    // الجرس يظهر في AppBar كل شاشة.
    return _col
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> markRead(String id) async {
    try {
      await _col.doc(id).update({'read': true});
    } catch (_) {}
  }

  Future<void> markAllRead(String userId) async {
    if (userId.isEmpty) return;
    try {
      final q = await _col
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (final d in q.docs) {
        batch.update(d.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }
}
