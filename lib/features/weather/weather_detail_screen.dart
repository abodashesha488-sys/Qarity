import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../services/weather_service.dart';
import '../../widgets/qurity_app_bar.dart';

/// شاشة الطقس الكاملة — تعرض كل بيانات openweathermap (الآن + توقع 5 أيام).
class WeatherDetailScreen extends StatefulWidget {
  const WeatherDetailScreen({super.key});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  Map<String, dynamic>? _current;
  Map<String, dynamic>? _forecast;
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() => _loading = true);
    if (force) WeatherService.instance.clearCache();
    final svc = WeatherService.instance;
    final current = await svc.getCurrent();
    final forecast = await svc.getForecast();
    if (!mounted) return;
    setState(() {
      _current = current;
      _forecast = forecast;
      _offline = current == null;
      _loading = false;
    });
  }

  String _fmtTime(int epochSec) {
    final tz = (_current?['timezone'] as num?)?.toInt() ?? 0;
    // epochSec + إزاحة المنطقة = وقت الحائط المحلي للموقع؛ نقرأه كوحدات UTC.
    final dt = DateTime.fromMillisecondsSinceEpoch(
        (epochSec + tz) * 1000,
        isUtc: true);
    return dt.format24h();
  }

  /// أرضية موحّدة لكل بطاقات الشاشة: زجاجية فوق الأزرق الداكن.
  BoxDecoration get _panel => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      );

  /// عنوان قسم موحّد: شريط ذهبي قصير + عنوان سميك + ملاحظة اختيارية.
  Widget _sectionTitle(String title, {String? note}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.headerAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900)),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(note,
              style: const TextStyle(
                  fontSize: 10.5, color: Colors.white70, height: 1.3)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: QurityAppBar(
        title: 'طقس القرية',
        actions: [
          IconButton(
              tooltip: 'تحديث',
              onPressed: () => _load(force: true),
              icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.headerAccent))
          : _offline
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 64, color: Colors.white54),
                      const SizedBox(height: 14),
                      Text('تعذّر جلب الطقس — تحقق من الاتصال',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.white)),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                          onPressed: () => _load(force: true),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _load(force: true),
                  color: AppColors.headerAccent,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _sectionTitle('الآن في القرية'),
                      const SizedBox(height: 10),
                      _hero(theme),
                      const SizedBox(height: 20),
                      _sectionTitle('تفاصيل الحالة'),
                      const SizedBox(height: 10),
                      _detailsGrid(theme),
                      const SizedBox(height: 20),
                      _sectionTitle('الطقس اليوم'),
                      const SizedBox(height: 10),
                      _astroRow(theme),
                      const SizedBox(height: 20),
                      _sectionTitle('الأيام القادمة',
                          note:
                              'تجميع يومي من بيانات كل ٣ ساعات (متاح ~٥ أيام من الخدمة المجانية)'),
                      const SizedBox(height: 10),
                      _dailyList(theme),
                      const SizedBox(height: 20),
                      _sectionTitle('توقع الساعات القادمة'),
                      const SizedBox(height: 10),
                      _forecastList(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _hero(ThemeData theme) {
    final c = _current!;
    final main = c['main'] as Map;
    final weather = (c['weather'] as List).first as Map;
    final wind = (c['wind'] as Map?) ?? const {};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF1976D2), Color(0xFF4FC3F7)]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConfig.weatherCityName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                        '${(main['temp'] as num).round()}°',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            height: 1)),
                    Text(
                      (weather['description'] ?? '').toString().toUpperCase(),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                        'العظمى ${(main['temp_max'] as num).round()}°  •  الصغرى ${(main['temp_min'] as num).round()}°',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              CachedNetworkImage(
                  imageUrl:
                      WeatherFormat.iconUrl(weather['icon'], big: true),
                  width: 100,
                  height: 100,
                  errorWidget: (_, __, ___) => Icon(
                      WeatherFormat.iconGlyph(weather['icon']),
                      size: 72,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _mini(Icons.thermostat_rounded,
                  'إحساس ${(main['feels_like'] as num).round()}°'),
              _mini(Icons.water_rounded, '${main['humidity']}% رطوبة'),
              _mini(Icons.air_rounded,
                  '${WeatherFormat.windSpeedKmh(wind['speed'])} ${WeatherFormat.windDirection((wind['deg'] as num?) ?? 0)}'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _mini(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      );

  Widget _detailsGrid(ThemeData theme) {
    final c = _current!;
    final main = c['main'] as Map;
    final wind = (c['wind'] as Map?) ?? const {};
    final clouds = (c['clouds'] as Map?) ?? const {};
    final coord = (c['coord'] as Map?) ?? const {};
    final items = <(IconData, String, String)>[
      (Icons.water_rounded, 'الرطوبة', '${main['humidity']}%'),
      (Icons.speed_rounded, 'الضغط', WeatherFormat.pressureHpa(main['pressure'])),
      (Icons.air_rounded, 'الرياح',
          '${WeatherFormat.windSpeedKmh(wind['speed'])} ${WeatherFormat.windDirection((wind['deg'] as num?) ?? 0)}'),
      if (wind['gust'] != null)
        (Icons.waves_rounded, 'الهبّات', WeatherFormat.windSpeedKmh(wind['gust'])),
      (Icons.visibility_rounded, 'الرؤية',
          WeatherFormat.visibility(c['visibility'] ?? 0)),
      (Icons.cloud_rounded, 'الغيوم', '${clouds['all'] ?? 0}%'),
      (Icons.public_rounded, 'الإحداثيات',
          '${(coord['lat'] as num?)?.toStringAsFixed(3) ?? '—'} , ${(coord['lon'] as num?)?.toStringAsFixed(3) ?? '—'}'),
      (Icons.schedule_rounded, 'آخر تحديث',
          _fmtTime((c['dt'] as num?)?.toInt() ?? 0)),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((e) => SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: _tile(theme, e.$1, e.$2, e.$3),
              ))
          .toList(),
    );
  }

  Widget _tile(ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panel,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.white70)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _astroRow(ThemeData theme) {
    final sys = (_current!['sys'] as Map?) ?? const {};
    final w = (_current!['weather'] as List).first as Map;
    final iconId = (w['icon'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: _panel,
      child: Row(
        children: [
          Expanded(
            child: _astro(
              const Icon(Icons.wb_sunny_rounded,
                  color: Colors.white, size: 22),
              'الشروق',
              sys['sunrise'] != null ? _fmtTime(sys['sunrise']) : '—',
            ),
          ),
          _astroDivider(),
          Expanded(
            child: _astro(
              const Icon(Icons.nights_stay_rounded,
                  color: Colors.white, size: 22),
              'الغروب',
              sys['sunset'] != null ? _fmtTime(sys['sunset']) : '—',
            ),
          ),
          _astroDivider(),
          Expanded(
            child: _astro(
              // أيقونة الحالة كما يقدّمها المزود نفسه — لا رمز مختار يدويًا
              CachedNetworkImage(
                  imageUrl: WeatherFormat.iconUrl(iconId),
                  width: 28,
                  height: 28,
                  errorWidget: (_, __, ___) => Icon(
                      WeatherFormat.iconGlyph(iconId),
                      color: Colors.white,
                      size: 22)),
              'الحالة',
              WeatherFormat.conditionAr(
                  iconId, (w['description'] ?? '').toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _astroDivider() => Container(
        width: 1,
        height: 34,
        color: Colors.white.withValues(alpha: 0.18),
      );

  Widget _astro(Widget icon, String label, String value) => Column(
        children: [
          SizedBox(height: 28, child: Center(child: icon)),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: Colors.white70)),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _dailyList(ThemeData theme) {
    final list = (_forecast?['list'] as List?) ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();
    final tz = (_current?['timezone'] as num?)?.toInt() ?? 0;
    // تجميع حسب اليوم المحلي للقرية
    final days = <String, List<Map>>{};
    for (final e in list) {
      final m = e as Map;
      final local = DateTime.fromMillisecondsSinceEpoch(
          ((m['dt'] as num).toInt() + tz) * 1000,
          isUtc: true);
      final key =
          '${local.year}-${local.month}-${local.day}';
      days.putIfAbsent(key, () => []).add(m);
    }
    final weekdayNames = const [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
    ];
    final monthNames = const [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final rows = days.entries.take(6).toList();
    return Column(
      children: [
        for (final r in rows) _dayRow(theme, r.value, weekdayNames, monthNames),
      ],
    );
  }

  Widget _dayRow(ThemeData theme, List<Map> slots,
      List<String> weekdayNames, List<String> monthNames) {
    double min = 999, max = -999;
    for (final s in slots) {
      final m = s['main'] as Map;
      final t = (m['temp'] as num).toDouble();
      final tmin = (m['temp_min'] as num?)?.toDouble() ?? t;
      final tmax = (m['temp_max'] as num?)?.toDouble() ?? t;
      if (tmin < min) min = tmin;
      if (tmax > max) max = tmax;
    }
    // تمثيل اليوم: أقرب مقطع للظهيرة (12 ظ)
    final tz = (_current?['timezone'] as num?)?.toInt() ?? 0;
    Map noon = slots.first;
    var bestDiff = 99;
    for (final s in slots) {
      final local = DateTime.fromMillisecondsSinceEpoch(
          ((s['dt'] as num).toInt() + tz) * 1000,
          isUtc: true);
      final diff = (local.hour - 12).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        noon = s;
      }
    }
    final w = (noon['weather'] as List).first as Map;
    final localDt = DateTime.fromMillisecondsSinceEpoch(
        ((noon['dt'] as num).toInt() + tz) * 1000,
        isUtc: true);
    final isToday = localDt.day == DateTime.fromMillisecondsSinceEpoch(
                (((_current?['dt'] as num?)?.toInt() ?? 0) + tz) * 1000,
                isUtc: true)
            .day &&
        localDt.month ==
            DateTime.fromMillisecondsSinceEpoch(
                    (((_current?['dt'] as num?)?.toInt() ?? 0) + tz) * 1000,
                    isUtc: true)
                .month;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _panel,
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isToday ? 'اليوم' : weekdayNames[localDt.weekday - 1],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
                Text('${localDt.day} ${monthNames[localDt.month - 1]}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          CachedNetworkImage(
              imageUrl: WeatherFormat.iconUrl(w['icon']),
              width: 42,
              height: 42,
              errorWidget: (_, __, ___) => Icon(
                  WeatherFormat.iconGlyph(w['icon']), color: Colors.white)),
          const SizedBox(width: 8),
          Expanded(
            child: Text((w['description'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          Text('${max.round()}°',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
          const SizedBox(width: 8),
          Text('${min.round()}°',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _forecastList(ThemeData theme) {
    final list = (_forecast?['list'] as List?) ?? const [];
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _panel,
        child: Center(
          child: Text('لا تتوفر بيانات التوقع',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ),
      );
    }
    final upcoming = list.take(8).toList();
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: upcoming.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final it = upcoming[i] as Map;
          final main = it['main'] as Map;
          final w = (it['weather'] as List).first as Map;
          return Container(
            width: 78,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: _panel,
            child: Column(
              children: [
                Text(_fmtTime((it['dt'] as num).toInt()),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                CachedNetworkImage(
                    imageUrl: WeatherFormat.iconUrl(w['icon']),
                    width: 40,
                    height: 40,
                    errorWidget: (_, __, ___) => Icon(
                        WeatherFormat.iconGlyph(w['icon']),
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('${(main['temp'] as num).round()}°',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text((w['description'] ?? '').toString(),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white70, fontSize: 9)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

extension on DateTime {
  String format24h() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
