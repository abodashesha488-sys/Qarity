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
  final PrayerTimeEntry? eidPrayer;

  const VillagePrayerSchedule({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.eidPrayer,
  });

  List<PrayerTimeEntry> get all => [fajr, sunrise, dhuhr, asr, maghrib, isha];

  List<PrayerTimeEntry> get allWithEid => [
        fajr,
        sunrise,
        if (eidPrayer != null) eidPrayer!,
        dhuhr,
        asr,
        maghrib,
        isha,
      ];

  /// الصلاة القادمة والوقت المتبقي لها (تشمل صلاة العيد في يومها)
  (PrayerTimeEntry, Duration) getNextPrayer(DateTime now) {
    for (final p in allWithEid) {
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

  /// الصلاة التي حان وقتها الآن (خلال نافذة 5 دقائق من دخول الوقت)
  PrayerTimeEntry? getCurrentActivePrayer(DateTime now) {
    for (final p in allWithEid.reversed) {
      if (!p.time.isAfter(now) &&
          now.isBefore(p.time.add(const Duration(minutes: 5)))) {
        return p;
      }
    }
    return null;
  }

  static String formatRemainingTime(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) {
      return 'الآن';
    }
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours س و $minutes د';
    } else if (hours > 0) {
      return '$hours س';
    } else if (d.inMinutes < 5) {
      if (minutes > 0 && seconds > 0) {
        return '$minutes د و $seconds ث';
      } else if (seconds > 0) {
        return '$seconds ثانية';
      } else {
        return '$minutes دقيقة';
      }
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

    // حساب صلاة العيدين طبقاً للشريعة والمواقيت الفلكية المصرية (بعد الشروق بـ 20 دقيقة)
    final hijri = IslamicCalendarHelper.fromGregorian(target);
    PrayerTimeEntry? eid;
    if (hijri.isEidAlFitrDay) {
      eid = PrayerTimeEntry(
        name: 'eid_fitr',
        nameAr: 'صلاة عيد الفطر المبارك',
        emoji: '🎉',
        time: _hoursToDateTime(target, sunriseHours + (20.0 / 60.0)),
      );
    } else if (hijri.isEidAlAdhaDay) {
      eid = PrayerTimeEntry(
        name: 'eid_adha',
        nameAr: 'صلاة عيد الأضحى المبارك',
        emoji: '🐑',
        time: _hoursToDateTime(target, sunriseHours + (20.0 / 60.0)),
      );
    }

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
      eidPrayer: eid,
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

/// نموذج التاريخ الهجري
class HijriDate {
  final int year;
  final int month; // 1..12
  final int day; // 1..30

  const HijriDate({required this.year, required this.month, required this.day});

  String get monthNameAr => switch (month) {
        1 => 'محرم',
        2 => 'صفر',
        3 => 'ربيع الأول',
        4 => 'ربيع الآخر',
        5 => 'جمادى الأولى',
        6 => 'جمادى الآخرة',
        7 => 'رجب',
        8 => 'شعبان',
        9 => 'رمضان',
        10 => 'شوال',
        11 => 'ذو القعدة',
        12 => 'ذو الحجة',
        _ => '',
      };

  /// أول أيام شهر رمضان المبارك
  bool get isFirstDayOfRamadan => month == 9 && day == 1;

  /// أيام عيد الفطر المبارك (1 - 3 شوال)
  bool get isEidAlFitr => month == 10 && day >= 1 && day <= 3;

  /// يوم صلاة عيد الفطر (1 شوال)
  bool get isEidAlFitrDay => month == 10 && day == 1;

  /// أيام عيد الأضحى المبارك (10 - 13 ذو الحجة)
  bool get isEidAlAdha => month == 12 && day >= 10 && day <= 13;

  /// يوم صلاة عيد الأضحى (10 ذو الحجة)
  bool get isEidAlAdhaDay => month == 12 && day == 10;
}

/// مساعد الحسابات الفلكية الهجرية والتهاني الرسمية لقرية أبودشيشة
class IslamicCalendarHelper {
  /// تحويل التاريخ الميلادي إلى التاريخ الهجري الفلكي المعتمد بمصر
  static HijriDate fromGregorian(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;

    var yy = y;
    var mm = m;
    if (mm <= 2) {
      yy -= 1;
      mm += 12;
    }
    final a = (yy / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (yy + 4716)).floor() +
        (30.6001 * (mm + 1)).floor() +
        d +
        b -
        1524;

    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l1 = l - 10631 * n + 354;
    final j = ((10985 - l1) / 5316).floor() * ((50 * l1) / 17719).floor() +
        (l1 / 5670).floor() * ((43 * l1) / 15238).floor();
    final l2 = l1 -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    final hMonth = ((24 * l2) / 709).floor();
    final hDay = l2 - ((709 * hMonth) / 24).floor();
    final hYear = 30 * n + j - 30;

    return HijriDate(year: hYear, month: hMonth, day: hDay);
  }

  /// نص التهنئة الرسمية لجميع المستخدمين عند دخول أول أيام رمضان أو أيام العيدين
  static String? getSeasonalGreeting(DateTime date) {
    final h = fromGregorian(date);
    if (h.isFirstDayOfRamadan) {
      return 'تطبيق قرية أبودشيشة يهنئكم بحلول شهر رمضان المبارك، تقبل الله منا ومنكم صالح الأعمال 🌙';
    }
    if (h.isEidAlFitr) {
      return 'تطبيق قرية أبودشيشة يهنئكم بحلول عيد الفطر المبارك، وكل عام وأنتم بخير 🎉';
    }
    if (h.isEidAlAdha) {
      return 'تطبيق قرية أبودشيشة يهنئكم بحلول عيد الأضحى المبارك، وكل عام وأنتم بخير 🐑';
    }
    return null;
  }
}
