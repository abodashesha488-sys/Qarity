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

  @override
  State<FullFitImage> createState() => _FullFitImageState();
}

class _FullFitImageState extends State<FullFitImage> {
  static final Map<String, double> _ratioCache = {};
  bool _probing = false;
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
      _probing = false;
      _failed = false;
      _probe();
    }
  }

  /// يقيس النسبة من الصورة المفكوكة فعليًا؛ والفشل يترك الإطار مربعًا.
  void _probe() {
    final url = widget.imageUrl;
    if (url.isEmpty || _probing || _ratioCache.containsKey(url)) return;
    _probing = true;
    try {
      CachedNetworkImageProvider(url)
          .resolve(ImageConfiguration.empty)
          .addListener(ImageStreamListener((info, _) {
        final h = info.image.height;
        if (h <= 0) return;
        _ratioCache[url] = info.image.width / h;
        if (mounted) setState(() {});
      }, onError: (Object _, StackTrace? __) {
        _ratioCache[url] = 1.0;
        if (mounted) setState(() {});
      }));
    } catch (_) {
      // بلا شبكة/بلا Firebase في اختبارات الواجهة: الإطار المربّع يكفي.
      _ratioCache[url] = 1.0;
    }
  }

  double get _height {
    if (widget.imageUrl.isEmpty || _failed) return widget.width;
    final ratio = (_ratioCache[widget.imageUrl] ?? 1.0)
        .clamp(widget.minRatio, widget.maxRatio);
    return widget.width / ratio;
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
