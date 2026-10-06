import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/app_colors.dart';
import 'package:qurity/core/theme/app_theme.dart';
import 'package:qurity/core/utils/comment_style.dart';

/// يبني سياقًا حقيقيًا تحت السمة المطلوبة لِيُقرأ منه تنسيق التعليق، لأن
/// CommentStyle صارت تقرأ الحبر من الثيم لا من ثابت.
Future<BuildContext> _contextUnder(WidgetTester tester, ThemeData theme) async {
  BuildContext? captured;
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Builder(builder: (context) {
      captured = context;
      return const SizedBox.shrink();
    }),
  ));
  return captured!;
}

/// عقد التنسيق الموحّد للتعليقات: كل مواضع التعليقات في التطبيق تستخدم
/// CommentStyle وحدها، فلا يعود موضع إلى خط صغير بألوان مختلفة.
void main() {
  const commentFiles = [
    'lib/features/news/view.dart',
    'lib/features/forum/post_detail.dart',
    'lib/features/forum/posts.dart',
    'lib/features/market/product_detail.dart',
    'lib/features/market/seller_reviews.dart',
    'lib/features/services/service_provider_detail_screen.dart',
    'lib/features/obituaries/detail.dart',
  ];

  testWidgets('CommentStyle هو الحجم الواضح المطلوب (لا bodySmall) وحبره حبر الثيم',
      (tester) async {
    final context = await _contextUnder(tester, AppTheme.lightTheme);
    final body = CommentStyle.body(context);
    expect(body.fontSize, greaterThanOrEqualTo(15));
    expect(body.color, AppTheme.lightTheme.colorScheme.onSurface);
    // في الفاتح حبر الثيم هو نص التطبيق الأساسي نفسه، فلا انحدار إلى باهت.
    expect(body.color, AppColors.textPrimary);
    expect(body.fontWeight!.value,
        greaterThanOrEqualTo(FontWeight.w500.value));
    expect(CommentStyle.author(context).fontSize, greaterThanOrEqualTo(13));
    expect(CommentStyle.avatarRadius, greaterThanOrEqualTo(18));
  });

  testWidgets('في الداكن يرتفع الحبر فلا يسودّ النص على البطاقات الداكنة',
      (tester) async {
    final context = await _contextUnder(tester, AppTheme.darkTheme);
    final body = CommentStyle.body(context);
    expect(body.color, AppTheme.darkTheme.colorScheme.onSurface);
    expect(body.color!.computeLuminance(), greaterThan(0.6));
    // الحجم والوزن قرار تنسيق واحد في السمتين؛ المختلف هو الحبر وحده.
    expect(body.fontSize, 15.5);
    expect(body.fontWeight, FontWeight.w600);
    expect(CommentStyle.author(context).color,
        AppTheme.darkTheme.colorScheme.primary);
  });

  test('كل ملف تعليقات يستورد CommentStyle ويستعمله لنص التعليق', () {
    for (final path in commentFiles) {
      final src = File(path).readAsStringSync();
      expect(src.contains('core/utils/comment_style.dart'), isTrue,
          reason: '$path يستورد تنسيق التعليقات');
      expect(src.contains('CommentStyle.body'), isTrue,
          reason: '$path يرسم نص التعليق بالتنسيق الموحّد');
      expect(src.contains('CommentStyle.avatarRadius'), isTrue,
          reason: '$path يستخدم نصف قطر الصورة الموحّد');
    }
  });

  test('لا رجوع إلى bodySmall/bodyMedium الممرّرة للتعليقات', () {
    for (final path in commentFiles) {
      final src = File(path).readAsStringSync();
      expect(
          RegExp(r'textTheme\.body(Small|Medium)\?\.copyWith\(\s*color: AppColors\.textPrimary')
              .hasMatch(src),
          isFalse,
          reason: '$path عاد لحجم الثيم الصغير بدل CommentStyle');
    }
  });

  test('لا صورة تُحمّل من رابط فارغ', () {
    expect(CommentStyle.photoProvider(null), isNull);
    expect(CommentStyle.photoProvider('   '), isNull);
    expect(CommentStyle.photoProvider('https://cdn.test/a.jpg'), isNotNull);
  });
}
