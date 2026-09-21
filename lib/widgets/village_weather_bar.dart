import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/village_alert.dart';
import '../services/alert_service.dart';
import '../services/alert_sound_service.dart';
import '../services/weather_service.dart';

class VillageWeatherBar extends StatefulWidget {
  const VillageWeatherBar({super.key});

  @override
  State<VillageWeatherBar> createState() => _VillageWeatherBarState();
}

class _VillageWeatherBarState extends State<VillageWeatherBar> {
  final AlertService _alerts = AlertService();
  Map<String, dynamic>? _weather;
  Timer? _refreshTimer;
  Timer? _breakingExpiryTimer;
  StreamSubscription<VillageAlert?>? _breakingSubscription;
  VillageAlert? _breaking;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _loadWeather(),
    );
    _breakingSubscription =
        _alerts.watchLiveBreaking().listen(_onBreakingChanged);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _breakingExpiryTimer?.cancel();
    _breakingSubscription?.cancel();
    super.dispose();
  }

  void _onBreakingChanged(VillageAlert? breaking) {
    if (!mounted) return;
    _breakingExpiryTimer?.cancel();
    _breakingExpiryTimer = null;
    _breaking = breaking;

    if (breaking != null && breaking.mode == VillageAlertMode.sound) {
      final stamp = breaking.updatedAt?.millisecondsSinceEpoch ?? 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(AlertSound.ringOnce('alert_ring_breaking_$stamp'));
        }
      });
    }

    final expiresAt = breaking?.expiresAt;
    if (expiresAt != null) {
      final delay = expiresAt.difference(DateTime.now());
      if (delay > Duration.zero) {
        _breakingExpiryTimer = Timer(delay, () {
          if (!mounted) return;
          setState(() => _breaking = null);
        });
      }
    }
    setState(() {});
  }

  Future<void> _loadWeather() async {
    final data = await WeatherService.instance.getCurrent();
    if (mounted) setState(() => _weather = data);
  }

  @override
  Widget build(BuildContext context) {
    final data = _weather;
    final weather = (data?['weather'] as List?)?.first as Map?;
    final main = data?['main'] as Map?;
    final wind = data?['wind'] as Map?;
    final temp = (main?['temp'] as num?)?.round();
    final tempMax = (main?['temp_max'] as num?)?.round();
    final tempMin = (main?['temp_min'] as num?)?.round();
    final humidity = (main?['humidity'] as num?)?.round();
    final windSpeed = (wind?['speed'] as num?)?.toStringAsFixed(1) ?? '0';
    final windDeg = wind?['deg'];
    final windDir = windDeg != null ? _windDirection(windDeg) : '--';
    final iconId = weather?['icon'] as String? ?? '01d';
    final description = (weather?['description'] as String? ?? '').trim();
    final arabicDesc = _conditionAr(iconId, description);

    final breaking = _breaking;
    if (breaking != null && breaking.liveAt(DateTime.now())) {
      return _breakingStrip(breaking);
    }
    return _weatherStrip(
      arabicDesc: arabicDesc,
      temp: temp,
      tempMax: tempMax,
      tempMin: tempMin,
      humidity: humidity,
      windSpeed: windSpeed,
      windDir: windDir,
      iconId: iconId,
    );
  }

  Widget _breakingStrip(VillageAlert breaking) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBreakingDialog(breaking),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC107), Color(0xFFFFE082)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded,
                    color: Color(0xFF0D47A1), size: 25),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('خبر عاجل',
                          style: TextStyle(
                              color: Color(0xFF0D47A1),
                              fontSize: 10,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(breaking.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFF0D47A1),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              height: 1.3)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF0D47A1), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBreakingDialog(VillageAlert breaking) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: Color(0xFFF9A825)),
            SizedBox(width: 8),
            Text('خبر عاجل'),
          ],
        ),
        content: Text(breaking.message,
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.6)),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1)),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  Widget _weatherStrip({
    required String arabicDesc,
    required int? temp,
    required int? tempMax,
    required int? tempMin,
    required int? humidity,
    required String windSpeed,
    required String windDir,
    required String iconId,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, '/weather'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          'https://openweathermap.org/img/wn/$iconId@2x.png',
                      fit: BoxFit.contain,
                      width: 36,
                      height: 36,
                      errorWidget: (_, __, ___) => const Icon(
                          Icons.cloud_rounded,
                          color: Colors.white,
                          size: 22),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text('طقس قرية أبودشيشة',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1)),
                              ),
                              Text(
                                temp != null ? '$temp°م' : '—',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$arabicDesc  •  العظمى ${tempMax != null ? '$tempMax°' : '—'} / الصغرى ${tempMin != null ? '$tempMin°' : '—'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                height: 1.2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'رطوبة ${humidity ?? 0}%  •  رياح $windSpeed م/ث $windDir',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                height: 1.1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_left_rounded,
                        size: 18, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _conditionAr(String? iconId, String? apiDesc) {
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
    return apiDesc ?? '—';
  }

  String _windDirection(num deg) {
    const dirs = [
      'شمالية',
      'شمالية شرقية',
      'شرقية',
      'جنوبية شرقية',
      'جنوبية',
      'جنوبية غربية',
      'غربية',
      'شمالية غربية',
    ];
    final i = (((deg + 22.5) % 360) ~/ 45) % 8;
    return dirs[i];
  }
}
