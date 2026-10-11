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
      backgroundColor: const Color(0xFF091F3C),
      appBar: QurityAppBar(
        title: 'طقس القرية',
        actions: [
          IconButton(
              tooltip: 'تحديث',
              onPressed: () => _load(force: true),
              icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF091F3C),
              Color(0xFF0D325E),
              Color(0xFF124376),
            ],
          ),
        ),
        child: _loading
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
      ),
    );
  }

  Widget _hero(ThemeData theme) {
    final c = _current!;
    final main = c['main'] as Map;
    final weather = (c['weather'] as List).first as Map;
    final wind = (c['wind'] as Map?) ?? const {};
    final conditionTitle = WeatherFormat.conditionAr(
        weather['icon'], (weather['description'] ?? '').toString());
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E5BB5),
            Color(0xFF0288D1),
            Color(0xFF00ACC1),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 16, color: Color(0xFFFFD54F)),
              const SizedBox(width: 5),
              const Text(
                AppConfig.weatherCityName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sensors_rounded,
                        size: 11, color: Color(0xFF69F0AE)),
                    const SizedBox(width: 4),
                    Text(
                      _fmtTime((c['dt'] as num?)?.toInt() ?? 0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(main['temp'] as num).round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        conditionTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'العظمى ${(main['temp_max'] as num).round()}°   •   الصغرى ${(main['temp_min'] as num).round()}°',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              CachedNetworkImage(
                imageUrl: WeatherFormat.iconUrl(weather['icon'], big: true),
                width: 105,
                height: 105,
                errorWidget: (_, __, ___) => Icon(
                  WeatherFormat.iconGlyph(weather['icon']),
                  size: 72,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _mini(Icons.thermostat_rounded,
                    'إحساس ${(main['feels_like'] as num).round()}°'),
                _mini(Icons.water_rounded, '${main['humidity']}% رطوبة'),
                _mini(
                  Icons.air_rounded,
                  '${WeatherFormat.windSpeedKmh(wind['speed'])} ${WeatherFormat.windDirection((wind['deg'] as num?) ?? 0)}',
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _mini(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFFD54F)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );

  Widget _detailsGrid(ThemeData theme) {
    final c = _current!;
    final main = c['main'] as Map;
    final wind = (c['wind'] as Map?) ?? const {};
    final clouds = (c['clouds'] as Map?) ?? const {};
    final coord = (c['coord'] as Map?) ?? const {};
    final items = <(IconData, Color, String, String)>[
      (
        Icons.water_drop_rounded,
        const Color(0xFF4FC3F7),
        'الرطوبة',
        '${main['humidity']}%'
      ),
      (
        Icons.compress_rounded,
        const Color(0xFFFFD54F),
        'الضغط',
        WeatherFormat.pressureHpa(main['pressure'])
      ),
      (
        Icons.air_rounded,
        const Color(0xFF80CBC4),
        'الرياح',
        '${WeatherFormat.windSpeedKmh(wind['speed'])} ${WeatherFormat.windDirection((wind['deg'] as num?) ?? 0)}'
      ),
      if (wind['gust'] != null)
        (
          Icons.waves_rounded,
          const Color(0xFF81D4FA),
          'الهبّات',
          WeatherFormat.windSpeedKmh(wind['gust'])
        ),
      (
        Icons.visibility_rounded,
        const Color(0xFFCE93D8),
        'الرؤية',
        WeatherFormat.visibility(c['visibility'] ?? 0)
      ),
      (
        Icons.cloud_rounded,
        const Color(0xFFB0BEC5),
        'الغيوم',
        '${clouds['all'] ?? 0}%'
      ),
      (
        Icons.location_on_rounded,
        const Color(0xFFA5D6A7),
        'الإحداثيات',
        '${(coord['lat'] as num?)?.toStringAsFixed(3) ?? '—'} , ${(coord['lon'] as num?)?.toStringAsFixed(3) ?? '—'}'
      ),
      (
        Icons.schedule_rounded,
        const Color(0xFFFFCC80),
        'آخر تحديث',
        _fmtTime((c['dt'] as num?)?.toInt() ?? 0)
      ),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((e) => SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: _tile(theme, e.$1, e.$2, e.$3, e.$4),
              ))
          .toList(),
    );
  }

  Widget _tile(ThemeData theme, IconData icon, Color iconColor, String label,
      String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: _panel,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7.5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: iconColor.withValues(alpha: 0.35), width: 0.8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: _panel,
      child: Row(
        children: [
          Expanded(
            child: _astro(
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny_rounded,
                    color: Color(0xFFFFD54F), size: 20),
              ),
              'الشروق',
              sys['sunrise'] != null ? _fmtTime(sys['sunrise']) : '—',
            ),
          ),
          _astroDivider(),
          Expanded(
            child: _astro(
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF81D4FA).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.nights_stay_rounded,
                    color: Color(0xFF81D4FA), size: 20),
              ),
              'الغروب',
              sys['sunset'] != null ? _fmtTime(sys['sunset']) : '—',
            ),
          ),
          _astroDivider(),
          Expanded(
            child: _astro(
              CachedNetworkImage(
                imageUrl: WeatherFormat.iconUrl(iconId),
                width: 32,
                height: 32,
                errorWidget: (_, __, ___) => Icon(
                  WeatherFormat.iconGlyph(iconId),
                  color: Colors.white,
                  size: 22,
                ),
              ),
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
        height: 38,
        color: Colors.white.withValues(alpha: 0.18),
      );

  Widget _astro(Widget icon, String label, String value) => Column(
        children: [
          SizedBox(height: 32, child: Center(child: icon)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
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
      final key = '${local.year}-${local.month}-${local.day}';
      days.putIfAbsent(key, () => []).add(m);
    }
    final weekdayNames = const [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    final monthNames = const [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final rows = days.entries.take(6).toList();
    return Column(
      children: [
        for (final r in rows) _dayRow(theme, r.value, weekdayNames, monthNames),
      ],
    );
  }

  Widget _dayRow(ThemeData theme, List<Map> slots, List<String> weekdayNames,
      List<String> monthNames) {
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
    final isToday = localDt.day ==
            DateTime.fromMillisecondsSinceEpoch(
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: _panel,
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'اليوم' : weekdayNames[localDt.weekday - 1],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${localDt.day} ${monthNames[localDt.month - 1]}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          CachedNetworkImage(
            imageUrl: WeatherFormat.iconUrl(w['icon']),
            width: 38,
            height: 38,
            errorWidget: (_, __, ___) =>
                Icon(WeatherFormat.iconGlyph(w['icon']), color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (w['description'] ?? '').toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
          Text(
            '${max.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${min.round()}°',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
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
