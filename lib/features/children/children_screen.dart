import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/qurity_app_bar.dart';
import 'arabic_letters.dart';
import 'children_lessons.dart';
import 'coloring_screen.dart';
import 'kids_progress.dart';
import 'lessons_screen.dart';
import 'letters_game_screen.dart';
import 'letters_learn_screen.dart';
import 'numbers_game_screen.dart';

/// 🧒 ركن الأطفال — بوابة ملوّنة لألعاب وأنشطة تعليمية مع إنجازات محفوظة.
class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  KidsSnapshot _progress = const KidsSnapshot(
      bestScores: {}, stars: {}, plays: {}, weakestLetters: []);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snap = await KidsProgress.load();
    if (mounted) setState(() => _progress = snap);
  }

  String? _chipFor(String game) {
    final best = _progress.bestScores[game] ?? 0;
    if (best <= 0) return null;
    final stars = _progress.stars[game] ?? 0;
    return '🏆 $best  ·  ${'⭐' * stars}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: QurityAppBar(
        title: 'ركن الأطفال',
        color: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            tooltip: 'تقرير الأهل',
            onPressed: () => showParentsReport(context, _progress),
            icon: const Icon(Icons.assessment_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Text('تعلّم والعب معنا! 🎈',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF5E35B1))),
          const SizedBox(height: 18),
          _ActivityCard(
            index: 0,
            emoji: '📚',
            title: 'تعلّم الحروف',
            subtitle: 'الحروف العربية بأشكالها وكلماتها',
            colors: const [Color(0xFFB39DDB), Color(0xFF5E35B1)],
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LearnLettersScreen())),
          ),
          _ActivityCard(
            index: 1,
            emoji: '🎮',
            title: 'لعبة الحروف',
            subtitle: 'أكمل الكلمة بالحرف الناقص واجمع النجوم',
            chip: _chipFor(KidsProgress.lettersGame),
            colors: const [Color(0xFFB9F6CA), Color(0xFF43A047)],
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LettersGameScreen())),
          ),
          _ActivityCard(
            index: 2,
            emoji: '🔢',
            title: 'لعبة الأرقام',
            subtitle: 'عُدّ الأشياء واختر العدد الصحيح',
            chip: _chipFor(KidsProgress.numbersGame),
            colors: const [Color(0xFF80D8FF), Color(0xFF1E88E5)],
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NumbersGameScreen())),
          ),
          _ActivityCard(
            index: 3,
            emoji: '🔢',
            title: 'تعلّم الأرقام',
            subtitle: 'من ١ إلى ١٠ بالعدّ بالأصابع والفواكه',
            colors: const [Color(0xFFFFE082), Color(0xFFF9A825)],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LessonsScreen(
                    title: 'تعلّم الأرقام',
                    subtitle: 'عُدّ الفواكه وتعرّف على الأرقام من ١ إلى ١٠ 🍎',
                    accent: const Color(0xFFF9A825),
                    lessons: kNumberLessons))),
          ),
          _ActivityCard(
            index: 4,
            emoji: '💧',
            title: 'تعلّم الوضوء',
            subtitle: 'خطوات الوضوء بالترتيب والنصوص المبسّطة',
            colors: const [Color(0xFF80DEEA), Color(0xFF00838F)],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LessonsScreen(
                    title: 'تعلّم الوضوء',
                    subtitle: 'توضّأ معي خطوة بخطوة كما علّمنا النبي ﷺ 💧',
                    accent: Color(0xFF00838F),
                    lessons: kWuduLessons))),
          ),
          _ActivityCard(
            index: 5,
            emoji: '🕌',
            title: 'تعلّم الصلاة',
            subtitle: 'أركان الصلاة وأذكارها في ثماني خطوات',
            colors: const [Color(0xFFC5E1A5), Color(0xFF33691E)],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LessonsScreen(
                    title: 'تعلّم الصلاة',
                    subtitle: 'صلِّ معي خطوة خطوة — الله أكبر حتى السلام عليكم 🕌',
                    accent: Color(0xFF33691E),
                    lessons: kSalahLessons))),
          ),
          _ActivityCard(
            index: 6,
            emoji: '📖',
            title: 'قصص الأنبياء',
            subtitle: 'قصص مختصرة للأطفال مع العبرة',
            colors: const [Color(0xFFFFCC80), Color(0xFF6D4C41)],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LessonsScreen(
                    title: 'قصص الأنبياء',
                    subtitle: 'من آدم إلى محمد ﷺ — قصص قصيرة وعبرة لكل نبي 🌟',
                    accent: Color(0xFF6D4C41),
                    lessons: kProphetStories))),
          ),
          _ActivityCard(
            index: 7,
            emoji: '🌟',
            title: 'آداب وسلوكيات',
            subtitle: 'أدب الطعام والسلام والصدق وبرّ الوالدين',
            colors: const [Color(0xFFFFAB91), Color(0xFFD84315)],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LessonsScreen(
                    title: 'آداب وسلوكيات',
                    subtitle: 'أجمل السلوكيات نتعلّمها ونعمل بها كل يوم 🌟',
                    accent: Color(0xFFD84315),
                    lessons: kMannersLessons))),
          ),
          _ActivityCard(
            index: 8,
            emoji: '🎨',
            title: 'لوحة التلوين',
            subtitle: 'ارسم ولوّح بألوانك المفضلة',
            colors: const [Color(0xFFF8BBD0), Color(0xFFD81B60)],
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ColoringScreen())),
          ),
        ],
      ),
    );
  }
}

/// 👨‍👩‍👧 تقرير الأهل — ملخص محلي: النجوم واللعبات وأفضل النتائج
/// والحروف التي يخطئ فيها الطفل كثيرًا (نقرتها تفتح بطاقة الحرف).
void showParentsReport(BuildContext context, KidsSnapshot snap) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF6A1B9A), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👨‍👩‍👧', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Text('تقرير الأهل',
                  style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF5E35B1))),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                  label: '⭐ ${snap.totalStars} نجمة',
                  color: const Color(0xFFF9A825)),
              _StatChip(
                  label: '🎯 ${snap.totalPlays} لعبة',
                  color: const Color(0xFF1E88E5)),
              for (final game in [
                KidsProgress.lettersGame,
                KidsProgress.numbersGame
              ])
                _StatChip(
                    label:
                        '${KidsProgress.labelFor(game)}: أفضل ${snap.bestScores[game] ?? 0}',
                    color: const Color(0xFF43A047)),
            ],
          ),
          const SizedBox(height: 16),
          Text('يحتاج تدريبًا',
              style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFC62828))),
          const SizedBox(height: 8),
          if (snap.weakestLetters.isEmpty)
            Text('لا توجد حروف متكررة الخطأ — أداء رائع 🌟',
                style: GoogleFonts.tajawal(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.brown.shade400))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in snap.weakestLetters)
                  GestureDetector(
                    onTap: () {
                      final letter = kArabicLetters.firstWhere(
                          (l) => l.letter == entry.key);
                      Navigator.of(context).pop();
                      LearnLettersScreen.showLetterCard(context, letter);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC62828).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFC62828)
                                .withValues(alpha: 0.4)),
                      ),
                      child: Text('${entry.key}  (×${entry.value})',
                          style: GoogleFonts.amiri(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFC62828))),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0),
  );
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label,
          style: GoogleFonts.tajawal(
              fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.index,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.chip,
  });

  final int index;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? chip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: colors,
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: colors[1].withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 34))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.tajawal(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: GoogleFonts.tajawal(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.92))),
                      if (chip != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(chip!,
                              style: GoogleFonts.tajawal(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
