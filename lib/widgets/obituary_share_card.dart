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
///
/// تُرسم البيانات فوق صورة الخلفية مباشرة بلا أي تبييض، لأن خلفيات azaa الأربع
/// سوداء فعليًا (قيسَ متوسط سطوعها فوجد 24–37 من 255)؛ فألوان النص كلها عاجية
/// وذهبية فاتحة محسوبة على هذا الأسود، والإطار الذهبي لصورة المتوفى وحدها.
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

  static const Color gold = Color(0xFFE3B873);
  static const Color ivory = Color(0xFFFBF4E6);
  static const Color cream = Color(0xFFE7DBC3);
  static const Color soft = Color(0xFFC8BCA4);

  /// ظل للنصوص الكبيرة يرفع الحروف عن تفاصيل الخلفية دون حجب الرسم.
  static const List<Shadow> _lift = [
    Shadow(color: Color(0xB3000000), blurRadius: 9, offset: Offset(0, 1))
  ];

  @override
  Widget build(BuildContext context) {
    final o = obituary;
    final sections = o.relativeSections;
    final note = (o.description ?? '').trim();

    // الكتل تُبنى بترتيبها فقط إن كان لها محتوى، فلا يترك `spaceBetween`
    // فراغًا حيث لا بيانات.
    final blocks = <Widget>[
      _crest(),
      _portrait(),
      _identity(o),
      if (_hasPlaces(o)) _places(o),
      if (sections.isNotEmpty) _relatives(sections),
      if (note.isNotEmpty) _note(note),
      _footer(),
    ];

    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(child: _CoverImage(image: background)),
            ConstrainedBox(
              // بطاقة طولية: حدّ أدنى = عرض × ١٫٥ يجعل التوزيع واضحًا ولو
              // كانت البيانات قليلة، ويتمدد معه عند كثرة الأسماء.
              constraints: BoxConstraints(minHeight: width * 1.5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  // `min`: ارتفاع البطاقة من محتواها لا من إطارها، فتخرج نفس
                  // البطاقة في المعاينة وفي الصورة المُشارَكة وفي أي حاوية.
                  // ومع `minHeight` أعلاه تتوزع الكتل بالعدل حين تقل البيانات.
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: blocks,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _crest() {
    return const Column(
      children: [
        Text('قرية أبوديشيشة',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: gold,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                shadows: _lift)),
        SizedBox(height: 2),
        Text('سجل العزاء',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: soft,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
      ],
    );
  }

  /// الإطار الذهبي وحده حول صورة المتوفى — سطر ذهبي يتبع انحناء المحراب.
  Widget _portrait() {
    final arch = _ArchClipper();
    return Center(
      child: SizedBox(
        width: 168,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipPath(
                clipper: arch,
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [gold, gold.withValues(alpha: 0.55)])))),
            Padding(
              padding: const EdgeInsets.all(3),
              child: ClipPath(clipper: arch, child: _CoverImage(image: photo)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identity(Obituary o) {
    return Column(
      children: [
        Text(o.transitionPhrase,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: cream,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.5,
                shadows: _lift)),
        const SizedBox(height: 6),
        Text(o.name.isEmpty ? '—' : o.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: ivory,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.35,
                shadows: _lift)),
        _facts(o),
      ],
    );
  }

  /// تواريخ الوفاة والجنازة سطورًا مقروءة فوق الأسود بلا صناديق. العمر لم يعد
  /// سؤالًا في النموذج، لكنه يبقى مقروءًا للسجلات القديمة فقط.
  Widget _facts(Obituary o) {
    final items = <String>[
      if (o.dateOfDeath.isNotEmpty) 'الوفاة ${o.dateOfDeath}',
      if (o.funeralDate.isNotEmpty) 'صلاة الجنازة ${o.funeralDate}',
      if (o.age.isNotEmpty) 'العمر ${o.age}',
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          for (final item in items)
            Text(item,
                style: const TextStyle(
                    color: cream,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  bool _hasPlaces(Obituary o) =>
      o.funeralLocation.isNotEmpty ||
      o.burialLocation.isNotEmpty ||
      o.mosque.isNotEmpty ||
      o.condolenceLocation.isNotEmpty;

  Widget _places(Obituary o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('الصلوات والأماكن'),
        const SizedBox(height: 10),
        if (o.funeralLocation.isNotEmpty)
          _PlaceLine(label: 'مكان صلاة الجنازة', value: o.funeralLocation),
        if (o.burialLocation.isNotEmpty)
          _PlaceLine(label: 'مكان الدفن', value: o.burialLocation),
        // السجلات القديمة كانت تسأل عن المسجد وحده، فلا مكان دفن لها
        if (o.burialLocation.isEmpty && o.mosque.isNotEmpty)
          _PlaceLine(label: 'المسجد', value: o.mosque),
        if (o.condolenceLocation.isNotEmpty)
          _PlaceLine(label: 'مكان العزاء', value: o.condolenceLocation),
      ],
    );
  }

  Widget _relatives(List<RelativeSection> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
            obituary.isFemale ? 'قريبات المتوفاة' : 'أقارب المتوفى'),
        const SizedBox(height: 10),
        for (final section in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, height: 1.6),
                children: [
                  TextSpan(
                      text: '${section.label}: ',
                      style: const TextStyle(
                          color: gold, fontWeight: FontWeight.w900)),
                  TextSpan(
                      text: section.namesLine,
                      style: const TextStyle(
                          color: ivory, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _note(String text) {
    return Column(
      children: [
        const _GoldRule(),
        Text(text,
            textAlign: TextAlign.center,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: cream,
                fontSize: 13,
                height: 1.7,
                fontWeight: FontWeight.w500,
                shadows: _lift)),
      ],
    );
  }

  Widget _footer() {
    return const Column(
      children: [
        _GoldRule(),
        Text('«إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ»',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: ivory,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.5)),
        SizedBox(height: 8),
        Text('تصميم من خلال تطبيق قرية أبوديشيشة',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: gold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2)),
      ],
    );
  }
}

/// عنوان قسم ذهبي بين خيطين: بنية واضحة فوق الخلفية بلا صناديق ولا طبقات.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    Widget hairline() => Container(
        height: 1,
        color: ObituaryShareCard.gold.withValues(alpha: 0.45));
    return Row(
      children: [
        Expanded(child: hairline()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text,
              style: const TextStyle(
                  color: ObituaryShareCard.gold,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4)),
        ),
        Expanded(child: hairline()),
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

  /// خلفية البطاقة: مفتاح من القائمة البيضاء (`azaa1..4`) أو رابط صورة أضافها
  /// المستخدم. الرابط يُفكّ كما هو، وأي فشل في تحميله يسقط إلى الخلفية
  /// الافتراضية — فلا توجد بطاقة بلا خلفية أبدًا.
  static Future<ui.Image> loadBackground(String keyOrUrl) async {
    final fromUrl = await _loadUrl(keyOrUrl);
    return fromUrl ?? await _loadAsset(obituaryCardAssetFor(keyOrUrl));
  }

  /// صورة المتوفى، أو `azaa 0` إن لم تُرفع صورة أو تعذّر تحميلها.
  static Future<ui.Image> loadPhoto(String? url) async {
    final fromUrl = await _loadUrl(url ?? '');
    return fromUrl ?? await _loadAsset(kObituaryDeceasedFallbackAsset);
  }

  /// رابط صورة حقيقي فقط؛ ما عدا ذلك (مفتاح خلفية، نص فارغ) يعيد null ليُقرأ
  /// من الأصول، فلا يتحول مفتاح `azaa2` إلى طلب شبكة.
  static Future<ui.Image?> _loadUrl(String value) async {
    final link = value.trim();
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      return null;
    }
    final cached = _decoded[link];
    if (cached != null) return cached;
    try {
      final response = await http
          .get(Uri.parse(link))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final image = await _decode(response.bodyBytes);
        _decoded[link] = image;
        return image;
      }
    } catch (_) {
      // السقوط إلى الأصل الافتراضي هو المقصود، بلا رسالة ولا توقف
    }
    return null;
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

class _PlaceLine extends StatelessWidget {
  const _PlaceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: ObituaryShareCard.soft,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: ObituaryShareCard.ivory,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.45)),
        ],
      ),
    );
  }
}
