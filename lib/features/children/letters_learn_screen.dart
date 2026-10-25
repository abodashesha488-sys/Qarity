import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/qurity_app_bar.dart';
import 'arabic_letters.dart';
import 'children_speech.dart';

/// 🎨 تعلّم الحروف — شبكة 28 حرفًا ملونة تفاعلية مع النطق الصوتي الفوري
/// والأشكال الأربعة لكل حرف وكلمات الأمثلة مع إمكانية التنقل والتوقف الفوري.
class LearnLettersScreen extends StatefulWidget {
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

  static String letterSpeechText(ArabicLetter letter) {
    final word = letter.letter == 'ط'
        ? 'طَيَّارة'
        : letter.letter == 'ك'
            ? 'كُورة'
            : letter.word;
    final name = letter.letter == 'ز' ? 'الزين' : 'ال${letter.name}';
    return 'حرف $name .. زي كلمة $word';
  }

  static void showLetterCard(BuildContext context, ArabicLetter letter) async {
    final startIndex = kArabicLetters.indexOf(letter);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LetterDetailSheet(startIndex: startIndex >= 0 ? startIndex : 0),
    );
    ChildrenSpeech.stop();
  }

  @override
  State<LearnLettersScreen> createState() => _LearnLettersScreenState();
}

class _LearnLettersScreenState extends State<LearnLettersScreen> {
  @override
  void dispose() {
    ChildrenSpeech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: QurityAppBar(
        title: 'تعلّم الحروف',
        actions: [
          ValueListenableBuilder<TtsPlayState>(
            valueListenable: ChildrenSpeech.playState,
            builder: (context, state, _) {
              if (state == TtsPlayState.stopped) return const SizedBox.shrink();
              return const IconButton(
                tooltip: 'إيقاف الصوت',
                icon: Icon(Icons.stop_circle_rounded, color: Colors.redAccent, size: 28),
                onPressed: ChildrenSpeech.stop,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط توجيهي مرح للأطفال
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎧', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'اضغط على أي حرف لسماع نطق الحرف وأشكاله والكلمة التوضيحية!',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5D4037),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // شبكة الحروف
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
              itemCount: kArabicLetters.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.76,
              ),
              itemBuilder: (context, index) {
                final letter = kArabicLetters[index];
                final colors = LearnLettersScreen.paletteFor(letter.colorIndex);
                return _LetterTile(letter: letter, colors: colors, index: index)
                    .animate(delay: (index * 20).ms)
                    .fadeIn(duration: 200.ms)
                    .scale(begin: const Offset(0.92, 0.92));
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 📋 بطاقة تفاصيل الحرف التفاعلية داخل BottomSheet مع أزرار السابق والتالي
class _LetterDetailSheet extends StatefulWidget {
  const _LetterDetailSheet({required this.startIndex});
  final int startIndex;

  @override
  State<_LetterDetailSheet> createState() => _LetterDetailSheetState();
}

class _LetterDetailSheetState extends State<_LetterDetailSheet> {
  late int _currentIndex = widget.startIndex;

  ArabicLetter get _letter => kArabicLetters[_currentIndex];
  List<Color> get _colors => LearnLettersScreen.paletteFor(_letter.colorIndex);

  @override
  void initState() {
    super.initState();
    _speakCurrent();
  }

  void _speakCurrent() {
    final text = LearnLettersScreen.letterSpeechText(_letter);
    ChildrenSpeech.speak(text);
  }

  void _goTo(int next) {
    if (next < 0 || next >= kArabicLetters.length) return;
    setState(() {
      _currentIndex = next;
    });
    _speakCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final letter = _letter;
    final colors = _colors;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors[1].withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // الرأس: الترقيم وزر الإغلاق
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors[0].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${kArabicLetters.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: colors[1],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: () {
                  ChildrenSpeech.stop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),

          // دائرة الحرف الكبيرة
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors[1].withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                letter.letter,
                style: GoogleFonts.amiri(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // اسم الحرف وزر الاستماع والإيقاف الفوري
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'حرف ${letter.name}',
                style: GoogleFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colors[1],
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TtsPlayState>(
                valueListenable: ChildrenSpeech.playState,
                builder: (context, state, _) {
                  final isPlaying = state == TtsPlayState.playing;
                  return FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isPlaying
                          ? Colors.red.shade50
                          : colors[0].withValues(alpha: 0.25),
                      foregroundColor: isPlaying ? Colors.red.shade700 : colors[1],
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(
                      isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isPlaying ? 'إيقاف' : 'اسمع',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        ChildrenSpeech.stop();
                      } else {
                        ChildrenSpeech.speak(LearnLettersScreen.letterSpeechText(letter));
                      }
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // أشكال الحرف الأربعة (قابلة للنقر للاستماع لشكل الحرف وموضعه)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _FormChip(
                label: 'مفرد',
                form: letter.isolated,
                color: colors[1],
                onTap: () {
                  final name = letter.letter == 'ز' ? 'الزين' : 'ال${letter.name}';
                  ChildrenSpeech.speak('حرف $name لوحده');
                },
              ),
              _FormChip(
                label: 'بالبداية',
                form: letter.initial,
                color: colors[1],
                onTap: () {
                  final name = letter.letter == 'ز' ? 'الزين' : 'ال${letter.name}';
                  ChildrenSpeech.speak('حرف $name في أول الكلمة');
                },
              ),
              _FormChip(
                label: 'بالوسط',
                form: letter.medial,
                color: colors[1],
                onTap: () {
                  final name = letter.letter == 'ز' ? 'الزين' : 'ال${letter.name}';
                  ChildrenSpeech.speak('حرف $name في نص الكلمة');
                },
              ),
              _FormChip(
                label: 'بالنهاية',
                form: letter.finalForm,
                color: colors[1],
                onTap: () {
                  final name = letter.letter == 'ز' ? 'الزين' : 'ال${letter.name}';
                  ChildrenSpeech.speak('حرف $name في آخر الكلمة');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // بطاقة الكلمة التوضيحية مع الصورة
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                final word = letter.letter == 'ط'
                    ? 'طَيَّارة'
                    : letter.letter == 'ك'
                        ? 'كُورة'
                        : letter.word;
                ChildrenSpeech.speak('كلمة $word');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: colors[0].withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors[1].withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors[1].withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        letter.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Center(
                          child: Text(letter.emoji, style: const TextStyle(fontSize: 32)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: letter.letter,
                            style: GoogleFonts.amiri(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: colors[1],
                            ),
                          ),
                          TextSpan(
                            text: letter.word.substring(1),
                            style: GoogleFonts.amiri(
                              fontSize: 28,
                              color: const Color(0xFF4E342E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.volume_down_rounded, color: colors[1], size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // أزرار التنقل (السابق / التالي)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18), // اتجاه عربي (يمين = سابق)
                  label: const Text('السابق', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _currentIndex < kArabicLetters.length - 1
                      ? () => _goTo(_currentIndex + 1)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors[1],
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18), // اتجاه عربي (يسار = تالي)
                  label: const Text('التالي', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.25, end: 0);
  }
}

class _FormChip extends StatelessWidget {
  const _FormChip({
    required this.label,
    required this.form,
    required this.color,
    this.onTap,
  });

  final String label;
  final String form;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: Text(
                  form,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.colors,
    required this.index,
  });

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
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors[1].withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      letter.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Center(
                        child: Text(letter.emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    letter.letter,
                    style: GoogleFonts.amiri(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    letter.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),

              // زر نطق صوتي سريع في ركن الكارت
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final text = LearnLettersScreen.letterSpeechText(letter);
                      ChildrenSpeech.togglePlayPause(text);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
