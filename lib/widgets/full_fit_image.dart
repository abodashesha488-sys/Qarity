import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// صورة تُعرض **كاملة** في مساحة بعرض ثابت: الارتفاع يُحسب من نسبة الصورة
/// الحقيقية (عرض ÷ ارتفاع) فتملأ الإطار بلا اقتصاص وبلا هوامش، بدل تربيع
/// الإطار وقصّ أطراف الصورة.
///
/// النسب المتطرفة تُقصّ بين [minRatio] و[maxRatio] حتى لا تصير الصورة شريطًا
/// رفيعًا أو مربعًا ضخمًا داخل البطاقة، والنسبة تُقاس مرة واحدة لكل رابط
/// وتُخزَّن، فبطاقات القائمة لا تُعيد فكّ الصورة لقياسها.
///
/// غياب الرابط أو فشله يرجع إلى [fallback] في إطار **مربّع**، لأن البديل
/// (صورة الصفة أو الأيقونة) مُصمَّم على المربع.
class FullFitImage extends StatefulWidget {
  const FullFitImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.fallback,
    this.radius = 12,
    this.minRatio = 0.72,
    this.maxRatio = 1.5,
    this.tint = const Color(0x14000000),
  });

  final String imageUrl;
  final double width;
  final Widget fallback;
  final double radius;

  /// أقل نسبة عرض/ارتفاع مقبولة (أطول إطار ممكن = العرض ÷ هذه النسبة).
  final double minRatio;

  /// أعلى نسبة عرض/ارتفاع مقبولة (أقصر إطار ممكن).
  final double maxRatio;

  /// لون الخلفية أثناء القياس وللحواف حين تُقصّ النسبة.
  final Color tint;

  static final Map<String, double> _ratioCache = {};
  static final Set<String> _inFlight = {};

  /// نسبة الصورة إن كانت مقيسة، و null إن لم تُقَس بعد. المعارض متعددة الصور
  /// (منتج/طلب شراء/تبرع/لوحة الإدارة) تحتاجها لضبط ارتفاع الشريط **قبل** الرسم،
  /// فتقيس عبر [measure] نفسها بدل نسخ منطق فكّ الصورة في كل شاشة.
  static double? ratioOf(String url) => _ratioCache[url];

  /// يقيس نسبة [url] ويخزّنها مرة واحدة لكل رابط. إن كانت النسبة محفوظة فعلًا
  /// لا يحدث شيء ولا يُستدعى [onResult] (لا استدعاء متزامن داخل البناء أو
  /// initState)، وإلا يُستدعى بالنسبة حين تكتمل — فيعيد المُضيف حساب ارتفاعه.
  static void measure(String url, {required void Function(double ratio) onResult}) {
    if (url.isEmpty || _ratioCache.containsKey(url) || _inFlight.contains(url)) {
      return;
    }
    _inFlight.add(url);
    void done(double ratio) {
      _inFlight.remove(url);
      _ratioCache[url] = ratio;
      onResult(ratio);
    }
    try {
      CachedNetworkImageProvider(url)
          .resolve(ImageConfiguration.empty)
          .addListener(ImageStreamListener((info, _) {
        final h = info.image.height;
        if (h <= 0) {
          _inFlight.remove(url);
          return;
        }
        done(info.image.width / h);
      }, onError: (Object _, StackTrace? __) => done(1.0)));
    } catch (_) {
      // بلا شبكة/بلا Firebase في اختبارات الواجهة: الإطار المربّع يكفي.
      done(1.0);
    }
  }

  /// ارتفاع إطار بعرض [width] يستوعب [url] كاملة — نفس حساب الوست بالضبط،
  /// فيبقى الشريط والمصغّرة على مقاس واحد.
  static double heightFor(String url, double width,
      {double minRatio = 0.72, double maxRatio = 1.5, double fallbackRatio = 1.0}) {
    final ratio = (_ratioCache[url] ?? fallbackRatio).clamp(minRatio, maxRatio);
    return width / ratio;
  }

  @override
  State<FullFitImage> createState() => _FullFitImageState();
}

class _FullFitImageState extends State<FullFitImage> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  @override
  void didUpdateWidget(covariant FullFitImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _failed = false;
      _probe();
    }
  }

  /// يقيس النسبة من الصورة المفكوكة فعليًا؛ والفشل يترك الإطار مربعًا.
  void _probe() {
    FullFitImage.measure(widget.imageUrl, onResult: (_) {
      if (mounted) setState(() {});
    });
  }

  double get _height {
    if (widget.imageUrl.isEmpty || _failed) return widget.width;
    return FullFitImage.heightFor(widget.imageUrl, widget.width,
        minRatio: widget.minRatio, maxRatio: widget.maxRatio);
  }

  @override
  Widget build(BuildContext context) {
    final height = _height;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Container(
        width: widget.width,
        height: height,
        color: widget.tint,
        child: widget.imageUrl.isEmpty || _failed
            ? widget.fallback
            : CachedNetworkImage(
                imageUrl: widget.imageUrl,
                width: widget.width,
                height: height,
                fit: BoxFit.contain,
                memCacheWidth: (widget.width * 3).ceil(),
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) {
                  if (!_failed) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _failed = true);
                    });
                  }
                  return widget.fallback;
                },
              ),
      ),
    );
  }
}
