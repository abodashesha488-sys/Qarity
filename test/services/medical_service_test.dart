import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/medical_models.dart';
import 'package:qurity/services/medical_service.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() => fake = FakeFirebaseFirestore());

  group('MedicalCenterService', () {
    test('seedIfEmpty adds defaults only when collection is empty', () async {
      final svc = MedicalCenterService(fake);
      await svc.seedIfEmpty();
      final snap1 = await fake.collection('medical_center_clinics').get();
      expect(snap1.docs.length, greaterThan(0));
      // Second call must not duplicate
      await svc.seedIfEmpty();
      final snap2 = await fake.collection('medical_center_clinics').get();
      expect(snap2.docs.length, snap1.docs.length);
    });

    test('addClinic writes a document with fields', () async {
      final svc = MedicalCenterService(fake);
      await svc.addClinic(const MedicalCenterClinic(
        id: '',
        name: 'عيادة القلب',
        specialty: 'قلب وأوعية',
        workingDays: ['السبت'],
        workingHours: '11 ص - 1 م',
        fees: 25,
      ));
      final snap = await fake.collection('medical_center_clinics').get();
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['name'], 'عيادة القلب');
      expect(data['fees'], 25);
      expect((data['workingDays'] as List).contains('السبت'), isTrue);
    });

    test('getClinicsStream returns parsed clinics sorted by name', () async {
      final svc = MedicalCenterService(fake);
      await svc.addClinic(const MedicalCenterClinic(id: '', name: 'ياء'));
      await svc.addClinic(const MedicalCenterClinic(id: '', name: 'ألف'));
      final list = await svc.getClinicsStream().first;
      expect(list.map((c) => c.name).toList(), ['ألف', 'ياء']);
    });

    test('deleteClinic removes document', () async {
      final svc = MedicalCenterService(fake);
      final id = await svc.addClinic(const MedicalCenterClinic(id: '', name: 'x'));
      await svc.deleteClinic(id);
      final snap = await fake.collection('medical_center_clinics').get();
      expect(snap.docs, isEmpty);
    });
  });

  group('VillageClinicService', () {
    test('create writes a pending clinic (isApproved == false)', () async {
      final svc = VillageClinicService(fake);
      await svc.create(const VillageClinic(id: '', name: 'عيادة خاص', phone: '0100'));
      final snap = await fake.collection('village_clinics').get();
      expect(snap.docs.single.data()['isApproved'], false);
      expect(snap.docs.single.data()['name'], 'عيادة خاص');
    });

    test('getApprovedStream filters only approved', () async {
      final svc = VillageClinicService(fake);
      final id = await svc.create(const VillageClinic(id: '', name: 'معلق'));
      await fake.collection('village_clinics').doc(id).update({'isApproved': true});
      await svc.create(const VillageClinic(id: '', name: 'آخر معلق'));
      final list = await svc.getApprovedStream().first;
      expect(list.map((c) => c.name).toList(), ['معلق']);
    });
  });

  group('PharmacyService', () {
    test('create writes a pending pharmacy', () async {
      final svc = PharmacyService(fake);
      await svc.create(const Pharmacy(id: '', name: 'صيدلية النور', phone: '0101'));
      final snap = await fake.collection('pharmacies').get();
      expect(snap.docs.single.data()['isApproved'], false);
      expect(snap.docs.single.data()['name'], 'صيدلية النور');
    });

    test('getApprovedStream sorts 24-hour pharmacies first', () async {
      final svc = PharmacyService(fake);
      final a = await svc.create(const Pharmacy(id: '', name: 'عادية'));
      await svc.create(const Pharmacy(id: '', name: 'مداومة', is24Hours: true));
      await fake.collection('pharmacies').doc(a).update({'isApproved': true});
      final all = await fake.collection('pharmacies').get();
      for (final d in all.docs) {
        await fake.collection('pharmacies').doc(d.id).update({'isApproved': true});
      }
      final list = await svc.getApprovedStream().first;
      expect(list.first.is24Hours, isTrue);
    });
  });

  group('BloodBankService', () {
    test('addDonor creates pending record with bloodType code', () async {
      final svc = BloodBankService(fake);
      await svc.addDonor(const BloodDonor(
        id: '',
        userId: 'u1',
        name: 'أحمد',
        phone: '0100',
        bloodType: BloodType.aPos,
        age: 30,
      ));
      final snap = await fake.collection('blood_donors').get();
      final d = snap.docs.single.data();
      expect(d['bloodType'], 'A+');
      expect(d['isApproved'], false);
    });

    test('getApprovedDonorsStream filters approved only', () async {
      final svc = BloodBankService(fake);
      await svc.addDonor(const BloodDonor(id: '', userId: 'u1', name: 'أ'));
      final all = await fake.collection('blood_donors').get();
      for (final d in all.docs) {
        await fake.collection('blood_donors').doc(d.id).update({'isApproved': true});
      }
      await svc.addDonor(const BloodDonor(id: '', userId: 'u2', name: 'ب', bloodType: BloodType.bNeg));
      final list = await svc.getApprovedDonorsStream().first;
      expect(list.length, 1);
      expect(list.first.name, 'أ');
    });

    test('countAvailableByType returns per-type counts', () async {
      final svc = BloodBankService(fake);
      await svc.addDonor(const BloodDonor(id: '', userId: 'u1', name: 'أ'));
      await svc.addDonor(const BloodDonor(id: '', userId: 'u2', name: 'ب'));
      await svc.addDonor(const BloodDonor(id: '', userId: 'u3', name: 'ج', bloodType: BloodType.abNeg));      final all = await fake.collection('blood_donors').get();
      for (final d in all.docs) {
        await fake.collection('blood_donors').doc(d.id).update({'isApproved': true});
      }
      final counts = await svc.countAvailableByType();
      expect(counts['O+'], 2);
      expect(counts['AB-'], 1);
    });

    test('createRequest + closeRequest transitions status', () async {
      final svc = BloodBankService(fake);
      final id = await svc.createRequest(const BloodRequest(
        id: '',
        userId: 'u1',
        requesterName: 'مستخدم',
        phone: '0100',
        bloodType: BloodType.aNeg,
        units: 2,
      ));
      final snap = await fake.collection('blood_requests').get();
      expect(snap.docs.single.data()['status'], 'open');
      await svc.closeRequest(id);
      final snap2 = await fake.collection('blood_requests').get();
      expect(snap2.docs.single.data()['status'], 'closed');
    });

    test('getOpenApprovedRequestsStream returns only open+approved', () async {
      final svc = BloodBankService(fake);
      final id = await svc.createRequest(const BloodRequest(id: '', userId: 'u1', requesterName: 'م'));
      await fake.collection('blood_requests').doc(id).update({'isApproved': true});
      await svc.createRequest(const BloodRequest(id: '', userId: 'u2', requesterName: 'ن'));
      final list = await svc.getOpenApprovedRequestsStream().first;
      expect(list.length, 1);
      expect(list.first.userId, 'u1');
    });
  });

  group('BloodType', () {
    test('fromCode maps codes correctly and falls back', () {
      expect(BloodType.fromCode('AB+'), BloodType.abPos);
      expect(BloodType.fromCode('O-'), BloodType.oNeg);
      expect(BloodType.fromCode(null), BloodType.oPos);
    });
  });

  group('MedicalCenterClinic model', () {
    test('scheduleLabel combines days and hours', () {
      const c = MedicalCenterClinic(
          id: '', name: 'x', workingDays: ['السبت', 'الأحد'], workingHours: '9 ص - 1 م');
      expect(c.scheduleLabel, contains('السبت'));
      expect(c.scheduleLabel, contains('9 ص'));
    });
  });
}
