import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/services/service_provider_detail_screen.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/services/service_provider_service.dart';

void main() {
  testWidgets('provider detail renders without framework errors',
      (tester) async {
    final fake = FakeFirebaseFirestore();
    final ref = await fake.collection('service_providers').add({
      'category': 'technicians',
      'name': 'ورشة نجارة أحمد',
      'specialty': 'نجارة',
      'phone': '01000000000',
      'address': 'شارع السوق',
      'description': 'أفضل نجار في القرية',
      'isApproved': true,
      'isFeatured': true,
      'rating': 4.5,
      'ratingCount': 2,
    });
    final snap = await ref.get();
    final provider = ServiceProvider.fromJson(snap.data()!, ref.id);

    await tester.pumpWidget(MaterialApp(
      home: ServiceProviderDetailScreen(
        provider: provider,
        service: ServiceProviderService(fake),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('نجارة'), findsWidgets);
    expect(find.textContaining('مميز'), findsWidgets);
  });

  testWidgets('provider detail without optional fields renders',
      (tester) async {
    const provider = ServiceProvider(
        id: 'x1', category: 'educational', name: 'أ. سالم', specialty: 'الرياضيات', stage: 'المرحلة الإعدادية');
    await tester.pumpWidget(MaterialApp(
      home: ServiceProviderDetailScreen(
        provider: provider,
        service: ServiceProviderService(FakeFirebaseFirestore()),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('الرياضيات'), findsWidgets);
  });
}
