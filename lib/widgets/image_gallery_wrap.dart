import 'package:flutter/material.dart';

import 'full_fit_image.dart';

/// معرض لعدة صور محتوى يُعرض **كاملًا بلا اقتصاص**: كل صورة تمر عبر
/// `FullFitImage` فيُقيس محرك العرض نسبتها الحقيقية ويرسمها بارتفاعها هي،
/// بدل إطار ثابت قصّ صور المستخدمين المرفوعة بمقاسات مختلفة.
///
/// المواضع التي تعرض قائمة `imageUrls` كاملة (صور المحل، صور العيادة/الصيدلية/
/// المعمل، صور محل النظارات، صور المراجعة، صور السجل في لوحة الإدارة، شبكة صور
/// البائع) تستعمل هذا الوست وحده، فلا تُعاد هندسة الشريط في كل شاشة.
///
/// التبديل من شريط أفقي بمقاس ثابت إلى `Wrap` مقصود: الارتفاعات المتفاوتة
/// لا تسع صفًا واحدًا بارتفاع موحّد، والاقتصاص هو ما يُصلَح هنا.
class ImageGalleryWrap extends StatelessWidget {
  const ImageGalleryWrap({
    super.key,
    required this.urls,
    required this.tileWidth,
    this.radius = 14,
    this.spacing = 10,
    this.fallbackColor,
  });

  final List<String> urls;
  final double tileWidth;
  final double radius;
  final double spacing;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = fallbackColor ?? theme.colorScheme.surfaceContainerHighest;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final url in urls)
          FullFitImage(
            imageUrl: url,
            width: tileWidth,
            radius: radius,
            tint: color,
            fallback: SizedBox(
              width: tileWidth,
              height: tileWidth,
              child: const Icon(Icons.broken_image_rounded, color: Colors.black26),
            ),
          ),
      ],
    );
  }
}
