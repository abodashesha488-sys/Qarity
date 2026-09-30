import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/relative_time.dart';

void main() {
  final now = DateTime(2026, 9, 30, 12);

  String at(Duration ago) => relativeTimeLabelAr(now.subtract(ago), now: now);

  group('relativeTimeLabelAr', () {
    test('بلا تاريخ ⇒ نص فارغ (لا «منذ» كاذبة)', () {
      expect(relativeTimeLabelAr(null, now: now), '');
    });

    test('أقل من دقيقة أو زمن مستقبلي ⇒ الآن', () {
      expect(at(const Duration(seconds: 40)), 'الآن');
      expect(at(const Duration(seconds: -120)), 'الآن');
    });

    test('الدقائق حتى الساعة', () {
      expect(at(const Duration(minutes: 1)), 'منذ دقيقة');
      expect(at(const Duration(minutes: 2)), 'منذ دقيقتين');
      expect(at(const Duration(minutes: 5)), 'منذ 5 دقائق');
      expect(at(const Duration(minutes: 45)), 'منذ 45 دقيقةً');
    });

    test('الساعات حتى ٢٤ ساعة', () {
      expect(at(const Duration(hours: 1)), 'منذ ساعة');
      expect(at(const Duration(hours: 2)), 'منذ ساعتين');
      expect(at(const Duration(hours: 9)), 'منذ 9 ساعات');
      expect(at(const Duration(hours: 23)), 'منذ 23 ساعةً');
    });

    test('أيام ثم أسابيع ثم أشهر ثم سنوات', () {
      expect(at(const Duration(hours: 24)), 'منذ يوم');
      expect(at(const Duration(days: 2)), 'منذ يومين');
      expect(at(const Duration(days: 5)), 'منذ 5 أيام');
      expect(at(const Duration(days: 6, hours: 23)), 'منذ 6 أيام');
      expect(at(const Duration(days: 7)), 'منذ أسبوع');
      expect(at(const Duration(days: 14)), 'منذ أسبوعين');
      expect(at(const Duration(days: 21)), 'منذ 3 أسابيع');
      // الأسابيع تُعدّ حتى ٤، ثم تنتقل الدلالة للأشهر
      expect(at(const Duration(days: 30)), 'منذ 4 أسابيع');
      expect(at(const Duration(days: 35)), 'منذ شهر');
      expect(at(const Duration(days: 65)), 'منذ شهرين');
      expect(at(const Duration(days: 100)), 'منذ 3 أشهر');
      expect(at(const Duration(days: 300)), 'منذ 10 أشهر');
      expect(at(const Duration(days: 330)), 'منذ 11 شهرًا');
      expect(at(const Duration(days: 360)), 'منذ سنة');
      expect(at(const Duration(days: 800)), 'منذ سنتين');
      expect(at(const Duration(days: 1500)), 'منذ 4 سنوات');
    });
  });
}
