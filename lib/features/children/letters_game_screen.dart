import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/qurity_app_bar.dart';
import 'arabic_letters.dart';
import 'children_speech.dart';
import 'kids_progress.dart';

/// 🎮 لعبة الحروف — «أكمل الكلمة»: إيموجي وكلمة بحرف أول ناقص،
/// والطفل يختار الحرف الصحيح من 4 خيارات. 10 أسئلة، نقاط ونجوم.
class LettersGameScreen extends StatefulWidget {
  const LettersGameScreen({super.key, Random? random}) : _random = random;

  final Random? _random;

  @override
  State<LettersGameScreen> createState() => _LettersGameScreenState();
}

class _LettersGameScreenState extends State<LettersGameScreen> {
  static const int _totalQuestions = 10;

  late final Random _rng = widget._random ?? Random();
  late List<_Question> _questions;
  int _index = 0;
  int _score = 0;
  int _correct = 0;
  int _streak = 0;
  int? _picked; // index within options of the last pick
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<_Question> _buildQuestions() {
    final pool = List<ArabicLetter>.from(kArabicLetters)..shuffle(_rng);
    return pool.take(_totalQuestions).map((target) {
      String base(String s) => s.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
      final others = List<ArabicLetter>.from(kArabicLetters)
        ..removeWhere((l) => base(l.letter) == base(target.letter));
      final distractors = (others..shuffle(_rng)).take(3).toList();
      final options = [target, ...distractors]..shuffle(_rng);
      return _Question(
          target: target,
          options: options.map((l) => l.letter).toList());
    }).toList();
  }

  _Question get _current => _questions[_index];

  Future<void> _onPick(int optionIndex) async {
    if (_revealed) return;
    setState(() {
      _picked = optionIndex;
      _revealed = true;
    });
    final correct =
        _current.options[optionIndex] == _current.target.letter;
    if (correct) {
      _score += 10 + _streak * 2;
      _correct++;
      _streak++;
      HapticFeedback.mediumImpact();
      unawaited(ChildrenSpeech.speak(_current.target.word));
    } else {
      _streak = 0;
      HapticFeedback.vibrate();
      unawaited(KidsProgress.recordLetterMiss(_current.target.letter));
    }
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    if (_index + 1 >= _questions.length) {
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
        KidsProgress.lettersGame, _score, stars));
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
                Text('أحسنت يا بطل!',
                    style: GoogleFonts.tajawal(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF5E35B1))),
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
                    backgroundColor: const Color(0xFF43A047),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    textStyle: GoogleFonts.tajawal(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _questions = _buildQuestions();
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
    final q = _current;
    final word = q.target.word;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: const QurityAppBar(title: 'لعبة الحروف', color: Color(0xFF43A047)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  _Pill(
                      icon: Icons.flag_rounded,
                      text: '${_index + 1} / ${_questions.length}',
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
                  value: (_index + (_revealed ? 1 : 0)) / _questions.length,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8DCC8),
                  color: const Color(0xFF43A047),
                ),
              ),
              const SizedBox(height: 18),
              Text('أكمل الكلمة بالحرف الناقص',
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(q.target.emoji,
                                style: const TextStyle(fontSize: 84)),
                            const SizedBox(height: 10),
                            Text('؟ـ${word.substring(1)}',
                                textDirection: TextDirection.rtl,
                                style: GoogleFonts.amiri(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF4E342E))),
                          ],
                        ),
                      ),
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: IconButton(
                          tooltip: 'اسمع الكلمة',
                          onPressed: () =>
                              ChildrenSpeech.speak(q.target.word),
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
                          padding: EdgeInsets.only(
                              top: row == 0 ? 0 : 12,
                              bottom: row == 1 ? 0 : 0),
                          child: Row(
                            children: [
                              for (var col = 0; col < 2; col++)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.only(
                                        start: col == 0 ? 0 : 6,
                                        end: col == 1 ? 0 : 6),
                                    child: _OptionButton(
                                      letter: q.options[row * 2 + col],
                                      state: !_revealed
                                          ? _OptionState.idle
                                          : q.options[row * 2 + col] ==
                                                  q.target.letter
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

class _Question {
  const _Question({required this.target, required this.options});
  final ArabicLetter target;
  final List<String> options;
}

enum _OptionState { idle, correct, wrong, dim }

class _OptionButton extends StatelessWidget {
  const _OptionButton(
      {required this.letter, required this.state, required this.onTap});
  final String letter;
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
            child: Text(letter,
                style: GoogleFonts.amiri(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
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
