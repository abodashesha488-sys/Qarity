import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// عقود مصدر لموجة «تصغير أيقونات البوابتين» (المهمة الثالثة من قائمة المستخدم):
///
/// «صفحة "الخدمات الطبية" وصفحة "خدمات المزارع" يجب تقليل حجم أيقونات الصفحات
/// الفرعية داخل كلتيهما … مع الإبقاء على خصائص الصفحات ولا تعديل غير حجم
/// الأيقونات فقط، بحيث تظهر الصفحات بشكل متسق ومريح للعين دون اقتصاص أي سجل»
/// + «مع ملاحظة ان هذا التعديل خاص بهذا الأمر ولا يمت بأي صله لموضوع او تعديل سابق».
///
/// لذلك يثبت هذا الملف أمرين معًا: أن **الأيقونة وحدها** صغُرت (تُرسم عند 0.7 من
/// بلاطتها ومتمركزة فوق أرضيتها)، وأن **كل ما عداها لم يُمسّ** — مرتِّب الشبكة
/// ومحسوب الصفوف والحشو والإطار والظل وأرضية `Material` ومنطقة النقر وسلسلة
/// `flutter_animate` و`cacheWidth` — وهي المواضع التي تُثبِّتها كذلك عقود قائمة
/// في `med_grid_tile_test.dart` و`standalone_service_pages_test.dart` و
/// `medical_center_clinic_test.dart`.
///
/// كل محكّى هنا حرفية ASCII واحدة السطر: ملفات المستودع CRLF فعقد متعدد الأسطر
/// لا يطابق أبدًا. والملف الطبي يطول خارج البلاطة (`child: Center(` عند :828 و:912،
/// و`Clip.antiAlias` عند :1854 و:1878، و`BoxFit.cover` عند :1882، وستة `onTap:`)
/// فقراءته تُقطع من منطقة بلاطة القسم وحدها، وإلا كان العقد أخضر على ملف سليم.
void main() {
  String src(String path) => File(path).readAsStringSync();

  /// يقطع مقطع بلاطة البوابة الطبية وحدها من المصدر الكامل.
  String medicalTile(String text) {
    final from = text.indexOf('class _MedicalSectionTile extends StatelessWidget {');
    final to = text.indexOf('class MedicalSectionScreen extends StatefulWidget {');
    expect(from, greaterThanOrEqualTo(0), reason: 'بلاطة البوابة الطبية مفقودة من المصدر');
    expect(to, greaterThan(from), reason: 'نهاية مقطع البلاطة الطبية مفقودة من المصدر');
    return text.substring(from, to);
  }

  /// يقطع مقطع بلاطة بوابة المزارع وحدها.
  String farmerTile(String text) {
    final from = text.indexOf('class _ServiceTile extends StatelessWidget {');
    final to = text.indexOf('class _FarmerService {');
    expect(from, greaterThanOrEqualTo(0), reason: 'بلاطة بوابة المزارع مفقودة من المصدر');
    expect(to, greaterThan(from), reason: 'نهاية مقطع بلاطة المزارع مفقودة من المصدر');
    return text.substring(from, to);
  }

  int count(String text, String pattern) => text.split(pattern).length - 1;

  const medicalPath = 'lib/features/medical/medical_home_screen.dart';
  const farmerPath = 'lib/features/services/farmer_services_screen.dart';

  group('الأيقونة مصغّرة عند 0.7 من بلاطتها ومتمركزة', () {
    test('البوابة الطبية: `Center` + `FractionallySizedBox(0.7, 0.7)` حول `Image.asset` — مرة واحدة', () {
      final tile = medicalTile(src(medicalPath));
      expect(count(tile, 'child: Center('), 1);
      expect(count(tile, 'child: FractionallySizedBox('), 1);
      expect(count(tile, 'widthFactor: 0.7'), 1);
      expect(count(tile, 'heightFactor: 0.7'), 1);
      expect(count(tile, 'child: Image.asset('), 1);
      expect(count(tile, 'width: double.infinity'), 1);
      expect(count(tile, 'height: double.infinity'), 1);
      expect(count(tile, 'fit: BoxFit.cover'), 1);
      expect(count(tile, 'cacheWidth: 520'), 1);
    });

    test('بوابة المزارع: نفس الغلاف بمقاس واحد', () {
      final tile = farmerTile(src(farmerPath));
      expect(count(tile, 'child: Center('), 1);
      expect(count(tile, 'child: FractionallySizedBox('), 1);
      expect(count(tile, 'widthFactor: 0.7'), 1);
      expect(count(tile, 'heightFactor: 0.7'), 1);
      expect(count(tile, 'child: Image.asset('), 1);
      expect(count(tile, 'width: double.infinity'), 1);
      expect(count(tile, 'height: double.infinity'), 1);
      expect(count(tile, 'fit: BoxFit.cover'), 1);
      expect(count(tile, 'cacheWidth: 520'), 1);
    });

    test('النقر يلفّ البلاطة كاملة لا الأيقونة: `onTap` يسبق `child: Center(`', () {
      final medical = medicalTile(src(medicalPath));
      expect(
          medical.indexOf(
              "Navigator.pushNamed(context, '/medical/section', arguments: index)"),
          lessThan(medical.indexOf('child: Center(')));
      final farmer = farmerTile(src(farmerPath));
      expect(farmer.indexOf('onTap: () => Navigator.pushNamed(context, service.route)'),
          lessThan(farmer.indexOf('child: Center(')));
    });
  });

  group('إطار البلاطة وأرضيتها وظلّها ورسوميتها كما كانت', () {
    test('الطبية: `Container` بحرف `Material(colorScheme.surface)` وظل وأنتي-ألياس', () {
      final tile = medicalTile(src(medicalPath));
      expect(count(tile, 'final radius = BorderRadius.circular(22);'), 1);
      expect(count(tile, 'decoration: BoxDecoration('), 1);
      expect(count(tile, 'borderRadius: radius,'), 2);
      expect(count(tile, 'color: Colors.black.withValues(alpha: 0.26),'), 1);
      expect(count(tile, 'blurRadius: 12,'), 1);
      expect(count(tile, 'offset: const Offset(0, 5),'), 1);
      expect(count(tile, 'clipBehavior: Clip.antiAlias,'), 1);
      expect(count(tile, 'child: Material('), 1);
      expect(count(tile, 'color: Theme.of(context).colorScheme.surface,'), 1);
      expect(count(tile, 'child: InkWell('), 1);
      expect(count(tile, 'borderRadius: radius,'), 2);
    });

    test('المزارع: نفس الإطار والظل والحرف وسلسلة الأنميشن', () {
      final tile = farmerTile(src(farmerPath));
      expect(count(tile, 'final radius = BorderRadius.circular(22);'), 1);
      expect(count(tile, 'color: Colors.black.withValues(alpha: 0.26),'), 1);
      expect(count(tile, 'blurRadius: 12,'), 1);
      expect(count(tile, 'offset: const Offset(0, 5),'), 1);
      expect(count(tile, 'clipBehavior: Clip.antiAlias,'), 1);
      expect(count(tile, 'child: Material('), 1);
      expect(count(tile, 'color: Theme.of(context).colorScheme.surface,'), 1);
      expect(count(tile, 'child: InkWell('), 1);
      expect(count(tile, '.animate(delay: (index * 45).ms).fadeIn(duration: 350.ms).scale('), 1);
      expect(count(tile, 'begin: const Offset(0.92, 0.92),'), 1);
      expect(count(tile, 'errorBuilder: (context, error, stackTrace) => Center('), 1);
    });
  });

  group('هندسة الشبكة لم تُمسّ: أربعة صفوف بمقام أربعة وثلاثة فراغات', () {
    test('الطبية: محسوب على `(maxHeight - vPadding - 3 * spacing) / 4` وبلاطة في عمودين', () {
      final text = src(medicalPath);
      expect(count(text, 'body: LayoutBuilder(builder: (context, box) {'), 1);
      expect(count(text, 'const vPadding = 16.0 + 28.0;'), 1);
      expect(count(text, 'const spacing = 16.0;'), 1);
      expect(count(text, '((box.maxHeight - vPadding - 3 * spacing) / 4)'), 1);
      expect(count(text, '.clamp(88.0, 240.0)'), 1);
      expect(count(text, 'crossAxisCount: 2,'), 1);
      expect(count(text, 'mainAxisExtent: extent'), 1);
      expect(count(text, 'padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),'), 1);
      expect(count(text, 'itemCount: _sections.length,'), 1);
    });

    test('المزارع: مقام البوابة مع كتلة العنوان كما كان', () {
      final text = src(farmerPath);
      expect(count(text, 'body: LayoutBuilder(builder: (context, box) {'), 1);
      expect(count(text, 'const titleBlock = 16.0 + 4.0 + 32.0;'), 1);
      expect(count(text, 'const vPadding = 12.0 + 28.0;'), 1);
      expect(count(text, 'const spacing = 16.0;'), 1);
      expect(count(text, '((box.maxHeight - titleBlock - vPadding - 3 * spacing) / 4)'), 1);
      expect(count(text, '.clamp(88.0, 240.0)'), 1);
      expect(count(text, 'crossAxisCount: 2,'), 1);
      expect(count(text, 'mainAxisExtent: extent,'), 1);
    });
  });

  group('لا انحدار: التصغير للصورة لا للبلاطة', () {
    test('البوابتان لا تخفضان `cacheWidth` ولا يستعملان نسبة ارتفاع بديلة للمقام', () {
      final medical = medicalTile(src(medicalPath));
      final farmer = farmerTile(src(farmerPath));
      expect(count(medical, 'cacheWidth: 520'), 1);
      expect(count(farmer, 'cacheWidth: 520'), 1);
      expect(count(medical, 'widthFactor'), 1);
      expect(count(medical, 'heightFactor'), 1);
      expect(count(farmer, 'widthFactor'), 1);
      expect(count(farmer, 'heightFactor'), 1);
    });

    test('سجلّات البوابتين بعددها وترتيبها وحرفيتها: سبع طبية وخمس زراعية', () {
      final medical = src(medicalPath);
      for (final image in [
        'tebkhairy.jpg',
        'blood.jpg',
        'doctor2.jpg',
        'doctor3.jpg',
        'doctor4.jpg',
        'nadara.jpg',
        'doctor5.jpg',
      ]) {
        expect(count(medical, 'assets/images/$image'), 1, reason: image);
      }
      final farmer = src(farmerPath);
      for (final image in ['tools.jpg', 'eng.jpg', 'plant.jpg', 'asmda.jpg', 'taqs.jpg']) {
        expect(count(farmer, 'assets/images/$image'), 1, reason: image);
      }
    });
  });
}
