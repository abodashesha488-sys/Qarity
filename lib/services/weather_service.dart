import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_config.dart';

/// خدمة الطقس — OpenWeatherMap (الآن + توقع 5 أيام/3 ساعات).
/// نتيجة كل استدعاء تُخزّن مؤقتاً في الذاكرة (10 دقائق) لتحمّل انقطاع الشبكة.
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  static const String _base = 'https://api.openweathermap.org/data/2.5';
  static const Duration _ttl = Duration(minutes: 10);

  Map<String, dynamic>? _currentCache;
  DateTime? _currentAt;
  Map<String, dynamic>? _forecastCache;
  DateTime? _forecastAt;

  Map<String, dynamic>? get cachedCurrent => _currentCache;
  Map<String, dynamic>? get cachedForecast => _forecastCache;

  /// إزاحة منطقة القرية الزمنية (ثوانٍ) من آخر استجابة — للساعة في الهيدر.
  /// 7200 = UTC+2 (مصر، بلا توقيت صيفي حاليًا) حتى وصول أول رد.
  static int tzOffsetSeconds = 7200;

  /// وقت القرية المحلي الآن.
  static DateTime villageNow() =>
      DateTime.now().toUtc().add(Duration(seconds: tzOffsetSeconds));

  Uri _uri(String path) => Uri.parse('$_base$path').replace(queryParameters: {
        'lat': AppConfig.weatherLat.toStringAsFixed(4),
        'lon': AppConfig.weatherLon.toStringAsFixed(4),
        'units': 'metric',
        'lang': 'ar',
        'appid': AppConfig.openWeatherApiKey,
      });

  /// طقس الآن — يرجع من الكاش إن كان طازجاً.
  Future<Map<String, dynamic>?> getCurrent() async {
    if (_currentCache != null &&
        _currentAt != null &&
        DateTime.now().difference(_currentAt!) < _ttl) {
      return _currentCache;
    }
    try {
      final res = await http
          .get(_uri('/weather'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _currentCache = data;
        _currentAt = DateTime.now();
        final tz = (data['timezone'] as num?)?.toInt();
        if (tz != null) tzOffsetSeconds = tz;
        return data;
      }
    } catch (_) {}
    return _currentCache;
  }

  /// توقع 5 أيام (كل 3 ساعات).
  Future<Map<String, dynamic>?> getForecast() async {
    if (_forecastCache != null &&
        _forecastAt != null &&
        DateTime.now().difference(_forecastAt!) < _ttl) {
      return _forecastCache;
    }
    try {
      final res = await http
          .get(_uri('/forecast'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _forecastCache = data;
        _forecastAt = DateTime.now();
        return data;
      }
    } catch (_) {}
    return _forecastCache;
  }

  void clearCache() {
    _currentCache = null;
    _currentAt = null;
    _forecastCache = null;
    _forecastAt = null;
  }
}

/// أدوات عرض موحّدة لبيانات الطقس.
class WeatherFormat {
  WeatherFormat._();

  static String iconUrl(String iconId, {bool big = false}) =>
      'https://openweathermap.org/img/wn/$iconId@${big ? '4x' : '2x'}.png';

  static String windDirection(num deg) {
    const dirs = [
      'شمالية', 'شمالية شرقية', 'شرقية', 'جنوبية شرقية',
      'جنوبية', 'جنوبية غربية', 'غربية', 'شمالية غربية',
    ];
    final i = (((deg + 22.5) % 360) ~/ 45) % 8;
    return dirs[i];
  }

  static String pressureHpa(num hpa) => '${hpa.round()} hPa';

  static String visibility(num m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} كم' : '${m.round()} م';

  static String clock(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
