import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/news/view.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/news_service.dart';
import 'package:qurity/services/user_service.dart';

/// إطار + زمن الحركة (280ms) + إطار أخير يرسم ما نتج عن setState أثناء التخطيط.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

/// مقال الخبر: معرض الصور (أسهم السابق/التالي + ملء الشاشة) وصورة المحرر
/// المُقرأَة من ملفه وقت العرض، والوقت النسبي منذ الإنشاء.
void main() {
  const first = 'https://cdn.test/a.jpg';
  const second = 'https://cdn.test/b.jpg';

  Future<void> open(WidgetTester tester, NewsItem item,
      {UserService? userService}) async {
    // مقاس هاتف: ListView المقال كسول، فالنافذة الافتراضية القصيرة لا تبني
    // بلوك المحرر والترويسة في أسفلها.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final fake = FakeFirebaseFirestore();
    await fake.collection('news').doc(item.id).set(<String, dynamic>{
      'title': item.title,
      'subtitle': item.subtitle,
      'imageUrls': item.imageUrls,
      'views': item.views,
      'isApproved': true,
      if (item.createdAt != null) 'createdAt': Timestamp.fromDate(item.createdAt!),
    });

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
        MaterialApp(navigatorKey: navKey, home: const SizedBox.shrink()));
    navKey.currentState!.push(MaterialPageRoute(
      settings: RouteSettings(name: '/news/view', arguments: item),
      builder: (_) =>
          NewsViewScreen(newsService: NewsService(fake), userService: userService),
    ));
    await _settle(tester);
  }


  NewsItem article({List<String> images = const [], DateTime? createdAt}) =>
      NewsItem(
        id: 'news-g',
        title: 'خبر بمعرض',
        subtitle: 'نص الخبر',
        imageUrl: images.isNotEmpty ? images.first : '',
        imageUrls: images,
        date: '',
        views: 4,
        authorId: 'editor-1',
        authorName: 'أحمد المحرر',
        createdAt: createdAt,
      );

  testWidgets('صور متعددة: السابق/التالي ينقّلان ويتعطلان عند الحافتين',
      (tester) async {
    await open(tester, article(images: const [first, second]));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('gallery-prev')), findsOneWidget);
    expect(find.byKey(const Key('gallery-next')), findsOneWidget);
    expect(find.byKey(const Key('gallery-counter')), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    // في الحافة الأولى «السابق» بلا إجراء
    await tester.tap(find.byKey(const Key('gallery-prev')));
    await _settle(tester);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gallery-next')));
    await _settle(tester);
    expect(find.text('2 / 2'), findsOneWidget);

    // وفي الأخيرة «التالي» بلا إجراء
    await tester.tap(find.byKey(const Key('gallery-next')));
    await _settle(tester);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gallery-prev')));
    await _settle(tester);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('صورة واحدة: بلا أسهم ولا عدّاد — العدسة وحدها', (tester) async {
    await open(tester, article(images: const [first]));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('gallery-prev')), findsNothing);
    expect(find.byKey(const Key('gallery-next')), findsNothing);
    expect(find.byKey(const Key('gallery-counter')), findsNothing);
    expect(find.byKey(const Key('gallery-zoom')), findsOneWidget);
  });

  testWidgets('العدسة تفتح ملء الشاشة بأسهمها وعدّادها', (tester) async {
    await open(tester, article(images: const [first, second]));

    await tester.tap(find.byKey(const Key('gallery-zoom')));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('viewer-counter')), findsOneWidget);
    expect(find.byKey(const Key('viewer-next')), findsOneWidget);
    // شريط المقال يبقى مركّبًا تحت المتفرّج، فالعدّاد يُقرأ من مفتاحه لا من النص.
    expect(tester.widget<Text>(find.byKey(const Key('viewer-counter'))).data,
        '1 / 2');

    await tester.tap(find.byKey(const Key('viewer-next')));
    await _settle(tester);
    expect(tester.widget<Text>(find.byKey(const Key('viewer-counter'))).data,
        '2 / 2');
  });

  testWidgets('صورة المحرر تُقرأ من ملفه بالمعرّف لا من الجلسة', (tester) async {
    final users = _RecordingUserService('https://cdn.test/editor.jpg');
    await open(tester, article(), userService: users);

    expect(users.requested, ['editor-1']);
    final avatar = tester.widget<CircleAvatar>(
        find.byKey(const Key('article-author-avatar')));
    expect((avatar.backgroundImage as CachedNetworkImageProvider).url,
        'https://cdn.test/editor.jpg');
    // تحميل الشبكة محجوب في الاختبارات: الخطأ من المحاولة لا من التنسيق.
    tester.takeException();
  });

  testWidgets('بلا صورة في الملف ⇒ أيقونة person بجوار الاسم', (tester) async {
    await open(tester, article(), userService: _RecordingUserService(null));

    expect(
        find.descendant(
            of: find.byKey(const Key('article-author-avatar')),
            matching: find.byIcon(Icons.person_rounded)),
        findsOneWidget);
  });

  testWidgets('ترويسة المقال تعرض الوقت منذ الإنشاء', (tester) async {
    await open(
      tester,
      article(
        createdAt:
            DateTime.now().subtract(const Duration(days: 3)),
      ),
      userService: _RecordingUserService(null),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('منذ 3 أيام'), findsWidgets);
  });
}

/// تسجّل معارف المستخدمين المطلوبين، فيثبت أن الصورة جاءت من ملف الكاتب.
class _RecordingUserService extends UserService {
  _RecordingUserService(this._photo) : super(FakeFirebaseFirestore());

  final String? _photo;
  final List<String> requested = [];

  @override
  Future<UserModel?> getUser(String uid) async {
    requested.add(uid);
    return UserModel(
      id: uid,
      name: 'محرر',
      email: 'editor@example.com',
      photoUrl: _photo,
      joinDate: DateTime(2026),
    );
  }
}
