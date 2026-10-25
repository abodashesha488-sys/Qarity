import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';

/// 🎬 أداة مساعدة لاستخراج معرّف يوتيوب والصورة المصغّرة وتشغيل الفيديو داخل التطبيق
class VillageVideoHelper {
  VillageVideoHelper._();

  /// استخراج معرّف فيديو YouTube من مختلف صيغ الروابط
  static String? extractYoutubeId(String url) {
    if (url.isEmpty) return null;
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    // صيغة: youtu.be/<id>
    if (uri.host.contains('youtu.be')) {
      final segs = uri.pathSegments;
      if (segs.isNotEmpty && segs.first.isNotEmpty) return segs.first;
    }

    // صيغة: youtube.com/watch?v=<id>
    if (uri.host.contains('youtube.com')) {
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
      // صيغة: youtube.com/shorts/<id> أو youtube.com/embed/<id>
      final segs = uri.pathSegments;
      if (segs.length >= 2 && (segs[0] == 'shorts' || segs[0] == 'embed')) {
        return segs[1];
      }
    }

    // فحص بالـ Regex لأي روابط غير قياسية
    final regExp = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\w-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    return match?.group(1);
  }

  /// الحصول على الصورة المصغرة عالية الدقة ليوتيوب
  static String? getYoutubeThumbnail(String url) {
    final id = extractYoutubeId(url);
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  /// تشغيل الفيديو داخل التطبيق مباشرة دون مغادرته
  static Future<void> playInApp(
    BuildContext context,
    String url, {
    String title = 'مشاهدة الفيديو',
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رابط الفيديو غير متوفر')),
        );
      }
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;

    try {
      // محاولة العرض داخل التطبيق عبر In-App Browser View
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر فتح الفيديو: $e')),
          );
        }
      }
    }
  }
}

/// 📽️ بطاقة فيديو أنيقة للقرية تدعم YouTube والروابط المباشرة وتظهر كبطاقة وسائط حية
class VillageVideoCard extends StatelessWidget {
  const VillageVideoCard({
    super.key,
    required this.title,
    required this.videoUrl,
    this.description = '',
    this.customThumbnail = '',
    this.source = 'قرية أبوديشيشة',
    this.onDelete,
    this.onEdit,
    this.canManage = false,
  });

  final String title;
  final String videoUrl;
  final String description;
  final String customThumbnail;
  final String source;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ytThumb = VillageVideoHelper.getYoutubeThumbnail(videoUrl);
    final finalThumb = customThumbnail.isNotEmpty
        ? customThumbnail
        : (ytThumb ?? '');

    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFC62828).withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => VillageVideoHelper.playInApp(context, videoUrl, title: title),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── مشغل الفيديو المصغر مع زر التشغيل ──
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: finalThumb.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: finalThumb,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(
                            color: Colors.black87,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => _fallbackCover(),
                        )
                      : _fallbackCover(),
                ),
                // طبقة تدرج مظللة
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),
                // زر التشغيل الأحمر المميز
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                // شارة يوتيوب أو فيديو القرية
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_rounded, size: 14, color: Colors.redAccent),
                        SizedBox(width: 5),
                        Text(
                          'فيديو من القرية',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // تنبيه تشغيل الفيديو
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_rounded, size: 13, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          'اضغط للمشاهدة الآن',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // ── تفاصيل الفيديو ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (canManage) ...[
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: theme.colorScheme.primary,
                            tooltip: 'تعديل',
                            onPressed: onEdit,
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            color: Colors.redAccent,
                            tooltip: 'حذف',
                            onPressed: onDelete,
                          ),
                      ],
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.source_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        source,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => VillageVideoHelper.playInApp(context, videoUrl, title: title),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC62828),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                        label: const Text(
                          'تشغيل الفيديو',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return const ColoredBox(
      color: Color(0xFF1E1E1E),
      child: Center(
        child: Icon(
          Icons.movie_creation_rounded,
          color: Colors.white24,
          size: 60,
        ),
      ),
    );
  }
}
