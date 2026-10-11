import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/prayer_times_service.dart';

void main() {
  group('PrayerTimesService - مواقيت صلاة قرية أبوديشيشة', () {
    test('حساب مواقيت اليوم يعود بجميع الصلوات الست مرتبة زمنيًا', () {
      final now = DateTime(2026, 10, 11, 12);
      final schedule = PrayerTimesService.calculate(date: now);

      expect(schedule.all.length, 6);
      expect(schedule.fajr.nameAr, 'الفجر');
      expect(schedule.sunrise.nameAr, 'الشروق');
      expect(schedule.dhuhr.nameAr, 'الظهر');
      expect(schedule.asr.nameAr, 'العصر');
      expect(schedule.maghrib.nameAr, 'المغرب');
      expect(schedule.isha.nameAr, 'العشاء');

      // الفجر قبل الشروق والشروق قبل الظهر والظهر قبل العصر والعصر قبل المغرب والمغرب قبل العشاء
      expect(schedule.fajr.time.isBefore(schedule.sunrise.time), isTrue);
      expect(schedule.sunrise.time.isBefore(schedule.dhuhr.time), isTrue);
      expect(schedule.dhuhr.time.isBefore(schedule.asr.time), isTrue);
      expect(schedule.asr.time.isBefore(schedule.maghrib.time), isTrue);
      expect(schedule.maghrib.time.isBefore(schedule.isha.time), isTrue);
    });

    test('getNextPrayer تحدد الصلاة القادمة والوقت المتبقي بدقة', () {
      final schedule = PrayerTimesService.calculate(
        date: DateTime(2026, 10, 11),
      );

      // قبل الفجر
      final beforeFajr = schedule.fajr.time.subtract(const Duration(minutes: 30));
      final (nextFajr, diffFajr) = schedule.getNextPrayer(beforeFajr);
      expect(nextFajr.name, 'fajr');
      expect(diffFajr.inMinutes, 30);
      expect(VillagePrayerSchedule.formatRemainingTime(diffFajr), '30 دقيقة');

      // بين الظهر والعصر
      final midAfternoon = schedule.dhuhr.time.add(const Duration(minutes: 45));
      final (nextAsr, diffAsr) = schedule.getNextPrayer(midAfternoon);
      expect(nextAsr.name, 'asr');
      expect(diffAsr.isNegative, isFalse);

      // تنسيق الوقت المتبقي
      expect(
        VillagePrayerSchedule.formatRemainingTime(
          const Duration(hours: 2, minutes: 15),
        ),
        '2 س و 15 د',
      );
    });

    test('تنسيق الوقت بنظام 12 ساعة مع مؤشر ص / م', () {
      final schedule = PrayerTimesService.calculate(
        date: DateTime(2026, 10, 11),
      );
      for (final p in schedule.all) {
        final str = p.format12Hour();
        expect(str.contains('ص') || str.contains('م'), isTrue);
        expect(str.contains(':'), isTrue);
      }
    });
  });
}
