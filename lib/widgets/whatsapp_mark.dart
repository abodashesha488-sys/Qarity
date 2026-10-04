import 'package:flutter/material.dart';

/// درجة أخضر واتساب المعتمدة في التطبيق (نفسها في إعلانات القرية وسجل
/// المحامين والمفقودات).
const Color kWhatsAppGreen = Color(0xFF128C7E);

/// رمز واتساب (فقاعة بذيلها + سماعة هاتف داخلها) مرسومًا لا كأيقونة نظام —
/// فMaterial لا يملك الشعار، والرسم يتتبّع الشكل الأصلي على أي مقاس.
class WhatsAppMark extends StatelessWidget {
  const WhatsAppMark({
    super.key,
    this.size = 22,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _WhatsAppMarkPainter(color: color),
    );
  }
}

class _WhatsAppMarkPainter extends CustomPainter {
  _WhatsAppMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(0.50 * s, 0.48 * s);
    final outer = 0.44 * s;
    final inner = 0.315 * s;
    final bubble = Rect.fromCircle(center: center, radius: outer);

    // الفقاعة + الذيل يُلوان معًا ثم يُثقب وسطها، فيبقى الحلقة شفافة الثقب
    // فوق أي خلفية (زر مصمت أو شريط فاتح).
    canvas.saveLayer(Rect.fromLTWH(0, 0, s, s), Paint());
    canvas.drawOval(bubble, paint);
    canvas.drawPath(_tail(s), paint);
    canvas.drawCircle(center, inner, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    // السماعة: خط منحني سُميك بأطراف مستديرة داخل الثقب.
    final receiver = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 0.095 * s;
    final path = Path()
      ..moveTo(0.375 * s, 0.365 * s)
      ..cubicTo(0.335 * s, 0.585 * s, 0.44 * s, 0.685 * s, 0.645 * s, 0.645 * s);
    canvas.drawPath(path, receiver);
    canvas.drawCircle(Offset(0.375 * s, 0.365 * s), 0.062 * s, paint);
    canvas.drawCircle(Offset(0.645 * s, 0.645 * s), 0.062 * s, paint);
  }

  /// ذيل الفقاعة أسفل اليسار: من حافتها إلى طرف مدبّب ثم عائدًا.
  Path _tail(double s) => Path()
    ..moveTo(0.335 * s, 0.845 * s)
    ..quadraticBezierTo(0.235 * s, 0.985 * s, 0.115 * s, 0.945 * s)
    ..quadraticBezierTo(0.215 * s, 0.845 * s, 0.225 * s, 0.735 * s)
    ..close();

  @override
  bool shouldRepaint(_WhatsAppMarkPainter old) => old.color != color;
}
