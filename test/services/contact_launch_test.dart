import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/launch_link.dart';

/// اختبارات الجزء المعدّل فقط: ممرّ فتح روابط التواصل (هاتف/رسائل/واتساب/فيسبوك)
/// بعد أن أُزيلت بوّابة `canLaunchUrl` من كل التطبيق لأن الفحص القبلي كان يرجع
/// false على أندرويد 11+ عند حزم غير مصرّح برؤيتها، فتصمت الأزرار.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final seen = <String, dynamic>{};

  /// url_launcher على هذا المضيف لا يمرّ بالقناة القديمة وحدها: التنفيذ الفعلي
  /// تنفيذ سطح المكتب بأسماء طرق وردود مختلفة (`LaunchWithParams` بخريطة
  /// `{'value': …}` لا بوليانيًا)، فالمنفذ يردّ على القناة بالشكلين.
  /// `canLaunchUrl` لم تعد تُنادى إطلاقًا — `launchUrl` هو الدليل: `false` تعني
  /// «الفتح رُفض» والاستثناء تعني فشلًا.
  void stub({Object? launch = true, bool throwOnLaunch = false}) {
    seen.clear();
    void mock(MethodChannel channel, {required bool desktop}) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        seen[call.method] = call.arguments;
        if (throwOnLaunch) throw PlatformException(code: 'no-handler');
        if (desktop && call.method == 'LaunchWithParams') {
          return <String, Object?>{'value': launch};
        }
        return launch;
      });
    }

    mock(const MethodChannel('plugins.flutter.io/url_launcher'),
        desktop: false);
    mock(const MethodChannel('plugins.flutter.io/url_launcher_linux'),
        desktop: true);
  }

  String? launchedUrl() {
    final args = seen['LaunchWithParams'] ?? seen['launch'];
    return args is Map ? args['url'] as String? : args as String?;
  }

  group('المحرك المشترك launchContactUrl', () {
    test('الفتح الناجح بلا رسالة فشل، والمرحّل يمرّر الرابط حرفيًا', () async {
      stub();
      final error = await launchContactUrl('https://wa.me/201032231330',
          unavailable: 'غير متاح.', failed: 'تعذّر.');
      expect(error, isNull);
      expect(launchedUrl(), 'https://wa.me/201032231330');
    });

    test('الوضع الخارجي هو الافتراضي في المحرك، والداخلي يُطلب صراحةً', () {
      // هذه هي نقطة الإصلاح: الرابط يُفتح في التطبيق الخارجي لا في معاينة.
      expect(File('lib/core/utils/launch_link.dart').readAsStringSync(),
          contains('LaunchMode mode = LaunchMode.externalApplication'));
    });

    test('الرفض كلمةٌ صادقة، والاستثناء كلمةٌ أخرى', () async {
      stub(launch: false);
      expect(
          await launchContactUrl('https://x.test',
              unavailable: 'رُفض.', failed: 'انفجر.'),
          'رُفض.');
      stub(throwOnLaunch: true);
      expect(
          await launchContactUrl('https://x.test',
              unavailable: 'رُفض.', failed: 'انفجر.'),
          'انفجر.');
    });
  });

  group('أغلفة الهاتف والرسائل وواتساب', () {
    test('launchPhoneCall يبني tel: من الرقم المجرّد ويبلّغ الرفض بوضوح', () async {
      stub(launch: false);
      expect(await launchPhoneCall(' 01032231330 '), 'لا يمكن الاتصال على هذا الجهاز.');
      stub();
      expect(await launchPhoneCall('01032231330'), isNull);
      expect(launchedUrl(), 'tel:01032231330');
    });

    test('launchSms يبني sms: وله كلمته الخاصة', () async {
      stub(launch: false);
      expect(await launchSms('01032231330'),
          'لا يمكن فتح الرسائل على هذا الجهاز.');
      stub();
      expect(await launchSms('01032231330'), isNull);
      expect(launchedUrl(), 'sms:01032231330');
    });

    test('launchWhatsAppUrl يمرّر الرابط كما أُعطي ولا يبني عنوانًا', () async {
      stub(launch: false);
      expect(await launchWhatsAppUrl('https://wa.me/201032231330'),
          'واتساب غير متاح على هذا الجهاز.');
      stub();
      expect(await launchWhatsAppUrl('https://wa.me/201032231330'), isNull);
      expect(launchedUrl(), 'https://wa.me/201032231330');
    });
  });

  group('عقد المصدر: لا بوّابة قبل التجربة في أي موضع', () {
    test('لا ملف في lib/ ينادي canLaunchUrl', () {
      final offenders = <String>[];
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final body = file.readAsStringSync();
        for (final line in body.split('\n')) {
          final code = line.trim();
          if (code.startsWith('//') || code.startsWith('///')) continue;
          if (code.contains('canLaunchUrl')) {
            offenders.add('${file.path}: $code');
            break;
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'الفحص القبلي هو ما كان يُصمّت الأزرار على أندرويد 11+');
    });

    test('لا استيراد url_launcher إلا حيث يُطلب وضعٌ مغاير للافتراضي', () {
      // الوضع الافتراضي صار داخل المحرك؛ فمن يورّده صراحةً يحتاج سببًا واحدًا
      // مرئيًا (`platformDefault` للمكالمة/الرسائل).
      final users = <String, int>{};
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final body = file.readAsStringSync();
        if (!body.contains("import 'package:url_launcher/url_launcher.dart'")) {
          continue;
        }
        users[file.path] = RegExp('LaunchMode\\.').allMatches(body).length;
      }
      expect(users.values.every((n) => n >= 1), isTrue,
          reason: 'ملف يستورد المنفّذ بلا أي LaunchMode = بقي من قبل التوحيد');
      expect(users.keys, isNot(contains('lib/widgets/promo_host.dart')));
    });

    test('مواضع التواصل المعدّلة تمرّ بالمحرك المشترك', () {
      const sites = [
        'lib/features/home/about_app.dart',
        'lib/features/phone/directory.dart',
        'lib/features/services/service_directory_screen.dart',
        'lib/features/services/service_provider_detail_screen.dart',
        'lib/features/services/lost_items_screen.dart',
        'lib/features/market/seller_detail.dart',
        'lib/features/market/seller_profile.dart',
        'lib/features/market/product_detail.dart',
        'lib/features/market/market_tab_shops.dart',
        'lib/features/market/market_tab_buy_donate.dart',
        'lib/features/medical/medical_home_screen.dart',
        'lib/features/medical/clinic_detail_screen.dart',
        'lib/features/medical/optical_shop_detail_screen.dart',
        'lib/features/ads/village_ad_detail_screen.dart',
        'lib/features/legal/lawyer_detail_screen.dart',
        'lib/features/emergency/contacts.dart',
        'lib/widgets/promo_host.dart',
        'lib/widgets/agriculture_promo_banner.dart',
      ];
      for (final path in sites) {
        final body = File(path).readAsStringSync();
        // مواضع السوق أجزاء من مكتبة `market_tabs_screen.dart` فاستيراد
        // المحرك يسكن الملف المضيف وحده — النداء هو الدليل هنا.
        if (!body.contains("part of '")) {
          expect(body, contains('launch_link.dart'), reason: path);
        }
        expect(
          body,
          anyOf(
            contains('launchPhoneCall('),
            contains('launchSms('),
            contains('launchWhatsAppUrl('),
            contains('launchContactUrl('),
          ),
          reason: '$path لم يمرّ بالمحرك',
        );
      }
    });

    test('الدالة الميتة makePhoneCall لا تعود', () {
      expect(File('lib/core/utils/helpers.dart').readAsStringSync(),
          isNot(contains('makePhoneCall')));
    });

    test('الـ manifest صرّح برؤية واتساب وروابط التواصل (علّة أندرويد 11+)', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('<queries>'));
      expect(manifest, contains('com.whatsapp'));
      expect(manifest, contains('com.whatsapp.w4b'));
      expect(manifest, contains('android.intent.action.DIAL'));
      expect(manifest, contains('android.intent.action.SENDTO'));
      expect(manifest, contains('android:scheme="tel"'));
      expect(manifest, contains('android:scheme="sms"'));
      expect(manifest, contains('android:scheme="https"'));
    });
  });
}
