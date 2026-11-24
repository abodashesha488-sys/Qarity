import 'package:cloud_firestore/cloud_firestore.dart';

/// أداة مركزية لترتيب التعليقات بشكل متشعب (Threaded) بحيث يظهر كل ردّ
/// مباشرةً أسفل التعليق الأب الخاص به بدلاً من ظهوره في نهاية القائمة تحت
/// تعليق مستخدم آخر.
class CommentThreadHelper {
  CommentThreadHelper._();

  /// يرتّب قائمة تعليقات مسطّحة بحيث يتبع كل تعليق رئيسي ردوده مباشرةً
  /// بترتيب زمني تصاعدي (الأقدم فالأحدث داخل كل سلسلة ردود)، مع حماية
  /// ضد الحلقات المفرغة أو الآباء المحذوفين.
  static List<T> orderThreaded<T>(
    List<T> items, {
    required String Function(T item) idOf,
    required String? Function(T item) parentIdOf,
    DateTime? Function(T item)? createdAtOf,
  }) {
    if (items.length <= 1) return items;

    final byId = <String, T>{};
    for (final item in items) {
      final id = idOf(item);
      if (id.isNotEmpty) byId[id] = item;
    }

    String? resolveRootId(T item) {
      final directParent = parentIdOf(item);
      if (directParent == null || directParent.isEmpty) return null;
      if (!byId.containsKey(directParent)) return null;

      final visited = <String>{idOf(item)};
      var rootId = directParent;
      while (true) {
        if (!visited.add(rootId)) return null;
        final parentItem = byId[rootId];
        if (parentItem == null) break;
        final grandParent = parentIdOf(parentItem);
        if (grandParent == null ||
            grandParent.isEmpty ||
            !byId.containsKey(grandParent)) {
          break;
        }
        rootId = grandParent;
      }
      return rootId;
    }

    final roots = <T>[];
    final repliesByRoot = <String, List<T>>{};

    for (final item in items) {
      final rootId = resolveRootId(item);
      if (rootId == null) {
        roots.add(item);
      } else {
        (repliesByRoot[rootId] ??= <T>[]).add(item);
      }
    }

    final result = <T>[];
    final emitted = <String>{};
    for (final root in roots) {
      result.add(root);
      emitted.add(idOf(root));
      final replies = repliesByRoot[idOf(root)];
      if (replies != null && replies.isNotEmpty) {
        if (createdAtOf != null) {
          replies.sort((a, b) {
            final da = createdAtOf(a) ?? DateTime(1970);
            final db = createdAtOf(b) ?? DateTime(1970);
            return da.compareTo(db);
          });
        }
        for (final r in replies) {
          result.add(r);
          emitted.add(idOf(r));
        }
      }
    }
    for (final item in items) {
      if (!emitted.contains(idOf(item))) {
        result.add(item);
      }
    }
    return result;
  }

  /// اختصار مريح لقوائم `QueryDocumentSnapshot` القادمة من Firestore مباشرةً.
  static List<QueryDocumentSnapshot> orderDocs(
    List<QueryDocumentSnapshot> docs,
  ) {
    return orderThreaded<QueryDocumentSnapshot>(
      docs,
      idOf: (d) => d.id,
      parentIdOf: (d) {
        final data = d.data() as Map<String, dynamic>?;
        return data?['parentId'] as String?;
      },
      createdAtOf: (d) {
        final data = d.data() as Map<String, dynamic>?;
        final ts = data?['createdAt'];
        return ts is Timestamp ? ts.toDate() : null;
      },
    );
  }

  /// اختصار مريح لقوائم `Map<String, dynamic>` (مثل تعليقات المنتجات).
  static List<Map<String, dynamic>> orderMaps(
    List<Map<String, dynamic>> maps,
  ) {
    return orderThreaded<Map<String, dynamic>>(
      maps,
      idOf: (m) => m['id'] as String? ?? '',
      parentIdOf: (m) => m['parentId'] as String?,
      createdAtOf: (m) {
        final ts = m['createdAt'];
        if (ts is Timestamp) return ts.toDate();
        if (ts is DateTime) return ts;
        return null;
      },
    );
  }
}
