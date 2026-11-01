import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_config.dart';

class ImageUploadService {
  static const String _imgbbUploadUrl = 'https://api.imgbb.com/1/upload';
  static const String _imgbbDeleteUrl = 'https://api.imgbb.com/1/delete';

  /// يرفع صورة إلى Cloudinary (أو ImgBB كاحتياطي) ويعيد رابط الصورة الآمن.
  /// أي استجابة بلا رابط تُرمى كخطأ — لا يُقبل رابط فارغ إطلاقًا.
  Future<String> uploadImage(Uint8List bytes) async {
    final cloudName = AppConfig.cloudinaryCloudName.trim();
    final uploadPreset = AppConfig.cloudinaryUploadPreset.trim();

    // 1. الأولوية لـ Cloudinary (سيرفرات فائقة السرعة مع ضغط تلقائي وتحويل WebP)
    if (cloudName.isNotEmpty && uploadPreset.isNotEmpty) {
      try {
        final uploadUrl =
            'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
        final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
        request.fields['upload_preset'] = uploadPreset;
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: 'upload.jpg'),
        );

        final response = await request.send().timeout(
          const Duration(seconds: 40),
          onTimeout: () => throw Exception(
              'انتهت مهلة رفع الصورة — تحقق من الاتصال وأعد المحاولة'),
        );
        final responseBody = await response.stream.bytesToString();
        return parseUploadResponse(response.statusCode, responseBody);
      } catch (cloudinaryErr) {
        // إذا كان ImgBB متاحاً، نلجأ إليه كاحتياطي مؤقت لضمان عدم توقف المستخدم
        final imgbbKey = AppConfig.imgbbApiKey.trim();
        if (imgbbKey.isEmpty) {
          rethrow;
        }
      }
    }

    // 2. احتياطي: ImgBB في حال لم يُضبط Cloudinary
    final imgbbKey = AppConfig.imgbbApiKey.trim();
    if (imgbbKey.isNotEmpty) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_imgbbUploadUrl?key=$imgbbKey'),
      );
      request.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: 'upload.jpg'),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception(
            'انتهت مهلة رفع الصورة — تحقق من الاتصال وأعد المحاولة'),
      );
      final responseBody = await response.stream.bytesToString();
      return parseUploadResponse(response.statusCode, responseBody);
    }

    throw Exception(
        'إعدادات رفع الصور غير مضبوطة — يلزم ضبط Cloudinary أو IMGBB_API_KEY');
  }

  /// يفكّ استجابة السيرفر (يدعم Cloudinary و ImgBB):
  /// يرد الرابط فقط عند نجاح حقيقي، ويرمي رسالة مفهومة عند الفشل أو غياب الرابط.
  static String parseUploadResponse(int statusCode, String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      decoded = null;
    }

    if (statusCode == 200 && decoded is Map) {
      // استجابة Cloudinary: secure_url أو url
      final secureUrl = decoded['secure_url'] as String?;
      if (secureUrl != null && secureUrl.isNotEmpty) {
        return optimizeUrl(secureUrl);
      }
      final rawUrl = decoded['url'] as String?;
      if (rawUrl != null && rawUrl.isNotEmpty) {
        return optimizeUrl(rawUrl);
      }

      // استجابة ImgBB القديمة: data.url
      final data = decoded['data'];
      final imgbbUrl = data is Map ? data['url'] as String? : null;
      if (imgbbUrl != null && imgbbUrl.isNotEmpty) {
        return imgbbUrl;
      }
    }

    // في حالة الخطأ، استخراج السبب من استجابة السيرفر
    var reason = '';
    if (decoded is Map) {
      final error = decoded['error'];
      if (error is Map && error['message'] is String) {
        reason = error['message'] as String;
      } else if (error is String) {
        reason = error;
      }
    }

    if (reason.isEmpty) {
      reason =
          statusCode == 200 ? 'لم يرجع الخدمة رابط الصورة' : 'رمز $statusCode';
    }
    throw Exception('تعذّر رفع الصورة ($reason) — أعد المحاولة');
  }

  /// يُحسن روابط Cloudinary تلقائياً عبر إضافة تحويلات السيرفر:
  /// - [width]: أقصى عرض مطلوب للصورة (مثلاً 800px لكروت القوائم).
  /// - `q_auto`: ضغط الجودة التلقائي الذكي بدون فقدان ملحوظ بالعين.
  /// - `f_auto`: تسليم الصورة بصيغة WebP أو AVIF الخفيفة جداً تلقائياً حسب المتصفح/النظام.
  /// في حال كان الرابط قديماً (ImgBB أو غيره)، يُعاد كما هو دون أي تغيير.
  static String optimizeUrl(String url, {int? width}) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    if (trimmed.contains('res.cloudinary.com') &&
        trimmed.contains('/upload/')) {
      // تجنب تكرار التحويلات إذا كانت موجودة بالفعل
      if (trimmed.contains('/upload/w_') ||
          trimmed.contains('/upload/q_auto,f_auto/')) {
        return trimmed;
      }

      final transform =
          width != null ? 'w_$width,c_limit,q_auto,f_auto' : 'q_auto,f_auto';
      return trimmed.replaceFirst('/upload/', '/upload/$transform/');
    }

    return trimmed;
  }

  /// يستخرج مفتاح الحذف من URL الصورة لـ ImgBB إن وُجد.
  String? extractDeleteKey(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      return uri.queryParameters['delete_key'];
    } catch (_) {
      return null;
    }
  }

  /// يحذف صورة (يدعم Cloudinary بأمان عبر سيرفر Vercel، و ImgBB كاحتياطي).
  Future<void> deleteImage(String imageUrl) async {
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) return;

    // 1. حذف آمن من Cloudinary عبر سيرفر المشروع
    if (trimmed.contains('cloudinary.com')) {
      try {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token != null) {
          final endpoint = AppConfig.pushEndpoint.trim();
          if (endpoint.isNotEmpty) {
            await http
                .post(
                  Uri.parse(endpoint),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    'action': 'delete_image',
                    'url': trimmed,
                  }),
                )
                .timeout(const Duration(seconds: 8));
          }
        }
      } catch (_) {}
      return;
    }

    // 2. احتياطي: ImgBB القديم في حال وُجد مفتاح حذف
    final deleteKey = extractDeleteKey(trimmed);
    final apiKey = AppConfig.imgbbApiKey.trim();
    if (deleteKey != null && deleteKey.isNotEmpty && apiKey.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$_imgbbDeleteUrl?key=$apiKey'),
          body: {'delete_keys': deleteKey},
        );
      } catch (_) {}
    }
  }
}