import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/image_upload_service.dart';

void main() {
  group('parseUploadResponse — لا رابط فارغ أبدًا (ImgBB & Cloudinary)', () {
    test('ImgBB: 200 مع رابط صحيح يُرجعه كما هو', () {
      const body =
          '{"success":true,"data":{"url":"https://i.ibb.co/abc/upload.jpg"}}';
      expect(ImageUploadService.parseUploadResponse(200, body),
          'https://i.ibb.co/abc/upload.jpg');
    });

    test('ImgBB: 200 بلا رابط ⇒ خطأ صريح (كان هذا يفقد الصورة بصمت)', () {
      expect(
          () => ImageUploadService.parseUploadResponse(
              200, '{"success":true,"data":{}}'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('تعذّر رفع الصورة') &&
              e.toString().contains('لم يرجع الخدمة رابط الصورة'))));
    });

    test('ImgBB: رفض ImgBB ينقل رسالتها إلى المستخدم', () {
      const body =
          '{"status":false,"error":{"message":"Image API monthly limit reached","code":402}}';
      expect(
          () => ImageUploadService.parseUploadResponse(400, body),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Image API monthly limit reached'))));
    });

    test('استجابة غير JSON أو رمز خطأ ⇒ رسالة برمز الحالة', () {
      expect(
          () => ImageUploadService.parseUploadResponse(500, '<html>'),
          throwsA(predicate(
              (e) => e is Exception && e.toString().contains('رمز 500'))));
    });

    test('Cloudinary: 200 مع secure_url يُرجعه محسّنًا بـ q_auto,f_auto', () {
      const body =
          '{"secure_url":"https://res.cloudinary.com/ygfhtwug/image/upload/v1730331000/sample.jpg"}';
      expect(
        ImageUploadService.parseUploadResponse(200, body),
        'https://res.cloudinary.com/ygfhtwug/image/upload/q_auto,f_auto/v1730331000/sample.jpg',
      );
    });

    test('Cloudinary: خطأ في الـ preset ينقل الرسالة للمستخدم بوضوح', () {
      const body =
          '{"error":{"message":"Upload preset must be specified when using unsigned upload"}}';
      expect(
          () => ImageUploadService.parseUploadResponse(400, body),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Upload preset must be specified'))));
    });
  });

  group('optimizeUrl — تحسين روابط Cloudinary التلقائي', () {
    test('يضيف تحويلات q_auto,f_auto الافتراضية لرابط Cloudinary', () {
      const original =
          'https://res.cloudinary.com/ygfhtwug/image/upload/v1234/test.jpg';
      expect(
        ImageUploadService.optimizeUrl(original),
        'https://res.cloudinary.com/ygfhtwug/image/upload/q_auto,f_auto/v1234/test.jpg',
      );
    });

    test('يضيف تحويلات العرض المحدد w_800 مع c_limit و q_auto,f_auto', () {
      const original =
          'https://res.cloudinary.com/ygfhtwug/image/upload/v1234/test.jpg';
      expect(
        ImageUploadService.optimizeUrl(original, width: 800),
        'https://res.cloudinary.com/ygfhtwug/image/upload/w_800,c_limit,q_auto,f_auto/v1234/test.jpg',
      );
    });

    test('يتجنب التكرار إذا كان الرابط يحتوي بالفعل على تحويلات', () {
      const withWidth =
          'https://res.cloudinary.com/ygfhtwug/image/upload/w_500,c_limit/v1234/test.jpg';
      expect(ImageUploadService.optimizeUrl(withWidth, width: 800), withWidth);

      const withAuto =
          'https://res.cloudinary.com/ygfhtwug/image/upload/q_auto,f_auto/v1234/test.jpg';
      expect(ImageUploadService.optimizeUrl(withAuto), withAuto);
    });

    test('يترك الروابط الخارجية (مثل ImgBB) بدون تغيير', () {
      const imgbb = 'https://i.ibb.co/abc/photo.jpg';
      expect(ImageUploadService.optimizeUrl(imgbb, width: 800), imgbb);
    });

    test('يتعامل بسلاسة مع الروابط الفارغة', () {
      expect(ImageUploadService.optimizeUrl(''), '');
      expect(ImageUploadService.optimizeUrl('   '), '');
    });
  });
}
