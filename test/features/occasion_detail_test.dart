import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/theme/app_theme.dart';
import 'package:qurity/features/occasions/detail.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/engagement_service.dart';
import 'package:qurity/services/occasion_service.dart';

void main() {
  testWidgets('OccasionDetailScreen renders occasion details and hero image without exceptions', (tester) async {
    final fake = FakeFirebaseFirestore();
    final engagement = EngagementService(fake);

    final occasion = Occasion(
      id: 'occ-1',
      title: 'حفل تكريم حفظة القرآن الكريم',
      date: '2026/12/15',
      location: 'المسجد الكبير بالقرية',
      description: 'يسر أهالي القرية دعوتكم لحضور حفل تكريم حفظة كتاب الله تعالى',
      organizer: 'لجنة شباب أبوديشيشة',
      imageUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
      isApproved: true,
      createdAt: DateTime(2026, 11),
    );

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      navigatorKey: navKey,
      home: const SizedBox.shrink(),
    ));

    navKey.currentState!.push(
      MaterialPageRoute(
        settings: RouteSettings(name: '/occasions/detail', arguments: occasion),
        builder: (_) => OccasionDetailScreen(
          service: OccasionService(fake),
          engagement: engagement,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('حفل تكريم حفظة القرآن الكريم'), findsOneWidget);
    expect(find.text('المسجد الكبير بالقرية'), findsOneWidget);
    expect(find.text('لجنة شباب أبوديشيشة'), findsOneWidget);
    expect(find.text('تفاصيل المناسبة'), findsNWidgets(2));
  });
}

