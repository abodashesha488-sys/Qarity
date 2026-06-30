import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImageUploadService {
  static const String _apiKey = '5adf17954a21d7d9146824fde7061c6d';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

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
      await http.post(Uri.parse('https://api.imgbb.com/1/delete?key=$_apiKey'), body: {'delete_keys': deleteKey});
    }
  }
}