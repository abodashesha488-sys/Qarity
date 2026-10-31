import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../services/image_upload_service.dart';

/// مدير ومكون الكاش الموحد لكافة صور تطبيق قرية أبوديشيشة
/// ----------------------------------------------------
/// يحفظ الصور في الذاكرة التخزينية (Disk Cache) للهاتف لمدة 90 يوماً
/// بسعة تصل إلى 2500 صورة، حتى لا يحتاج التطبيق لإعادة طلب أي صورة سبق فتحها.
class AppImageCache {
  static const String key = 'qarity_image_cache';

  /// مدير الكاش طويل الأمد (90 يوماً · 2500 ملف)
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 90),
      maxNrOfCacheObjects: 2500,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  /// ImageProvider مخصص مع كاش طويل الأمد
  static ImageProvider provider(String url, {int? targetWidth}) {
    final optimized = ImageUploadService.optimizeUrl(
      url,
      width: targetWidth ?? 800,
    );
    return CachedNetworkImageProvider(
      optimized,
      cacheManager: instance,
    );
  }

  /// ودجت موحد لتحميل وعرض وتخزين الصور محلياً مع تصغير الحجم
  static Widget image({
    required String url,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    int? targetWidth,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
  }) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return placeholder != null
          ? Builder(builder: (ctx) => placeholder(ctx, trimmed))
          : const SizedBox.shrink();
    }

    final optimizedUrl = ImageUploadService.optimizeUrl(
      trimmed,
      width: targetWidth ?? (width != null ? (width * 2.5).ceil() : 800),
    );

    return CachedNetworkImage(
      cacheManager: instance,
      imageUrl: optimizedUrl,
      fit: fit,
      width: width,
      height: height,
      maxWidthDiskCache: 1200,
      maxHeightDiskCache: 1200,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}

