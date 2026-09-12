import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/wisdom_calendar.dart';

void main() {
  group('WisdomCalendar coverage', () {
    test('contains exactly 365 daily wisdoms', () {
      expect(WisdomCalendar.total, 365);
    });

    test('each month has the right number of days', () {
      const expected = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      for (var m = 1; m <= 12; m++) {
        expect(WisdomCalendar.monthDays(m).length, expected[m - 1],
            reason: 'month $m');
      }
    });

    test('all entries have non-empty text and category', () {
      for (var m = 1; m <= 12; m++) {
        for (final w in WisdomCalendar.monthDays(m)) {
          expect(w.text.trim(), isNotEmpty);
          expect(w.category.trim(), isNotEmpty);
        }
      }
    });

    test('lookup by date returns the right wisdom', () {
      expect(
        WisdomCalendar.of(DateTime(2026)).text,
        'ابدأ عامك بنية طيبة، وخطوة صغيرة نحو ما تتمنى.',
      );
      expect(WisdomCalendar.of(DateTime(2026, 1, 25)).occasion, 'عيد الشرطة');
      expect(WisdomCalendar.of(DateTime(2026, 12, 31)).occasion, 'نهاية العام');
      expect(WisdomCalendar.of(DateTime(2026, 1, 3)).occasion, 'عامة');
      expect(WisdomCalendar.of(DateTime(2026, 1, 3)).isSpecial, isFalse);
    });

    test('leap Feb 29 falls back to Feb 28 wisdom', () {
      expect(WisdomCalendar.of(DateTime(2028, 2, 29)).text,
          WisdomCalendar.of(DateTime(2028, 2, 28)).text);
    });

    test('label formats date with month name in Arabic', () {
      expect(WisdomCalendar.label(DateTime(2026, 8, 13)), '13 أغسطس 2026');
    });
  });
}
