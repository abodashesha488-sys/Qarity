import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/qurity_app_bar.dart';
import 'children_lessons.dart';
import 'children_speech.dart';
import 'letters_learn_screen.dart' show LearnLettersScreen;

/// 🔢 تعلّم الأرقام — على نمط «تعلّم الحروف»: لكل رقم بطاقة صورة + رقم + اسم،
/// والنقر يفتح بطاقة الرقم بالعدّ البصري والصوت. صور الأرقام في
/// `assets/images/kids/num/01.jpg…10.jpg`، وعند غيابها يرسم البديل تفاحات.
class LearnNumbersScreen extends StatelessWidget {
  const LearnNumbersScreen({super.key});

  static const String imageFolder = 'num';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar:
          const QurityAppBar(title: 'تعلّم الأرقام', color: Color(0xFFF9A825)),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: kNumberLessons.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final colors = LearnLettersScreen.paletteFor(index);
          return _NumberTile(index: index, colors: colors)
              .animate(delay: (index * 40).ms)
              .fadeIn(duration: 250.ms)
              .scale(begin: const Offset(0.9, 0.9));
        },
      ),
    );
  }

  static void showNumberCard(BuildContext context, int index) {
    final colors = LearnLettersScreen.paletteFor(index);
    final n = index + 1;
    ChildrenSpeech.speak('الرقم ${kNumberNames[index]}. تعال نعدّ $n تفاحات');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: colors[1].withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: colors, begin: Alignment.topLeft),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: colors[1].withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Center(
                    child: Text(kNumberDigits[index],
                        style: GoogleFonts.tajawal(
                            fontSize: index == 9 ? 34 : 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                _NumberImage(index: index, size: 96, radius: 24),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${kNumberNames[index]}  —  ${kNumberDigits[index]}',
                    style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colors[1])),
                IconButton(
                  tooltip: 'اسمع',
                  onPressed: () => ChildrenSpeech.speak(
                      'الرقم ${kNumberNames[index]}. تعال نعدّ $n تفاحات'),
                  icon: Icon(Icons.volume_up_rounded,
                      color: colors[1], size: 24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: colors[0].withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < n; i++)
                    const Text('🍎', style: TextStyle(fontSize: 30))
                        .animate(delay: (i * 90).ms)
                        .scale(begin: const Offset(0, 0)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('عِدّ معي: ${kNumberDigits[index]}',
                style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.brown.shade400)),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0),
    );
  }
}

/// 🖼 صورة الرقم مع بديل مرسوم (دوائر تفاح) إن لم يكن الملف موجودًا بعد.
class _NumberImage extends StatelessWidget {
  const _NumberImage(
      {required this.index, required this.size, required this.radius});
  final int index;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        kidLessonImage(LearnNumbersScreen.imageFolder, index),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => CustomPaint(
          size: Size(size, size),
          painter: _ApplesPainter(count: index + 1),
        ),
      ),
    );
  }
}

/// 🍎 رسم تفاحات حممة صغيرة بعدد الرقم داخل صفوف متوازنة.
class _ApplesPainter extends CustomPainter {
  _ApplesPainter({required this.count});
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    const rowsByCount = {
      1: [1],
      2: [2],
      3: [3],
      4: [2, 2],
      5: [2, 3],
      6: [3, 3],
      7: [3, 4],
      8: [4, 4],
      9: [3, 3, 3],
      10: [4, 3, 3],
    };
    final rows = rowsByCount[count] ?? [count];
    final body = Paint()..color = const Color(0xFFE53935);
    final leaf = Paint()..color = const Color(0xFF43A047);
    final stem = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final pad = size.width * 0.10;
    final availH = size.height - pad * 2;
    final rowGap = availH / rows.length;
    for (var r = 0; r < rows.length; r++) {
      final n = rows[r];
      final colGap = (size.width - pad * 2) / n;
      final radius = (colGap < rowGap ? colGap : rowGap) * 0.32;
      for (var c = 0; c < n; c++) {
        final center = Offset(
            pad + colGap * (c + 0.5), pad + rowGap * (r + 0.55));
        canvas.drawCircle(center, radius, body);
        canvas.drawLine(
            center.translate(0, -radius),
            center.translate(radius * 0.15, -radius * 1.55),
            stem);
        final leafCenter =
            center.translate(radius * 0.55, -radius * 1.25);
        canvas.save();
        canvas.translate(leafCenter.dx, leafCenter.dy);
        canvas.rotate(0.6);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero,
                width: radius * 0.9,
                height: radius * 0.45),
            leaf);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ApplesPainter old) => old.count != count;
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.index, required this.colors});
  final int index;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => LearnNumbersScreen.showNumberCard(context, index),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: colors[1].withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumberImage(index: index, size: 62, radius: 18),
              const SizedBox(height: 8),
              Text(kNumberDigits[index],
                  style: GoogleFonts.tajawal(
                      fontSize: index == 9 ? 24 : 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Text(kNumberNames[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.92))),
            ],
          ),
        ),
      ),
    );
  }
}
