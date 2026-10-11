import 'dart:math' as math;

/// نموذج مواقيت الصلاة لقرية أبوديشيشة
class PrayerTimeEntry {
  final String name;
  final String nameAr;
  final String emoji;
  final DateTime time;

  const PrayerTimeEntry({
    required this.name,
    required this.nameAr,
    required this.emoji,
    required this.time,
  });

  String format12Hour() {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:$minute $period';
  }
}

class VillagePrayerSchedule {
  final DateTime date;
  final PrayerTimeEntry fajr;
  final PrayerTimeEntry sunrise;
  final PrayerTimeEntry dhuhr;
  final PrayerTimeEntry asr;
  final PrayerTimeEntry maghrib;
  final PrayerTimeEntry isha;

  const VillagePrayerSchedule({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  List<PrayerTimeEntry> get all => [fajr, sunrise, dhuhr, asr, maghrib, isha];

  /// الصلاة القادمة والوقت المتبقي لها
  (PrayerTimeEntry, Duration) getNextPrayer(DateTime now) {
    for (final p in all) {
      if (p.time.isAfter(now)) {
        return (p, p.time.difference(now));
      }
    }
    // إذا انتهت صلوات اليوم، فالصلاة القادمة فجر الغد
    final tomorrowSchedule = PrayerTimesService.calculate(
      date: date.add(const Duration(days: 1)),
    );
    return (
      tomorrowSchedule.fajr,
      tomorrowSchedule.fajr.time.difference(now),
    );
  }

  static String formatRemainingTime(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours س و $minutes د';
    } else if (hours > 0) {
      return '$hours س';
    } else if (minutes > 0) {
      return '$minutes دقيقة';
    } else {
      return 'الآن';
    }
  }
}

/// خدمة حساب مواقيت الصلاة الفلكية الدقيقة لقرية أبوديشيشة
/// طبقاً لمعايير الهيئة المصرية العامة للمساحة:
/// خط العرض: 31.02 شمالاً، خط الطول: 31.38 شرقاً
/// زاوية الفجر: 19.5°، زاوية العشاء: 17.5°
class PrayerTimesService {
  // إحداثيات قرية أبوديشيشة (مركز شربين - الدقهلية)
  static const double villageLatitude = 31.299677;
  static const double villageLongitude = 31.354846;

  // زوايا الهيئة المصرية العامة للمساحة
  static const double fajrAngle = 19.5;
  static const double ishaAngle = 17.5;

  /// فارق التوقيت لقرية أبوديشيشة (مصر) عن UTC بالساعات.
  /// صيفي (+3) من الجمعة الأخيرة من أبريل حتى نهاية الخميس الأخير من أكتوبر، وشتوي (+2) باقي العام.
  static double egyptTimeZoneOffsetHours(DateTime date) {
    final y = date.year;
    // الجمعة الأخيرة في أبريل
    var aprLastFri = 30;
    while (DateTime.utc(y, 4, aprLastFri).weekday != DateTime.friday) {
      aprLastFri--;
    }
    final dstStart = DateTime.utc(y, 4, aprLastFri);

    // الخميس الأخير في أكتوبر (ينتهي العمل بالتوقيت الصيفي بنهاية يوم الخميس)
    var octLastThu = 31;
    while (DateTime.utc(y, 10, octLastThu).weekday != DateTime.thursday) {
      octLastThu--;
    }
    final dstEnd = DateTime.utc(y, 10, octLastThu + 1);

    final dUtc = date.isUtc ? date : date.toUtc();
    if (dUtc.isAfter(dstStart) && dUtc.isBefore(dstEnd)) {
      return 3.0;
    }
    return 2.0;
  }

  /// حساب جدول الصلوات لتاريخ محدد
  static VillagePrayerSchedule calculate({DateTime? date}) {
    final target = date ?? DateTime.now();
    final y = target.year;
    final m = target.month;
    final d = target.day;

    // اليوم في السنة (Julian Day approximate)
    final jDate = _julianDate(y, m, d);
    final dEpoch = jDate - 2451545.0;

    // الموضع المتوسط للشمس
    final g = _fixAngle(357.529 + 0.98560028 * dEpoch);
    final q = _fixAngle(280.459 + 0.98564736 * dEpoch);
    final l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));

    // ميل الشمس (Declination)
    final e = 23.439 - 0.00000036 * dEpoch;
    final decl = _arcsin(_sin(e) * _sin(l));

    // معادلة الوقت (Equation of Time بالدقائق)
    final ra = _fixAngle(_arctan2(_cos(e) * _sin(l), _cos(l))) / 15.0;
    var eqtDiff = (q / 15.0) - ra;
    while (eqtDiff > 12) {
      eqtDiff -= 24;
    }
    while (eqtDiff < -12) {
      eqtDiff += 24;
    }
    final eqt = eqtDiff;

    // زوال الشمس (الظهر الفلكي) بالتوقيت العالمي UTC
    final noonUtc = 12.0 - (villageLongitude / 15.0) - eqt;

    // فارق التوقيت المحلي لقرية أبوديشيشة مع UTC للتاريخ المحدد
    final tzOffset = egyptTimeZoneOffsetHours(target);
    final localNoon = noonUtc + tzOffset;

    // حساب زوايا الساعات لمختلف الأوقات
    final sunriseHa = _sunAngleTime(-0.8333, decl, villageLatitude);
    final fajrHa = _sunAngleTime(-fajrAngle, decl, villageLatitude);
    final ishaHa = _sunAngleTime(-ishaAngle, decl, villageLatitude);

    // العصر (المذهب الشافعي/الجمهور: ظل الشيء مثله)
    final asrAltitude = _arccot(1.0 + _tan((villageLatitude - decl).abs()));
    final asrHa = _sunAngleTime(asrAltitude, decl, villageLatitude);

    final fajrHours = localNoon - fajrHa;
    final sunriseHours = localNoon - sunriseHa;
    final dhuhrHours = localNoon;
    final asrHours = localNoon + asrHa;
    final maghribHours = localNoon + sunriseHa; // الغروب وزاوية الشروق متناظرتان
    final ishaHours = localNoon + ishaHa;

    return VillagePrayerSchedule(
      date: target,
      fajr: PrayerTimeEntry(
        name: 'fajr',
        nameAr: 'الفجر',
        emoji: '🌅',
        time: _hoursToDateTime(target, fajrHours),
      ),
      sunrise: PrayerTimeEntry(
        name: 'sunrise',
        nameAr: 'الشروق',
        emoji: '☀️',
        time: _hoursToDateTime(target, sunriseHours),
      ),
      dhuhr: PrayerTimeEntry(
        name: 'dhuhr',
        nameAr: 'الظهر',
        emoji: '🌞',
        time: _hoursToDateTime(target, dhuhrHours),
      ),
      asr: PrayerTimeEntry(
        name: 'asr',
        nameAr: 'العصر',
        emoji: '🌤️',
        time: _hoursToDateTime(target, asrHours),
      ),
      maghrib: PrayerTimeEntry(
        name: 'maghrib',
        nameAr: 'المغرب',
        emoji: '🌇',
        time: _hoursToDateTime(target, maghribHours),
      ),
      isha: PrayerTimeEntry(
        name: 'isha',
        nameAr: 'العشاء',
        emoji: '🌙',
        time: _hoursToDateTime(target, ishaHours),
      ),
    );
  }

  // ─── العمليات الفلكية الرياضية ───
  static double _julianDate(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;
  }

  static double _fixAngle(double a) {
    final angle = a - 360.0 * (a / 360.0).floor();
    return angle < 0 ? angle + 360.0 : angle;
  }

  static double _sunAngleTime(double alpha, double decl, double lat) {
    final cosH = (_sin(alpha) - _sin(lat) * _sin(decl)) / (_cos(lat) * _cos(decl));
    if (cosH > 1.0) return 0; // ليل دائم
    if (cosH < -1.0) return 12; // نهار دائم
    return _arccos(cosH) / 15.0;
  }

  static double _sin(double d) => math.sin(d * math.pi / 180.0);
  static double _cos(double d) => math.cos(d * math.pi / 180.0);
  static double _tan(double d) => math.tan(d * math.pi / 180.0);
  static double _arcsin(double x) => math.asin(x.clamp(-1.0, 1.0)) * 180.0 / math.pi;
  static double _arccos(double x) => math.acos(x.clamp(-1.0, 1.0)) * 180.0 / math.pi;
  static double _arctan2(double y, double x) => math.atan2(y, x) * 180.0 / math.pi;
  static double _arccot(double x) => (math.atan(1.0 / x)) * 180.0 / math.pi;

  static DateTime _hoursToDateTime(DateTime date, double hours) {
    var h = hours.floor();
    final minFract = (hours - h) * 60;
    var m = minFract.floor();
    var s = ((minFract - m) * 60).round();

    if (s >= 60) {
      s -= 60;
      m += 1;
    }
    if (m >= 60) {
      m -= 60;
      h += 1;
    }

    if (date.isUtc) {
      return DateTime.utc(date.year, date.month, date.day, h % 24, m, s);
    }
    return DateTime(date.year, date.month, date.day, h % 24, m, s);
  }
}
