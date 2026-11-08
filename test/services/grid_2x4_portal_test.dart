import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/medical/medical_home_screen.dart';
import 'package:qurity/features/services/farmer_services_screen.dart';
import 'package:qurity/features/village/village_facilities_screen.dart';

void main() {
  group('شبكة 2*4 لبوابات الخدمات والمنشآت', () {
    testWidgets('شاشة الخدمات الطبية: شبكة 2*4 تتسع لـ 8 أيقونات بالتساوي مع بطاقة قريباً',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MedicalHomeScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // التحقق من وجود شبكة بعمودين
      final gridFinder = find.byType(SliverGrid);
      expect(gridFinder, findsOneWidget);

      final grid = tester.widget<SliverGrid>(gridFinder);
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2, reason: 'الشبكة 2 أعمدة');

      // التحقق من أن عدد العناصر في الشبكة هو 8
      final childDelegate = grid.delegate as SliverChildBuilderDelegate;
      expect(childDelegate.childCount, 8, reason: 'تحتوي الشاشة على 8 أيقونات (4 صفوف × 2 أعمدة)');

      // التحقق من وجود عنصر "قريباً" في الموضع الثامن
      expect(find.text('قريباً'), findsOneWidget);
      expect(find.text('خدمة طبية جديدة'), findsOneWidget);

      // تجربة النقر على بطاقة قريباً وظهور رسالة توضيحية
      await tester.tap(find.text('قريباً'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('شاشة خدمات المزارع: شبكة 2*4 تتسع لـ 8 أيقونات بالتساوي مع 3 بطاقات قريباً',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FarmerServicesScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // التحقق من وجود شبكة بعمودين
      final gridFinder = find.byType(SliverGrid);
      expect(gridFinder, findsOneWidget);

      final grid = tester.widget<SliverGrid>(gridFinder);
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2, reason: 'الشبكة 2 أعمدة');

      // التحقق من أن عدد العناصر في الشبكة هو 8
      final childDelegate = grid.delegate as SliverChildBuilderDelegate;
      expect(childDelegate.childCount, 8, reason: 'تحتوي الشاشة على 8 أيقونات (4 صفوف × 2 أعمدة)');

      // التحقق من وجود 3 بطاقات قريباً لإكمال الـ 8
      expect(find.text('قريباً'), findsNWidgets(3));
      expect(find.text('خدمة زراعية جديدة'), findsNWidgets(3));

      // تجربة النقر على أول بطاقة قريباً وظهور رسالة توضيحية
      await tester.tap(find.text('قريباً').first);
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('شاشة منشأة القرية: شبكة 2*4 تضم المنشآت الـ 8 الرئيسية بالكامل',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VillageFacilitiesScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // التحقق من وجود شبكة بعمودين
      final gridFinder = find.byType(SliverGrid);
      expect(gridFinder, findsOneWidget);

      final grid = tester.widget<SliverGrid>(gridFinder);
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2, reason: 'الشبكة 2 أعمدة');

      // التحقق من أن عدد المنشآت هو 8
      final childDelegate = grid.delegate as SliverChildBuilderDelegate;
      expect(childDelegate.childCount, 8, reason: 'تحتوي الشاشة على 8 منشآت بالضبط (4 صفوف × 2 أعمدة)');

      // التحقق من وجود المنشآت الثمانية بأسمائها الصريحة
      expect(find.text('مركز الشباب'), findsOneWidget);
      expect(find.text('الوحدة الصحية'), findsOneWidget);
      expect(find.text('مكتب البريد'), findsOneWidget);
      expect(find.text('الجمعية الزراعية'), findsOneWidget);
      expect(find.text('مدارس القرية'), findsOneWidget);
      expect(find.text('المعاهد الدينية'), findsOneWidget);
      expect(find.text('مساجد القرية'), findsOneWidget);
      expect(find.text('مكتب الأوقاف'), findsOneWidget);

      // تجربة النقر على منشأة والانتقال لتفاصيلها
      await tester.tap(find.text('مركز الشباب'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // التأكد من فتح شاشة التفاصيل وعرض النبذة
      expect(find.byType(FacilityDetailScreen), findsOneWidget);
      expect(find.text('نبذة عن المنشأة'), findsOneWidget);
      expect(find.text('بيانات الخدمة والموقع'), findsOneWidget);
      expect(find.text('أبرز الخدمات والأنشطة'), findsOneWidget);
    });
  });
}

