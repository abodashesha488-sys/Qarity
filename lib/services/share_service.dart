import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/data_models.dart';

/// يولّد بطاقة تعزية كصورة عالية الجودة للمشاركة على السوشيال ميديا
class ShareService {
  ShareService._();

  static const Size _cardSize = Size(800, 1100);

  static const String appSignature =
      '📲 تمت المشاركة من خلال تطبيق قرية أبوديشيشة';

  /// مشاركة نصية موحّدة لأي محتوى (خبر/منتج/منشور/مناسبة/عيادة/صيدلية/طلب…)
  /// مع توقيع التطبيق في نهاية النص.
  static Future<void> shareText({
    required String title,
    String? body,
    String? link,
  }) async {
    final buffer = StringBuffer(title.trim());
    if (body != null && body.trim().isNotEmpty) {
      buffer
        ..write('\n\n')
        ..write(body.trim());
    }
    if (link != null && link.trim().isNotEmpty) {
      buffer
        ..write('\n\n')
        ..write(link.trim());
    }
    buffer
      ..write('\n\n')
      ..write(appSignature);
    await SharePlus.instance.share(
      ShareParams(text: buffer.toString(), subject: title.trim()),
    );
  }

  /// يرسم بطاقة التعزية ويعيدها كـ PNG bytes
  static Future<Uint8List> generateMemorialCard(Obituary obituary) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = _cardSize;

    _drawBackground(canvas, size);
    _drawHeader(canvas, size);
    _drawDeceasedPlaceholder(canvas, size);
    _drawDeceasedInfo(canvas, size, obituary);
    _drawLocations(canvas, size, obituary);
    _drawRelatives(canvas, size, obituary.relatives);
    _drawFooter(canvas, size);

    final picture = recorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5F5F5), Color(0xFFE8EAF6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  static void _drawHeader(Canvas canvas, Size size) {
    _drawText(canvas, 'قرية أبوديشيشة', Offset(size.width / 2, 55),
        fontSize: 30, fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20));
    _drawText(canvas, 'سجل العزاء', Offset(size.width / 2, 95),
        fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF388E3C));
    final line = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.3)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * 0.2, 120), Offset(size.width * 0.8, 120), line);
  }

  static void _drawDeceasedPlaceholder(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(size.width * 0.3, 150, size.width * 0.4, size.width * 0.4);
    final paint = Paint()..color = Colors.grey.shade300;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)), paint);
    _drawText(canvas, '🕊', Offset(size.width / 2, rect.center.dy - 24),
        fontSize: 48, fontWeight: FontWeight.normal, color: Colors.grey.shade600);
  }

  static void _drawDeceasedInfo(Canvas canvas, Size size, Obituary obituary) {
    double y = 150 + size.width * 0.4 + 40;
    _drawText(canvas, 'انتقل إلى رحمة الله تعالى', Offset(size.width / 2, y),
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87);
    y += 40;
    final line = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.4)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * 0.3, y), Offset(size.width * 0.7, y), line);
    y += 35;
    _drawText(canvas, obituary.name, Offset(size.width / 2, y),
        fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black);
    y += 55;
    _drawText(canvas, 'العمر: ${obituary.age} سنة', Offset(size.width / 2, y),
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87);
    y += 35;
    _drawText(canvas, 'تاريخ الوفاة: ${obituary.dateOfDeath}', Offset(size.width / 2, y),
        fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFC62828));
  }

  static void _drawLocations(Canvas canvas, Size size, Obituary obituary) {
    double y = 150 + size.width * 0.4 + 40 + 40 + 35 + 55 + 35 + 35;
    final line = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.3)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * 0.2, y), Offset(size.width * 0.8, y), line);
    y += 35;
    if (obituary.funeralLocation.isNotEmpty) {
      _drawText(canvas, 'مكان الصلاة: ${obituary.funeralLocation}', Offset(size.width / 2, y),
          fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87);
      y += 32;
    }
    if (obituary.funeralDate.isNotEmpty) {
      _drawText(canvas, 'تاريخ الدفن: ${obituary.funeralDate}', Offset(size.width / 2, y),
          fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF0D47A1));
      y += 32;
    }
    if (obituary.condolenceLocation.isNotEmpty) {
      _drawText(canvas, 'مكان العزاء: ${obituary.condolenceLocation}', Offset(size.width / 2, y),
          fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87);
      y += 32;
    }
  }

  static void _drawRelatives(Canvas canvas, Size size, List<Relative> relatives) {
    if (relatives.isEmpty) return;
    double y = 150 + size.width * 0.4 + 40 + 40 + 35 + 55 + 35 + 35 + 35 + 32 + 32 + 32;
    final line = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.3)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * 0.2, y), Offset(size.width * 0.8, y), line);
    y += 35;
    _drawText(canvas, 'أقارب المتوفى', Offset(size.width / 2, y),
        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black);
    y += 40;

    final grouped = <RelativeType, List<Relative>>{};
    for (final r in relatives) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }
    for (final type in RelativeType.values) {
      final list = grouped[type];
      if (list == null || list.isEmpty) continue;
      _drawText(canvas, '${type.label}: ${list.map((r) => r.name).join('، ')}',
          Offset(size.width / 2, y),
          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87);
      y += 30;
      if (y > size.height - 160) break;
    }
  }

  static void _drawFooter(Canvas canvas, Size size) {
    _drawText(canvas, '"إنا لله وإنا إليه راجعون"', Offset(size.width / 2, size.height - 90),
        fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87, italic: true);
    _drawText(canvas, 'تم النشر عبر تطبيق قرية أبوديشيشة', Offset(size.width / 2, size.height - 50),
        fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600);
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    bool italic = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );
    painter.layout(maxWidth: 720);
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy));
  }

  /// يولّد الصورة ويشاركها عبر نظام المشاركة
  static Future<void> shareObituaryAsImage(BuildContext context, Obituary obituary) async {
    try {
      final bytes = await generateMemorialCard(obituary);
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/obituary_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          text: 'تعزية في وفاة ${obituary.name} - إنا لله وإنا إليه راجعون',
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Share error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر مشاركة التعزية'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════ بطاقة الدعوة للمناسبة ═══════════════════
  static Future<Uint8List> generateOccasionCard(Occasion occasion) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(800, 900);

    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00695C), Color(0xFF004D40)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    _drawText(canvas, 'دعوة', Offset(size.width / 2, 80),
        fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white70);
    _drawText(canvas, '🎉', Offset(size.width / 2, 130),
        fontSize: 56, fontWeight: FontWeight.w700, color: Colors.white);
    _drawText(canvas, occasion.title, Offset(size.width / 2, 250),
        fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white);

    double y = 340;
    if (occasion.date.isNotEmpty) {
      _drawText(canvas, '📅  ${occasion.date}', Offset(size.width / 2, y),
          fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white);
      y += 50;
    }
    if (occasion.location.isNotEmpty) {
      _drawText(canvas, '📍  ${occasion.location}', Offset(size.width / 2, y),
          fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white);
      y += 50;
    }
    if ((occasion.organizer ?? '').isNotEmpty) {
      _drawText(canvas, '👤  ${occasion.organizer}', Offset(size.width / 2, y),
          fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white70);
      y += 50;
    }
    if (occasion.description.isNotEmpty) {
      y += 10;
      _drawText(canvas, occasion.description, Offset(size.width / 2, y),
          fontSize: 20, fontWeight: FontWeight.w400, color: Colors.white);
    }

    _drawText(canvas, 'حضوركم يُسعدنا  •  قرية أبوديشيشة',
        Offset(size.width / 2, size.height - 70),
        fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white70);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static Future<void> shareOccasionAsImage(BuildContext context, Occasion occasion) async {
    try {
      final bytes = await generateOccasionCard(occasion);
      final tempDir = await getTemporaryDirectory();
      final file =
          File('${tempDir.path}/occasion_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          text: 'دعوة لحضور: ${occasion.title}',
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Share error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر مشاركة الدعوة'), backgroundColor: Colors.red),
        );
      }
    }
  }
}