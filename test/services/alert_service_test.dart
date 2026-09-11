import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/wisdoms.dart';
import 'package:qurity/services/alert_service.dart';

void main() {
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
      expect(TodayWisdom.items.length, greaterThanOrEqualTo(40));
      expect(TodayWisdom.items.toSet().length, TodayWisdom.items.length);
    });
  });
}
