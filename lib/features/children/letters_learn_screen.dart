import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/qurity_app_bar.dart';
import 'arabic_letters.dart';
import 'children_speech.dart';

/// 🎨 تعلّم الحروف — شبكة 28 حرفًا ملونة، والنقر يفتح بطاقة الحرف
/// بأشكاله الأربعة وكلمة المثال مع الإيموجي.
class LearnLettersScreen extends StatelessWidget {
  const LearnLettersScreen({super.key});

  static const List<List<Color>> _palettes = [
    [Color(0xFFFF8A80), Color(0xFFE53935)], // أحمر
    [Color(0xFFFFD180), Color(0xFFFB8C00)], // برتقالي
    [Color(0xFFFFF59D), Color(0xFFF9A825)], // أصفر
    [Color(0xFFB9F6CA), Color(0xFF43A047)], // أخضر
    [Color(0xFF80D8FF), Color(0xFF1E88E5)], // أزرق
    [Color(0xFFB39DDB), Color(0xFF5E35B1)], // بنفسجي
    [Color(0xFFF8BBD0), Color(0xFFD81B60)], // وردي
  ];

  static List<Color> paletteFor(int i) => _palettes[i % _palettes.length];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: const QurityAppBar(title: 'تعلّم الحروف', color: Color(0xFF6A1B9A)),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: kArabicLetters.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final letter = kArabicLetters[index];
          final colors = paletteFor(letter.colorIndex);
          return _LetterTile(letter: letter, colors: colors, index: index)
              .animate(delay: (index * 25).ms)
              .fadeIn(duration: 250.ms)
              .scale(begin: const Offset(0.9, 0.9));
        },
      ),
    );
  }

  static void showLetterCard(BuildContext context, ArabicLetter letter) {
    final colors = paletteFor(letter.colorIndex);
    ChildrenSpeech.speak('حرف ${letter.name}. ${letter.word}');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors[1].withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                child: Text(letter.letter,
                    style: GoogleFonts.amiri(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('حرف ${letter.name}',
                    style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colors[1])),
                IconButton(
                  tooltip: 'اسمع',
                  onPressed: () =>
                      ChildrenSpeech.speak('حرف ${letter.name}. ${letter.word}'),
                  icon: Icon(Icons.volume_up_rounded,
                      color: colors[1], size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FormChip(label: 'مفرد', form: letter.isolated, color: colors[1]),
                _FormChip(label: 'بالبداية', form: letter.initial, color: colors[1]),
                _FormChip(label: 'بالوسط', form: letter.medial, color: colors[1]),
                _FormChip(label: 'بالنهاية', form: letter.finalForm, color: colors[1]),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: colors[0].withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: colors[1].withValues(alpha: 0.35), width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(letter.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            Center(child: Text(letter.emoji,
                                style: const TextStyle(fontSize: 34)))),
                  ),
                  const SizedBox(width: 14),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: letter.letter,
                          style: GoogleFonts.amiri(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: colors[1])),
                      TextSpan(
                          text: letter.word.substring(1),
                          style: GoogleFonts.amiri(
                              fontSize: 30, color: const Color(0xFF4E342E))),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0),
    );
  }
}

class _FormChip extends StatelessWidget {
  const _FormChip(
      {required this.label, required this.form, required this.color});
  final String label;
  final String form;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: SizedBox(
            width: 58,
            height: 58,
            child: Center(
              child: Text(form,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.tajawal(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.brown.shade400)),
      ],
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile(
      {required this.letter, required this.colors, required this.index});
  final ArabicLetter letter;
  final List<Color> colors;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => LearnLettersScreen.showLetterCard(context, letter),
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
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 5,
                        offset: const Offset(0, 2)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(letter.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        Center(child: Text(letter.emoji,
                            style: const TextStyle(fontSize: 30)))),
              ),
              const SizedBox(height: 8),
              Text(letter.letter,
                  style: GoogleFonts.amiri(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text(letter.name,
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
