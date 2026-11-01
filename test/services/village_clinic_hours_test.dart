import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/medical_models.dart';
import 'package:qurity/services/medical_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VillageClinic Model & Hours Tests', () {
    test('toJson and fromJson serialize structured workDays and shifts', () {
      const clinic = VillageClinic(
        id: 'c1',
        name: 'عيادة الأمل',
        specialty: 'باطنة',
        workDays: ['السبت', 'الأحد', 'الثلاثاء'],
        hasMorningShift: true,
        morningStart: '09:00',
        morningEnd: '13:00',
        hasEveningShift: true,
        eveningStart: '17:00',
        eveningEnd: '22:00',
      );

      final json = clinic.toJson();
      expect(json['workDays'], ['السبت', 'الأحد', 'الثلاثاء']);
      expect(json['hasMorningShift'], true);
      expect(json['morningStart'], '09:00');
      expect(json['morningEnd'], '13:00');
      expect(json['hasEveningShift'], true);
      expect(json['eveningStart'], '17:00');
      expect(json['eveningEnd'], '22:00');

      final deserialized = VillageClinic.fromJson(json, 'c1');
      expect(deserialized.workDays, ['السبت', 'الأحد', 'الثلاثاء']);
      expect(deserialized.hasMorningShift, true);
      expect(deserialized.morningStart, '09:00');
      expect(deserialized.morningEnd, '13:00');
      expect(deserialized.hasEveningShift, true);
      expect(deserialized.shiftsSummary, contains('صباحاً'));
      expect(deserialized.shiftsSummary, contains('مساءً'));
      expect(deserialized.workDaysSummary, contains('السبت'));
    });

    test('isCurrentlyOpen returns false on non-working day', () {
      final allWeekDays = [
        'السبت',
        'الأحد',
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
      ];
      final now = DateTime.now();
      final dayNames = {
        DateTime.saturday: 'السبت',
        DateTime.sunday: 'الأحد',
        DateTime.monday: 'الإثنين',
        DateTime.tuesday: 'الثلاثاء',
        DateTime.wednesday: 'الأربعاء',
        DateTime.thursday: 'الخميس',
        DateTime.friday: 'الجمعة',
      };
      final todayName = dayNames[now.weekday];
      final otherDays = allWeekDays.where((d) => d != todayName).toList();

      final clinic = VillageClinic(
        id: 'c2',
        name: 'عيادة الشفاء',
        workDays: otherDays,
        hasMorningShift: true,
        morningStart: '00:00',
        morningEnd: '23:59',
      );

      expect(clinic.isCurrentlyOpen, isFalse);
    });

    test('isCurrentlyOpen returns true when today is a workDay and current time is in shift', () {
      final now = DateTime.now();
      final dayNames = {
        DateTime.saturday: 'السبت',
        DateTime.sunday: 'الأحد',
        DateTime.monday: 'الإثنين',
        DateTime.tuesday: 'الثلاثاء',
        DateTime.wednesday: 'الأربعاء',
        DateTime.thursday: 'الخميس',
        DateTime.friday: 'الجمعة',
      };
      final todayName = dayNames[now.weekday]!;

      // عيادة مفتوحة طوال الـ 24 ساعة اليوم
      final clinic = VillageClinic(
        id: 'c3',
        name: 'عيادة النور',
        workDays: [todayName],
        hasMorningShift: true,
        morningStart: '00:00',
        morningEnd: '23:59',
      );

      expect(clinic.isCurrentlyOpen, isTrue);
    });
  });

  group('VillageClinicService Comments Tests', () {
    test('getCommentsStream emits comments and toggleCommentLike updates likes', () async {
      final fake = FakeFirebaseFirestore();
      final service = VillageClinicService(fake);

      await fake.collection('village_clinics').doc('c10').collection('comments').doc('com1').set({
        'text': 'عيادة ممتازة ودكتور متميز جداً',
        'userId': 'u1',
        'userName': 'أحمد',
        'likes': 0,
        'likedBy': <String>[],
        'createdAt': DateTime.now(),
      });

      final stream = service.getCommentsStream('c10');
      final snap = await stream.first;
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data() as Map<String, dynamic>;
      expect(data['text'], 'عيادة ممتازة ودكتور متميز جداً');

      // تجربة الإعجاب
      await service.toggleCommentLike('c10', 'com1', 'u2');
      final updatedSnap = await fake.collection('village_clinics').doc('c10').collection('comments').doc('com1').get();
      expect(updatedSnap.data()?['likes'], 1);
      expect(updatedSnap.data()?['likedBy'], contains('u2'));

      // تعديل التعليق
      await service.editComment('c10', 'com1', 'تم التعديل: تجربة رائعة');
      final editedSnap = await fake.collection('village_clinics').doc('c10').collection('comments').doc('com1').get();
      expect(editedSnap.data()?['text'], 'تم التعديل: تجربة رائعة');

      // حذف التعليق
      await service.deleteComment('c10', 'com1');
      final afterDelete = await fake.collection('village_clinics').doc('c10').collection('comments').doc('com1').get();
      expect(afterDelete.exists, isFalse);
    });
  });
}
