import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// تنسيق موحّد لنص التعليقات والمراجعات والتعازي في كل التطبيق.
///
/// كان كل موضع يمرّر `bodySmall`/`bodyMedium` من الثيم، وكلاهما يُحسب ~14 بكسل
/// بوزن w300/w400 هنا، فبدت التعليقات صغيرة وباهتة وبأحجام مختلفة بين الشاشات.
class CommentStyle {
  CommentStyle._();

  static const TextStyle body = TextStyle(
    fontSize: 15.5,
    height: 1.6,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle author = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  static const double avatarRadius = 20;

  /// صورة الكاتب من ملفه وقت العرض؛ لا صورة ⇒ null فترسم الواجهة حرف الاسم
  /// أو أيقونة الشخص (بلا محاولة تحميل رابط فارغ).
  static ImageProvider? photoProvider(String? url) {
    final trimmed = (url ?? '').trim();
    if (trimmed.isEmpty) return null;
    return CachedNetworkImageProvider(trimmed);
  }
}
