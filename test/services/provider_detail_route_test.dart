import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/services/service_provider_detail_screen.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/services/service_provider_service.dart';

void main() {
  testWidgets('provider detail renders via NAMED ROUTE with arguments',
      (tester) async {
    final fake = FakeFirebaseFirestore();
    final ref = await fake.collection('service_providers').add({
      'category': 'technicians',
      'name': 'ورشة نجارة',
      'specialty': 'نجارة',
      'phone': '0100',
      'isApproved': true,
      'isFeatured': false,
      'rating': 0,
      'ratingCount': 0,
    });
    final snap = await ref.get();
    final provider = ServiceProvider.fromJson(snap.data()!, ref.id);

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/detail',
                    arguments: provider),
                child: const Text('go'),
              ),
            ),
          )),
      routes: {
        '/detail': (_) => ServiceProviderDetailScreen(
            service: ServiceProviderService(fake)),
      },
    ));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('نجارة'), findsWidgets);
  });
}
