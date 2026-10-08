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
  int? _rainChance;
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
    final forecast = await WeatherService.instance.getForecast();
    if (mounted) {
      setState(() {
        _weather = data;
        _rainChance = _nearestRainChance(forecast);
      });
    }
  }

  /// احتمال سقوط الأمطار لأقرب فتحة ثلاثية ساعات من الآن، أو null عند غياب
  /// البيانات — والكارت يعرض «—» الصادقة لا صفرًا مخترعًا.
  static int? _nearestRainChance(Map<String, dynamic>? forecast) {
    final slots = (forecast?['list'] as List?)?.whereType<Map>();
    if (slots == null || slots.isEmpty) return null;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final slot in slots) {
      final dt = slot['dt'];
      if (dt is num && dt >= nowSeconds) return _chanceOf(slot['pop']);
    }
    return _chanceOf(slots.first['pop']);
  }

  static int? _chanceOf(Object? pop) {
    final value = pop is num ? pop : null;
    if (value == null) return null;
    return (value * 100).clamp(0, 100).round();
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
    final arabicDesc = WeatherFormat.conditionAr(iconId, description);

    final breaking = _breaking;
    if (breaking != null && breaking.liveAt(DateTime.now())) {
      return _breakingStrip(breaking);
    }
    return _weatherStrip(
      arabicDesc: arabicDesc,
      temp: temp,
      rainChance: _rainChance,
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
    required int? rainChance,
    required int? tempMax,
    required int? tempMin,
    required int? humidity,
    required String windSpeed,
    required String windDir,
    required String iconId,
  }) {
    // أرضية الكارت صورة `wither.jpg`، وهي لوحة فاتحة شبه موحدة في الوضعين: قياس
    // الصورة نفسها أعطى أقل بكسل (232، 242، 231) وأعلاها (236، 246، 237)، أي فرق
    // أربع درجات فقط، فلا حجاب فوقها ولا حاجة لحساب الحبر على عائلة الألوان —
    // `readableInk` يقيس على أرضية الثيم، فتمرير أرضية الكارت كدلالة كان يعطي
    // عكس المقصود ويجعل النص بلون الخلفية في الوضع الداكن.
    const plate = Color(0xFFE9F3E8);
    const ink = Color(0xFF10331F);
    const inkMuted = Color(0xFF33513F);
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
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              color: plate,
              border: Border.all(color: ink.withValues(alpha: 0.20)),
              image: const DecorationImage(
                image: AssetImage('assets/images/wither.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  // عمود الرمز: أيقونة الحالة كما يرسلها المزود، ورمز الحالة عند الفشل
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.62),
                      shape: BoxShape.circle,
                      border: Border.all(color: ink.withValues(alpha: 0.10)),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: WeatherFormat.iconUrl(iconId),
                      fit: BoxFit.contain,
                      width: 32,
                      height: 32,
                      errorWidget: (_, __, ___) => Icon(
                          WeatherFormat.iconGlyph(iconId), color: ink, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // العمود الأول: اسم القرية ثم حالتها العربية، بلا أي اقتصاص للنص
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('طقس قرية أبودشيشة',
                            style: TextStyle(
                                color: ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                height: 1.1)),
                        const SizedBox(height: 2),
                        Text(arabicDesc,
                            style: const TextStyle(
                                color: ink,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                height: 1.2)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // العمود الثاني: درجة الحرارة ثم احتمال سقوط الأمطار
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(temp != null ? '$temp°م' : '—',
                            style: const TextStyle(
                                color: ink,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                height: 1.1)),
                        Text(rainChance != null ? 'أمطار $rainChance%' : 'أمطار —',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: inkMuted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                height: 1.15)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // العمود الثالث: باقي البيانات — سطر لكل قيمة
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('العظمى ${tempMax != null ? '$tempMax°' : '—'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: inkMuted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                height: 1.15)),
                        Text('الصغرى ${tempMin != null ? '$tempMin°' : '—'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: inkMuted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                height: 1.15)),
                        Text('رطوبة ${humidity ?? 0}%',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: inkMuted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                height: 1.15)),
                        Text('رياح $windSpeed م/ث $windDir',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: inkMuted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                height: 1.15)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_left_rounded, size: 18, color: ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
