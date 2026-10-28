import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_times_service.dart';

/// خدمة التاريخ الهجري الموثق لقرية أبودشيشة.
///
/// نظراً لأن التاريخ الهجري الشرعي مرتبط برؤية الهلال واستطلاع دار الإفتاء
/// ولا يعتمد فقط على المعادلات الحسابية الثابتة مع التاريخ الميلادي:
/// 1. يتم الاستعلام من المصدر الفلكي المعتمد لرؤية الهلال وتقويم أم القرى (AlAdhan API).
/// 2. تُحفظ النتيجة في التخزين المحلي (SharedPreferences وكاش الذاكرة) لتكون متاحة دائماً وفورياً حتى دون إنترنت.
/// 3. في حال عدم وجود إنترنت لأول مرة، يُستخدم الحساب الفلكي الدقيق كاحتياطي تلقائي.
class HijriCalendarService {
  HijriCalendarService._();
  static final HijriCalendarService instance = HijriCalendarService._();

  static const String _apiBase = 'https://api.aladhan.com/v1/gToH';
  final Map<String, HijriDate> _memoryCache = {};
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);
  bool _isFetching = false;

  String _cacheKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// إرجاع التاريخ الهجري فوراً وبلا أي تأخير (متزامناً)
  HijriDate getHijriDateSync(DateTime gregorian) {
    final key = _cacheKey(gregorian);
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!;
    }
    // احتياطي الحساب الفلكي المعتمد حتى يتم التحقق
    return IslamicCalendarHelper.fromGregorian(gregorian);
  }

  /// إرجاع النص المنسق المطلوب: ( 1 رمضان 1445 هـ )
  String formatFor(DateTime gregorian) {
    final h = getHijriDateSync(gregorian);
    return '${h.day} ${h.monthNameAr} ${h.year} هـ';
  }

  /// جلب التاريخ الهجري الموثق من المصدر الرسمي مع كاش محلي
  Future<HijriDate> fetchVerifiedHijriDate(DateTime gregorian) async {
    final key = _cacheKey(gregorian);

    // 1) كاش الذاكرة
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!;
    }

    // 2) التخزين المحلي الدائم
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('hijri_verified_$key');
      if (savedJson != null) {
        final map = jsonDecode(savedJson) as Map<String, dynamic>;
        final h = HijriDate(
          year: map['year'] as int,
          month: map['month'] as int,
          day: map['day'] as int,
        );
        _memoryCache[key] = h;
        return h;
      }
    } catch (_) {}

    // 3) الاستعلام من المصدر الرسمي للرؤية
    if (!_isFetching) {
      _isFetching = true;
      try {
        final dStr =
            '${gregorian.day.toString().padLeft(2, '0')}-${gregorian.month.toString().padLeft(2, '0')}-${gregorian.year}';
        final uri = Uri.parse('$_apiBase?date=$dStr');
        final response =
            await http.get(uri).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final hijri = data['data']?['hijri'];
          if (hijri != null) {
            final day = int.tryParse('${hijri['day']}') ?? 1;
            final month = int.tryParse('${hijri['month']?['number']}') ?? 1;
            final year = int.tryParse('${hijri['year']}') ?? 1445;
            final h = HijriDate(year: year, month: month, day: day);

            _memoryCache[key] = h;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'hijri_verified_$key',
              jsonEncode({'year': year, 'month': month, 'day': day}),
            );

            changeNotifier.value++;
            return h;
          }
        }
      } catch (e) {
        debugPrint('HijriCalendarService error: $e');
      } finally {
        _isFetching = false;
      }
    }

    // 4) احتياطي الحساب الفلكي
    final fallback = IslamicCalendarHelper.fromGregorian(gregorian);
    _memoryCache[key] = fallback;
    return fallback;
  }
}
