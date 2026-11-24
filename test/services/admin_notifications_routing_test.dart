import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/remote_push_service.dart';

void main() {
  group('Role-based admin notification routing', () {
    test('kAdminNotifyCollections includes all core and new service modules',
        () {
      for (final col in [
        'news',
        'market_products',
        'forum_posts',
        'medical_center_clinics',
        'agriculture_consultations',
        'group_deals',
        'eshterili_orders',
        'etsawaqli_orders',
        'upgrade_requests',
        'reports',
      ]) {
        expect(kAdminNotifyCollections, contains(col));
      }
    });

    test(
        'api/push.js routes every admin_notify to admin + assistant_admin and scopes specialists',
        () {
      final pushJs = File('api/push.js').readAsStringSync();

      // القاعدة الأساسية: admin و assistant_admin يضافان دائماً لكل إخطار إداري
      expect(
        pushJs,
        contains("new Set(['admin', 'assistant_admin', ...(kind.roles || [])])"),
      );

      // التحقق من وجود المجموعات الجديدة والتخصصية في PENDING_KINDS
      for (final key in [
        'eshterili_orders:',
        'etsawaqli_orders:',
        'group_deals:',
        'agriculture_consultations:',
        'upgrade_requests:',
        'medical_center_clinics:',
      ]) {
        expect(pushJs, contains(key));
      }

      // التحقق من توجيه الأدوار التخصصية
      expect(pushJs, contains("'medical_admin'"));
      expect(pushJs, contains("'agricultural_admin'"));
      expect(pushJs, contains("'commercial_admin'"));
      expect(pushJs, contains("'delivery_agent'"));
    });
  });
}
