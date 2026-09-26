import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../core/constants/app_config.dart';

class ImageUploadResult {
  final String imageUrl;
  final String deleteUrl;
  const ImageUploadResult({required this.imageUrl, required this.deleteUrl});
}

class ImageUploadService {
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';
  static const String _deleteUrl = 'https://api.imgbb.com/1/delete';
  static const String _apiKey = AppConfig.imgbbApiKey;

  Future<ImageUploadResult> uploadImage(Uint8List bytes) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_uploadUrl?key=$_apiKey'));
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'upload.jpg'));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return ImageUploadResult(
        imageUrl: data['data']['url'] as String? ?? '',
        deleteUrl: data['data']['delete_url'] as String? ?? '',
      );
    }
    throw Exception('Failed to upload image: ${response.statusCode}');
  }

  String? extractDeleteKey(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      return uri.queryParameters['delete_key'];
    } catch (_) {
      return null;
    }
  }

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

  Future<void> deleteImageByUrl(String deleteUrl) async {
    if (deleteUrl.isEmpty) return;
    try {
      final uri = Uri.parse(deleteUrl);
      await http.get(uri);
    } catch (_) {}
  }
}
