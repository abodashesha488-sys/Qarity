import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/firebase_ts.dart';
import 'package:qurity/core/utils/user_gender_groups.dart';
import 'package:qurity/routes/app_routes.dart';

Map<String, dynamic> _makeUser({
  required String id,
  required String name,
  String role = 'user',
  dynamic joinDate,
  dynamic lastLogin,
  String gender = '',
}) {
  return {
    'id': id,
    'name': name,
    'role': role,
    if (joinDate != null) 'joinDate': joinDate,
    if (lastLogin != null) 'lastLogin': lastLogin,
    if (gender.isNotEmpty) 'gender': gender,
  };
}

void main() {
  group('سجل المستخدمين الشامل — آليات الفرز', () {
    test('فرز تاريخ التسجيل (الأحدث أولاً)', () {
      final u1 = _makeUser(
        id: '1',
        name: 'قديم',
        joinDate: DateTime(2026),
      );
      final u2 = _makeUser(
        id: '2',
        name: 'حديث',
        joinDate: DateTime(2026, 10),
      );
      final u3 = _makeUser(
        id: '3',
        name: 'أحدث',
        joinDate: DateTime(2026, 10, 25),
      );

      final list = [u1, u3, u2];
      list.sort((a, b) {
        final da = signupAt(a);
        final db = signupAt(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      expect(list.map((u) => u['id']).toList(), ['3', '2', '1']);
    });

    test('فرز تاريخ التسجيل (الأقدم أولاً)', () {
      final u1 = _makeUser(
        id: '1',
        name: 'قديم',
        joinDate: DateTime(2026),
      );
      final u2 = _makeUser(
        id: '2',
        name: 'حديث',
        joinDate: DateTime(2026, 10),
      );

      final list = [u2, u1];
      list.sort((a, b) {
        final da = signupAt(a);
        final db = signupAt(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

      expect(list.map((u) => u['id']).toList(), ['1', '2']);
    });

    test('فرز الاسم أبجدياً (أ - ي) و (ي - أ)', () {
      final a = _makeUser(id: 'a', name: 'أحمد');
      final b = _makeUser(id: 'b', name: 'بلال');
      final z = _makeUser(id: 'z', name: 'ياسر');

      final listAsc = [z, a, b]
        ..sort((x, y) => (x['name'] as String).compareTo(y['name'] as String));
      expect(listAsc.map((u) => u['id']).toList(), ['a', 'b', 'z']);

      final listDesc = [a, z, b]
        ..sort((x, y) => (y['name'] as String).compareTo(x['name'] as String));
      expect(listDesc.map((u) => u['id']).toList(), ['z', 'b', 'a']);
    });

    test('فرز الرتبة / التصنيف: المسؤولون أولاً ثم البائعون ثم المستخدمون', () {
      final admin = _makeUser(id: 'ad', name: 'مدير', role: 'admin');
      final seller = _makeUser(id: 'sel', name: 'بائع', role: 'seller');
      final user = _makeUser(id: 'usr', name: 'مستخدم');

      final list = [user, seller, admin]..sort((x, y) =>
          userRoleRank((x['role'] as String))
              .compareTo(userRoleRank((y['role'] as String))));

      expect(list.map((u) => u['id']).toList(), ['ad', 'sel', 'usr']);
    });
  });

  group('سجل المستخدمين الشامل — المسارات وعقود الشاشات', () {
    test('مسار adminAllUsers معرّف ومسجل في AppRoutes', () {
      expect(AppRoutes.adminAllUsers, '/admin/all-users');
      final routesSrc = File('lib/routes/app_routes.dart').readAsStringSync();
      expect(routesSrc, contains('settings.name == adminAllUsers'));
      expect(routesSrc, contains('AllUsersDirectoryScreen()'));
    });

    test('تبويب المستخدمين يضم كارت الانتقال إلى السجل الشامل وخيار فرز الرتبة',
        () {
      final usersTabSrc = File('lib/features/admin/admin_dashboard_users.dart')
          .readAsStringSync();
      expect(usersTabSrc, contains('AllUsersDirectoryScreen('));
      expect(usersTabSrc, contains('سجل كامل المستخدمين الشامل'));
      expect(usersTabSrc, contains("value: 'role'"));
      expect(usersTabSrc, contains("case 'role':"));
    });
  });
}
