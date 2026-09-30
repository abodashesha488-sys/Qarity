import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/image_upload_service.dart';

void main() {
  group('parseUploadResponse — لا رابط فارغ أبدًا', () {
    test('200 مع رابط صحيح يُرجعه كما هو', () {
      const body =
          '{"success":true,"data":{"url":"https://i.ibb.co/abc/upload.jpg"}}';
      expect(ImageUploadService.parseUploadResponse(200, body),
          'https://i.ibb.co/abc/upload.jpg');
    });

    test('200 بلا رابط ⇒ خطأ صريح (كان هذا يفقد الصورة بصمت)', () {
      expect(
          () => ImageUploadService.parseUploadResponse(
              200, '{"success":true,"data":{}}'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('تعذّر رفع الصورة') &&
              e.toString().contains('لم يرجع الخدمة رابط الصورة'))));
    });

    test('رفض ImgBB ينقل رسالتها إلى المستخدم', () {
      const body =
          '{"status":false,"error":{"message":"Image API monthly limit reached","code":402}}';
      expect(
          () => ImageUploadService.parseUploadResponse(400, body),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Image API monthly limit reached'))));
    });

    test('استجابة غير JSON أو رمز خطأ ⇒ رسالة برمز الحالة', () {
      expect(() => ImageUploadService.parseUploadResponse(500, '<html>'),
          throwsA(predicate(
              (e) => e is Exception && e.toString().contains('رمز 500'))));
    });
  });
}
