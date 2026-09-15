import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/village_alert.dart';
import '../routes/app_routes.dart';
import '../services/alert_service.dart';
import '../services/weather_service.dart';

/// الشريط الثاني أسفل الهيدر:
/// — خبر عاجل مفعّل؟ شريط أصفر بكتابة زرقاء (الضغط = نص الخبر كاملاً).
/// — غير ذلك؟ كارت «طقس القرية» بخلفية wither.jpg وعمودين (أيقونة+حالة+درجة
///   الحرارة | العظمى/الصغرى فوق الرطوبة/الرياح) — الضغط = شاشة الطقس الكاملة.
/// التنبيه الأحمر لا يحجبه — يظهران معاً كلٌّ في شريطه.
class VillageWeatherBar extends StatefulWidget {
  const VillageWeatherBar({super.key});

  @override
  State<VillageWeatherBar> createState() => _VillageWeatherBarState();
}

class _VillageWeatherBarState extends State<VillageWeatherBar> {
  final AlertService _alerts = AlertService();
  Map<String, dynamic>? _weather;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _refreshTimer =
        Timer.periodic(const Duration(minutes: 15), (_) => _loadWeather());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    final data = await WeatherService.instance.getCurrent();
    if (mounted) setState(() => _weather = data);
  }

  void _showBreakingDialog(VillageAlert breaking) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('خبر عاجل',
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(breaking.message,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, height: 1.6)),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF9A825),
                foregroundColor: const Color(0xFF1565C0)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<VillageAlert?>(
      stream: _alerts.watchLiveBreaking(),
      builder: (context, breakingSnap) {
        final breaking = breakingSnap.data;
        if (breaking != null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showBreakingDialog(breaking),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 58),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Color(0xFFFFD54F), Color(0xFFFBC02D)]),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.bolt_rounded,
                            color: Color(0xFF1565C0), size: 18),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .scale(
                              duration: 600.ms,
                              curve: Curves.easeInOut,
                              begin: const Offset(0.85, 0.85),
                              end: const Offset(1.1, 1.1)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF1565C0),
                                      borderRadius:
                                          BorderRadius.circular(6)),
                                  child: const Text('عاجل',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white)),
                                ),
                                const SizedBox(width: 6),
                                const Text('خبر القرية العاجل — اضغط للتفاصيل',
                                    style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1565C0))),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(breaking.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xFF0D47A1),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    height: 1.35)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left_rounded,
                          color: Color(0xFF1565C0), size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 350.ms);
        }
        return _weatherStrip(theme);
      },
    );
  }

  static String _conditionAr(String? iconId, String apiDesc) {
    if (iconId != null && iconId.length >= 2) {
      switch (iconId.substring(0, 2)) {
        case '01':
          return 'مشمس';
        case '02':
          return 'غائم جزئيًا';
        case '03':
          return 'غائم';
        case '04':
          return 'غائم كليًا';
        case '09':
        case '10':
          return 'ممطر';
        case '11':
          return 'عاصفة رعدية';
        case '13':
          return 'ثلوج';
        case '50':
          return 'ضباب';
      }
    }
    return apiDesc.isNotEmpty ? apiDesc : '—';
  }

  Widget _weatherStrip(ThemeData theme) {
    final w = _weather;
    final weather = (w?['weather'] as List?)?.first as Map?;
    final main = w?['main'] as Map?;
    final wind = w?['wind'] as Map?;
    final temp = (main?['temp'] as num?)?.round();
    final desc = (weather?['description'] as String? ?? '').trim();
    final iconId = weather?['icon'] as String?;

    final lineStyle = TextStyle(
        color: Colors.white.withValues(alpha: 0.92),
        fontWeight: FontWeight.w700,
        fontSize: 10.5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, AppRoutes.weather),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              image: DecorationImage(
                image: AssetImage('assets/images/wither.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.38),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: w == null
                                ? const Icon(Icons.cloud_rounded,
                                    color: Colors.white, size: 16)
                                : CachedNetworkImage(
                                    imageUrl: WeatherFormat.iconUrl(
                                        iconId ?? '01d'),
                                    fit: BoxFit.contain,
                                    errorWidget: (_, __, ___) => const Icon(
                                        Icons.cloud_rounded,
                                        color: Colors.white,
                                        size: 16)),
                          ),
                          Text(
                              w == null
                                  ? 'جارٍ الجلب…'
                                  : _conditionAr(iconId, desc),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 8.5,
                                  height: 1.3)),
                          Text(w == null ? '—' : '$temp°م',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                  height: 1.2)),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.call_merge_rounded,
                                  size: 12,
                                  color: Colors.white
                                      .withValues(alpha: 0.85)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                    w == null
                                        ? 'جارٍ جلب حالة الطقس…'
                                        : 'العظمى ${(main?['temp_max'] as num?)?.round()}°  •  الصغرى ${(main?['temp_min'] as num?)?.round()}°',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: lineStyle),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.water_drop_rounded,
                                  size: 12,
                                  color: Colors.white
                                      .withValues(alpha: 0.85)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                    w == null
                                        ? ' '
                                        : 'رطوبة ${(main?['humidity'] as num?)?.round()}%  •  رياح ${(wind?['speed'] as num?)?.toStringAsFixed(1) ?? '—'} م/ث',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: lineStyle),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_left_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
