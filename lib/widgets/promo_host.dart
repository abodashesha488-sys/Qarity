import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/promo_placements.dart';
import '../core/utils/navigator_key.dart';
import '../models/promo_model.dart';
import '../services/promo_service.dart';

const int kPromoAutoDismissSeconds = 15;

/// طبقة الإعلانات المنبثقة — تُلفّ شجرة التطبيق كاملة، وتعرض الإعلان
/// المطابق للشاشة الحالية فورًا فوق كل الصفحات (بما فيها الرئيسية).
class PromoHost extends StatefulWidget {
  const PromoHost({super.key, required this.child});
  final Widget child;

  @override
  State<PromoHost> createState() => _PromoHostState();
}

class _PromoHostState extends State<PromoHost> {
  final PromoService _service = PromoService();
  final AudioPlayer _player = AudioPlayer();
  late final Stream<List<Promo>> _stream = _service.watchAll();

  List<Promo> _all = const [];
  Set<String> _seenKeys = {};
  final Set<String> _sessionShown = {};
  Promo? _current;
  int _remaining = kPromoAutoDismissSeconds;
  Timer? _ticker;
  Timer? _openTimer;

  @override
  void initState() {
    super.initState();
    PromoLocation.instance.addListener(_onLocationChanged);
    _loadSeen();
  }

  Future<void> _loadSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seenKeys = prefs
          .getKeys()
          .where((k) => k.startsWith('promo_seen_'))
          .toSet();
    } catch (_) {}
    if (mounted) _reconcile();
  }

  void _onLocationChanged() => _reconcile();

  List<Promo> _candidates() {
    final key = PromoLocation.instance.currentKey;
    if (key.isEmpty) return const [];
    final now = DateTime.now();
    return _all.where((p) {
      if (p.placement != key || !p.isVisibleAt(now)) return false;
      if (_sessionShown.contains(p.id)) return false;
      if (p.showOnce && _seenKeys.contains(p.seenKey)) return false;
      return true;
    }).toList();
  }

  void _reconcile() {
    if (!mounted) return;
    if (_current != null) {
      final p = _current!;
      final key = PromoLocation.instance.currentKey;
      final still = p.placement == key && p.isVisibleAt(DateTime.now());
      if (still) return;
      _hide();
    }
    final next = _candidates();
    if (next.isEmpty) return;
    _openTimer?.cancel();
    _openTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final fresh = _candidates();
      if (fresh.isEmpty) return;
      _show(fresh.first);
    });
  }

  void _show(Promo promo) {
    setState(() {
      _current = promo;
      _remaining = kPromoAutoDismissSeconds;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        _dismiss();
        return;
      }
      setState(() => _remaining--);
    });
    if (promo.showOnce) {
      unawaited(() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(promo.seenKey, true);
          _seenKeys.add(promo.seenKey);
        } catch (_) {}
      }());
    }
    if (promo.vibrate) {
      unawaited(HapticFeedback.vibrate().catchError((_) {}));
    }
    if (promo.playSound) {
      unawaited(() async {
        try {
          await _player.stop();
          await _player.play(AssetSource('sounds/ding.wav'), volume: 0.9);
        } catch (_) {}
      }());
    }
  }

  void _dismiss() {
    _ticker?.cancel();
    final promo = _current;
    if (promo != null) _sessionShown.add(promo.id);
    setState(() => _current = null);
    // إعلان آخر لنفس الشاشة؟
    _openTimer?.cancel();
    _openTimer = Timer(const Duration(milliseconds: 400), _reconcile);
  }

  void _hide() {
    _ticker?.cancel();
    _openTimer?.cancel();
    if (mounted && _current != null) setState(() => _current = null);
  }

  Future<void> _openLink(Promo promo) async {
    final value = promo.linkValue.trim();
    if (promo.linkType == 'none' || value.isEmpty) {
      _dismiss();
      return;
    }
    if (promo.linkType == 'app') {
      final (route, args) = PromoInternalLink.decode(value);
      _dismiss();
      try {
        navigatorKey.currentState
            ?.pushNamed(route, arguments: args)
            .ignore();
      } catch (_) {}
      return;
    }
    final url = buildExternalUrl(promo.linkType, value);
    _dismiss();
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _openTimer?.cancel();
    PromoLocation.instance.removeListener(_onLocationChanged);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<Promo>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.hasData && snap.data != _all) {
              _all = snap.data!;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _reconcile();
              });
            }
            return widget.child;
          },
        ),
        if (_current != null)
          Positioned.fill(
            child: PromoOverlayView(
              promo: _current!,
              secondsLeft: _remaining,
              onClose: _dismiss,
              onImageTap: () => _openLink(_current!),
            ),
          ),
      ],
    );
  }
}

/// واجهة الإعلان نفسها — قابلة للاستخدام أيضًا في «المعاينة الحية» بالأدمن.
class PromoOverlayView extends StatelessWidget {
  const PromoOverlayView({
    super.key,
    required this.promo,
    required this.secondsLeft,
    required this.onClose,
    required this.onImageTap,
    this.preview = false,
  });

  final Promo promo;
  final int secondsLeft;
  final VoidCallback onClose;
  final VoidCallback onImageTap;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxW = size.width * 0.92;
    final maxH = size.height * 0.72;
    return Stack(
      fit: StackFit.expand,
      children: [
          // الخلفية المعتمة — الضغط خارج الصورة يغلق
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: const ColoredBox(color: Color(0xD9000000)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                // زر الإغلاق خارج حدود الصورة (أعلى يسارها)
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: (size.width - maxW) / 2 + 4),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF6F4E37), width: 2),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 10,
                                offset: Offset(0, 3))
                          ],
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFF6F4E37), size: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // الصورة الدعائية
                GestureDetector(
                  onTap: onImageTap,
                  child: Hero(
                    tag: preview ? 'promo-preview' : 'promo-${promo.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        constraints:
                            BoxConstraints(maxWidth: maxW, maxHeight: maxH),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x80000000),
                                blurRadius: 26,
                                offset: Offset(0, 10))
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          imageUrl: promo.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => SizedBox(
                            width: 220,
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.grey.shade400),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const SizedBox(
                            width: 260,
                            height: 200,
                            child: Center(
                              child: Icon(Icons.broken_image_rounded,
                                  size: 48, color: Colors.black26),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // عدّاد المدة + تلميح الرابط
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!preview)
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white70, width: 1.6),
                        ),
                        child: Text('$secondsLeft',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12)),
                      ),
                    if (promo.linkType != 'none' &&
                        promo.linkValue.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.touch_app_rounded,
                          size: 15, color: Colors.white70),
                      const Text(' — اضغط الصورة للانتقال',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
      ],
    );
  }
}

/// معاينة حية من نموذج الأدمن — تعرض الإعلان كما سيراه المستخدم.
Future<void> showPromoPreview(BuildContext context, Promo promo) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: PromoOverlayView(
        promo: promo,
        secondsLeft: kPromoAutoDismissSeconds,
        preview: true,
        onClose: () => Navigator.pop(ctx),
        onImageTap: () => Navigator.pop(ctx),
      ),
    ),
  );
}
