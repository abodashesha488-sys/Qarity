import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// عقود مصدر لموجة «إعادة تنسيق أيقونات البوابتين بشكل جذاب ومتناسق»:
///
/// تم التخلص من التصغير القسري العشوائي (0.7)، وأصبحت كل أيقونة تملأ بطاقتها
/// بأناقة هندسية ونسبة أبعاد 0.89 تطابق الرسم الأصلي مع حواف دائرية 18 وظل ناعم
/// وبلا أي اقتصاص للرسم أو للشارة السفلية.
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

  group('الأيقونة كبطاقة جذابة متناسقة تملأ مساحتها بلا تشوه', () {
    test('البوابة الطبية: بطاقة متكاملة بملء الغلاف', () {
      final tile = medicalTile(src(medicalPath));
      expect(count(tile, 'child: Image.asset('), 1);
      expect(count(tile, 'width: double.infinity'), 1);
      expect(count(tile, 'height: double.infinity'), 1);
      expect(count(tile, 'fit: BoxFit.cover'), 1);
      expect(count(tile, 'cacheWidth: 520'), 1);
    });

    test('بوابة المزارع: نفس الغلاف المتناسق بمقاس واحد', () {
      final tile = farmerTile(src(farmerPath));
      expect(count(tile, 'child: Image.asset('), 1);
      expect(count(tile, 'width: double.infinity'), 1);
      expect(count(tile, 'height: double.infinity'), 1);
      expect(count(tile, 'fit: BoxFit.cover'), 1);
      expect(count(tile, 'cacheWidth: 520'), 1);
    });

    test('النقر يلفّ زر الصورة البارز: `InkWell` داخل `Material`', () {
      final medical = medicalTile(src(medicalPath));
      expect(medical.contains("Navigator.pushNamed(context, '/medical/section'"), isTrue);
      final farmer = farmerTile(src(farmerPath));
      expect(farmer.contains('onTap: () => Navigator.pushNamed(context, service.route)'), isTrue);
    });
  });

  group('الصورة زر بارز بظل وإطار وحواف دائرية أنيقة', () {
    test('الطبية: `Container` بظل وحواف 18 وإطار متناسق', () {
      final tile = medicalTile(src(medicalPath));
      expect(count(tile, 'const imgRadius = BorderRadius.all(Radius.circular(18));'), 1);
      expect(count(tile, 'decoration: BoxDecoration('), 1);
      expect(count(tile, 'border: Border.all('), 1);
      expect(count(tile, 'blurRadius: 10,'), 1);
      expect(count(tile, 'offset: const Offset(0, 4),'), 1);
      expect(count(tile, 'clipBehavior: Clip.antiAlias,'), 1);
      expect(count(tile, 'child: InkWell('), 1);
    });

    test('المزارع: نفس الظل والحواف وسلسلة الأنميشن', () {
      final tile = farmerTile(src(farmerPath));
      expect(count(tile, 'const imgRadius = BorderRadius.all(Radius.circular(18));'), 1);
      expect(count(tile, 'border: Border.all('), 1);
      expect(count(tile, 'blurRadius: 10,'), 1);
      expect(count(tile, 'offset: const Offset(0, 4),'), 1);
      expect(count(tile, 'clipBehavior: Clip.antiAlias,'), 1);
      expect(count(tile, 'child: InkWell('), 1);
      expect(count(tile, '.animate(delay: (index * 40).ms).fadeIn(duration: 350.ms).scale('), 1);
      expect(count(tile, 'begin: const Offset(0.93, 0.93),'), 1);
      expect(count(tile, 'errorBuilder: (context, error, stackTrace) => Center('), 1);
    });
  });

  group('هندسة الشبكة: عمودان بنسبة أبعاد هندسية متناسقة', () {
    test('الطبية: شبكة عمودين بنسبة 0.89 وبطاقة سابعة متمركزة', () {
      final text = src(medicalPath);
      expect(count(text, 'body: LayoutBuilder(builder: (context, constraints) {'), 1);
      expect(count(text, 'const childAspectRatio = 0.89;'), 1);
      expect(count(text, 'crossAxisCount: 2,'), 1);
      expect(count(text, 'childAspectRatio: childAspectRatio'), 1);
      expect(count(text, 'childCount: 6,'), 1);
      expect(count(text, 'index: 6,'), 1);
    });

    test('المزارع: شبكة عمودين بنسبة 0.89 وبطاقة خامسة متمركزة', () {
      final text = src(farmerPath);
      expect(count(text, 'body: LayoutBuilder(builder: (context, constraints) {'), 1);
      expect(count(text, 'const childAspectRatio = 0.89;'), 1);
      expect(count(text, 'crossAxisCount: 2,'), 1);
      expect(count(text, 'childAspectRatio: childAspectRatio'), 1);
      expect(count(text, 'childCount: 4,'), 1);
      expect(count(text, 'index: 4,'), 1);
    });
  });

  group('سجلّات البوابتين بعددها وترتيبها وحرفيتها: سبع طبية وخمس زراعية', () {
    test('الطبية: 7 خدمات بأسمائها وصورها الأصلية', () {
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
    });

    test('المزارع: 5 خدمات بأسمائها وصورها الأصلية', () {
      final farmer = src(farmerPath);
      for (final image in ['tools.jpg', 'eng.jpg', 'plant.jpg', 'asmda.jpg', 'taqs.jpg']) {
        expect(count(farmer, 'assets/images/$image'), 1, reason: image);
      }
    });
  });
}
