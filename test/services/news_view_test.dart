import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/app_colors.dart';
import 'package:qurity/core/theme/app_theme.dart';
import 'package:qurity/features/news/view.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/news_service.dart';

/// اختبارات شاشة تفاصيل الخبر:
///  • التعليق يُعرض باللون الأسود
///  • زر حذف التعليق لا يظهر لمستخدم عادي (للأدمن/الأدمن المساعد فقط)
void main() {
  testWidgets('التعليق أسود وزر الحذف مخفي لمستخدم عادي', (tester) async {
    final fake = FakeFirebaseFirestore();
    const newsId = 'news-1';
    await fake.collection('news').doc(newsId).set({
      'title': 'خبر تجريبي',
      'subtitle': 'نص الخبر',
      'views': 3,
      'likes': 2,
      'comments': 1,
      'isApproved': true,
    });
    await fake
        .collection('news')
        .doc(newsId)
        .collection('comments')
        .doc('c1')
        .set({
      'userId': 'u1',
      'userName': 'أحمد',
      'userPhotoUrl': '',
      'text': 'تعليق أسود اللون',
      'createdAt': Timestamp.now(),
    });
    final svc = NewsService(fake);

    const item = NewsItem(
      id: newsId,
      title: 'خبر تجريبي',
      subtitle: 'نص الخبر',
      imageUrl: '',
      date: '',
      views: 3,
      likes: 2,
      comments: 1,
    );

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      // ثيم التطبيق نفسه: الحبر صار يُقرأ من الثيم، فالثيم الافتراضي كان
      // يقيس تعليق الشاشة على أرضية لا يراها المستخدم أبدًا.
      theme: AppTheme.lightTheme,
      navigatorKey: navKey,
      home: const SizedBox.shrink(),
    ));
    navKey.currentState!.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/news/view', arguments: item),
        builder: (_) => NewsViewScreen(newsService: svc),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // نص التعليق حاضر وبلونه الأسود
    final commentText = find.text('تعليق أسود اللون');
    expect(commentText, findsOneWidget);
    final textWidget = tester.widget<Text>(commentText);
    expect(textWidget.style?.color, AppColors.textPrimary);

    // عدّاد التعليقات مأخوذ من عدد التعليقات الفعلية
    expect(find.textContaining('التعليقات (1)'), findsOneWidget);

    // مستخدم عادي (غير مسجّل في هذا الاختبار) لا يرى زر الحذف
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });
}
