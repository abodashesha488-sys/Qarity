import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/app_image_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('AppImageCache — مدير الكاش الموحد للصور', () {
    test('key معرّف بشكل صحيح', () {
      expect(AppImageCache.key, 'qarity_image_cache');
    });

    test('provider ينشئ CachedNetworkImageProvider مع الكاش المخصص', () {
      final provider = AppImageCache.provider('https://example.com/image.jpg');
      expect(provider, isNotNull);
      expect(provider.cacheKey, 'https://example.com/image.jpg');
    });

    test('canonicalKey يوحد روابط Cloudinary بمختلف مقاساتها', () {
      const transformed800 =
          'https://res.cloudinary.com/demo/image/upload/w_800,c_limit,q_auto,f_auto/v123456/sample.jpg';
      const transformed300 =
          'https://res.cloudinary.com/demo/image/upload/w_300,c_limit,q_auto,f_auto/v123456/sample.jpg';
      const transformedQ =
          'https://res.cloudinary.com/demo/image/upload/q_auto,f_auto/v123456/sample.jpg';
      const raw =
          'https://res.cloudinary.com/demo/image/upload/v123456/sample.jpg';

      final key1 = AppImageCache.canonicalKey(transformed800);
      final key2 = AppImageCache.canonicalKey(transformed300);
      final key3 = AppImageCache.canonicalKey(transformedQ);
      final key4 = AppImageCache.canonicalKey(raw);

      expect(key1, raw);
      expect(key2, raw);
      expect(key3, raw);
      expect(key4, raw);
    });

    test('canonicalKey ينظف معاملات الاستعلام وصور جوجل', () {
      const withQuery = 'https://i.ibb.co/123/img.jpg?delete_key=abc&t=99';
      expect(AppImageCache.canonicalKey(withQuery), 'https://i.ibb.co/123/img.jpg');

      const googleAvatar = 'https://lh3.googleusercontent.com/a/ACg8oc=s96-c';
      expect(AppImageCache.canonicalKey(googleAvatar), 'https://lh3.googleusercontent.com/a/ACg8oc');
    });

    test('image widget يتعامل بسلاسة مع الروابط الفارغة', () {
      final widget = AppImageCache.image(url: '');
      expect(widget, isNotNull);
    });
  });
}
