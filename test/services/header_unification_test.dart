import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/routes/app_routes.dart';
import 'package:qurity/widgets/qurity_app_bar.dart';
import 'package:qurity/widgets/qurity_logo.dart';

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpBar(WidgetTester tester, QurityAppBar bar) async {
  _usePhoneViewport(tester);
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(appBar: bar, body: const SizedBox())));
  await tester.pump();
}

/// ملفات تُبقي زراً عائماً عن قصد: أزرار «إدارة» لا «إضافة»، وتبويب الإعلانات
/// داخل لوحة الإدارة (له هيستره الخاص فلا «+» في الهيدر العلوي).
const _kFloatingButtonAllowlist = {
  'lib/features/admin/admin_dashboard_promos.dart',
  'lib/features/medical/medical_home_screen.dart',
  'lib/features/village/village_section_scaffold.dart',
  'lib/features/village/village_archive_screen.dart',
  'lib/features/village/village_history_screen.dart',
  'lib/features/village/village_institutions_screen.dart',
};

List<String> _dartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .map((f) => f.path.replaceAll(r'\', '/'))
    .toList();

/// true لو مرّر الملف وسطيّاً `color:` في مستوى وسائط نداء `QurityAppBar(`
/// (الأقواس المتداخلة تُتجاهل فلا تُحسب ألوان العناصر داخل الوسائط).
bool _passesAppBarColor(String src) {
  const call = 'QurityAppBar(';
  var at = src.indexOf(call);
  while (at >= 0) {
    var i = at + call.length;
    var depth = 0;
    while (i < src.length) {
      final c = src[i];
      if (c == '(' || c == '[' || c == '{') {
        depth++;
      } else if (c == ')' || c == ']' || c == '}') {
        if (depth == 0) break; // نهاية وسائط النداء
        depth--;
      } else if (depth == 0 && src.startsWith('color:', i)) {
        return true;
      }
      i++;
    }
    at = src.indexOf(call, i);
  }
  return false;
}

void main() {
  group('الهيدر الموحّد', () {
    testWidgets('زر الرئيسية يحل محل الشعار، ولا «+» بلا إجراء إضافة',
        (tester) async {
      await _pumpBar(tester, const QurityAppBar(title: 'سجل العزاء'));

      expect(find.byKey(const Key('header-home')), findsOneWidget);
      expect(find.byKey(const Key('header-add')), findsNothing);
      expect(find.byType(QurityLogo), findsNothing);
    });

    testWidgets('«+» الخضراء تظهر بجوار الجرس وتستدعي إجراء الشاشة',
        (tester) async {
      var taps = 0;
      await _pumpBar(
          tester,
          QurityAppBar(
              title: 'أخبار القرية',
              onAdd: () => taps++,
              addTooltip: 'إضافة خبر'));

      final add = find.byKey(const Key('header-add'));
      expect(add, findsOneWidget);
      await tester.tap(add);
      expect(taps, 1);

      final circle = find.descendant(
          of: add, matching: find.byType(Container));
      expect(circle, findsOneWidget);
      final deco = tester.widget<Container>(circle).decoration;
      expect((deco as BoxDecoration).color, const Color(0xFF2E7D32));
      expect(deco.shape, BoxShape.circle);

      final plus = tester.widget<Icon>(
          find.descendant(of: add, matching: find.byIcon(Icons.add)).first);
      expect(plus.size, greaterThan(24));
    });

    testWidgets('خلفية الهيدر بنية ثابتة لا تتغيّر من شاشة لشاشة',
        (tester) async {
      await _pumpBar(tester, const QurityAppBar(title: 'مناسبات القرية'));
      final bar = tester.widget<AppBar>(find.byType(AppBar).first);
      expect(bar.backgroundColor, QurityAppBar.headerColor);
      expect(QurityAppBar.headerColor, const Color(0xFF6F4E37));
    });

    testWidgets('زر الرئيسية يغلق كل المسارات فوقها', (tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => settings.name == AppRoutes.home
              ? Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.newsList),
                      child: const Text('افتح الأخبار'),
                    ),
                  ),
                )
              : const Scaffold(
                  appBar: QurityAppBar(title: 'أخبار القرية'),
                  body: SizedBox(),
                ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('افتح الأخبار'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('header-home')), findsOneWidget);

      await tester.tap(find.byKey(const Key('header-home')));
      await tester.pumpAndSettle();

      expect(find.text('افتح الأخبار'), findsOneWidget);
      expect(find.byKey(const Key('header-home')), findsNothing);
    });

    testWidgets('لا فيضان عند جمع زر الرئيسية + عنوان طويل + «+» + الجرس',
        (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      await _pumpBar(
          tester,
          QurityAppBar(
              title: 'المركز الطبي الخيري — عيادات القرية والصيدليات',
              onAdd: () {},
              addTooltip: 'أضف عيادة'));
      FlutterError.onError = previous;

      expect(errors, isEmpty);
      expect(find.byKey(const Key('header-home')), findsOneWidget);
      expect(find.byKey(const Key('header-add')), findsOneWidget);
    });
  });

  group('عقد المصدر', () {
    test('لا شاشة تمرّر لوناً خاصاً بها للهيدر', () {
      final offenders = <String>[];
      for (final path in _dartFiles()) {
        if (path.endsWith('qurity_app_bar.dart')) continue;
        if (_passesAppBarColor(File(path).readAsStringSync())) offenders.add(path);
      }
      expect(offenders, isEmpty);
    });

    test('أزرار الإضافة لم تعد عائمة في أي شاشة', () {
      final found = <String>{
        for (final path in _dartFiles())
          if (File(path).readAsStringSync().contains('FloatingActionButton'))
            path,
      };
      expect(found.difference(_kFloatingButtonAllowlist), isEmpty);
    });
  });
}
