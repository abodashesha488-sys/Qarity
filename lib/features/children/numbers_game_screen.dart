import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/qurity_app_bar.dart';
import 'children_speech.dart';
import 'kids_progress.dart';

/// 🔢 لعبة الأرقام — «عُدّ الأشياء»: مجموعة إيموجي والطفل يختار
/// عددها بالأرقام العربية من 4 خيارات. 10 جولات، نقاط ونجوم.
class NumbersGameScreen extends StatefulWidget {
  const NumbersGameScreen({super.key, Random? random}) : _random = random;

  final Random? _random;

  @override
  State<NumbersGameScreen> createState() => _NumbersGameScreenState();
}

const List<String> kArabicDigitWords = [
  'واحد',
  'اثنان',
  'ثلاثة',
  'أربعة',
  'خمسة',
  'ستة',
  'سبعة',
  'ثمانية',
  'تسعة',
  'عشرة',
];

String toArabicDigits(int n) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return n.toString().split('').map((d) => digits[int.parse(d)]).join();
}

/// 🧺 رموز العدّ في اللعبة — كلها إيموجي أحادي النقطة قابل للعرض على كل
/// المنصات، ولا يُسمح أبدًا بمدخل فارغ (كان يسبب جولات بلا صورة).
const List<String> kNumbersEmojiPool = [
  '\u{1F34E}', // 🍎 تفاحة
  '\u{1F424}', // 🐤 فرخ
  '\u{2B50}', // ⭐ نجمة
  '\u{1F388}', // 🎈 بالون
  '\u{1F41F}', // 🐟 سمكة
  '\u{1F347}', // 🍇 عنب
  '\u{1F338}', // 🌸 زهرة
  '\u{1F353}', // 🍓 فراولة
];

class _NumbersGameScreenState extends State<NumbersGameScreen> {
  static const int _totalQuestions = 10;

  late final Random _rng = widget._random ?? Random();
  late List<_Round> _rounds;
  int _index = 0;
  int _score = 0;
  int _correct = 0;
  int _streak = 0;
  int? _picked;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _rounds = _buildRounds();
  }

  List<_Round> _buildRounds() {
    return List.generate(_totalQuestions, (_) {
      final count = 1 + _rng.nextInt(10);
      final emoji = kNumbersEmojiPool[_rng.nextInt(kNumbersEmojiPool.length)];
      final others = List<int>.generate(10, (i) => i + 1)
        ..removeWhere((n) => n == count);
      final distractors = (others..shuffle(_rng)).take(3).toList();
      final options = [count, ...distractors]..shuffle(_rng);
      return _Round(count: count, emoji: emoji, options: options);
    });
  }

  _Round get _current => _rounds[_index];

  Future<void> _onPick(int optionIndex) async {
    if (_revealed) return;
    setState(() {
      _picked = optionIndex;
      _revealed = true;
    });
    final correct = _current.options[optionIndex] == _current.count;
    if (correct) {
      _score += 10 + _streak * 2;
      _correct++;
      _streak++;
      HapticFeedback.mediumImpact();
      unawaited(
          ChildrenSpeech.speak(kArabicDigitWords[_current.count - 1]));
    } else {
      _streak = 0;
      HapticFeedback.vibrate();
    }
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    if (_index + 1 >= _rounds.length) {
      _showResult();
    } else {
      setState(() {
        _index++;
        _picked = null;
        _revealed = false;
      });
    }
  }

  void _showResult() {
    final stars = _correct >= 9
        ? 3
        : _correct >= 7
            ? 2
            : _correct >= 5
                ? 1
                : 0;
    unawaited(KidsProgress.recordGameResult(
        KidsProgress.numbersGame, _score, stars));
    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'result',
      pageBuilder: (context, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF9A825), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stars >= 2 ? '🎉' : '💪',
                    style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 6),
                Text('عدّاد ماهر!',
                    style: GoogleFonts.tajawal(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E88E5))),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Text(i < stars ? '⭐' : '☆',
                          style: const TextStyle(fontSize: 40)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('النقاط: $_score',
                    style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4E342E))),
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    textStyle: GoogleFonts.tajawal(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _rounds = _buildRounds();
                      _index = 0;
                      _score = 0;
                      _correct = 0;
                      _streak = 0;
                      _picked = null;
                      _revealed = false;
                    });
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('العب مرة أخرى'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text('خروج',
                      style: GoogleFonts.tajawal(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.brown.shade400)),
                ),
              ],
            ),
          ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final round = _current;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: const QurityAppBar(title: 'لعبة الأرقام', color: Color(0xFF1E88E5)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  _Pill(
                      icon: Icons.flag_rounded,
                      text: '${_index + 1} / ${_rounds.length}',
                      color: const Color(0xFF1E88E5)),
                  const Spacer(),
                  _Pill(
                      icon: Icons.emoji_events_rounded,
                      text: '$_score',
                      color: const Color(0xFFF9A825)),
                  if (_streak >= 2) ...[
                    const SizedBox(width: 8),
                    _Pill(
                        icon: Icons.local_fire_department_rounded,
                        text: '$_streak',
                        color: const Color(0xFFE53935)),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: (_index + (_revealed ? 1 : 0)) / _rounds.length,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8DCC8),
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 18),
              Text('كَم عدد الأشياء؟',
                  style: GoogleFonts.tajawal(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.brown.shade600)),
              const SizedBox(height: 14),
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                        color: const Color(0xFFD7CCC8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (var i = 0; i < round.count; i++)
                              Text(round.emoji,
                                  style: const TextStyle(fontSize: 46)),
                          ],
                        ),
                      ),
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: IconButton(
                          tooltip: 'اسمع العدد',
                          onPressed: () => ChildrenSpeech.speak(
                              kArabicDigitWords[round.count - 1]),
                          icon: const Icon(Icons.volume_up_rounded,
                              color: Color(0xFF1E88E5), size: 30),
                        ),
                      ),
                    ],
                  ),
                ).animate(key: ValueKey(_index)).fadeIn(duration: 250.ms),
              ),
              const SizedBox(height: 18),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    for (var row = 0; row < 2; row++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: row == 0 ? 0 : 12),
                          child: Row(
                            children: [
                              for (var col = 0; col < 2; col++)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.only(
                                        start: col == 0 ? 0 : 6,
                                        end: col == 1 ? 0 : 6),
                                    child: _NumberOption(
                                      value: round.options[row * 2 + col],
                                      state: !_revealed
                                          ? _OptionState.idle
                                          : round.options[row * 2 + col] ==
                                                  round.count
                                              ? _OptionState.correct
                                              : row * 2 + col == _picked
                                                  ? _OptionState.wrong
                                                  : _OptionState.dim,
                                      onTap: () => _onPick(row * 2 + col),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Round {
  const _Round(
      {required this.count, required this.emoji, required this.options});
  final int count;
  final String emoji;
  final List<int> options;
}

enum _OptionState { idle, correct, wrong, dim }

class _NumberOption extends StatelessWidget {
  const _NumberOption(
      {required this.value, required this.state, required this.onTap});
  final int value;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = switch (state) {
      _OptionState.idle => [
          const Color(0xFF80D8FF),
          const Color(0xFF1E88E5)
        ],
      _OptionState.correct => [
          const Color(0xFFB9F6CA),
          const Color(0xFF43A047)
        ],
      _OptionState.wrong => [
          const Color(0xFFFF8A80),
          const Color(0xFFE53935)
        ],
      _OptionState.dim => [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)],
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: state == _OptionState.idle ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: colors[1].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Center(
            child: Text(toArabicDigits(value),
                style: GoogleFonts.tajawal(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Text(text,
              style: GoogleFonts.tajawal(
                  fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
