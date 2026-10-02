import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/promo_placements.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/routes/app_routes.dart';

/// عقد «الصفحات المستقلة»: بوّابة «دليل الخدمات» الجامعة أُلغيت، وصار لكل فئة
/// خدمة مسارها الخاص بلا وسائط — كبقية صفحات الشاشة الرئيسية.
void main() {
  List<String> dartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path.replaceAll(r'\', '/'))
      .toList();

  String src(String path) => File(path).readAsStringSync();

  group('مسارات الصفحات المستقلة', () {
    test('كل فئة خدمة لها مسار مسجّل في خريطة المسارات', () {
      expect(AppRoutes.techniciansDirectory, '/services/technicians');
      expect(AppRoutes.agriculturalServices, '/services/agricultural');
      expect(AppRoutes.educationalServices, '/services/educational');
      expect(
        AppRoutes.routes.keys,
        containsAll(<String>[
          AppRoutes.techniciansDirectory,
          AppRoutes.agriculturalServices,
          AppRoutes.educationalServices,
        ]),
      );
    });

    test('فئة السجل تحسم صفحته، والقديم المجهول لا يبقى بلا صفحة', () {
      expect(AppRoutes.routeForProviderCategory(ServiceCategory.technicians),
          AppRoutes.techniciansDirectory);
      expect(AppRoutes.routeForProviderCategory(ServiceCategory.agricultural),
          AppRoutes.agriculturalServices);
      expect(AppRoutes.routeForProviderCategory(ServiceCategory.educational),
          AppRoutes.educationalServices);
      expect(AppRoutes.routeForProviderCategory(null),
          AppRoutes.techniciansDirectory);
      expect(
          AppRoutes.routeForProviderCategory(''), AppRoutes.techniciansDirectory);
    });

    test('لا بوّابة جامعة ولا مسار بالوسائط في الكود', () {
      for (final path in dartFiles()) {
        final text = src(path);
        expect(text, isNot(contains('ServiceDirectoryScreen')), reason: path);
        expect(text, isNot(contains('/services/category')), reason: path);
        expect(text, isNot(contains("'/services'")), reason: path);
      }
    });

    test('الشاشة الرئيسية وبوّابة المزارع تدخل الصفحات مباشرة', () {
      final home = src('lib/features/home/home.dart');
      expect(home, contains('AppRoutes.techniciansDirectory'));
      expect(home, contains('AppRoutes.educationalServices'));
      expect(home, isNot(contains('serviceCategory')));

      final farmer = src('lib/features/services/farmer_services_screen.dart');
      expect(farmer, contains('AppRoutes.agriculturalServices'));

      // صفحة الفئة تُبنى بمجموعة ثابتة في المسار، فلا وسائط لأي منها.
      final routes = src('lib/routes/app_routes.dart');
      expect(routes, contains('category: ServiceCategory.technicians'));
      expect(routes, contains('category: ServiceCategory.agricultural'));
      expect(routes, contains('category: ServiceCategory.educational'));
    });

    test('ترتيب بلاطات الشبكة الرئيسية وأسمائها حرفيًا', () {
      final home = src('lib/features/home/home.dart');
      final start = home.indexOf('static const _services = [');
      expect(start, greaterThan(-1), reason: 'الشبكة تبنى من قائمة واحدة ثابتة');
      final block = home.substring(start, home.indexOf('];', start));
      final tiles = RegExp(r"_ServiceItem\('([^']+)',\s*AppRoutes\.(\w+)")
          .allMatches(block)
          .map((m) => '${m.group(2)}|${m.group(1)}')
          .toList();
      expect(
        tiles,
        const <String>[
          'about|تعرف على القرية',
          'newsList|أخبار القرية',
          'forumPosts|مندرة القرية',
          'marketProducts|سوق القرية',
          'techniciansDirectory|فنيين القرية',
          'legalAdvisor|مستشار القرية',
          'medical|الخدمات الطبية',
          'educationalServices|الخدمات التعليمية',
          'farmerServices|خدمات المزارع',
          'villageAds|إعلانات القرية',
          'lostItems|المفقودات',
          'phoneDirectory|دليل الهاتف',
          'occasionsList|المناسبات',
          'obituariesList|سجل العزاء',
          'children|ركن الأطفال',
          'aboutApp|حول التطبيق',
        ],
      );
      expect(tiles.toSet().length, tiles.length, reason: 'لا صفحة تتكرر ولا تُفقد');
    });

    test('لوحة الإدارة تسمّي الصفحة التي سيظهر فيها السجل', () {
      expect(src('lib/features/admin/admin_detail.dart'),
          contains('ServiceCategory.label(value)'));
      final review = src('lib/features/admin/admin_dashboard_review.dart');
      expect(review, contains('سجل في صفحة دليل الحرفيين'));
      expect(review, contains('سجل في صفحة خدمات زراعية'));
      expect(review, contains('سجل في صفحة خدمات تعليمية'));
      // مسارات الإشعارات تُبنى من فئة السجل، لا من بوّابة.
      expect(src('lib/services/admin_service.dart'),
          contains('_routeForProviderCategory(data?[\'category\'])'));
      expect(src('lib/services/service_provider_service.dart'),
          contains('AppRoutes.routeForProviderCategory(provider.category)'));
    });

    test('أماكن الإعلانات تعدّ الصفحات الثلاث بلا بوّابة', () {
      final keys = kPromoPlacements.map((p) => p.key).toList();
      expect(keys, containsAll(<String>[
        'svc_technicians',
        'svc_agricultural',
        'svc_educational',
      ]));
      expect(keys, isNot(contains('services')));
      expect(promoKeyForRoute(AppRoutes.techniciansDirectory, null),
          'svc_technicians');
      expect(promoKeyForRoute('/services', null), '');
    });
  });
}
