import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_design_tokens.dart';

/// قائمة تحميل هيكلية (Skeleton Shimmer) أفقية للبطاقات في الشاشة الرئيسية،
/// تحاكي أبعاد البطاقات الحقيقية وتستبدل المساحات الفارغة أثناء جلب البيانات.
class QarityHorizontalShimmerList extends StatelessWidget {
  const QarityHorizontalShimmerList({
    super.key,
    this.height = 148,
    this.itemWidth = 148,
    this.itemCount = 4,
    this.imageHeight = 64,
  });

  final double height;
  final double itemWidth;
  final int itemCount;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final surface = Theme.of(context).colorScheme.surface;

    return SizedBox(
      height: height,
      child: Shimmer.fromColors(
        baseColor: tokens.shimmerBase,
        highlightColor: tokens.shimmerHighlight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, __) => Container(
            width: itemWidth,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: tokens.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: imageHeight,
                  width: double.infinity,
                  color: Colors.white,
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 11,
                        width: itemWidth * 0.72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 9,
                        width: itemWidth * 0.48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
