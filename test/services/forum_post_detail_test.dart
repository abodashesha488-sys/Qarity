import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/forum/post_detail.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/forum_service.dart';
import 'package:qurity/widgets/common_appbar_actions.dart';

/// اختبارات شاشة تفاصيل منشور المندرة:
///  • جرس إشعار واحد فقط (كان مكرراً)
///  • نص التعليق باللون الأزرق
void main() {
  testWidgets('جرس واحد فقط في الهيدر + التعليق أزرق', (tester) async {
    final fake = FakeFirebaseFirestore();
    final postId = 'post-1';
    await fake.collection('forum_posts').doc(postId).set({
      'userId': 'owner',
      'userName': 'صاحب الموضوع',
      'title': 'موضوع تجريبي',
      'content': 'نص الموضوع',
      'comments': 1,
      'isApproved': true,
    });
    await fake
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .doc('c1')
        .set({
      'userId': 'u1',
      'userName': 'أحمد',
      'userPhotoUrl': '',
      'text': 'تعليق باللون الأزرق',
      'createdAt': Timestamp.now(),
    });
    final svc = ForumService(fake);

    final post = ForumPost(
      id: postId,
      userId: 'owner',
      userName: 'صاحب الموضوع',
      title: 'موضوع تجريبي',
      content: 'نص الموضوع',
      comments: 1,
      createdAt: DateTime(2026),
    );

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      home: const SizedBox.shrink(),
    ));
    navKey.currentState!.push(
      MaterialPageRoute(
        settings: RouteSettings(name: '/forum/detail', arguments: post),
        builder: (_) => ForumPostDetailScreen(forumService: svc),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // جرس واحد فقط (QurityAppBar يضيفه تلقائياً — لا تكرار)
    expect(find.byType(NotificationBellButton), findsOneWidget);

    // نص التعليق حاضر وبلونه الأزرق
    final commentText = find.text('تعليق باللون الأزرق');
    expect(commentText, findsOneWidget);
    final textWidget = tester.widget<Text>(commentText);
    expect(textWidget.style?.color, const Color(0xFF1565C0));
  });
}
