import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/engagement_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late EngagementService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = EngagementService(fakeFirestore);
  });

  group('Condolences', () {
    test('addCondolence writes a document with fields', () async {
      await service.addCondolence(
        obituaryId: 'o1',
        userId: 'u1',
        userName: 'أحمد',
        message: 'البقاء لله',
      );
      final snap = await fakeFirestore.collection('condolences').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['message'], 'البقاء لله');
      expect(snap.docs.first.data()['obituaryId'], 'o1');
      expect(snap.docs.first.data()['userName'], 'أحمد');
    });

    test('condolencesCount reflects only the given obituary', () async {
      await service.addCondolence(obituaryId: 'o1', userId: 'u1', userName: 'أ', message: '1');
      await service.addCondolence(obituaryId: 'o1', userId: 'u2', userName: 'ب', message: '2');
      await service.addCondolence(obituaryId: 'o2', userId: 'u3', userName: 'ج', message: '3');
      final count = await service.condolencesCount('o1').first;
      expect(count, 2);
    });

    test('condolences stream emits the submitted items', () async {
      await service.addCondolence(obituaryId: 'o1', userId: 'u1', userName: 'أ', message: 'أول');
      await service.addCondolence(obituaryId: 'o1', userId: 'u2', userName: 'ب', message: 'ثان');
      final list = await service.condolences('o1').first;
      expect(list.length, 2);
      final names = list.map((c) => c.userName).toList();
      expect(names, containsAll(['أ', 'ب']));
      expect(list.first.message, isA<String>());
    });
  });

  group('Attendance', () {
    test('attendOccasion marks attending and counts', () async {
      await service.attendOccasion(occasionId: 'ev1', userId: 'u1', userName: 'أحمد');
      final attending = await service.isAttending('ev1', 'u1').first;
      expect(attending, isTrue);
      final count = await service.attendeesCount('ev1').first;
      expect(count, 1);
    });

    test('attendOccasion is idempotent', () async {
      await service.attendOccasion(occasionId: 'ev1', userId: 'u1', userName: 'أحمد');
      await service.attendOccasion(occasionId: 'ev1', userId: 'u1', userName: 'أحمد');
      final count = await service.attendeesCount('ev1').first;
      expect(count, 1);
    });

    test('cancelAttendance removes attendance', () async {
      await service.attendOccasion(occasionId: 'ev1', userId: 'u1', userName: 'أحمد');
      await service.cancelAttendance(occasionId: 'ev1', userId: 'u1');
      final attending = await service.isAttending('ev1', 'u1').first;
      expect(attending, isFalse);
      final count = await service.attendeesCount('ev1').first;
      expect(count, 0);
    });

    test('different users each count once', () async {
      await service.attendOccasion(occasionId: 'ev1', userId: 'u1', userName: 'أ');
      await service.attendOccasion(occasionId: 'ev1', userId: 'u2', userName: 'ب');
      final count = await service.attendeesCount('ev1').first;
      expect(count, 2);
    });
  });
}
