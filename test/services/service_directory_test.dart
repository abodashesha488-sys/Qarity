import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/medical_models.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/services/medical_service.dart';
import 'package:qurity/services/service_provider_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ServiceProviderService', () {
    test('create persists with isApproved=false and category', () async {
      final fake = FakeFirebaseFirestore();
      final svc = ServiceProviderService(fake);
      await svc.create(const ServiceProvider(
        id: '',
        category: ServiceCategory.technicians,
        specialty: 'نجارة',
        name: 'ورشة أحمد',
        phone: '0100',
        submittedBy: 'u1',
      ));
      final snap = await fake.collection('service_providers').get();
      final data = snap.docs.single.data();
      expect(data['isApproved'], false);
      expect(data['category'], 'technicians');
      expect(data['specialty'], 'نجارة');
    });

    test('getApprovedByCategory filters approved + category only', () async {
      final fake = FakeFirebaseFirestore();
      final svc = ServiceProviderService(fake);
      await fake.collection('service_providers').add({
        'category': 'technicians', 'name': 'فني معتمد', 'isApproved': true,
      });
      await fake.collection('service_providers').add({
        'category': 'technicians', 'name': 'معلق', 'isApproved': false,
      });
      await fake.collection('service_providers').add({
        'category': 'educational', 'name': 'مدرس معتمد', 'isApproved': true,
      });
      final techs = await svc
          .getApprovedByCategory(ServiceCategory.technicians)
          .first;
      expect(techs.length, 1);
      expect(techs.single.name, 'فني معتمد');
    });

    test('fromJson defaults unapproved and displaySpecialty joins stage',
        () {
      final p = ServiceProvider.fromJson(
        {
          'category': 'educational',
          'name': 'أ. محمد',
          'specialty': 'الرياضيات',
          'stage': 'الصف الأول الثانوي',
        },
        'x',
      );
      expect(p.isApproved, isFalse);
      expect(p.displaySpecialty, 'الرياضيات — الصف الأول الثانوي');
    });
  });

  group('MedicalCenterClinic approval field', () {
    test('legacy docs without isApproved parse as approved', () {
      final c = MedicalCenterClinic.fromJson({'name': 'عيادة'}, 'x');
      expect(c.isApproved, isTrue);
    });

    test('addClinic with isApproved=false stays pending', () async {
      final fake = FakeFirebaseFirestore();
      final svc = MedicalCenterService(fake);
      await svc.addClinic(const MedicalCenterClinic(
        id: '',
        name: 'عيادة جديدة',
        isApproved: false,
      ));
      final snap = await fake.collection('medical_center_clinics').get();
      expect(snap.docs.single.data()['isApproved'], false);
    });

    test('public clinic toJson carries isApproved flag', () {
      const c = VillageClinic(id: 'x', name: 'عيادة');
      expect(c.toJson()['isApproved'], false);
    });
  });
}
