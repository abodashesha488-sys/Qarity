import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_config.dart';

/// خدمة الطقس — Open-Meteo (مجاني 100% وبدون مفتاح API، مع احتياطي OpenWeatherMap وكاش محلي).
/// نتيجة كل استدعاء تُخزّن مؤقتاً في الذاكرة (10 دقائق) لتحمّل انقطاع الشبكة.
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  static const String _openMeteoBase = 'https://api.open-meteo.com/v1/forecast';
  static const String _openWeatherBase = 'https://api.openweathermap.org/data/2.5';
  static const Duration _ttl = Duration(minutes: 10);
  static const String _currentStorageKey = 'offline_weather_current';
  static const String _forecastStorageKey = 'offline_weather_forecast';

  Map<String, dynamic>? _currentCache;
  DateTime? _currentAt;
  Map<String, dynamic>? _forecastCache;
  DateTime? _forecastAt;
  bool _persistentCacheLoaded = false;

  Map<String, dynamic>? get cachedCurrent => _currentCache;
  Map<String, dynamic>? get cachedForecast => _forecastCache;

  /// إزاحة منطقة القرية الزمنية (ثوانٍ) من آخر استجابة — للساعة في الهيدر.
  /// 7200 = UTC+2 (مصر) حتى وصول أول رد حي.
  static int tzOffsetSeconds = 7200;

  /// وقت القرية المحلي الآن.
  static DateTime villageNow() =>
      DateTime.now().toUtc().add(Duration(seconds: tzOffsetSeconds));

  Uri _openMeteoUri() => Uri.parse(_openMeteoBase).replace(queryParameters: {
        'latitude': AppConfig.weatherLat.toStringAsFixed(4),
        'longitude': AppConfig.weatherLon.toStringAsFixed(4),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m',
        'hourly':
            'temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,wind_speed_10m,wind_direction_10m',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max',
        'wind_speed_unit': 'ms',
        'timeformat': 'unixtime',
        'timezone': 'auto',
      });

  Uri _legacyUri(String path) =>
      Uri.parse('$_openWeatherBase$path').replace(queryParameters: {
        'lat': AppConfig.weatherLat.toStringAsFixed(4),
        'lon': AppConfig.weatherLon.toStringAsFixed(4),
        'units': 'metric',
        'lang': 'ar',
        'appid': AppConfig.openWeatherApiKey,
      });

  /// جلب الطقس والتوقعات من Open-Meteo بدون مفتاح API وبطلب شبكة واحد.
  Future<bool> _fetchOpenMeteo() async {
    try {
      final res = await http
          .get(_openMeteoUri())
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return false;
      final raw = jsonDecode(res.body) as Map<String, dynamic>;
      final current = raw['current'] as Map<String, dynamic>? ?? {};
      final daily = raw['daily'] as Map<String, dynamic>? ?? {};
      final hourly = raw['hourly'] as Map<String, dynamic>? ?? {};

      final tz = (raw['utc_offset_seconds'] as num?)?.toInt() ?? 7200;
      tzOffsetSeconds = tz;

      final wCode = (current['weather_code'] as num?)?.toInt() ?? 0;
      final isDay = (current['is_day'] as num?)?.toInt() ?? 1;
      final info = _wmoToInfo(wCode);
      final iconId = '${info.iconBase}${isDay == 1 ? 'd' : 'n'}';

      final dailyMinList = (daily['temperature_2m_min'] as List?) ?? [];
      final dailyMaxList = (daily['temperature_2m_max'] as List?) ?? [];
      final sunriseList = (daily['sunrise'] as List?) ?? [];
      final sunsetList = (daily['sunset'] as List?) ?? [];

      final tempMin = dailyMinList.isNotEmpty ? dailyMinList[0] : current['temperature_2m'];
      final tempMax = dailyMaxList.isNotEmpty ? dailyMaxList[0] : current['temperature_2m'];
      final sunrise = sunriseList.isNotEmpty ? sunriseList[0] : null;
      final sunset = sunsetList.isNotEmpty ? sunsetList[0] : null;

      final currentData = <String, dynamic>{
        'coord': {
          'lat': raw['latitude'] ?? AppConfig.weatherLat,
          'lon': raw['longitude'] ?? AppConfig.weatherLon,
        },
        'weather': [
          {
            'id': wCode,
            'main': info.main,
            'description': info.desc,
            'icon': iconId,
          }
        ],
        'main': {
          'temp': current['temperature_2m'] ?? 0,
          'feels_like': current['apparent_temperature'] ?? current['temperature_2m'] ?? 0,
          'temp_min': tempMin,
          'temp_max': tempMax,
          'pressure': (current['surface_pressure'] as num?)?.round() ?? 1013,
          'humidity': (current['relative_humidity_2m'] as num?)?.round() ?? 0,
        },
        'visibility': 10000,
        'wind': {
          'speed': current['wind_speed_10m'] ?? 0,
          'deg': (current['wind_direction_10m'] as num?)?.round() ?? 0,
          if (current['wind_gusts_10m'] != null) 'gust': current['wind_gusts_10m'],
        },
        'clouds': {
          'all': (info.iconBase == '01' ? 0 : info.iconBase == '02' ? 25 : info.iconBase == '03' ? 70 : 100),
        },
        'dt': (current['time'] as num?)?.toInt() ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        'sys': {
          if (sunrise != null) 'sunrise': (sunrise as num).toInt(),
          if (sunset != null) 'sunset': (sunset as num).toInt(),
        },
        'timezone': tz,
        'name': AppConfig.weatherCityName,
      };

      // تحويل توقعات الساعات إلى خانات كل ٣ ساعات لمطابقة الواجهات الحالية
      final times = (hourly['time'] as List?) ?? [];
      final temps = (hourly['temperature_2m'] as List?) ?? [];
      final humidities = (hourly['relative_humidity_2m'] as List?) ?? [];
      final popList = (hourly['precipitation_probability'] as List?) ?? [];
      final codes = (hourly['weather_code'] as List?) ?? [];
      final windSpeeds = (hourly['wind_speed_10m'] as List?) ?? [];
      final windDegs = (hourly['wind_direction_10m'] as List?) ?? [];

      final forecastSlots = <Map<String, dynamic>>[];
      for (int i = 0; i < times.length; i += 3) {
        final dt = (times[i] as num).toInt();
        final slotWCode = i < codes.length ? (codes[i] as num).toInt() : 0;
        final slotInfo = _wmoToInfo(slotWCode);

        final localHour = DateTime.fromMillisecondsSinceEpoch((dt + tz) * 1000, isUtc: true).hour;
        final isSlotDay = localHour >= 6 && localHour < 18;
        final slotIconId = '${slotInfo.iconBase}${isSlotDay ? 'd' : 'n'}';

        final popPercent = i < popList.length ? (popList[i] as num?)?.toDouble() ?? 0.0 : 0.0;
        final popFraction = popPercent / 100.0;

        final t = i < temps.length ? temps[i] : 0;
        final h = i < humidities.length ? humidities[i] : 0;
        final ws = i < windSpeeds.length ? windSpeeds[i] : 0;
        final wd = i < windDegs.length ? windDegs[i] : 0;

        forecastSlots.add({
          'dt': dt,
          'main': {
            'temp': t,
            'temp_min': t,
            'temp_max': t,
            'humidity': h,
            'pressure': 1013,
          },
          'weather': [
            {
              'id': slotWCode,
              'main': slotInfo.main,
              'description': slotInfo.desc,
              'icon': slotIconId,
            }
          ],
          'wind': {
            'speed': ws,
            'deg': wd,
          },
          'pop': popFraction,
        });
      }

      final forecastData = <String, dynamic>{
        'list': forecastSlots,
        'city': {
          'name': AppConfig.weatherCityName,
          'timezone': tz,
        },
      };

      _currentCache = currentData;
      _currentAt = DateTime.now();
      _forecastCache = forecastData;
      _forecastAt = DateTime.now();

      await _savePersistent(_currentStorageKey, currentData);
      await _savePersistent(_forecastStorageKey, forecastData);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// مسار احتياطي لـ OpenWeatherMap إن تعذّر Open-Meteo وكان المفتاح موجوداً.
  Future<void> _fetchLegacyOpenWeatherMap() async {
    try {
      if (_currentCache == null ||
          _currentAt == null ||
          DateTime.now().difference(_currentAt!) >= _ttl) {
        final res = await http
            .get(_legacyUri('/weather'))
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          _currentCache = data;
          _currentAt = DateTime.now();
          await _savePersistent(_currentStorageKey, data);
          final tz = (data['timezone'] as num?)?.toInt();
          if (tz != null) tzOffsetSeconds = tz;
        }
      }
      if (_forecastCache == null ||
          _forecastAt == null ||
          DateTime.now().difference(_forecastAt!) >= _ttl) {
        final res = await http
            .get(_legacyUri('/forecast'))
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          _forecastCache = data;
          _forecastAt = DateTime.now();
          await _savePersistent(_forecastStorageKey, data);
        }
      }
    } catch (_) {}
  }

  /// طقس الآن — يرجع من الكاش إن كان طازجاً، وإلا يجلبه من Open-Meteo.
  Future<Map<String, dynamic>?> getCurrent() async {
    await _loadPersistentCache();
    if (_currentCache != null &&
        _currentAt != null &&
        DateTime.now().difference(_currentAt!) < _ttl) {
      return _currentCache;
    }
    final ok = await _fetchOpenMeteo();
    if (!ok && AppConfig.openWeatherApiKey.isNotEmpty) {
      await _fetchLegacyOpenWeatherMap();
    }
    return _currentCache;
  }

  /// توقع 5 أيام (كل 3 ساعات).
  Future<Map<String, dynamic>?> getForecast() async {
    await _loadPersistentCache();
    if (_forecastCache != null &&
        _forecastAt != null &&
        DateTime.now().difference(_forecastAt!) < _ttl) {
      return _forecastCache;
    }
    final ok = await _fetchOpenMeteo();
    if (!ok && AppConfig.openWeatherApiKey.isNotEmpty) {
      await _fetchLegacyOpenWeatherMap();
    }
    return _forecastCache;
  }

  void clearCache() {
    _currentCache = null;
    _currentAt = null;
    _forecastCache = null;
    _forecastAt = null;
  }

  Future<void> _loadPersistentCache() async {
    if (_persistentCacheLoaded) return;
    _persistentCacheLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getString(_currentStorageKey);
      final forecast = prefs.getString(_forecastStorageKey);
      if (_currentCache == null && current != null) {
        _currentCache = jsonDecode(current) as Map<String, dynamic>;
      }
      if (_forecastCache == null && forecast != null) {
        _forecastCache = jsonDecode(forecast) as Map<String, dynamic>;
      }
    } catch (_) {}
  }

  Future<void> _savePersistent(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }
}

class _WmoInfo {
  final String iconBase;
  final String main;
  final String desc;
  const _WmoInfo(this.iconBase, this.main, this.desc);
}

_WmoInfo _wmoToInfo(int code) {
  switch (code) {
    case 0:
      return const _WmoInfo('01', 'Clear', 'مشمس');
    case 1:
      return const _WmoInfo('02', 'Clear', 'صافٍ غالبًا');
    case 2:
      return const _WmoInfo('02', 'Clouds', 'غائم جزئيًا');
    case 3:
      return const _WmoInfo('03', 'Clouds', 'غائم');
    case 45:
    case 48:
      return const _WmoInfo('50', 'Fog', 'ضباب');
    case 51:
    case 53:
    case 55:
    case 56:
    case 57:
      return const _WmoInfo('09', 'Drizzle', 'رذاذ');
    case 61:
    case 63:
    case 65:
      return const _WmoInfo('10', 'Rain', 'ممطر');
    case 66:
    case 67:
      return const _WmoInfo('13', 'Rain', 'أمطار متجمدة');
    case 71:
    case 73:
    case 75:
    case 77:
      return const _WmoInfo('13', 'Snow', 'ثلوج');
    case 80:
    case 81:
    case 82:
      return const _WmoInfo('09', 'Rain', 'زخات مطر');
    case 85:
    case 86:
      return const _WmoInfo('13', 'Snow', 'زخات ثلج');
    case 95:
      return const _WmoInfo('11', 'Thunderstorm', 'عاصفة رعدية');
    case 96:
    case 99:
      return const _WmoInfo('11', 'Thunderstorm', 'عاصفة رعدية مع بَرَد');
    default:
      return const _WmoInfo('03', 'Clouds', 'غائم');
  }
}

/// أدوات عرض موحّدة لبيانات الطقس.
class WeatherFormat {
  WeatherFormat._();

  static String iconUrl(String iconId, {bool big = false}) =>
      'https://openweathermap.org/img/wn/$iconId@${big ? '4x' : '2x'}.png';

  static String windDirection(num deg) {
    const dirs = [
      'شمالية',
      'شمالية شرقية',
      'شرقية',
      'جنوبية شرقية',
      'جنوبية',
      'جنوبية غربية',
      'غربية',
      'شمالية غربية',
    ];
    final i = (((deg + 22.5) % 360) ~/ 45) % 8;
    return dirs[i];
  }

  /// المزود يرسل سرعة الرياح متر/ثانية حتى مع `units=metric`، فتُحوَّل هنا في
  /// موضع واحد فلا يتفارق كارت الرئيسية عن صفحة التفاصيل ولا عن صفحة الإرشاد.
  static String windSpeedKmh(Object? speed) {
    final v = speed is num ? speed : null;
    if (v == null) return '—';
    return '${(v * 3.6).round()} كم/س';
  }

  static String pressureHpa(num hpa) => '${hpa.round()} hPa';

  /// سلة الحالة من مفتاح أيقونة المزود — مصدر واحد للتسمية ولرمز الرجوع،
  /// فالتسميات والرموز لا تتفارق عند إضافة مفتاح جديد.
  static String _bucketOf(String? iconId) {
    if (iconId == null || iconId.length < 2) return 'other';
    return switch (iconId.substring(0, 2)) {
      '01' => 'sun',
      '02' => 'few',
      '03' => 'cloud',
      '04' => 'overcast',
      '09' || '10' => 'rain',
      '11' => 'storm',
      '13' => 'snow',
      '50' => 'fog',
      _ => 'other',
    };
  }

  /// الحالة بالعربية من مفتاح أيقونة المزود، مع رجوع صادق إلى وصفه العربي.
  static String conditionAr(String? iconId, String? apiDesc) {
    final label = switch (_bucketOf(iconId)) {
      'sun' => 'مشمس',
      'few' => 'غائم جزئيًا',
      'cloud' => 'غائم',
      'overcast' => 'غائم كليًا',
      'rain' => 'ممطر',
      'storm' => 'عاصفة رعدية',
      'snow' => 'ثلوج',
      'fog' => 'ضباب',
      _ => '',
    };
    if (label.isNotEmpty) return label;
    final desc = apiDesc?.trim();
    return (desc == null || desc.isEmpty) ? '—' : desc;
  }

  /// رمز يرجع محل صورة المزود عند تعذّرها — لكل حالة رمزها، فلا سحابة واحدة
  /// تُخفي اختلاف الطقس بين المشمس والثلج.
  static IconData iconGlyph(String? iconId) => switch (_bucketOf(iconId)) {
        'sun' => Icons.wb_sunny_rounded,
        'few' => Icons.wb_cloudy_rounded,
        'cloud' => Icons.cloud_rounded,
        'overcast' => Icons.cloud_queue_rounded,
        'rain' => Icons.water_drop_rounded,
        'storm' => Icons.thunderstorm_rounded,
        'snow' => Icons.ac_unit_rounded,
        'fog' => Icons.blur_on_rounded,
        _ => Icons.cloud_rounded,
      };

  static String visibility(num m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} كم' : '${m.round()} م';

  static String clock(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
