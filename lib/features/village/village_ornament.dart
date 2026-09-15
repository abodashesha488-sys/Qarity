import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// عناصر زخرفية موحدة لقسم «تعرف على القرية».
class VillageOrnament {
  VillageOrnament._();

  static const Color gold = Color(0xFFF1C40F);
  static const Color goldDark = Color(0xFFB8860B);

  /// مرشح سيبيا دافئ للصور الأرشيفية.
  static TextStyle amiri(
          {double size = 20, FontWeight weight = FontWeight.w700, Color? color}) =>
      GoogleFonts.amiri(fontSize: size, fontWeight: weight, color: color);
}

/// خلفية بنقوش هندسية إسلامية مبسطة (معينات ونجوم) فوق تدرج اللون.
class GeoPatternPainter extends CustomPainter {
  GeoPatternPainter({this.color = Colors.white});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    const step = 46.0;
    for (var y = step / 2; y < size.height + step; y += step) {
      for (var x = step / 2; x < size.width + step; x += step) {
        _diamond(canvas, Offset(x, y), 15, paint);
        _star(canvas, Offset(x, y), 7, paint);
      }
    }
  }

  void _diamond(Canvas c, Offset o, double r, Paint p) {
    final path = Path()
      ..moveTo(o.dx, o.dy - r)
      ..lineTo(o.dx + r, o.dy)
      ..lineTo(o.dx, o.dy + r)
      ..lineTo(o.dx - r, o.dy)
      ..close();
    c.drawPath(path, p);
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = (math.pi / 4) * i;
      final pt = Offset(o.dx + r * math.cos(a), o.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant GeoPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// ترويسة قسم مزخرفة: تدرج + نقوش هندسية + عنوان Amiri + خط ذهبي.
class VillageSectionHeader extends StatelessWidget {
  const VillageSectionHeader({
    super.key,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.icon,
    this.height = 150,
  });

  final Color accent;
  final String title;
  final String subtitle;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accent,
            Color.alphaBlend(
                Colors.black.withValues(alpha: 0.35), accent),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: GeoPatternPainter()),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0x00F1C40F),
                    VillageOrnament.gold,
                    Color(0x00F1C40F),
                  ]),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                VillageOrnament.gold.withValues(alpha: 0.7)),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                  if (icon != null) const SizedBox(height: 8),
                  Text(title,
                      style: VillageOrnament.amiri(
                          size: 26,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// فاصل زخرفي: خطان ذهبيان مع نجمة ثمانية في المنتصف.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, this.color = VillageOrnament.goldDark});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(
                thickness: 1.2,
                color: Color.alphaBlend(
                    color.withValues(alpha: 0.4), Colors.transparent))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.stars_rounded, size: 16, color: color),
        ),
        Expanded(
            child: Divider(
                thickness: 1.2,
                color: Color.alphaBlend(
                    color.withValues(alpha: 0.4), Colors.transparent))),
      ],
    );
  }
}
