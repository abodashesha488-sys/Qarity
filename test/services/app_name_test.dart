import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// «في شاشة الاسبلاش هناك كلمة "قريتي" اريد تغيرها الي "أبودشيشة" كما انني اريد
/// تغيير اسم التطبيق الذي سيظهر علي سطح المكتب او شاشة العميل الي "أبودشيشة"».
///
/// الاسم المعروض على الجهاز لا يسكن مكانًا واحدًا: كلمة الاسبلاش في Dart، وتسمية
/// المشغّل في `AndroidManifest`، و`CFBundleDisplayName` في iOS، و`name`/`short_name`
/// في manifest الويب (وهو ما يظهر تحت أيقونة PWA على سطح المكتب)، و
/// `apple-mobile-web-app-title` (تسمية الشاشة الرئيسية على iOS عند التركيب).
/// لذلك يثبت هذا الملف الخمسة معًا، ويثبت أن اسم حزمة Dart `qurity` **لم يُمسّ**
/// (فكل استيراد في المشروع `package:qurity/…` وتغييره يكسر البناء كاملًا).
void main() {
  String src(String path) => File(path).readAsStringSync();

  const kAppName = 'أبودشيشة';

  group('اسم التطبيق المعروض', () {
    test('الاسبلاش يقول «أبودشيشة» ولا بقي أثر لـ«قريتي»', () {
      final splash = src('lib/features/home/splash.dart');
      expect(splash, contains("'$kAppName'"));
      expect(splash, isNot(contains('قريتي')));
    });

    test('تسمية مشغّل أندرويد هي الاسم الجديد', () {
      final manifest = src('android/app/src/main/AndroidManifest.xml');
      expect(manifest, contains('android:label="$kAppName"'));
      expect(manifest, isNot(contains('android:label="قريتي"')));
    });

    test('iOS: اسم العرض جديد، و`CFBundleName` يبقى ASCII كما تشترط أبل', () {
      final plist = src('ios/Runner/Info.plist');
      expect(plist, contains('<string>$kAppName</string>'));
      expect(plist, isNot(contains('<string>Qarity</string>')));
      // أبل تشترط `CFBundleName` بالأحرف اللاتينية وبـ15 حرفًا كحدّ أقصى، فاسم
      // العرض وحده هو المتغيّر — والأسماء الداخلية تبقى كما هي كي لا ينكسر الحزمة.
      expect(plist, contains('<string>qarity</string>'));
    });

    test('ويب/PWA: manifest يحمل الاسم تحت الأيقونة وعلى شريط النافذة', () {
      final webManifest = src('web/manifest.json');
      expect(webManifest, contains('"name": "$kAppName"'));
      expect(webManifest, contains('"short_name": "$kAppName"'));
      expect(webManifest, isNot(contains('"name": "qarity"')));
    });

    test('index.html: تسمية الشاشة الرئيسية على iOS بلا اسم إنجليزي ولا خطأ إملائي', () {
      final html = src('web/index.html');
      expect(html, contains('content="$kAppName"'));
      expect(html, isNot(contains('قرية أبوديشة'))); // الصيغة الناقصة القديمة
    });

    test('اسم حزمة Dart بقي `qurity` كما هو', () {
      expect(
        src('pubspec.yaml').split('\n').first.trim(),
        'name: qurity',
      );
    });
  });
}
