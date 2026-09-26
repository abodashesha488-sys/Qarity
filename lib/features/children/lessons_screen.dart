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
      appBar: QurityAppBar(title: title, color: accent),
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
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _assetFor(i) == null
                              ? _emojiBadge(lessons[i], 32, accent)
                              : Image.asset(_assetFor(i)!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      _emojiBadge(lessons[i], 32, accent)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lessons[i].title,
                                  style: GoogleFonts.tajawal(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF4E342E))),
                              const SizedBox(height: 3),
                              Text(lessons[i].body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.tajawal(
                                      fontSize: 12,
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

  @override
  void initState() {
    super.initState();
    ChildrenSpeech.speak('${_lesson.title}. ${_lesson.body}');
  }

  void _goTo(int next) {
    setState(() => _index = next);
    ChildrenSpeech.speak('${_lesson.title}. ${_lesson.body}');
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
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.35),
                            accent
                          ],
                          begin: Alignment.topLeft),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: asset == null
                        ? Center(
                            child: Text(lesson.emoji,
                                style: GoogleFonts.tajawal(
                                    fontSize:
                                        lesson.emoji.length > 1 ? 26 : 34,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)))
                        : Image.asset(asset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Center(
                                child: Text(lesson.emoji,
                                    style: const TextStyle(fontSize: 30)))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(lesson.title,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: accent)),
                  ),
                  IconButton(
                    tooltip: 'اسمع',
                    onPressed: () => ChildrenSpeech.speak(
                        '${lesson.title}. ${lesson.body}${lesson.tip == null ? '' : '. ${lesson.tip}'}'),
                    icon: Icon(Icons.volume_up_rounded,
                        color: accent, size: 24),
                  ),
                ],
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
              const SizedBox(height: 16),
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
