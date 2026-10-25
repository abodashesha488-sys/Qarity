import 'package:cloud_firestore/cloud_firestore.dart';

/// إشعارات شخصية وإذاعية داخل التطبيق (تعمل على كل المنصات حتى بدون FCM/web-push).
/// تُكتب عند موافقة/رفض أدمن على محتوى مستخدم، أو عند بث إشعار إذاعي للقرية كلها،
/// ويقرؤها المستخدم من الجرس وتُحدَّث شارة غير المقروء لحظياً.
class UserNotification {
  final String id;
  final String title;
  final String body;
  final String? route;
  final bool read;
  final DateTime createdAt;
  final String? kind; // approve | reject | info | broadcast | alert
  final String? userId; // 'all' أو uid محدد

  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    this.route,
    required this.read,
    required this.createdAt,
    this.kind,
    this.userId,
  });

  bool get isBroadcast => userId == 'all';

  factory UserNotification.fromJson(
    Map<String, dynamic> json,
    String id, {
    String? currentUserId,
  }) {
    final ts = json['createdAt'];
    final docUserId = json['userId']?.toString();
    final isBroad = docUserId == 'all';
    final readByList = (json['readBy'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final isRead = isBroad
        ? (currentUserId != null && readByList.contains(currentUserId)) ||
            json['read'] == true
        : json['read'] == true;

    return UserNotification(
      id: id,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      route: json['route'] as String?,
      read: isRead,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : (ts is String
              ? DateTime.tryParse(ts) ?? DateTime.now()
              : DateTime.now()),
      kind: json['kind'] as String?,
      userId: docUserId,
    );
  }
}

class NotificationInboxService {
  NotificationInboxService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// المثيل الافتراضي للتطبيق؛ يهيَّأ عند أول استخدام فقط حتى لا تلمسه
  /// اختبارات الخدمات التي تمرّر Firestore وهميًا.
  static final NotificationInboxService instance = NotificationInboxService();

  final FirebaseFirestore _firestore;

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

  /// بث إشعار إذاعي لجميع مستخدمي القرية يظهر في الجرس لكل الحسابات.
  Future<void> pushBroadcast({
    required String title,
    required String body,
    String? route,
    bool isAlert = false,
  }) async {
    try {
      await _col.add({
        'userId': 'all',
        'title': title,
        'body': body,
        'route': route,
        'kind': isAlert ? 'alert' : 'broadcast',
        'read': false,
        'readBy': <String>[],
        'deletedBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('broadcast push failed: $e');
    }
  }

  Stream<List<UserNotification>> streamFor(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    // نطلب الإشعارات الخاصة بالمستخدم والإشعارات العامة للقرية (userId in [userId, 'all'])
    // بدون orderBy مركب لتجنب الحاجة لفهرس يدوي، ونفرز في الذاكرة.
    return _col
        .where('userId', whereIn: [userId, 'all'])
        .limit(50)
        .snapshots()
        .map((s) {
      final list = <UserNotification>[];
      for (final d in s.docs) {
        var m = d.data();
        final deletedBy = (m['deletedBy'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
        if (deletedBy.contains(userId)) continue;

        m = {...m, 'createdAt': m['createdAt'] ?? Timestamp.now()};
        list.add(UserNotification.fromJson(m, d.id, currentUserId: userId));
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<int> unreadCount(String userId) {
    if (userId.isEmpty) return Stream.value(0);
    return _col
        .where('userId', whereIn: [userId, 'all'])
        .limit(100)
        .snapshots()
        .map((s) {
      int count = 0;
      for (final d in s.docs) {
        final data = d.data();
        final deletedBy = (data['deletedBy'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
        if (deletedBy.contains(userId)) continue;

        final isBroad = data['userId'] == 'all';
        if (isBroad) {
          final readBy = (data['readBy'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
          if (!readBy.contains(userId)) {
            count++;
          }
        } else {
          if (data['read'] != true) {
            count++;
          }
        }
      }
      return count;
    });
  }

  Future<void> markRead(String id, {String? userId}) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data?['userId'] == 'all' && userId != null && userId.isNotEmpty) {
        await _col.doc(id).update({
          'readBy': FieldValue.arrayUnion([userId]),
        });
      } else {
        await _col.doc(id).update({'read': true});
      }
    } catch (_) {}
  }

  Future<void> markAllRead(String userId) async {
    if (userId.isEmpty) return;
    try {
      final q = await _col
          .where('userId', whereIn: [userId, 'all'])
          .limit(100)
          .get();
      final batch = _firestore.batch();
      for (final d in q.docs) {
        final data = d.data();
        if (data['userId'] == 'all') {
          batch.update(d.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
        } else if (data['read'] != true) {
          batch.update(d.reference, {'read': true});
        }
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> deleteNotification(String id, {String? userId}) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data?['userId'] == 'all' && userId != null && userId.isNotEmpty) {
        await _col.doc(id).update({
          'deletedBy': FieldValue.arrayUnion([userId]),
        });
      } else {
        await _col.doc(id).delete();
      }
    } catch (_) {}
  }

  Future<void> deleteAll(String userId) async {
    if (userId.isEmpty) return;
    try {
      final q = await _col
          .where('userId', whereIn: [userId, 'all'])
          .limit(100)
          .get();
      final batch = _firestore.batch();
      for (final d in q.docs) {
        final data = d.data();
        if (data['userId'] == 'all') {
          batch.update(d.reference, {
            'deletedBy': FieldValue.arrayUnion([userId]),
          });
        } else {
          batch.delete(d.reference);
        }
      }
      await batch.commit();
    } catch (_) {}
  }
}
