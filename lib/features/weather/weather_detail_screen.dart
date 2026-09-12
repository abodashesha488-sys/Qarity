import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_config.dart';
import '../../services/weather_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        title: const Text('طقس القرية',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () => _load(force: true),
              icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white))
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
                  color: const Color(0xFF1976D2),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _hero(theme),
                      const SizedBox(height: 16),
                      _detailsGrid(theme),
                      const SizedBox(height: 18),
                      _astroRow(theme),
                      const SizedBox(height: 18),
                      Text('توقع الساعات القادمة',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
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
                  errorWidget: (_, __, ___) => const Icon(
                      Icons.cloud_rounded,
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
                  '${wind['speed']} م/ث ${WeatherFormat.windDirection((wind['deg'] as num?) ?? 0)}'),
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
          '${wind['speed']} م/ث ${WeatherFormat.windDirection((wind['deg'] as num?) ?? 0)}'),
      if (wind['gust'] != null)
        (Icons.waves_rounded, 'الهبّات', '${wind['gust']} م/ث'),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _astro(Icons.wb_sunny_rounded, 'الشروق',
              sys['sunrise'] != null ? _fmtTime(sys['sunrise']) : '—'),
          _astro(Icons.nights_stay_rounded, 'الغروب',
              sys['sunset'] != null ? _fmtTime(sys['sunset']) : '—'),
          _astro(Icons.cloud_queue_rounded, 'الطقس',
              (_current!['weather'] as List).first['main'] ?? ''),
        ],
      ),
    );
  }

  Widget _astro(IconData icon, String label, String value) => Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _forecastList(ThemeData theme) {
    final list = (_forecast?['list'] as List?) ?? const [];
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14)),
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
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
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
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.cloud_rounded, color: Colors.white)),
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
