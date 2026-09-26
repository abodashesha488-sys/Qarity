import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/qurity_app_bar.dart';
import 'children_lessons.dart';
import 'children_speech.dart';

/// 📖 شاشة دروس عامة — تُعرض فيها قائمة دروس (أرقام/وضوء/صلاة/قصص/آداب)
/// ببطاقات ملونة، والنقر يفتح بطاقة الدرس مع النطق الصوتي.
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.lessons,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<ChildLesson> lessons;

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
                  onTap: () => showLessonCard(context, lessons[i], accent),
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
                          child: Center(
                              child: Text(lessons[i].emoji,
                                  style: GoogleFonts.tajawal(
                                      fontSize: lessons[i].emoji.length > 1
                                          ? 24
                                          : 32,
                                      fontWeight: FontWeight.w900,
                                      color: accent))),
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

  /// 🔊 بطاقة الدرس: نص كامل + نصيحة + زر استماع، مع نطق تلقائي عند الفتح.
  static void showLessonCard(
      BuildContext context, ChildLesson lesson, Color accent) {
    ChildrenSpeech.speak('${lesson.title}. ${lesson.body}');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    child: Center(
                        child: Text(lesson.emoji,
                            style: GoogleFonts.tajawal(
                                fontSize: lesson.emoji.length > 1 ? 26 : 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.white))),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.3)),
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
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0),
    );
  }
}
