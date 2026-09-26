import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../core/constants/app_config.dart';

class ImageUploadService {
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';
  static const String _deleteUrl = 'https://api.imgbb.com/1/delete';
  static const String _apiKey = AppConfig.imgbbApiKey;

  /// يرفع صورة إلى ImgBB ويعيد URL بنتيجة الرفع.
  /// يُخزّن مفتاح الحذف (delete_key) داخل URL كمعلمة استعلام.
  Future<String> uploadImage(Uint8List bytes) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_uploadUrl?key=$_apiKey'));
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'upload.jpg'));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return data['data']['url'] as String? ?? '';
    }
    throw Exception('Failed to upload image: ${response.statusCode}');
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
