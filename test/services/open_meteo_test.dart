import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/weather_service.dart';

void main() {
  group('Open-Meteo WeatherService Integration & Format', () {
    test('WeatherFormat.windSpeedKmh يحوّل سرعة الرياح من متر/ثانية إلى كم/س بدقة', () {
      expect(WeatherFormat.windSpeedKmh(0), '0 كم/س');
      expect(WeatherFormat.windSpeedKmh(5), '18 كم/س');
      expect(WeatherFormat.windSpeedKmh(10), '36 كم/س');
      expect(WeatherFormat.windSpeedKmh(null), '—');
    });

    test('WeatherFormat.conditionAr يترجم أكواد الحالات بدقة من المفتاح', () {
      expect(WeatherFormat.conditionAr('01d', ''), 'مشمس');
      expect(WeatherFormat.conditionAr('02d', ''), 'غائم جزئيًا');
      expect(WeatherFormat.conditionAr('03d', ''), 'غائم');
      expect(WeatherFormat.conditionAr('04d', ''), 'غائم كليًا');
      expect(WeatherFormat.conditionAr('09d', ''), 'ممطر');
      expect(WeatherFormat.conditionAr('10d', ''), 'ممطر');
      expect(WeatherFormat.conditionAr('11d', ''), 'عاصفة رعدية');
      expect(WeatherFormat.conditionAr('13d', ''), 'ثلوج');
      expect(WeatherFormat.conditionAr('50d', ''), 'ضباب');
    });

    test('WeatherFormat.iconUrl يرجع رابط الأيقونة القياسي دون تكرار', () {
      expect(
        WeatherFormat.iconUrl('01d'),
        'https://openweathermap.org/img/wn/01d@2x.png',
      );
      expect(
        WeatherFormat.iconUrl('01d', big: true),
        'https://openweathermap.org/img/wn/01d@4x.png',
      );
    });

    test('WeatherFormat.pressureHpa ينسق الضغط الجوي', () {
      expect(WeatherFormat.pressureHpa(1013), '1013 hPa');
    });

    test('WeatherFormat.windDirection يحدد الاتجاهات الثمانية', () {
      expect(WeatherFormat.windDirection(0), 'شمالية');
      expect(WeatherFormat.windDirection(90), 'شرقية');
      expect(WeatherFormat.windDirection(180), 'جنوبية');
      expect(WeatherFormat.windDirection(270), 'غربية');
    });

    test('WeatherService instance singleton and initial state', () {
      final s1 = WeatherService.instance;
      final s2 = WeatherService.instance;
      expect(identical(s1, s2), isTrue);
      expect(WeatherService.tzOffsetSeconds, greaterThanOrEqualTo(7200));
      expect(WeatherService.villageNow(), isNotNull);
    });
  });
}
