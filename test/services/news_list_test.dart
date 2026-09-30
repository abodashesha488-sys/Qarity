import 'package:cached_network_image/cached_network_image.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/news/list.dart';
import 'package:qurity/services/news_service.dart';

/// اختبار دخان لتصميم شاشة الأخبار: الرئيسي + القائمة، وشرائح التصنيف تحت
/// الهيدر وفوق الأخبار، و«كل الأخبار» مرتّبة الأحدث أولًا بوقتها الحقيقي.
void main() {
  testWidgets('شاشة الأخبار تعرض الرئيسي والقائمة دون أخطاء', (tester) async {
    final fake = FakeFirebaseFirestore();
    for (int i = 0; i < 3; i++) {
      await fake.collection('news').add({
        'title': 'خبر رقم $i',
        'subtitle': 'ملخص الخبر رقم $i',
        'imageUrl': '',
        'imageUrls': <String>[],
        'date': '2026/09/27',
        'views': 10 + i,
        'likes': i,
        'comments': i,
        'category': i == 0 ? 'عام' : 'رياضة',
        'isApproved': true,
        'createdAt': fakeTimestamp(i),
      });
    }
    final svc = NewsService(fake);

    await tester.pumpWidget(MaterialApp(
      home: NewsScreen(newsService: svc),
    ));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    // الخبر الرئيسي الظاهر أعلى الشاشة
    expect(find.textContaining('خبر رقم 0'), findsWidgets);
    expect(find.text('الخبر الرئيسي'), findsOneWidget);

    // التمرير لإظهار رأس و بطاقات قائمة الأخبار (slivers لا تُبنى إلا عند ظهورها)
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('كل الأخبار'), findsOneWidget);
    // لا يوجد شريط «عاجل» بعد الآن
    expect(find.text('عاجل'), findsNothing);
  });

  testWidgets('شرائح التصنيف تحت الهيدر وفوق الأخبار ولا تدخل تكوينه',
      (tester) async {
    await seed(tester, count: 2);
    final chip = find.text('ثقافة'); // لا خبر بهذه فئة ⇒ الشريحة وحدها

    // خارج SliverAppBar تمامًا (كانت داخل bottom الخاص بالهيدر)
    expect(
        find.ancestor(of: chip, matching: find.byType(SliverAppBar)),
        findsNothing);
    // تحت صندوق البحث في الهيدر، وفوق الخبر الرئيسي
    expect(tester.getRect(find.byType(TextField)).bottom,
        lessThanOrEqualTo(tester.getRect(chip).top));
    expect(tester.getRect(chip).bottom,
        lessThanOrEqualTo(tester.getRect(find.text('الخبر الرئيسي')).top));
  });

  testWidgets('«كل الأخبار» تعرض كل الأخبار أجدّها أولًا (بما فيها الرئيسي)',
      (tester) async {
    await seed(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('كل الأخبار'), findsOneWidget);
    // الخبر الرئيسي مكرر في القائمة لأنه خبر مثل بقية الأخبار
    expect(find.text('خبر رقم 0'), findsAtLeastNWidgets(2));
    expect(find.text('خبر رقم 1'), findsWidgets);
    expect(find.text('خبر رقم 2'), findsWidgets);

    // الترتيب المعروض: الأحدث قبل الأقدم
    expect(tester.getRect(find.text('خبر رقم 0').last).top,
        lessThan(tester.getRect(find.text('خبر رقم 1').last).top));
    expect(tester.getRect(find.text('خبر رقم 1').last).top,
        lessThan(tester.getRect(find.text('خبر رقم 2').last).top));
  });

  testWidgets('كارت الخبر يعرض الوقت منذ الإنشاء لا زمن القراءة',
      (tester) async {
    await seed(tester, count: 1, minutesAgo: 5);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('منذ 5 دقائق'), findsWidgets);
    // لا شارة «٣ د» (زمن قراءة تقديري من كلمات الملخّص)
    expect(
        find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').endsWith(' د')),
        findsNothing);
  });

  testWidgets('كل صور الأخبار تملأ إطارها المخصّص (توحيد التنسيق)',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final fake = FakeFirebaseFirestore();
    final base = DateTime.now();
    for (int i = 0; i < 3; i++) {
      await fake.collection('news').add({
        'title': 'خبر مصوّر $i',
        'subtitle': 'ملخّص',
        'imageUrl': 'https://cdn.test/$i.jpg',
        'imageUrls': <String>['https://cdn.test/$i.jpg'],
        'views': 5,
        'likes': 1,
        'comments': 0,
        'category': 'عام',
        'isApproved': true,
        'createdAt': base.subtract(Duration(minutes: i)),
      });
    }
    await tester.pumpWidget(
        MaterialApp(home: NewsScreen(newsService: NewsService(fake))));
    // بلا pumpAndSettle: المؤشر الدوّار داخل إطار التحميل لا يستقر أبدًا.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final images = tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage)).toList();
    expect(images, isNotEmpty);
    for (final image in images) {
      expect(image.fit, BoxFit.cover);
      expect(image.width, double.infinity);
      expect(image.height, double.infinity);
    }
  });
}

/// ثلاث أخبار حديثة متناصرة الأحدث أولًا، بواجهة بمقاس الهاتف.
Future<void> seed(WidgetTester tester,
    {int count = 3, int minutesAgo = 0}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final fake = FakeFirebaseFirestore();
  final base = DateTime.now();
  for (int i = 0; i < count; i++) {
    await fake.collection('news').add({
      'title': 'خبر رقم $i',
      'subtitle': 'ملخص الخبر رقم $i',
      'imageUrl': '',
      'imageUrls': <String>[],
      'date': '2026-09-30',
      'views': 10 + i,
      'likes': i,
      'comments': i,
      'category': i == 0 ? 'عام' : 'رياضة',
      'isApproved': true,
      'createdAt': base.subtract(Duration(minutes: minutesAgo + i)),
    });
  }
  await tester.pumpWidget(MaterialApp(home: NewsScreen(newsService: NewsService(fake))));
  await tester.pump();
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// طابع زمني متناقص بحيث يكون أحدث خبر هو «خبر رقم 0».
dynamic fakeTimestamp(int i) =>
    DateTime(2026, 9, 27, 12).subtract(Duration(hours: i));
