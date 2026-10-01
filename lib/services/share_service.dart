import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/data_models.dart';
import '../widgets/obituary_share_card.dart';

/// يولّد بطاقة تعزية كصورة عالية الجودة للمشاركة على السوشيال ميديا
class ShareService {
  ShareService._();

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

  /// يرسم بطاقة العزاء ويلتقطها PNG. البطاقة كويجت حقيقي في
  /// `widgets/obituary_share_card.dart` فتطابق المعاينةُ الصورةَ المُشارَكة.
  static Future<Uint8List> generateMemorialCard(
    BuildContext context,
    Obituary obituary,
  ) async {
    final background =
        await ObituaryCardAssets.loadBackground(obituary.cardBackground);
    final photo = await ObituaryCardAssets.loadPhoto(obituary.imageUrl);
    if (!context.mounted) {
      throw StateError('أُغلقت الشاشة قبل إنشاء البطاقة');
    }
    return ObituaryCardCapturer.capture(
      context,
      card: ObituaryShareCard(
        obituary: obituary,
        background: background,
        photo: photo,
      ),
    );
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
      final bytes = await generateMemorialCard(context, obituary);
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
          const SnackBar(
            content: Text('تعذر إنشاء صورة التعزية ومشاركتها — تحقق من الاتصال ثم أعد المحاولة.'),
            backgroundColor: Color(0xFFB71C1C),
          ),
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
        colors: [Color(0xFF00695C), Color(0xFF6F4E37)],
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