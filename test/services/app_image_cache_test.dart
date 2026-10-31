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
    });

    test('image widget يتعامل بسلاسة مع الروابط الفارغة', () {
      final widget = AppImageCache.image(url: '');
      expect(widget, isNotNull);
    });
  });
}
