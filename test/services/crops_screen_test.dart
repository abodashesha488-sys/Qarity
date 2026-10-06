import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/services/crops_screen.dart';
import 'package:qurity/services/agriculture_content_service.dart';

/// اختبارات شاشة المحاصيل الزراعية: الصور أصبحت أصولًا محلية مضمّنة،
/// وصفحة كل محصول تعرض بيانات موثقة (مدة النمو، معدل البذار، المصدر العلمي).
void main() {
  testWidgets('الشبكة تعرض المحاصيل بصورها المحلية المضمّنة', (tester) async {
    final fake = FakeFirebaseFirestore();
    await tester.pumpWidget(MaterialApp(
      home: CropsScreen(
          contentService: AgricultureContentService(fake)),
    ));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    // أول محصولين ظاهران في الشبكة
    expect(find.text('القمح'), findsOneWidget);
    expect(find.text('الأرز'), findsOneWidget);

    // صورة القمح أصل محلي (لا رابط شبكي)
    final wheatImage = _assetImage(tester, 'assets/images/crops/wheat.jpg');
    expect(wheatImage, isNotNull,
        reason: 'بطاقة القمح يجب أن تستخدم assets/images/crops/wheat.jpg');

    // التمرير لإظهار بقية المحاصيل
    await tester.dragUntilVisible(
      find.text('البرسيم الحجازي'),
      find.byType(GridView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('البرسيم الحجازي'), findsOneWidget);
    expect(_assetImage(tester, 'assets/images/crops/alfalfa.jpg'), isNotNull);
  });

  testWidgets('صفحة المحصول تعرض الحقول الموثقة الجديدة', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: CropDetailScreen(crop: _wheat)));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    // شبكة البيانات السريعة الجديدة
    expect(find.text('150 - 165 يومًا'), findsOneWidget);
    expect(find.text('60 - 70 كجم بذار/فدان'), findsOneWidget);
    expect(find.text('المصدر العلمي والمراجع'), findsOneWidget);
    expect(
        find.text('معهد بحوث المحاصيل الحقلية - قسم بحوث القمح، مركز البحوث '
            'الزراعية'),
        findsOneWidget);

    // الصورة الرئيسية أصل محلي
    final image = _assetImage(tester, 'assets/images/crops/wheat.jpg');
    expect(image, isNotNull);
  });

  test('كل سجل محصول يملك صورة محلية موجودة وسليمة في الحزمة', () {
    final source =
        File('lib/features/services/crops_screen.dart').readAsStringSync();
    final refs = RegExp(r"image:\s*'(assets/images/crops/[^']+\.(?:jpg|jpeg|png))'")
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toList();

    // 35 محصولًا: الأربعة عشر الأصلية + واحد وعشرون مضافة
    expect(refs.length, 35, reason: 'عدد صور المحاصيل في المصدر');
    expect(refs.toSet().length, refs.length,
        reason: 'لا يجوز أن يتشارك محصولان نفس الصورة');

    for (final asset in refs) {
      final file = File(asset);
      expect(file.existsSync(), isTrue, reason: 'ناقص: $asset');
      final length = file.lengthSync();
      expect(length, greaterThan(300), reason: 'حجم غير سليم: $asset ($length)');
    }
  });
}

/// يجد أول Image يستخدم أصلًا محليًا بالاسم المحدد، أو يعيد null.
/// ملاحظة: Image.asset مع cacheWidth يغلّف AssetImage داخل ResizeImage.
Image? _assetImage(WidgetTester tester, String assetName) {
  final images = tester.widgetList<Image>(find.byType(Image));
  for (final img in images) {
    var provider = img.image;
    if (provider is ResizeImage) provider = provider.imageProvider;
    if (provider is AssetImage && provider.assetName == assetName) {
      return img;
    }
  }
  return null;
}

const _wheat = CropRecord(
  name: 'القمح',
  scientificName: 'Triticum aestivum',
  nameEn: 'Wheat',
  image: 'assets/images/crops/wheat.jpg',
  season: 'شتوي (نوفمبر - أبريل)',
  region: 'شمال ووسط الدلتا',
  description: 'القمح هو المحصول الاستراتيجي الأول في مصر.',
  growthPeriod: '150 - 165 يومًا',
  seedRate: '60 - 70 كجم بذار/فدان',
  soilType: 'طينية ثقيلة - جيدة الصرف',
  irrigation: 'غمر: كل 10-15 يوم',
  fertilization: 'أزوت: 100-120 كجم/فدان',
  pests: 'صدأ القمح',
  varieties: 'جميزة 11، سوهاج 3',
  yieldTarget: '18-22 أردب/فدان',
  plantingMethod: 'بذار مباشر على خطوط',
  harvestMethod: 'حصاد آلي عند نضج الحبوب',
  economicImportance: 'المحصول الاستراتيجي الأول',
  source:
      'معهد بحوث المحاصيل الحقلية - قسم بحوث القمح، مركز البحوث الزراعية',
);
