import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/wisdoms.dart';
import 'package:qurity/models/village_alert.dart';
import 'package:qurity/services/alert_service.dart';

void main() {
  group('VillageAlert mode/expiry', () {
    test('defaults: mode push, no expiry, live by default', () {
      final a = VillageAlert.fromJson({'message': 'م', 'isActive': true});
      expect(a.mode, VillageAlertMode.push);
      expect(a.expiresAt, isNull);
      expect(a.isLive, isTrue);
    });
    test('liveAt false after expiresAt and before starts window end', () {
      final now = DateTime(2026, 6, 1, 12);
      final expired = VillageAlert(
          message: 'م',
          isActive: true,
          expiresAt: now.subtract(const Duration(minutes: 1)));
      final live = VillageAlert(
          message: 'م', isActive: true, expiresAt: now.add(const Duration(hours: 1)));
      expect(expired.liveAt(now), isFalse);
      expect(live.liveAt(now), isTrue);
    });
    test('fromJson parses mode and expiresAt', () {
      final t = Timestamp.fromDate(DateTime(2026, 7));
      final a = VillageAlert.fromJson({
        'message': 'م', 'isActive': true,
        'mode': 'sound', 'expiresAt': t,
      });
      expect(a.mode, VillageAlertMode.sound);
      expect(a.expiresAt, DateTime(2026, 7));
    });
  });

  group('AlertService expiry-aware live mapping', () {
    test('expired doc is not live', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('village_alerts').doc('current').set({
        'message': 'قديم',
        'isActive': true,
        'expiresAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 2))),
      });
      expect(await AlertService(fake).getLiveAlert(), isNull);
    });
    test('in-window doc is live', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('village_alerts').doc('current').set({
        'message': 'حالي',
        'isActive': true,
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(hours: 2))),
      });
      final alert = await AlertService(fake).getLiveAlert();
      expect(alert, isNotNull);
      expect(alert!.message, 'حالي');
    });
  });

  group('AlertService watchLiveAlert', () {
    test('null when doc missing', () async {
      final fake = FakeFirebaseFirestore();
      final alert = await AlertService(fake).getLiveAlert();
      expect(alert, isNull);
    });

    test('null when inactive or empty', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('village_alerts').doc('current').set({
        'message': 'نص',
        'isActive': false,
      });
      expect(await AlertService(fake).getLiveAlert(), isNull);

      await fake.collection('village_alerts').doc('current').set({
        'message': '   ',
        'isActive': true,
      }, SetOptions(merge: true));
      expect(await AlertService(fake).getLiveAlert(), isNull);
    });

    test('returns the live alert when active with message', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('village_alerts').doc('current').set({
        'message': 'انقطاع المياه غدًا',
        'isActive': true,
      });
      final alert = await AlertService(fake).getLiveAlert();
      expect(alert, isNotNull);
      expect(alert!.message, 'انقطاع المياه غدًا');
      expect(alert.isLive, isTrue);
    });

    test('stream emits null after disabling', () async {
      final fake = FakeFirebaseFirestore();
      final svc = AlertService(fake);
      await fake.collection('village_alerts').doc('current').set({
        'message': 'تنبيه',
        'isActive': true,
      });
      await fake.collection('village_alerts').doc('current').update({'isActive': false});
      final value = await svc.watchLiveAlert().first;
      expect(value, isNull);
    });
  });

  group('TodayWisdom', () {
    test('pick is stable within the same day', () {
      expect(TodayWisdom.pick(), TodayWisdom.pick());
    });

    test('pick offsets cycle inside list bounds', () {
      for (var i = 0; i < TodayWisdom.items.length + 3; i++) {
        final w = TodayWisdom.pick(offset: i);
        expect(TodayWisdom.items, contains(w));
        expect(w, isNotEmpty);
      }
    });

    test('inventory is broad and non-duplicated', () {
      expect(TodayWisdom.items.length, greaterThanOrEqualTo(140));
      expect(TodayWisdom.items.toSet().length, TodayWisdom.items.length);
    });
  });
}
