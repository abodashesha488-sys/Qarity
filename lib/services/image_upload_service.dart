import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../core/constants/app_config.dart';

class ImageUploadService {
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';
  static const String _deleteUrl = 'https://api.imgbb.com/1/delete';
  static const String _apiKey = AppConfig.imgbbApiKey;

  /// يرفع صورة إلى ImgBB ويعيد URL بنتيجة الرفع.
  /// أي استجابة بلا رابط تُرمى كخطأ — لا يُقبل رابط فارغ إطلاقًا.
  Future<String> uploadImage(Uint8List bytes) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_uploadUrl?key=$_apiKey'));
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'upload.jpg'));

    final response = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception(
          'انتهت مهلة رفع الصورة — تحقق من الاتصال وأعد المحاولة'),
    );
    final responseBody = await response.stream.bytesToString();
    return parseUploadResponse(response.statusCode, responseBody);
  }

  /// يفكّ استجابة ImgBB: يرد الرابط فقط عند نجاح حقيقي، ويرمّي رسالة مفهومة
  /// عند الرفض أو عند غياب الرابط — وإلا ضاعت الصورة بصمت داخل السجل.
  static String parseUploadResponse(int statusCode, String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      decoded = null;
    }
    final data = decoded is Map ? decoded['data'] : null;
    final url = data is Map ? data['url'] as String? : null;
    if (statusCode == 200 && url != null && url.isNotEmpty) return url;

    final error = decoded is Map ? decoded['error'] : null;
    var reason = error is Map ? (error['message'] as String?) : null;
    if (reason == null || reason.isEmpty) {
      reason = statusCode == 200 ? 'لم يرجع الخدمة رابط الصورة' : 'رمز $statusCode';
    }
    throw Exception('تعذّر رفع الصورة ($reason) — أعد المحاولة');
  }

  /// يستخرج مفتاح الحذف من URL الصورة.
  /// مفتاح الحذف مخزّن داخل URL كمعلمة query: ?delete_key=xxx
  String? extractDeleteKey(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      return uri.queryParameters['delete_key'];
    } catch (_) {
      return null;
    }
  }

  /// يحذف صورة من ImgBB باستخدام مفتاح الحذف المستخرج من URL الصورة.
  /// النهج الحالي آمن لأن مفتاح الحذف غير هو مفتاح API.
  Future<void> deleteImage(String imageUrl) async {
    final deleteKey = extractDeleteKey(imageUrl);
    if (deleteKey != null && deleteKey.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$_deleteUrl?key=$_apiKey'),
          body: {'delete_keys': deleteKey},
        );
      } catch (_) {}
    }
  }
}
