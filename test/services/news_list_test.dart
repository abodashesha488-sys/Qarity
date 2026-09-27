import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/news/list.dart';
import 'package:qurity/services/news_service.dart';

/// اختبار دخان لتصميم شاشة الأخبار الجديد: تُعرض الأخبار (البطاقة الرئيسية
/// + بطاقات القائمة) دون أي استثناء.
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

    expect(find.text('أحدث الأخبار'), findsOneWidget);
    // لا يوجد شريط «عاجل» بعد الآن
    expect(find.text('عاجل'), findsNothing);
  });
}

/// طابع زمني متناقص بحيث يكون أحدث خبر هو «خبر رقم 0».
dynamic fakeTimestamp(int i) =>
    DateTime(2026, 9, 27, 12).subtract(Duration(hours: i));
