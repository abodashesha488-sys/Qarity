import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/home/global_search_screen.dart';

void main() {
  testWidgets('GlobalSearchResultItem holds image and original record',
      (tester) async {
    const item = GlobalSearchResultItem(
      title: 'طبيب باطنة',
      subtitle: 'د. أحمد محمود · 01000000000',
      category: 'عيادات القرية',
      icon: Icons.medical_services_rounded,
      accentColor: Colors.teal,
      imageUrl: 'https://example.com/doctor.jpg',
      originalRecord: 'record_sample',
      phone: '01000000000',
    );

    expect(item.imageUrl, 'https://example.com/doctor.jpg');
    expect(item.originalRecord, 'record_sample');
    expect(item.title, 'طبيب باطنة');
    expect(item.category, 'عيادات القرية');
    expect(item.phone, '01000000000');
  });

  testWidgets('GlobalSearchScreen renders search bar and initial filter chips',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalSearchScreen(),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ChoiceChip), findsWidgets);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('سوق القرية والمحلات'), findsOneWidget);
    expect(find.text('دليل الحرفيين'), findsOneWidget);
  });
}
