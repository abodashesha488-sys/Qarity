import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/app_colors.dart';
import 'package:qurity/core/utils/comment_style.dart';

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

  test('CommentStyle هو الحجم الواضح المطلوب (لا bodySmall)', () {
    expect(CommentStyle.body.fontSize, greaterThanOrEqualTo(15));
    expect(CommentStyle.body.color, AppColors.textPrimary);
    expect(CommentStyle.body.fontWeight!.value,
        greaterThanOrEqualTo(FontWeight.w500.value));
    expect(CommentStyle.author.fontSize, greaterThanOrEqualTo(13));
    expect(CommentStyle.avatarRadius, greaterThanOrEqualTo(18));
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
