import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/news/list.dart';
import 'package:qurity/features/news/view.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/news_service.dart';

/// تحقّق بصري على مقاس الهاتف (٣٩٠×٨٤٤): لا فيضان عرض في التصميم الجديد
/// للقائمة وللمقال، وشريط الصور يأكل العرض كله بمقاسه المحسوب.
void main() {
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532); // ٣٩٠×٨٤٤ بمنطقية ×٣
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  const longTitle =
      'افتتاح مركز شبابي جديد بالقرية يخدم الأبناء بالمراحل التعليمية الثلاث';
  const urls = [
    'https://cdn.test/1.jpg',
    'https://cdn.test/2.jpg',
    'https://cdn.test/3.jpg',
  ];

  Future<FakeFirebaseFirestore> seedDocs({int count = 4}) async {
    final fake = FakeFirebaseFirestore();
    final base = DateTime.now();
    for (int i = 0; i < count; i++) {
      await fake.collection('news').add({
        'title': i.isEven ? longTitle : 'خبر قصير $i',
        'subtitle': 'ملخّص طويل عمدًا لاختبار التفاف الأسطر في البطاقة المدمجة '
            'ذات الصورة الجانبية مقاس ١٠٤ بكسل',
        'imageUrl': 'https://cdn.test/$i.jpg',
        'imageUrls': <String>['https://cdn.test/$i.jpg'],
        'views': 120 - i,
        'likes': 9,
        'comments': 3,
        'category': 'مجتمع',
        'isApproved': true,
        'createdAt': base.subtract(Duration(minutes: 7 + i)),
      });
    }
    return fake;
  }

  testWidgets('قائمة الأخبار على مقاس الهاتف: لا فيضان ولا استثناء',
      (tester) async {
    usePhone(tester);
    final fake = await seedDocs();
    await tester.pumpWidget(
        MaterialApp(home: NewsScreen(newsService: NewsService(fake))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);

    // بطاقات القائمة + ترويسة «كل الأخبار» تحت الطيّ: نقفز برمجيا، فالسحب مع
    // فيزياء الارتداد يحتاج عشرات الإطارات ليهدأ والصور ما زالت دوّارة.
    expect(await scrollUntil(tester, find.text('كل الأخبار')), isTrue);
    expect(tester.takeException(), isNull);
    // شريط الوقت صار زمنًا حقيقيًا منذ الإنشاء، لا تقدير مدة قراءة.
    expect(find.textContaining(RegExp('^منذ ')), findsWidgets);
    expect(find.textContaining(RegExp(r' د$')), findsNothing);
  });

  testWidgets('المقال على مقاس الهاتف: شريط الصور يملأ العرض وبلا فيضان',
      (tester) async {
    usePhone(tester);
    final fake = await seedDocs(count: 1);
    await fake.collection('news').doc('n1').set({
      'title': longTitle,
      'subtitle': 'نص المقال',
      'imageUrls': urls,
      'views': 5,
      'isApproved': true,
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
    });

    const item = NewsItem(
      id: 'n1',
      title: longTitle,
      subtitle: 'نص المقال',
      imageUrl: '',
      imageUrls: urls,
      date: '',
      views: 5,
      authorId: 'editor-9',
      authorName: 'أحمد المحرر',
    );

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
        MaterialApp(navigatorKey: navKey, home: const SizedBox.shrink()));
    navKey.currentState!.push(MaterialPageRoute(
      settings: const RouteSettings(name: '/news/view', arguments: item),
      builder: (_) => NewsViewScreen(newsService: NewsService(fake)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);

    // النسبة الافتراضية ٤:٣ على عرض المقال (٣٩٠ − ٣٢ حشوة) = ٢٦٩ بكسل
    final gallery = tester.getRect(find.byKey(const Key('gallery-counter')));
    expect(gallery.top, greaterThan(0));
    final box = tester.getRect(find
        .ancestor(of: find.byKey(const Key('gallery-next')), matching: find.byType(Stack))
        .first);
    expect(box.width, closeTo(358, 1));
    expect(box.height, inInclusiveRange(180, 420));

    // الترويسة تحت الصورة تعرض الزمن الحقيقي منذ الإنشاء (ظهرت على مقاس الهاتف
    // دون تمرير: الصورة ٢٦٩ + العنوان + الشارات كلها داخل أول الشاشة).
    expect(find.text('منذ 5 أيام'), findsOneWidget);
  });
}

/// القفز بالتدريج على التمرير الخارجي حتى يُبنى [finder]، لأن السحب بيدٍ واحدة
/// مع فيزياء الارتداد لا يستقر في إطار واحد.
Future<bool> scrollUntil(WidgetTester tester, Finder finder,
    {double step = 400, int maxSteps = 8}) async {
  final position = tester
      .state<ScrollableState>(find
          .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable))
          .first)
      .position;
  for (int i = 0; i <= maxSteps; i++) {
    position.jumpTo(step * i); // jumpTo تُقصّ القيمة نفسها إلى الحدود
    await tester.pump(const Duration(milliseconds: 300));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}
