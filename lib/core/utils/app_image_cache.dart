import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../services/image_upload_service.dart';

/// استجابة خدمة ملفات مخصصة تفرض مدة صلاحية لا تقل عن 90 يوماً في الكاش،
/// وتمنع محاولة إعادة التحقق من السيرفر عند وجود الصورة محلياً، مما يضمن عرضها أوفلاين بسرعة 0ms.
class _LongLivedFileServiceResponse implements FileServiceResponse {
  _LongLivedFileServiceResponse(this._inner)
      : _validTill = DateTime.now().add(const Duration(days: 90));

  final FileServiceResponse _inner;
  final DateTime _validTill;

  @override
  Stream<List<int>> get content => _inner.content;

  @override
  int? get contentLength => _inner.contentLength;

  @override
  String? get eTag => _inner.eTag;

  @override
  String get fileExtension => _inner.fileExtension;

  @override
  int get statusCode => _inner.statusCode;

  @override
  DateTime get validTill => _validTill;
}

/// استجابة احتياطية محلية تُرجع بايتات صورة وُجدت في الكاش القديم (DefaultCacheManager)
/// عند فشل الاتصال بالشبكة لضمان عدم فقدان أي صورة سبق فتحها قبل التحديث.
class _LocalFallbackFileResponse implements FileServiceResponse {
  _LocalFallbackFileResponse(this._bytes, this._path);

  final List<int> _bytes;
  final String _path;

  @override
  Stream<List<int>> get content => Stream.value(_bytes);

  @override
  int? get contentLength => _bytes.length;

  @override
  String? get eTag => null;

  @override
  String get fileExtension {
    final dot = _path.lastIndexOf('.');
    return dot != -1 ? _path.substring(dot) : '.jpg';
  }

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 90));
}

/// خدمة جلب الصور لـ AppImageCache مع تحصين كامل ضد انقطاع الشبكة واسترجاع كاش الطوارئ
class _AppLongLivedHttpFileService extends HttpFileService {
  _AppLongLivedHttpFileService();

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await super.get(url, headers: headers);
      return _LongLivedFileServiceResponse(response);
    } catch (_) {
      // إذا كان الجهاز غير متصل، نتحقق مما إذا كان الملف موجوداً في الكاش القديم
      try {
        final legacyFile = await DefaultCacheManager().getFileFromCache(url);
        if (legacyFile != null && await legacyFile.file.exists()) {
          final bytes = await legacyFile.file.readAsBytes();
          return _LocalFallbackFileResponse(bytes, legacyFile.file.path);
        }
      } catch (_) {}
      rethrow;
    }
  }
}

/// مدير ومكون الكاش الموحد لكافة صور تطبيق قرية أبوديشيشة
/// ----------------------------------------------------
/// يحفظ الصور في الذاكرة التخزينية (Disk Cache) للهاتف لمدة 90 يوماً
/// بسعة تصل إلى 2500 صورة، بمفتاح كاش موحد (Canonical Key) لكل صورة
/// لضمان ظهور الصور فوراً أوفلاين حتى لو اختلف مقاس العرض بين الشاشات.
class AppImageCache {
  static const String key = 'qarity_image_cache';

  /// مدير الكاش طويل الأمد (90 يوماً · 2500 ملف)
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 90),
      maxNrOfCacheObjects: 2500,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: _AppLongLivedHttpFileService(),
    ),
  );

  /// يستخرج المفتاح الكاشي الموحد (Canonical Cache Key) لأي رابط صورة:
  /// يضمن أن صورة المنتج/الخبر/العضو تشترك في نفس ملف الكاش على القرص
  /// بغض النظر عن المقاس المطلوب (سواء عُرضت في بطاقة صغيرة w_300، أو في شاشة التفاصيل w_800، أو الرابط الأصلي).
  static String canonicalKey(String url) {
    var clean = url.trim();
    if (clean.isEmpty) return clean;

    // 1. إزالة معاملات الاستعلام الزائدة (مثل ?delete_key=... أو ?t=...)
    final qIndex = clean.indexOf('?');
    if (qIndex != -1) {
      clean = clean.substring(0, qIndex);
    }

    // 2. توحيد روابط Cloudinary: إزالة أي تحويلات تحجيم أو جودة في المسار بعد /upload/
    // مثل: /upload/w_800,c_limit,q_auto,f_auto/v12345/abc.jpg -> /upload/v12345/abc.jpg
    if (clean.contains('res.cloudinary.com') && clean.contains('/upload/')) {
      clean = clean.replaceFirst(
        RegExp(r'/upload/(?:(?:w_\d+|h_\d+|c_\w+|q_\w+|f_\w+|e_\w+|b_\w+|dpr_\w+)[,/]?)+/'),
        '/upload/',
      );
    }

    // 3. توحيد صور Google Profiles: إزالة معاملات التحجيم مثل =s96-c
    if (clean.contains('googleusercontent.com')) {
      clean = clean.replaceFirst(RegExp(r'=s\d+(-c)?$'), '');
    }

    return clean;
  }

  /// ImageProvider مخصص مع كاش طويل الأمد ومفتاح موحد يضمن استدعاء الصورة أوفلاين
  static CachedNetworkImageProvider provider(
    String url, {
    int? targetWidth,
    String? cacheKey,
  }) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return const CachedNetworkImageProvider('');
    }
    final optimized = ImageUploadService.optimizeUrl(
      trimmed,
      width: targetWidth ?? 800,
    );
    return CachedNetworkImageProvider(
      optimized,
      cacheKey: cacheKey ?? canonicalKey(trimmed),
      cacheManager: instance,
    );
  }

  /// ودجت موحد لتحميل وعرض وتخزين الصور محلياً مع تصغير الحجم والاحتفاظ بها أوفلاين
  static Widget image({
    required String url,
    BoxFit? fit,
    double? width,
    double? height,
    int? targetWidth,
    String? cacheKey,
    Alignment alignment = Alignment.center,
    int? memCacheWidth,
    int? memCacheHeight,
    int? maxWidthDiskCache = 1200,
    int? maxHeightDiskCache = 1200,
    Duration fadeInDuration = const Duration(milliseconds: 300),
    Duration? fadeOutDuration,
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
      cacheKey: cacheKey ?? canonicalKey(trimmed),
      imageUrl: optimizedUrl,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
