import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/promo_placements.dart';
import 'package:qurity/features/medical/medical_home_screen.dart';
import 'package:qurity/models/medical_models.dart';
import 'package:qurity/routes/app_routes.dart';
import 'package:qurity/services/medical_service.dart';
import 'package:qurity/services/remote_push_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// لحظة ثابتة تُجرى عليها اختبارات نافذة العرض المميز.
final _opticalNow = DateTime(2026, 10, 1, 12);

/// اسم الأصل من مزوّد صورة — `Image.asset(..., cacheWidth:)` يغلّفها بـ ResizeImage.
String _assetName(ImageProvider<Object> provider) {
  if (provider is ResizeImage) return _assetName(provider.imageProvider);
  if (provider is AssetImage) return provider.assetName;
  return '';
}

OpticalShop _opticalShop({
  String name = 'محل',
  String adType = kOpticalAdNormal,
  DateTime? featuredUntil,
  bool isApproved = true,
}) =>
    OpticalShop(
      id: '',
      name: name,
      adType: adType,
      featuredUntil: featuredUntil,
      isApproved: isApproved,
      submittedBy: 'u1',
    );

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

  group('OpticalShop model — نوع الإعلان ونافذته', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('مستند قديم بلا adType/isApproved ⇒ عادي وغير معتمد وبلا مدة', () {
      final s = OpticalShop.fromJson({'name': 'محل قديم'}, 'd1');
      expect(s.adType, kOpticalAdNormal);
      expect(s.isApproved, isFalse);
      expect(s.featuredUntil, isNull);
      expect(s.visibleAt(_opticalNow), isTrue,
          reason: 'الإعلان العادي لا تنتهي صلاحيته');
    });

    test('toJson/fromJson يحفظان featuredUntil كطابع زمني', () {
      final until = DateTime(2026, 10, 10, 8);
      final s = _opticalShop(
          name: 'نظارات النور',
          adType: kOpticalAdFeatured,
          featuredUntil: until);
      final json = s.toJson();
      expect(json['featuredUntil'], isA<Timestamp>());
      expect(json['adType'], kOpticalAdFeatured);
      final back = OpticalShop.fromJson(
          {...json, 'createdAt': Timestamp.fromDate(_opticalNow)}, 'd2');
      expect(back.featuredUntil, until);
      expect(back.name, 'نظارات النور');
    });

    test('الإعلان العادي لا يصبح مميزًا ولو حمل مدة قديمة', () {
      final s = _opticalShop(
          featuredUntil: _opticalNow.add(const Duration(days: 5)));
      expect(s.isFeaturedAd, isFalse);
      expect(s.adLiveAt(_opticalNow), isFalse);
      expect(s.sortWeightAt(_opticalNow), 1);
    });

    test('المميز الحيّ أولاً في الترتيب، والمنتهي يختفي من الدليل', () {
      final live = _opticalShop(
          name: 'مميز حيّ',
          adType: kOpticalAdFeatured,
          featuredUntil: _opticalNow.add(const Duration(days: 3)));
      final expired = _opticalShop(
          name: 'مميز منتهٍ',
          adType: kOpticalAdFeatured,
          featuredUntil: _opticalNow.subtract(const Duration(minutes: 1)));
      expect(live.adLiveAt(_opticalNow), isTrue);
      expect(live.sortWeightAt(_opticalNow), 0);
      expect(expired.visibleAt(_opticalNow), isFalse);
      expect(expired.sortWeightAt(_opticalNow), 1);
    });
  });

  group('OpticalShopService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('create يبدأ غير معتمد ويحفظ مقدم البيان والتخصصات', () async {
      final svc = OpticalShopService(fake);
      await svc.create(OpticalShop(
        id: '',
        name: 'محل نظارات',
        categories: const ['نظارات طبية', 'عدسات لاصقة'],
        phone: '0100',
        adType: kOpticalAdFeatured,
        featuredUntil: _opticalNow.add(const Duration(days: 7)),
        submittedBy: 'u1',
        submittedByName: 'أحمد',
      ));
      final doc =
          (await fake.collection('optical_shops').get()).docs.single.data();
      expect(doc['isApproved'], false);
      expect(doc['submittedBy'], 'u1');
      expect(doc['adType'], kOpticalAdFeatured);
      expect(doc['categories'], ['نظارات طبية', 'عدسات لاصقة']);
    });

    test('الدليل: المعتمد فقط، والمميز الحيّ أولاً، والمنتهي مخفي', () async {
      final svc = OpticalShopService(fake);
      await fake.collection('optical_shops').add({
        'name': 'مميز حيّ',
        'isApproved': true,
        'adType': kOpticalAdFeatured,
        'featuredUntil':
            Timestamp.fromDate(_opticalNow.add(const Duration(days: 2))),
      });
      await fake.collection('optical_shops').add({
        'name': 'عادي',
        'isApproved': true,
        'adType': kOpticalAdNormal
      });
      await fake.collection('optical_shops').add({
        'name': 'مميز منتهٍ',
        'isApproved': true,
        'adType': kOpticalAdFeatured,
        'featuredUntil':
            Timestamp.fromDate(_opticalNow.subtract(const Duration(days: 1))),
      });
      await fake.collection('optical_shops')
          .add({'name': 'بانتظار الموافقة', 'isApproved': false});

      final list = await svc.getApprovedStream(now: _opticalNow).first;
      expect(list.map((s) => s.name).toList(), ['مميز حيّ', 'عادي']);
    });

    test('getMine يعيد كل محلات صاحبه (معلّق + منتهي) الأحدث أولاً', () async {
      final svc = OpticalShopService(fake);
      await fake.collection('optical_shops').add({
        'name': 'معلّق',
        'isApproved': false,
        'submittedBy': 'u1',
        'createdAt':
            Timestamp.fromDate(_opticalNow.subtract(const Duration(days: 3))),
      });
      await fake.collection('optical_shops').add({
        'name': 'منتهي',
        'isApproved': true,
        'submittedBy': 'u1',
        'createdAt':
            Timestamp.fromDate(_opticalNow.subtract(const Duration(days: 1))),
      });
      await fake.collection('optical_shops')
          .add({'name': 'محل غيري', 'isApproved': true, 'submittedBy': 'u2'});
      expect((await svc.getMine('u1')).map((s) => s.name).toList(),
          ['منتهي', 'معلّق']);
    });

    test('setFeaturedWindow يمدّد النافذة دون المساس بالموافقة أو البيانات',
        () async {
      final svc = OpticalShopService(fake);
      final ref = await fake.collection('optical_shops').add({
        'name': 'محل نظارات',
        'isApproved': true,
        'submittedBy': 'u1',
        'phone': '0100',
        'adType': kOpticalAdFeatured,
        'featuredUntil':
            Timestamp.fromDate(_opticalNow.subtract(const Duration(days: 1))),
      });

      await svc.setFeaturedWindow(ref.id, 15);

      final doc = (await ref.get()).data()!;
      expect(doc['adType'], kOpticalAdFeatured);
      expect((doc['featuredUntil'] as Timestamp).toDate().isAfter(_opticalNow),
          isTrue);
      expect(doc['name'], 'محل نظارات');
      expect(doc['phone'], '0100');
      expect(doc['isApproved'], true);
      expect(doc['submittedBy'], 'u1');
    });

    test('التجديد يعيد المحل المنتهي إلى الدليل', () async {
      final svc = OpticalShopService(fake);
      final ref = await fake.collection('optical_shops').add({
        'name': 'محل نظارات',
        'isApproved': true,
        'submittedBy': 'u1',
        'adType': kOpticalAdFeatured,
        'featuredUntil':
            Timestamp.fromDate(_opticalNow.subtract(const Duration(days: 1))),
      });
      expect(await svc.getApprovedStream(now: _opticalNow).first, isEmpty);

      await svc.setFeaturedWindow(ref.id, 3);

      final after = await svc.getApprovedStream(now: _opticalNow).first;
      expect(after.single.name, 'محل نظارات');
      expect(after.single.adLiveAt(_opticalNow), isTrue);
    });

    test('setFeaturedWindow يتجاهل المعرّف الفارغ والمدة غير الموجبة', () async {
      final svc = OpticalShopService(fake);
      await svc.setFeaturedWindow('', 7);
      await svc.setFeaturedWindow('abc', 0);
      expect((await fake.collection('optical_shops').get()).docs, isEmpty);
    });

    test('getById يعيد المحل مهما كانت حالته، وnull لمعرّف فارغ', () async {
      final svc = OpticalShopService(fake);
      final ref = await fake.collection('optical_shops').add({
        'name': 'محل منتهٍ',
        'isApproved': true,
        'adType': kOpticalAdFeatured,
        'featuredUntil':
            Timestamp.fromDate(_opticalNow.subtract(const Duration(days: 2))),
      });
      final shop = await svc.getById(ref.id);
      expect(shop?.name, 'محل منتهٍ');
      expect(shop?.visibleAt(_opticalNow), isFalse);
      expect(await svc.getById(''), isNull);
    });
  });

  group('بوابة الخدمات الطبية وسجلات قسم النظارات', () {
    testWidgets('البوابة تعرض بلاطة النظارات بصورة nadara', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: MedicalHomeScreen())));
      await tester.pump(const Duration(milliseconds: 600));

      expect(MedicalHomeScreen.colors.length, 6);
      final assets = tester
          .widgetList<Image>(find.byType(Image))
          .map((i) => _assetName(i.image))
          .toList();
      expect(assets, contains('assets/images/nadara.jpg'));
      // الشعار في أعلى الصفحة صورة من نفس المجلد، لذا يُحسب كل صورة قسم وحدها
      final sectionImages =
          assets.where((a) => a != 'assets/images/Qurity.png').toList();
      expect(sectionImages.length, 6);
      expect(sectionImages.toSet().length, 6);
    });

    test('لكل قسم لون خاص — السادس غير الخامس', () {
      expect(MedicalHomeScreen.colors[5], isNot(MedicalHomeScreen.colors[4]));
    });

    test('الإشعارات: إخطار الأدمن وقناة طبية', () {
      expect(kAdminNotifyCollections.contains('optical_shops'), isTrue);
      expect(kPushTopicForCollection['optical_shops'], 'village_medical');
    });

    test('مواضع الدعاية ومسار التفاصيل مسجّلة', () {
      expect(promoKeyForRoute(AppRoutes.medicalSection, 4), 'med_labs');
      expect(promoKeyForRoute(AppRoutes.medicalSection, 5), 'med_optical');
      expect(promoKeyForRoute(AppRoutes.medicalOpticalDetail, null), '');
      expect(
          kPromoPlacements
              .any((p) => p.key == 'med_optical' && p.group == 'المركز الطبي'),
          isTrue);
      expect(AppRoutes.routes.containsKey(AppRoutes.medicalOpticalDetail),
          isTrue);
    });

    test('مدد العرض وتصنيفات المحلات سليمة', () {
      expect(kOpticalFeaturedDayOptions, [3, 7, 15, 30]);
      expect(kOpticalCategories, contains('نظارات طبية'));
      expect(kOpticalCategories.toSet().length, kOpticalCategories.length);
    });
  });

}
