import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/wassalni_model.dart';
import 'package:qurity/routes/app_routes.dart';
import 'package:qurity/services/wassalni_service.dart';
import 'package:qurity/widgets/wassalni_ride_sheet.dart';

void main() {
  group('WassalniModel & Service Tests', () {
    test('WassalniRide serialization preserves all ride and driver fields', () {
      final now = DateTime(2026, 11, 26, 10);
      final ride = WassalniRide(
        id: 'w_1',
        rideNumber: 'WAS-20261126-4321',
        userId: 'u_1',
        userName: 'أحمد محمود',
        userPhone: '01012345678',
        vehicleType: WassalniVehicleType.privateCar,
        pickupLocation: 'المسجد الكبير',
        dropoffLocation: 'مستشفى بلقاس',
        isRoundTrip: true,
        passengersCount: 3,
        estimatedFare: 80.0,
        finalFare: 90.0,
        driverName: 'كابتن كريم',
        driverPhone: '01099887766',
        vehicleInfo: 'هيونداي فيرنا فضي',
        status: WassalniStatus.accepted,
        createdAt: now,
      );

      final json = ride.toJson();
      final restored = WassalniRide.fromJson(json, 'w_1');

      expect(restored.rideNumber, 'WAS-20261126-4321');
      expect(restored.vehicleType, WassalniVehicleType.privateCar);
      expect(restored.pickupLocation, 'المسجد الكبير');
      expect(restored.dropoffLocation, 'مستشفى بلقاس');
      expect(restored.isRoundTrip, isTrue);
      expect(restored.passengersCount, 3);
      expect(restored.effectiveFare, 90.0);
      expect(restored.driverName, 'كابتن كريم');
      expect(restored.status, WassalniStatus.accepted);
    });

    test('generateRideNumber matches WAS-YYYYMMDD-XXXX format', () {
      for (var i = 0; i < 10; i++) {
        expect(
          WassalniService.generateRideNumber(),
          matches(r'^WAS-\d{8}-\d{4}$'),
        );
      }
    });

    test('AppRoutes.wassalni is registered in AppRoutes.routes', () {
      expect(AppRoutes.wassalni, '/wassalni');
      expect(AppRoutes.routes.containsKey(AppRoutes.wassalni), isTrue);
    });
  });

  group('WassalniRideSheet UI & Workflow Tests', () {
    testWidgets(
        'renders landing view with quick vehicle cards and navigates to booking form',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WassalniRideSheet(
              currentUserId: 'u_test',
            ),
          ),
        ),
      );

      expect(find.text('خدمة «وصّلني» 🚖'), findsOneWidget);
      expect(find.text('اطلب توك توك 🛺'), findsOneWidget);
      expect(find.text('سيارة خاصة 🚗'), findsOneWidget);
      expect(find.text('اطلب رحلة جديدة الآن'), findsOneWidget);

      await tester.tap(find.text('اطلب رحلة جديدة الآن'));
      await tester.pumpAndSettle();

      expect(find.text('حجز رحلة «وصّلني» 🚖'), findsOneWidget);
      expect(find.text('من أين تتحرك؟ (نقطة الانطلاق) *'), findsOneWidget);
      expect(find.text('إلى أين تتجه؟ (الوجهة المطلوبة) *'), findsOneWidget);
    });
  });
}
