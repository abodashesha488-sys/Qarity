import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/qurity_app_bar.dart';
import 'arabic_letters.dart';
import 'children_lessons.dart';
import 'children_speech.dart';
import 'coloring_screen.dart';
import 'kids_certificate_dialog.dart';
import 'kids_progress.dart';
import 'lessons_screen.dart';
import 'letters_game_screen.dart';
import 'letters_learn_screen.dart';
import 'numbers_game_screen.dart';
import 'numbers_learn_screen.dart';

/// 🧒 ركن الأطفال — واجهة عصرية مرحة ومنظمة للأطفال مع تصنيفات تفاعلية
/// وإنجازات محفوظة ومحرك نطق مصري ودود.
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

  void _push(BuildContext context, Widget screen) async {
    ChildrenSpeech.stop();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      appBar: QurityAppBar(
        title: 'ركن الأطفال',
        actions: [
          IconButton(
            tooltip: 'تقرير الأهل',
            onPressed: () => showParentsReport(context, _progress),
            icon: const Icon(Icons.assessment_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ─── البانر الترحيبي مع النجوم ───
          _PortalBanner(
            totalStars: _progress.totalStars,
            onOpenReport: () => showParentsReport(context, _progress),
            onOpenCertificate: () => showKidsCertificateDialog(
              context,
              totalStars: _progress.totalStars,
            ),
          ),
          const SizedBox(height: 18),

          // ─── 1. التعلّم والمعرفة ───
          const _SectionHeader(
            emoji: '📚',
            title: 'التعلّم والمعرفة',
            subtitle: 'الحروف والأرقام بطريقة ممتعة وبصرية',
            color: Color(0xFF5E35B1),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LargeFeatureCard(
                  emoji: '📚',
                  title: 'تعلّم الحروف',
                  subtitle: '٢٨ حرفاً بالصور والكلمات',
                  colors: const [Color(0xFF7E57C2), Color(0xFF512DA8)],
                  onTap: () => _push(context, const LearnLettersScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LargeFeatureCard(
                  emoji: '🔢',
                  title: 'تعلّم الأرقام',
                  subtitle: 'من ١ إلى ١٠ بالصور والعد',
                  colors: const [Color(0xFFFFB300), Color(0xFFF57C00)],
                  onTap: () => _push(context, const LearnNumbersScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ─── 2. ألعاب الذكاء والتحدي ───
          const _SectionHeader(
            emoji: '🎮',
            title: 'ألعاب وتحديات ممتعة',
            subtitle: 'العب واجمع النجوم والكؤوس الذهبية',
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _GameCard(
                  emoji: '🎮',
                  title: 'لعبة الحروف',
                  subtitle: 'أكمل الكلمة الناقصة',
                  chip: _chipFor(KidsProgress.lettersGame),
                  colors: const [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  onTap: () => _push(context, const LettersGameScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GameCard(
                  emoji: '🎯',
                  title: 'لعبة الأرقام',
                  subtitle: 'عُدّ واختر الرقم الصحيح',
                  chip: _chipFor(KidsProgress.numbersGame),
                  colors: const [Color(0xFF29B6F6), Color(0xFF0288D1)],
                  onTap: () => _push(context, const NumbersGameScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ─── 3. واحة الإيمان والقصص والآداب ───
          const _SectionHeader(
            emoji: '🕌',
            title: 'واحة الإيمان والقصص',
            subtitle: 'سيرة الأنبياء المفصلة والصلوات والأخلاق',
            color: Color(0xFF8D6E63),
          ),
          const SizedBox(height: 10),

          // بطاقة قصص الأنبياء البارزة
          _ProphetStoriesHeroCard(
            onTap: () => _push(
              context,
              const LessonsScreen(
                title: 'قصص الأنبياء',
                subtitle: 'قصص مفصلة ومشوقة من آدم إلى محمد ﷺ 🌟',
                accent: Color(0xFF6D4C41),
                imageFolder: 'prophets',
                lessons: kProphetStories,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // بطاقات الصلاة والوضوء والآداب
          Row(
            children: [
              Expanded(
                child: _LessonTile(
                  emoji: '🕌',
                  title: 'تعلّم الصلاة',
                  subtitle: 'خطوة بخطوة بالصور',
                  colors: const [Color(0xFF81C784), Color(0xFF388E3C)],
                  onTap: () => _push(
                    context,
                    const LessonsScreen(
                      title: 'تعلّم الصلاة',
                      subtitle: 'صلِّ معي خطوة خطوة 🕌',
                      accent: Color(0xFF33691E),
                      imageFolder: 'salah',
                      lessons: kSalahLessons,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LessonTile(
                  emoji: '💧',
                  title: 'تعلّم الوضوء',
                  subtitle: '٨ خطوات سهلة',
                  colors: const [Color(0xFF4DD0E1), Color(0xFF0097A7)],
                  onTap: () => _push(
                    context,
                    const LessonsScreen(
                      title: 'تعلّم الوضوء',
                      subtitle: 'توضّأ معي خطوة بخطوة 💧',
                      accent: Color(0xFF00838F),
                      imageFolder: 'wudu',
                      lessons: kWuduLessons,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MannersBannerCard(
            onTap: () => _push(
              context,
              const LessonsScreen(
                title: 'آداب وسلوكيات',
                subtitle: 'أجمل الأخلاق والعادات اليومية 🌟',
                accent: Color(0xFFD84315),
                imageFolder: 'manners',
                lessons: kMannersLessons,
              ),
            ),
          ),
          const SizedBox(height: 22),

          // ─── 4. الإبداع والمرح ───
          const _SectionHeader(
            emoji: '🎨',
            title: 'الإبداع والتلوين',
            subtitle: 'ارسم ولوّن بألوانك الجميلة المفضلة',
            color: Color(0xFFD81B60),
          ),
          const SizedBox(height: 10),
          _ColoringHeroCard(
            onTap: () => _push(context, const ColoringScreen()),
          ),
        ],
      ),
    );
  }
}

/// 🌟 ترويسة القسم التصنيفي
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 🌈 بانر الترحيب — تدرّج مرح مع عرض النجوم وتقرير الأهل
class _PortalBanner extends StatelessWidget {
  const _PortalBanner({
    required this.totalStars,
    required this.onOpenReport,
    required this.onOpenCertificate,
  });

  final int totalStars;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenCertificate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFF5E35B1), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E35B1).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text('🧒', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلًا بك في ركن الأطفال!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'تعلّم، العب، واستمع لأجمل القصص',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // كبسولة النجوم
          InkWell(
            onTap: onOpenReport,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$totalStars',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // زر الشهادة
          InkWell(
            onTap: onOpenCertificate,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD54F),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      size: 15, color: Color(0xFFFFD54F)),
                  const SizedBox(width: 4),
                  Text(
                    'الشهادة',
                    style: GoogleFonts.tajawal(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scaleXY(begin: 0.96, end: 1);
  }
}

/// 📚 بطاقة كبيرة للتعلّم (الحروف والأرقام)
class _LargeFeatureCard extends StatelessWidget {
  const _LargeFeatureCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[1].withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.26),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 27)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎮 بطاقة الألعاب مع شارة النتائج
class _GameCard extends StatelessWidget {
  const _GameCard({
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[1].withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 25)),
                    ),
                  ),
                  if (chip != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        chip!,
                        style: GoogleFonts.tajawal(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🌟 بطاقة عريضة فخمة لقصص الأنبياء المفصلة
class _ProphetStoriesHeroCard extends StatelessWidget {
  const _ProphetStoriesHeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5D4037).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text('🌟', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'قصص الأنبياء',
                          style: GoogleFonts.tajawal(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '١٣ قصة مفصلة',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'قصص شيقة مفصلة بصوت واضح ودروس وعبر 📖',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded,
                  color: Colors.white70, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🕌 بطاقة تعليمية متوسطة
class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors[1].withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🤝 بانر آداب وسلوكيات
class _MannersBannerCard extends StatelessWidget {
  const _MannersBannerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A65), Color(0xFFD84315)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD84315).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🤝', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'آداب وسلوكيات',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'أجمل العادات اليومية وأخلاق المسلم الصغير 🌟',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎨 بطاقة لوحة التلوين
class _ColoringHeroCard extends StatelessWidget {
  const _ColoringHeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEC407A), Color(0xFFC2185B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC2185B).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text('🎨', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لوحة التلوين',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ألوان رائعة وفرشاة رسم حرة لتنمية موهبة طفلك 🖌️',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70, size: 20),
            ],
          ),
        ),
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
              Text(
                'تقرير الأهل',
                style: GoogleFonts.tajawal(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF5E35B1),
                ),
              ),
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
          Text(
            'يحتاج تدريبًا',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFC62828),
            ),
          ),
          const SizedBox(height: 8),
          if (snap.weakestLetters.isEmpty)
            Text(
              'لا توجد حروف متكررة الخطأ — أداء رائع 🌟',
              style: GoogleFonts.tajawal(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.brown.shade400,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in snap.weakestLetters)
                  GestureDetector(
                    onTap: () {
                      final letter = kArabicLetters
                          .firstWhere((l) => l.letter == entry.key);
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
                      child: Text(
                        '${entry.key}  (×${entry.value})',
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                showKidsCertificateDialog(context, totalStars: snap.totalStars);
              },
              icon: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.black87),
              label: Text(
                'إصدار شهادة التفوق للبطل 🎖️',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ),
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
      child: Text(
        label,
        style: GoogleFonts.tajawal(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
