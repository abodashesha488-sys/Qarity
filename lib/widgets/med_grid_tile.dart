import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// شبكة بطاقات الدليل — عمودان في كل سطر.
///
/// الارتفاع مطلق (`mainAxisExtent`) لا نسبة: البطاقة صورة معلومة الارتفاع ثم
/// أسطر نصّية محدودة، والنسبة تتقلّ مع العرض الضيّق فتُقصّ السطور على هواتف
/// ٣٦٠dp.
const SliverGridDelegateWithFixedCrossAxisCount kMedGridDelegate =
    SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 14,
  crossAxisSpacing: 14,
  mainAxisExtent: 252,
);

/// بطاقة سجل في شبكة عمودين: مساحة صورة تعلو الكارت يملؤها الرسم، ثم العنوان
/// وشارته، ثم وسومه، ثم سطر المواعيد والموقع — فتتساوى البطاقات ويقرأ السطر
/// اثنين منها.
///
/// تُستعمل في أدلة الخدمات الطبية (عيادات/صيدليات/معامل/نظارات)؛ وسم التعريف
/// (`badge`) والوسوم (`tags`) ووصف السجل (`subtitle`) كلها اختيارية، ولا يفيض
/// أي منها لأن النصّين الطويلين مقصوصان بـ ellipsis والوسوم تلتفّ داخل عرض
/// البطاقة.
class MedGridTile extends StatelessWidget {
  const MedGridTile({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.badge,
    this.tags = const <Widget>[],
    this.subtitle,
    this.goldBorder = false,
  });

  final String title;
  final String imageUrl;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final Widget? badge;
  final List<Widget> tags;
  final String? subtitle;
  final bool goldBorder;

  static const double imageHeight = 104;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: goldBorder
                ? const Color(0xFFB8860B)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: goldBorder ? 1.6 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: accent.withValues(alpha: 0.10)),
                  if (imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 520,
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) => Icon(icon, color: accent),
                    )
                  else
                    Icon(icon, color: accent),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 13.5)),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          badge!,
                        ],
                      ],
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Wrap(spacing: 6, runSpacing: 4, children: tags),
                    ],
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
