/// صياغة عربية «منذ …» لعبت الزمن منذ إنشاء عنصر، بمراحل:
/// دقائق ← ساعات (≤24س) ← أيام ← أسابيع ← أشهر ← سنوات.
///
/// كانت بطاقة الخبر تعرض زمن قراءة تقديريًا من عدد كلمات الملخّص
/// («٣ د») فتنسب للخبر وقتًا لا علاقة له بوقت إنشائه.
library;

String relativeTimeLabelAr(DateTime? at, {DateTime? now}) {
  if (at == null) return '';
  final diff = (now ?? DateTime.now()).difference(at);
  if (diff.isNegative) return 'الآن';
  final minutes = diff.inMinutes;
  if (minutes < 1) return 'الآن';
  if (minutes < 60) return 'منذ ${_countAr(minutes, 'دقيقة', 'دقيقتين', 'دقائق', 'دقيقةً')}';
  final hours = diff.inHours;
  if (hours < 24) return 'منذ ${_countAr(hours, 'ساعة', 'ساعتين', 'ساعات', 'ساعةً')}';
  final days = diff.inDays;
  if (days < 7) return 'منذ ${_countAr(days, 'يوم', 'يومين', 'أيام', 'يومًا')}';
  final weeks = days ~/ 7;
  if (weeks < 5) return 'منذ ${_countAr(weeks, 'أسبوع', 'أسبوعين', 'أسابيع', 'أسبوعًا')}';
  final months = days ~/ 30;
  if (months < 12) {
    return 'منذ ${_countAr(months, 'شهر', 'شهرين', 'أشهر', 'شهرًا')}';
  }
  final years = months ~/ 12;
  return 'منذ ${_countAr(years, 'سنة', 'سنتين', 'سنوات', 'سنةً')}';
}

/// ١ مفرد · ٢ مثنى · ٣–٩ جمع قلة · ١٠+ جمع كثرة
String _countAr(int n, String singular, String dual, String few, String many) {
  if (n == 1) return singular;
  if (n == 2) return dual;
  if (n <= 10) return '$n $few';
  return '$n $many';
}
