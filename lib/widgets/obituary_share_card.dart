import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../core/utils/obituary_card_assets.dart';
import '../models/data_models.dart';

/// بطاقة العزاء التي تُشارك كصورة. مبنية كواجهة حقيقية لا رسم بالإحداثيات،
/// فتُلفّ الأسطر تلقائيًا وتظهر كل الأسماء مهما كثرت، وتبقى المعاينة على
/// الشاشة مطابقة تمامًا للصورة المُشارَكة.
class ObituaryShareCard extends StatelessWidget {
  const ObituaryShareCard({
    super.key,
    required this.obituary,
    required this.background,
    required this.photo,
    this.width = 420,
  });

  final Obituary obituary;

  /// خلفية azaa المختارة، مفكوكة مسبقًا فترسم في أول إطار بلا انتظار.
  final ui.Image background;

  /// صورة المتوفى مفكوكة؛ `ObituaryCardAssets` تضمن أنها `azaa 0` عند غيابها.
  final ui.Image photo;
  final double width;

  static const Color brown = Color(0xFF4E342E);
  static const Color gold = Color(0xFFB8860B);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B5B4C);

  @override
  Widget build(BuildContext context) {
    final o = obituary;
    final sections = o.relativeSections;

    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(child: _CoverImage(image: background)),
            // التبييض خفيف عمدًا: الغرض أن تُقرأ ملامح خلفية `azaa` المختارة
            // كإطار حول اللوح، واللوح الأبيض الداخلي هو ما يحمي وضوح النص.
            Positioned.fill(
                child: ColoredBox(
                    color: const Color(0xFFFDF6E9).withValues(alpha: 0.45))),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: gold.withValues(alpha: 0.55), width: 1.4),
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('قرية أبوديشيشة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: brown,
                            fontSize: 17,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    const Text('سجل العزاء',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: gold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                    const SizedBox(height: 16),
                    Center(child: _portrait()),
                    const SizedBox(height: 14),
                    Text(
                      o.transitionPhrase,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: muted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o.name.isEmpty ? '—' : o.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: brown,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    _metaWrap(o),
                    _places(o),
                    if (sections.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      const _GoldRule(),
                      const SizedBox(height: 12),
                      _relatives(sections),
                    ],
                    if ((o.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const _GoldRule(),
                      const SizedBox(height: 12),
                      Text(
                        o.description!.trim(),
                        textAlign: TextAlign.center,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: ink,
                            fontSize: 12.5,
                            height: 1.6,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const _GoldRule(),
                    const SizedBox(height: 12),
                    const Text(
                      '«إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ»',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: brown,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'تصميم من خلال تطبيق قرية أبوديشيشة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _portrait() {
    return Container(
      width: 148,
      height: 176,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: brown.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 5)),
        ],
      ),
      child: ClipPath(clipper: _ArchClipper(), child: _CoverImage(image: photo)),
    );
  }

  List<Widget> _metaTiles(Obituary o) => [
        if (o.gender.isNotEmpty) _MetaTile(icon: Icons.wc_rounded, label: o.gender),
        if (o.dateOfDeath.isNotEmpty)
          _MetaTile(
              icon: Icons.calendar_today_rounded,
              label: 'الوفاة ${o.dateOfDeath}'),
        if (o.funeralDate.isNotEmpty)
          _MetaTile(
              icon: Icons.volunteer_activism_rounded,
              label: 'صلاة الجنازة ${o.funeralDate}'),
        if (o.age.isNotEmpty)
          _MetaTile(icon: Icons.cake_rounded, label: 'العمر ${o.age}'),
      ];

  Widget _metaWrap(Obituary o) {
    final tiles = _metaTiles(o);
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          alignment: WrapAlignment.center,
          children: tiles,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _places(Obituary o) {
    final lines = <Widget>[
      if (o.funeralLocation.isNotEmpty)
        _PlaceLine(label: 'مكان صلاة الجنازة', value: o.funeralLocation),
      if (o.burialLocation.isNotEmpty)
        _PlaceLine(label: 'مكان الدفن', value: o.burialLocation),
      // السجلات القديمة كانت تسأل عن المسجد وحده، فلا مكان دفن لها
      if (o.burialLocation.isEmpty && o.mosque.isNotEmpty)
        _PlaceLine(label: 'المسجد', value: o.mosque),
      if (o.condolenceLocation.isNotEmpty)
        _PlaceLine(label: 'مكان العزاء', value: o.condolenceLocation),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('الصلوات والأماكن',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: gold, fontSize: 12.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...lines,
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _relatives(List<RelativeSection> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(obituary.isFemale ? 'قريبات المتوفاة' : 'أقارب المتوفى',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: gold, fontSize: 12.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final section in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, height: 1.55),
                children: [
                  TextSpan(
                      text: '${section.label}: ',
                      style: const TextStyle(
                          color: brown, fontWeight: FontWeight.w900)),
                  TextSpan(
                      text: section.namesLine,
                      style: const TextStyle(
                          color: ink, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// معاينة على الشاشة: تفكّ الخلفية وصورة المتوفى ثم ترسم البطاقة نفسها،
/// فتكون المعاينة هي الصورة المُشارَكة سطرًا بسطر.
class ObituaryShareCardPreview extends StatefulWidget {
  const ObituaryShareCardPreview({
    super.key,
    required this.obituary,
    this.width = 420,
  });

  final Obituary obituary;
  final double width;

  @override
  State<ObituaryShareCardPreview> createState() =>
      _ObituaryShareCardPreviewState();
}

class _ObituaryShareCardPreviewState extends State<ObituaryShareCardPreview> {
  ui.Image? _background;
  ui.Image? _photo;
  String? _error;
  String _stamp = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final o = widget.obituary;
    final stamp = '${o.cardBackground}|${o.imageUrl ?? ''}';
    if (_stamp == stamp) return;
    _stamp = stamp;
    try {
      final background =
          await ObituaryCardAssets.loadBackground(o.cardBackground);
      final photo = await ObituaryCardAssets.loadPhoto(o.imageUrl);
      if (!mounted) return;
      setState(() {
        _background = background;
        _photo = photo;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ObituaryCardAssets.describeFailure(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = _background;
    final photo = _photo;
    if (_error != null) {
      return Container(
        width: widget.width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFB71C1C).withValues(alpha: 0.4)),
        ),
        child: Text(_error!,
            style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
      );
    }
    if (background == null || photo == null) {
      return SizedBox(
        width: widget.width,
        height: 320,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return ObituaryShareCard(
      obituary: widget.obituary,
      background: background,
      photo: photo,
      width: widget.width,
    );
  }
}

/// أصول بطاقة العزاء: فكّ الخلفية والصورة في موضع واحد، مع `azaa 0` للمفقودة.
class ObituaryCardAssets {
  ObituaryCardAssets._();

  static final Map<String, ui.Image> _decoded = {};

  static Future<ui.Image> loadBackground(String key) =>
      _loadAsset(obituaryCardAssetFor(key));

  /// صورة المتوفى، أو `azaa 0` إن لم تُرفع صورة أو تعذّر تحميلها.
  static Future<ui.Image> loadPhoto(String? url) async {
    final link = (url ?? '').trim();
    if (link.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(link))
            .timeout(const Duration(seconds: 25));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return await _decode(response.bodyBytes);
        }
      } catch (_) {
        // يسقط إلى الصورة الافتراضية، وهو المقصود بلا صورة
      }
    }
    return _loadAsset(kObituaryDeceasedFallbackAsset);
  }

  static Future<ui.Image> _loadAsset(String path) async {
    final cached = _decoded[path];
    if (cached != null) return cached;
    final data = await rootBundle.load(path);
    final image = await _decode(Uint8List.view(data.buffer));
    _decoded[path] = image;
    return image;
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static String describeFailure(Object error) =>
      'تعذّر تحميل خلفية البطاقة (${error.toString().replaceFirst('Exception: ', '')}) — تحقّق من الاتصال وأعد المحاولة.';

  @visibleForTesting
  static void clearCacheForTest() => _decoded.clear();
}

/// يرسم البطاقة في أي سياق ويُعيدها PNG، فلا تحتاج شاشة كاملة ولا حفظ ملف.
class ObituaryCardCapturer {
  ObituaryCardCapturer._();

  static Future<Uint8List> capture(BuildContext context,
      {required ObituaryShareCard card, double pixelRatio = 3}) async {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      throw StateError('لا طبقة Overlay للسياق الحالي');
    }
    final boundaryKey = GlobalKey();
    final width = card.width;
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: -width * 2,
        top: 0,
        width: width,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: RepaintBoundary(key: boundaryKey, child: card),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      // إطاران: الأول يقيس ويرسم، والثاني يضمن اكتمال التركيب قبل الالتقاط
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (renderObject == null) {
        throw StateError('لم تُبنَ البطاقة للالتقاط');
      }
      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('تعذّر تحويل البطاقة إلى صورة');
      return data.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }
}

/// صورة تملأ إطارها بالاقتطاع (cover) بلا تشوّه للنسبة.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.image});

  final ui.Image image;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _CoverImagePainter(image));
}

class _CoverImagePainter extends CustomPainter {
  _CoverImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    if (size.isEmpty || iw <= 0 || ih <= 0) return;
    final scale =
        (size.width / iw) > (size.height / ih) ? size.width / iw : size.height / ih;
    final sw = size.width / scale;
    final sh = size.height / scale;
    final src = Rect.fromLTWH((iw - sw) / 2, (ih - sh) / 2, sw, sh);
    canvas.drawImageRect(
        image,
        src,
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _CoverImagePainter oldDelegate) =>
      oldDelegate.image != image;
}

/// محراب مقوّس أعلى الصورة، بأسلوب زخارف القرية.
class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    const r = 12.0;
    return Path()
      ..moveTo(0, h * 0.34)
      ..quadraticBezierTo(0, 0, w / 2, 0)
      ..quadraticBezierTo(w, 0, w, h * 0.34)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..close();
  }

  @override
  bool shouldReclip(covariant _ArchClipper oldClipper) => false;
}

class _GoldRule extends StatelessWidget {
  const _GoldRule();

  @override
  Widget build(BuildContext context) => Container(
        height: 1.2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: ObituaryShareCard.gold.withValues(alpha: 0.5),
      );
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ObituaryShareCard.brown.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: ObituaryShareCard.brown.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ObituaryShareCard.gold),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: ObituaryShareCard.brown,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PlaceLine extends StatelessWidget {
  const _PlaceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: ObituaryShareCard.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: ObituaryShareCard.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.45)),
        ],
      ),
    );
  }
}
