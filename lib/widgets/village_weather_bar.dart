import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/village_alert.dart';
import '../routes/app_routes.dart';
import '../services/alert_service.dart';
import '../services/weather_service.dart';

/// الشريط الثاني أسفل الهيدر — بنفس مقاس كارت «حكمة اليوم» تماماً:
/// — خبر عاجل مفعّل؟ شريط أصفر بكتابة زرقاء (الضغط = نص الخبر كاملاً).
/// — غير ذلك؟ «طقس القرية» (الضغط = شاشة الطقس الكاملة).
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

  Widget _weatherStrip(ThemeData theme) {
    final w = _weather;
    final weather = (w?['weather'] as List?)?.first as Map?;
    final main = w?['main'] as Map?;
    final temp = (main?['temp'] as num?)?.round();
    final desc = (weather?['description'] as String? ?? '').trim();
    final iconId = weather?['icon'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, AppRoutes.weather),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: w == null
                      ? const Icon(Icons.cloud_rounded,
                          color: Colors.white, size: 24)
                      : CachedNetworkImage(
                          imageUrl: WeatherFormat.iconUrl(iconId ?? '01d'),
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.cloud_rounded,
                              color: Colors.white,
                              size: 24)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('طقس القرية • اضغط للتفاصيل والتوقعات',
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white
                                  .withValues(alpha: 0.85))),
                      const SizedBox(height: 2),
                      Text(
                        w == null
                            ? 'جارٍ جلب حالة الطقس…'
                            : '$temp°م  •  $desc  •  العظمى ${(main?['temp_max'] as num?)?.round()}° / الصغرى ${(main?['temp_min'] as num?)?.round()}°',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded,
                    size: 18, color: Colors.white.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
