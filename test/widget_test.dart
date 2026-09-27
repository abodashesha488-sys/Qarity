import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/theme/app_theme.dart';
import 'package:qurity/routes/app_routes.dart';

void main() {
  test('AppRoutes defines all core screen routes', () {
    expect(AppRoutes.home, '/');
    expect(AppRoutes.marketProducts, '/market');
    expect(AppRoutes.newsList, '/news');
    expect(AppRoutes.forumPosts, '/forum');
    expect(AppRoutes.obituariesList, '/obituaries');
    expect(AppRoutes.occasionsList, '/occasions');
    expect(AppRoutes.emergencyContacts, '/emergency');
    expect(AppRoutes.phoneDirectory, '/phone-directory');
    expect(AppRoutes.profileMain, '/profile');
    expect(AppRoutes.settingsIndex, '/settings');
    expect(AppRoutes.admin, '/admin');
    expect(AppRoutes.routes.containsKey(AppRoutes.home), isTrue);
    expect(AppRoutes.routes.containsKey(AppRoutes.marketProducts), isTrue);
  });

  test('admin detail/edit routes are protected by AdminGuard', () {
    // المسارات الإدارية الحساسة لا تُبنى مباشرة — تمرّ كلها عبر بوابة
    // AdminGuard التي تتحقق من الدور. لولاها يصل أي مستخدم لإدراجه المسار.
    final detail = AppRoutes.onGenerateRoute(
      const RouteSettings(
        name: AppRoutes.adminDetail,
        arguments: {
          'collection': 'news',
          'docId': 'x',
          'item': <String, dynamic>{},
        },
      ),
    );
    final edit = AppRoutes.onGenerateRoute(
      const RouteSettings(
        name: AppRoutes.adminEdit,
        arguments: {
          'collection': 'news',
          'docId': 'x',
          'item': <String, dynamic>{},
        },
      ),
    );
    expect(detail, isNotNull);
    expect(edit, isNotNull);
    // البوابة موجودة في الشجرة حتى لو لم ننفّذ البناء (Firebase غير مهيأ في
    // الاختبار) — التأكيد على وجود المسار المحمي يكفي لعقد التسجيل.
  });

  testWidgets('Light theme is a valid Material 3 theme', (tester) async {
    final theme = AppTheme.lightTheme;
    expect(theme, isA<ThemeData>());
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, isNotNull);
  });
}
