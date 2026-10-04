import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// إطار معلوم المساحة لصورة الإعلان: عرضه كامل وارتفاعه ثابت، والصورة تملؤه
/// بـ`cover` — فلا يختلف ارتفاع البطاقة باختلاف مقاس صورة صاحب الإعلان.
class AdPhotoFrame extends StatelessWidget {
  const AdPhotoFrame({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.accent,
    this.radius = 0,
    this.icon = Icons.campaign_rounded,
  });

  final String imageUrl;
  final double height;
  final Color accent;
  final double radius;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: imageUrl.isEmpty
            ? _blank()
            : LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth.isFinite ? c.maxWidth : height;
                return CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheWidth: (w * 3).round(),
                  placeholder: (_, __) => _blank(),
                  errorWidget: (_, __, ___) => _blank(),
                );
              }),
      ),
    );
  }

  Widget _blank() => ColoredBox(
        color: accent.withValues(alpha: 0.10),
        child: Center(
          child: Icon(icon, size: 40, color: accent.withValues(alpha: 0.6)),
        ),
      );
}
