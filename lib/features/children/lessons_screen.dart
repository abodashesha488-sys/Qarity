import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/qurity_app_bar.dart';
import 'children_lessons.dart';
import 'children_speech.dart';
import 'numbers_game_screen.dart' show toArabicDigits;

/// 📖 شاشة دروس عامة — تُعرض فيها قائمة دروس (وضوء/صلاة/قصص/آداب)
/// ببطاقات ملونة، والنقر يفتح بطاقة الدرس مع النطق الصوتي.
/// عند تمرير `imageFolder` تُعرض صورة الدرس من
/// `assets/images/kids/<folder>/NN.jpg`، ومع غيابها يرجع البند للإيموجي.
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.lessons,
    this.imageFolder,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<ChildLesson> lessons;
  final String? imageFolder;

  String? _assetFor(int index) =>
      imageFolder == null ? null : kidLessonImage(imageFolder!, index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: QurityAppBar(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: accent.withValues(alpha: 0.85))),
          const SizedBox(height: 14),
          for (var i = 0; i < lessons.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _showLessonCard(context, i),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: accent.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.25), width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _assetFor(i) == null
                              ? _emojiBadge(lessons[i], 36, accent)
                              : Image.asset(_assetFor(i)!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      _emojiBadge(lessons[i], 36, accent)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lessons[i].title,
                                  style: GoogleFonts.tajawal(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF4E342E))),
                              const SizedBox(height: 4),
                              Text(lessons[i].body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.tajawal(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.brown.shade300)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: (i * 40).ms).fadeIn(duration: 250.ms),
            ),
        ],
      ),
    );
  }

  Widget _emojiBadge(ChildLesson lesson, double size, Color accent) => Center(
      child: Text(lesson.emoji,
          style: GoogleFonts.tajawal(
              fontSize: lesson.emoji.length > 1 ? size - 8 : size,
              fontWeight: FontWeight.w900,
              color: accent)));

  /// 🔊 بطاقة الدرس: نص كامل + نصيحة + زر استماع، مع نطق تلقائي عند الفتح،
  /// وأزرار «السابق/التالي» للتسلسل داخل القسم (مناسب خطوات الوضوء والصلاة).
  void _showLessonCard(BuildContext context, int startIndex) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LessonCard(
        lessons: lessons,
        accent: accent,
        startIndex: startIndex,
        assetFor: _assetFor,
      ),
    );
  }
}

class _LessonCard extends StatefulWidget {
  const _LessonCard({
    required this.lessons,
    required this.accent,
    required this.startIndex,
    required this.assetFor,
  });

  final List<ChildLesson> lessons;
  final Color accent;
  final int startIndex;
  final String? Function(int index) assetFor;

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> {
  late int _index = widget.startIndex;

  ChildLesson get _lesson => widget.lessons[_index];

  String get _currentFullText => _lesson.effectiveSpeech;

  @override
  void initState() {
    super.initState();
    ChildrenSpeech.speak(_currentFullText);
  }

  @override
  void dispose() {
    ChildrenSpeech.stop();
    super.dispose();
  }

  void _goTo(int next) {
    setState(() => _index = next);
    ChildrenSpeech.speak(_currentFullText);
  }

  Widget _buildLargeEmojiBadge(ChildLesson lesson, Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.15),
            accent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  lesson.emoji,
                  style: TextStyle(
                    fontSize: lesson.emoji.length > 1 ? 40 : 54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                lesson.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    final asset = widget.assetFor(_index);
    final accent = widget.accent;
    final hasPrev = _index > 0;
    final hasNext = _index < widget.lessons.length - 1;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // ─── 🖼️ صورة الدرس التوضيحية بحجم كبير وواضح وبارز للأطفال ───
                    Container(
                      width: double.infinity,
                      height: 195,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: asset != null
                          ? Image.asset(
                              asset,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stack) =>
                                  _buildLargeEmojiBadge(lesson, accent),
                            )
                          : _buildLargeEmojiBadge(lesson, accent),
                    ),

                    // ─── عنوان الدرس وزر الاستماع السريع ───
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson.title,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.tajawal(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              color: accent,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'اسمع',
                          onPressed: () =>
                              ChildrenSpeech.togglePlayPause(_currentFullText),
                          icon: Icon(Icons.volume_up_rounded,
                              color: accent, size: 26),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ─── شريط التحكم الصوتي التفاعلي (تشغيل / إيقاف مؤقت / استمرار / إيقاف) ───
                    ValueListenableBuilder<TtsPlayState>(
                      valueListenable: ChildrenSpeech.playState,
                      builder: (context, state, _) {
                        final isPlaying = state == TtsPlayState.playing;
                        final isPaused = state == TtsPlayState.paused;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              // زر التشغيل / الإيقاف المؤقت
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => ChildrenSpeech.togglePlayPause(
                                      _currentFullText),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          isPlaying
                                              ? 'إيقاف مؤقت'
                                              : (isPaused ? 'استمرار' : 'استمع للقصة'),
                                          style: GoogleFonts.tajawal(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (isPlaying || isPaused) ...[
                                const SizedBox(width: 8),
                                // زر إيقاف كامل
                                IconButton(
                                  tooltip: 'إيقاف نهائي',
                                  iconSize: 22,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.stop_circle_rounded,
                                      color: Color(0xFFD32F2F)),
                                  onPressed: () => ChildrenSpeech.stop(),
                                ),
                              ],
                              const Spacer(),
                              // مؤشر الحالة النصي
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isPlaying
                                        ? 'جارٍ الاستماع 🔊'
                                        : (isPaused
                                            ? 'موقوف مؤقتاً ⏸️'
                                            : 'صوت واضح 🎧'),
                                    style: GoogleFonts.tajawal(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(lesson.body,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.tajawal(
                              fontSize: 15,
                              height: 1.8,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4E342E))),
                    ),
                    if (lesson.tip != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                        ),
                        child: Text('💡 ${lesson.tip}',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.tajawal(
                                fontSize: 13,
                                height: 1.7,
                                fontWeight: FontWeight.w800,
                                color: Color.alphaBlend(
                                    accent.withValues(alpha: 0.6),
                                    const Color(0xFF4E342E)))),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // ─── أزرار التنقل السفلية الثابتة ───
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasPrev
                          ? () => _goTo(_index - 1)
                          : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text('السابق',
                          style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(
                              color: accent.withValues(alpha: 0.5))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                        '${toArabicDigits(_index + 1)} / ${toArabicDigits(widget.lessons.length)}',
                        style: GoogleFonts.tajawal(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.brown.shade400)),
                  ),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: hasNext
                          ? () => _goTo(_index + 1)
                          : null,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text('التالي',
                          style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}
