import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/utils/time_format.dart';
import '../../models/agriculture_content_model.dart';
import '../../services/weather_service.dart';
import '../../widgets/agriculture_content_panel.dart';
import '../../widgets/qurity_app_bar.dart';

/// شاشة أحوال الطقس مع إرشادات زراعية — تستخدم بيانات طقس القرية
class WeatherAdvisoryScreen extends StatefulWidget {
  const WeatherAdvisoryScreen({super.key});

  @override
  State<WeatherAdvisoryScreen> createState() => _WeatherAdvisoryScreenState();
}

class _WeatherAdvisoryScreenState extends State<WeatherAdvisoryScreen> {
  final WeatherService _weather = WeatherService.instance;
  Map<String, dynamic>? _current;
  Map<String, dynamic>? _forecast;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _weather.getCurrent(),
        _weather.getForecast(),
      ]);
      if (mounted) {
        setState(() {
          _current = results[0];
          _forecast = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذر تحميل بيانات الطقس';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFF1565C0); // أزرق

    return Scaffold(
      appBar: QurityAppBar(
        title: 'أحوال الطقس والإرشادات',
        color: color,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadWeather,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _loading
          ? _buildSkeleton(theme, color)
          : _error != null
              ? _buildError(theme, color)
              : RefreshIndicator(
                  onRefresh: _loadWeather,
                  color: color,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_current != null) ...[
                          const AgricultureContentPanel(
                              section: AgricultureSections.weather),
                          _buildCurrentWeatherCard(context, color),
                          const SizedBox(height: 20),
                          _buildAgriculturalAdvisoryCard(context, color),
                          const SizedBox(height: 20),
                        ],
                        if (_forecast != null) ...[
                          _buildSectionTitle(context, 'توقعات 5 أيام', color),
                          const SizedBox(height: 12),
                          _buildForecastList(context, color),
                          const SizedBox(height: 20),
                        ],
                        _buildSectionTitle(
                            context, 'إرشادات زراعية حسب الطقس الحالي', color),
                        const SizedBox(height: 12),
                        ..._buildWeatherBasedAdvisory(context, color),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSkeleton(ThemeData theme, Color color) {
    final base = theme.colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _skeletonCard(base, height: 180),
        const SizedBox(height: 20),
        _skeletonCard(base, height: 200),
        const SizedBox(height: 20),
        _skeletonCard(base, height: 200),
        const SizedBox(height: 20),
        ...List.generate(
            5,
            (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _skeletonCard(base, height: 80))),
      ],
    );
  }

  Widget _skeletonCard(Color base, {required double height}) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withValues(alpha: 0.5),
      child: Container(
        height: height,
        decoration:
            BoxDecoration(color: base, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildError(ThemeData theme, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: color),
            const SizedBox(height: 16),
            Text(_error!,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: _loadWeather,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard(BuildContext context, Color color) {
    final theme = Theme.of(context);
    final data = _current!;
    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List).first as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>;
    final sys = data['sys'] as Map<String, dynamic>;
    final dt = DateTime.fromMillisecondsSinceEpoch(
            (data['dt'] as num).toInt() * 1000,
            isUtc: true)
        .add(Duration(seconds: data['timezone'] as int? ?? 0));

    final temp = (main['temp'] as num).toDouble();
    final feelsLike = (main['feels_like'] as num).toDouble();
    final humidity = main['humidity'] as int;
    final pressure = main['pressure'] as int;
    final windSpeed = (wind['speed'] as num).toDouble();
    final windDeg = (wind['deg'] as num?)?.toInt() ?? 0;
    final description = (weather['description'] as String).toUpperCase();
    final iconId = weather['icon'] as String;
    final iconUrl = WeatherFormat.iconUrl(iconId, big: true);
    final sunrise = DateTime.fromMillisecondsSinceEpoch(
            (sys['sunrise'] as num).toInt() * 1000,
            isUtc: true)
        .add(Duration(seconds: data['timezone'] as int? ?? 0));
    final sunset = DateTime.fromMillisecondsSinceEpoch(
            (sys['sunset'] as num).toInt() * 1000,
            isUtc: true)
        .add(Duration(seconds: data['timezone'] as int? ?? 0));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withValues(alpha: 0.3))),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Image.network(iconUrl,
                      width: 48,
                      height: 48,
                      errorBuilder: (c, u, e) => const Icon(
                          Icons.wb_sunny_rounded,
                          color: Colors.white,
                          size: 32)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800, color: color)),
                      const SizedBox(height: 4),
                      Text(
                          'القرية • ${DateFormat('EEEE، d MMMM yyyy', 'ar').format(dt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${temp.round()}°',
                        style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900, color: color)),
                    Text('محسوس: ${feelsLike.round()}°',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _WeatherMetric(
                    icon: Icons.water_drop_rounded,
                    label: 'رطوبة',
                    value: '$humidity%',
                    color: color),
                const SizedBox(width: 12),
                _WeatherMetric(
                    icon: Icons.speed_rounded,
                    label: 'رياح',
                    value:
                        '${windSpeed.toStringAsFixed(1)} م/ث ${WeatherFormat.windDirection(windDeg)}',
                    color: color),
                const SizedBox(width: 12),
                _WeatherMetric(
                    icon: Icons.compress_rounded,
                    label: 'ضغط',
                    value: '$pressure hPa',
                    color: color),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _WeatherMetric(
                    icon: Icons.wb_sunny_rounded,
                    label: 'شروق',
                    value: formatTime12(sunrise),
                    color: color),
                const SizedBox(width: 12),
                _WeatherMetric(
                    icon: Icons.nights_stay_rounded,
                    label: 'غروب',
                    value: formatTime12(sunset),
                    color: color),
                const SizedBox(width: 12),
                _WeatherMetric(
                    icon: Icons.thermostat_rounded,
                    label: 'محسوس',
                    value: '${feelsLike.round()}°',
                    color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgriculturalAdvisoryCard(BuildContext context, Color color) {
    final theme = Theme.of(context);
    final data = _current!;
    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List).first as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>;

    final temp = (main['temp'] as num).toDouble();
    final humidity = main['humidity'] as int;
    final windSpeed = (wind['speed'] as num).toDouble();
    final condition = (weather['main'] as String).toLowerCase();

    final advisories =
        _generateAdvisories(temp, humidity, windSpeed, condition);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child:
                      Icon(Icons.agriculture_rounded, color: color, size: 24)),
              const SizedBox(width: 12),
              Text('إرشادات المزارع الآن',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900, color: color)),
            ]),
            const SizedBox(height: 16),
            ...advisories.map((a) => _AdvisoryItem(text: a, color: color)),
          ],
        ),
      ),
    );
  }

  List<String> _generateAdvisories(
      double temp, int humidity, double windSpeed, String condition) {
    final List<String> advisories = [];

    // حرارة
    if (temp > 38) {
      advisories.add(
          '🔥 حرارة شديدة (>38°): ريّ صباحاً باكراً أو مساءً — تجنب الرش — استخدم تظليل للصوب');
    } else if (temp > 32) {
      advisories.add(
          '☀️ حرارة عالية (32-38°): ريّ مبكر — رش ورقي مبكراً — تظليل جزئي للخضار');
    } else if (temp < 5) {
      advisories.add(
          '❄️ برودة شديدة (<5°): خطر صقيع — ريّ خفيف مساءً للتدفئة — أغلق الصوب — لا رش');
    } else if (temp < 10) {
      advisories.add(
          '🌡️ برودة (5-10°): قلل الري — لا تسميد آزوت — احمِ المحاصيل الحساسة');
    }

    // رطوبة
    if (humidity > 85) {
      advisories.add(
          '💧 رطوبة عالية (>85%): خطر أمراض فطرية (بياض، لفحة) — رش وقائي (مانكوزيب/كليوروثالونيل) — تهوية الصوب');
    } else if (humidity < 30) {
      advisories.add(
          '🏜️ رطوبة منخفضة (<30%): إجهاد مائي — زيادة تردد الري — رش ورقي صباحاً — ملاحة حول النباتات');
    }

    // رياح
    if (windSpeed > 10) {
      advisories.add(
          '💨 رياح قوية (>10 م/ث): خطر تطاير رش — لا رش — ثبت الصوب والتلاحيف — تحقق من تكاسير');
    } else if (windSpeed > 6) {
      advisories.add(
          '🌬️ رياح معتدلة (6-10 م/ث): رش مع الحذر — اتجاه الريح — تجنب الرش الظهيرة');
    }

    // حالة الطقس
    if (condition.contains('rain') || condition.contains('drizzle')) {
      advisories.add(
          '🌧️ ممطر: تأخر الري — لا رش (يغسل المبيد) — تحقق من تصريف الحقول — راقب تعفن الجذور');
    } else if (condition.contains('thunderstorm')) {
      advisories.add(
          '⛈️ عواصف رعدية: لا تعمل في الحقول — افصل الكهرباء عن الصوب — ثبت المعدات');
    } else if (condition.contains('clear')) {
      advisories.add(
          '☀️ صافٍ: وقت مناسب للرش صباحاً/مساءً — ريّ منتظم — مراقبة آفات');
    } else if (condition.contains('cloud')) {
      advisories.add(
          '☁️ غائم: مناسب للرش الورقي — ريّ حسب الحاجة — مراقبة أمراض فطرية');
    }

    // نصائح عامة دائماً
    advisories.add(
        '📋 عام: سجل كل عملية (ري، رش، تسميد) — تفقد الحقول يومياً — استخدم مصائد فرمونية للمراقبة');

    return advisories;
  }

  Widget _buildForecastList(BuildContext context, Color color) {
    final forecast = _forecast!['list'] as List;
    final daily = <DateTime, List<Map<String, dynamic>>>{};

    for (final item in forecast) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          (item['dt'] as num).toInt() * 1000,
          isUtc: true);
      final day = DateTime(dt.year, dt.month, dt.day);
      daily.putIfAbsent(day, () => []).add(item);
    }

    final sortedDays = daily.keys.toList()..sort();

    return Column(
      children: sortedDays.take(5).map((day) {
        final items = daily[day]!;
        final midday = items.firstWhere(
            (i) =>
                DateTime.fromMillisecondsSinceEpoch(
                        (i['dt'] as num).toInt() * 1000)
                    .hour >=
                12,
            orElse: () => items[items.length ~/ 2]);
        final main = midday['main'] as Map<String, dynamic>;
        final weather =
            (midday['weather'] as List).first as Map<String, dynamic>;
        final tempMin = items
            .map((i) => (i['main']['temp_min'] as num).toDouble())
            .reduce((a, b) => a < b ? a : b);
        final tempMax = items
            .map((i) => (i['main']['temp_max'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b);
        final iconUrl = WeatherFormat.iconUrl(weather['icon'] as String);
        final desc = (weather['description'] as String).toUpperCase();

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: color.withValues(alpha: 0.25))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      Text(DateFormat('EEEE', 'ar').format(day),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 12)),
                      Text(DateFormat('d/M', 'ar').format(day),
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Image.network(iconUrl,
                    width: 48,
                    height: 48,
                    errorBuilder: (c, u, e) =>
                        const Icon(Icons.cloud_rounded, size: 48)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(desc,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('${tempMin.round()}° / ${tempMax.round()}°',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: color)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _AdvisoryBadge(
                        text: _dailyAdvisory(main, weather), color: color),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _dailyAdvisory(
      Map<String, dynamic> main, Map<String, dynamic> weather) {
    final temp = (main['temp'] as num).toDouble();
    final humidity = main['humidity'] as int;
    final condition = (weather['main'] as String).toLowerCase();

    if (condition.contains('rain')) return '🌧️ ممطر';
    if (temp > 35) return '🔥 حار';
    if (temp < 10) return '❄️ بارد';
    if (humidity > 80) return '💧 رطب';
    return '☀️ عادي';
  }

  List<Widget> _buildWeatherBasedAdvisory(BuildContext context, Color color) {
    if (_current == null) return [];
    final data = _current!;
    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List).first as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>;

    final temp = (main['temp'] as num).toDouble();
    final humidity = main['humidity'] as int;
    final windSpeed = (wind['speed'] as num).toDouble();
    final condition = (weather['main'] as String).toLowerCase();

    final advisories =
        _generateAdvisories(temp, humidity, windSpeed, condition);

    return advisories.map((a) => _AdvisoryItem(text: a, color: color)).toList();
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color color) {
    final theme = Theme.of(context);
    return Row(children: [
      Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900, color: color)),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════
// ويدجتس مساعدة
// ════════════════════════════════════════════════════════════════════

class _WeatherMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _WeatherMetric(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w900, color: color)),
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AdvisoryItem extends StatelessWidget {
  final String text;
  final Color color;
  const _AdvisoryItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.circle_rounded, size: 8, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5))),
        ],
      ),
    );
  }
}

class _AdvisoryBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _AdvisoryBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
