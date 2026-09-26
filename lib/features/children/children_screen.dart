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
import 'numbers_learn_screen.dart';

/// 🧒 ركن الأطفال — بوابة شبكية حديثة: بطاقات ملونة بأيقونات دائرية
/// لتسعة أنشطة تعليمية مع إنجازات محفوظة وتقارير للأهل.
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
    return '🏆 $best · ${'⭐' * stars}';
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  List<_Activity> _activities(BuildContext context) => [
        _Activity(
          emoji: '📚',
          title: 'تعلّم الحروف',
          subtitle: '٢٨ حرفًا بصور وكلمات',
          colors: const [Color(0xFFB39DDB), Color(0xFF5E35B1)],
          onTap: () => _push(context, const LearnLettersScreen()),
        ),
        _Activity(
          emoji: '🔢',
          title: 'تعلّم الأرقام',
          subtitle: 'من ١ إلى ١٠ بالصور',
          colors: const [Color(0xFFFFE082), Color(0xFFF9A825)],
          onTap: () => _push(context, const LearnNumbersScreen()),
        ),
        _Activity(
          emoji: '🎮',
          title: 'لعبة الحروف',
          subtitle: 'أكمل الكلمة الناقصة',
          chip: _chipFor(KidsProgress.lettersGame),
          colors: const [Color(0xFFB9F6CA), Color(0xFF43A047)],
          onTap: () => _push(context, const LettersGameScreen()),
        ),
        _Activity(
          emoji: '🎯',
          title: 'لعبة الأرقام',
          subtitle: 'عُدّ واختر الصحيح',
          chip: _chipFor(KidsProgress.numbersGame),
          colors: const [Color(0xFF80D8FF), Color(0xFF1E88E5)],
          onTap: () => _push(context, const NumbersGameScreen()),
        ),
        _Activity(
          emoji: '💧',
          title: 'تعلّم الوضوء',
          subtitle: '٨ خطوات بالصور',
          colors: const [Color(0xFF84FFFF), Color(0xFF00838F)],
          onTap: () => _push(
              context,
              const LessonsScreen(
                  title: 'تعلّم الوضوء',
                  subtitle: 'توضّأ معي خطوة بخطوة 💧',
                  accent: Color(0xFF00838F),
                  imageFolder: 'wudu',
                  lessons: kWuduLessons)),
        ),
        _Activity(
          emoji: '🕌',
          title: 'تعلّم الصلاة',
          subtitle: 'من التكبير إلى السلام',
          colors: const [Color(0xFFC5E1A5), Color(0xFF33691E)],
          onTap: () => _push(
              context,
              const LessonsScreen(
                  title: 'تعلّم الصلاة',
                  subtitle: 'صلِّ معي خطوة خطوة 🕌',
                  accent: Color(0xFF33691E),
                  imageFolder: 'salah',
                  lessons: kSalahLessons)),
        ),
        _Activity(
          emoji: '🌟',
          title: 'قصص الأنبياء',
          subtitle: '٨ قصص قصيرة بالعبرة',
          colors: const [Color(0xFFFFCC80), Color(0xFF6D4C41)],
          onTap: () => _push(
              context,
              const LessonsScreen(
                  title: 'قصص الأنبياء',
                  subtitle: 'من آدم إلى محمد ﷺ 🌟',
                  accent: Color(0xFF6D4C41),
                  imageFolder: 'prophets',
                  lessons: kProphetStories)),
        ),
        _Activity(
          emoji: '🤝',
          title: 'آداب وسلوكيات',
          subtitle: 'أجمل العادات كل يوم',
          colors: const [Color(0xFFFFAB91), Color(0xFFD84315)],
          onTap: () => _push(
              context,
              const LessonsScreen(
                  title: 'آداب وسلوكيات',
                  subtitle: 'نتعلّمها ونعمل بها 🌟',
                  accent: Color(0xFFD84315),
                  imageFolder: 'manners',
                  lessons: kMannersLessons)),
        ),
        _Activity(
          emoji: '🎨',
          title: 'لوحة التلوين',
          subtitle: 'ارسم بألوانك المفضلة',
          colors: const [Color(0xFFF8BBD0), Color(0xFFD81B60)],
          onTap: () => _push(context, const ColoringScreen()),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final activities = _activities(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3DC),
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
        padding: EdgeInsets.zero,
        children: [
          const _PortalBanner(),
          const SizedBox(height: 6),
          Text('اختَر نشاطك 🎈',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF6A1B9A))),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 26),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.92,
            children: [
              for (var i = 0; i < activities.length; i++)
                _ActivityTile(activity: activities[i], index: i),
            ],
          ),
        ],
      ),
    );
  }
}

/// 🌈 بانر الترحيب — تدرّج بنفسجي مع قباب ووجوه مرحة.
class _PortalBanner extends StatelessWidget {
  const _PortalBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF8E24AA), Color(0xFF5E35B1), Color(0xFF3949AB)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF5E35B1).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: const Center(
                child: Text('🧒', style: TextStyle(fontSize: 34))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('أهلًا بك في ركن الأطفال!',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 3),
                Text('تعلّم والعب واجمع النجوم ⭐',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.tajawal(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scaleXY(begin: 0.96, end: 1);
  }
}

class _Activity {
  const _Activity({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.chip,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? chip;
}

/// 🧱 بلاطة نشاط: تدرّج لوني + أيقونة دائرية بارزة + عنوان ووصف.
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.index});
  final _Activity activity;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: activity.onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: activity.colors,
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: activity.colors[1].withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Center(
                    child: Text(activity.emoji,
                        style: const TextStyle(fontSize: 38))),
              ),
              const SizedBox(height: 10),
              Text(activity.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(activity.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.92))),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: activity.chip == null
                      ? const SizedBox.shrink()
                      : Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(activity.chip!,
                              style: GoogleFonts.tajawal(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 60).ms).fadeIn(duration: 300.ms).scaleXY(
        begin: 0.9, end: 1, curve: Curves.easeOutBack);
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
                      final letter =
                          kArabicLetters.firstWhere((l) => l.letter == entry.key);
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
                            color:
                                const Color(0xFFC62828).withValues(alpha: 0.4)),
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
