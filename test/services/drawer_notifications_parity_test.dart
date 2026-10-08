import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/remote_push_service.dart';

/// عقد «القائمة الجانبية وإعدادات الإشعارات»: القائمة الجانبية في الرئيسية
/// يجب أن تواكب شبكة الخدمات (١٦ بلاطة) فلا تبقى صفحة بلا مدخل، وقنوات
/// الإشعارات المعروضة يجب أن تساوي مواضيع البثّ الحقيقية التي يشترك فيها
/// المستخدم فعلًا — بلا قناة مخترعة وبلا قناة ناقصة.
void main() {
  String src(String path) => File(path).readAsStringSync();

  /// لا `expect` هنا: هذه الدوال تُنادى أثناء تحميل الملف، و`expect` خارج منطقة
  /// اختبار يرمي `OutsideTestException` فلا ينفّذ أي عقد.
  String slice(String text, String from, String to) {
    final start = text.indexOf(from);
    if (start < 0) throw StateError('البداية غير موجودة: $from');
    final end = text.indexOf(to, start);
    if (end <= start) throw StateError('النهاية غير موجودة: $to');
    return text.substring(start, end);
  }

  Set<String> routeNames(String block) => RegExp(r'AppRoutes\.(\w+)')
      .allMatches(block)
      .map((m) => m.group(1)!)
      .toSet();

  final home = src('lib/features/home/home.dart');
  final routesSrc = src('lib/routes/app_routes.dart');
  final notif = src('lib/features/settings/notifications.dart');

  final drawerBlock = slice(home, 'class HomeDrawer', 'Future<void> _checkForUpdate');
  final gridBlock = slice(
      slice(home, 'class ModernServiceGrid', 'class _ServiceItem'),
      'static const _services = [',
      '];');
  final routesMap = slice(routesSrc, 'static final routes = <String', '};');
  final generated = slice(routesSrc, 'static Route<dynamic> onGenerateRoute',
      'static PageRouteBuilder<dynamic> _buildSlideRoute');

  group('القائمة الجانبية تواكب شبكة الرئيسية', () {
    test('شبكة الخدمات ستة عشر بلاطة كما هي', () {
      expect(RegExp(r"_ServiceItem\('").allMatches(gridBlock).length, 16);
    });

    test('كل مسار في شبكة الرئيسية له مدخل في القائمة الجانبية', () {
      final gridRoutes = routeNames(gridBlock);
      expect(gridRoutes.length, 16);
      expect(routeNames(drawerBlock), containsAll(gridRoutes));
    });

    test('كل مسار تستعمله القائمة مسجّل فعلًا (في الخريطة أو في المولّد)', () {
      for (final name in routeNames(drawerBlock)) {
        final inMap = RegExp('\\b$name:').hasMatch(routesMap);
        final generated2 = generated.contains('settings.name == $name');
        expect(inMap || generated2, isTrue,
            reason: 'المسار $name غير مسجّل في AppRoutes.routes ولا في onGenerateRoute');
      }
    });

    test('الصفحات الجديدة دخلت القائمة بأسمائها الحالية', () {
      for (final title in <String>[
        'فنيين القرية',
        'مستشار القرية',
        'الخدمات الطبية',
        'الخدمات التعليمية',
        'خدمات المزارع',
        'إعلانات القرية',
        'المفقودات',
        'ركن الأطفال',
        'مندرة القرية',
      ]) {
        expect(drawerBlock, contains("_buildDrawerItem(context, '$title'"),
            reason: 'القائمة لا تحمل «$title»');
      }
    });

    test('التسمية القديمة «حوارات المندرة» لا تعود إلى القائمة ولا إلى القنوات', () {
      // العنوان في الرئيسية نفسها (`_SectionHead` لقسم المندرة) وفي شاشة المندرة
      // اسمٌ لتلك الشاشة لا للقائمة الجانبية، فالعقد على الموضعين المعدّلين فقط.
      expect(drawerBlock, isNot(contains('حوارات المندرة')));
      expect(notif, isNot(contains('حوارات المندرة')));
    });

    test('مداخل الحساب واللوحة والتحديثات باقية', () {
      for (final title in <String>[
        'الطوارئ',
        'الملف الشخصي',
        'الإعدادات',
        'عن التطبيق',
        'لوحة التحكم',
        'التحقق من التحديثات',
      ]) {
        expect(drawerBlock, contains(title));
      }
    });
  });

  group('قنوات الإشعارات تساوي مواضيع البثّ', () {
    Set<String> topics() => RegExp(r"_Service\('([a-z_]+)'")
        .allMatches(notif)
        .map((m) => m.group(1)!)
        .toSet();

    test('تسع قنوات: سبعة مواضيع بثّ + التنبيهات + الخبر العاجل', () {
      final expected = kPushTopicForCollection.values.toSet()
        ..addAll(<String>{'village_alerts', 'village_breaking'});
      expect(expected.length, 9);
      expect(topics(), expected);
    });

    test('لا قناة مكرّرة ولا قناة مخترعة', () {
      final all = RegExp(r"_Service\('([a-z_]+)'")
          .allMatches(notif)
          .map((m) => m.group(1)!)
          .toList();
      expect(all.length, all.toSet().length);
      expect(all, isNot(contains('all_users')));
      expect(notif, isNot(contains('all_users')));
    });

    test('مفتاح التفضيل المحفوظ على الأجهزة لم يتغيّر', () {
      expect(notif, contains(r"static String _key(String topic) => 'notif_pref_$topic';"));
    });

    test('كل قسم يُبَثّ على موضوع مسمّى في وصف قناته', () {
      for (final section in <String>[
        'إعلانات القرية',
        'المستلزمات الطبية',
        'المفقودات',
        'سجل المحامين',
        'معامل التحاليل',
        'محال النظارات',
        'بنك الدم',
        'المركز الطبي الخيري',
        'مندرة القرية',
      ]) {
        expect(notif, contains(section), reason: 'الوصف لا يسمّي «$section»');
      }
    });

    test('المجموعات بلا بثّ للقرية لا قناة لها', () {
      for (final silent in <String>[
        'phone_directory',
        'buy_requests',
        'donations',
        'seller_requests',
        'legal_consultations',
      ]) {
        expect(kPushTopicForCollection.containsKey(silent), isFalse,
            reason: '$silent صار لها موضوع بثّ — راجع قنوات الإعدادات');
      }
    });
  });
}
