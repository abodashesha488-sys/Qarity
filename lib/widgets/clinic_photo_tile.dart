import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// صورة عيادة المركز الطبي الخيري: مربّع مقسّح بزوايا ناعمة، وأيقونة بديلة
/// حين لا توجد صورة أو فشل تحميلها — حتى لا يبدو السجل مكسوراً.
class ClinicPhotoTile extends StatelessWidget {
  const ClinicPhotoTile(
      {super.key,
      required this.imageUrl,
      this.side = 84,
      this.radius = 14,
      this.accent = const Color(0xFF00897B)});
  final String imageUrl;
  final double side;
  final double radius;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (imageUrl.isEmpty) return _fallback(brightness);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: side,
        height: side,
        fit: BoxFit.cover,
        memCacheWidth: (side * 3).round(),
        placeholder: (_, __) => Container(
          width: side,
          height: side,
          color: accent.withValues(alpha: 0.08),
        ),
        errorWidget: (_, __, ___) =>
            _fallback(Theme.of(context).brightness),
      ),
    );
  }

  Widget _fallback(Brightness brightness) {
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.medical_services_rounded,
          size: side * 0.45, color: AppColors.inkOn(accent, brightness)),
    );
  }
}
