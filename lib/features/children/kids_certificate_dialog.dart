import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/share_service.dart';

/// 🎖️ نافذة شهادة التقدير والتفوق لركن الأطفال.
void showKidsCertificateDialog(
  BuildContext context, {
  required int totalStars,
  String? defaultName,
  String? gameTitle,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => _KidsCertificateDialog(
      totalStars: totalStars,
      initialName: defaultName ?? 'بطل القرية الصغير',
      gameTitle: gameTitle,
    ),
  );
}

class _KidsCertificateDialog extends StatefulWidget {
  const _KidsCertificateDialog({
    required this.totalStars,
    required this.initialName,
    this.gameTitle,
  });

  final int totalStars;
  final String initialName;
  final String? gameTitle;

  @override
  State<_KidsCertificateDialog> createState() => _KidsCertificateDialogState();
}

class _KidsCertificateDialogState extends State<_KidsCertificateDialog> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _shareCertificate() {
    final name = _nameController.text.trim().isEmpty
        ? 'بطل القرية'
        : _nameController.text.trim();
    final starsText =
        widget.totalStars > 0 ? '${widget.totalStars} نجمة ذهبية ⭐' : 'نجوم التفوق ⭐';

    ShareService.shareText(
      title: '🎖️ شهادة تفوق وتميز للبطل $name',
      body: [
        '✨ يسر ركن الأطفال بتطبيق قرية أبوديشيشة أن يمنح هذه الشهادة للبطل المتميز:',
        '🌟 **$name** 🌟',
        'تقديرًا لاجتهاده وتفوقه في ${widget.gameTitle ?? 'ألعاب وتحديات ركن الأطفال'} وحصده $starsText!',
        'بارك الله فيك وإلى مزيد من النجاح والتفوق دائماً يا بطل 🎈🎉',
      ].join('\n\n'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── بطاقة الشهادة الذهبية ──
            Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFD4AF37), // ذهبي
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // زخارف الإطار الداخلي
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الترويسة
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🌟', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Text(
                              'قرية أبوديشيشة · ركن الأطفال',
                              style: GoogleFonts.tajawal(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB78103),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('🌟', style: TextStyle(fontSize: 22)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // شعار التاج والشهادة
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ).animate().scale(duration: 350.ms),
                        const SizedBox(height: 12),
                        Text(
                          'شهادة تفوق وتقدير',
                          style: GoogleFonts.amiri(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF4A148C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تُمنح بكل فخر واعتزاز للبطل:',
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // حقل اسم الطفل التفاعلي
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFD4AF37),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.amiri(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFC2185B),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'اكتب اسم الطفل هنا',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'تقديرًا لاجتهاده وتميزه الملحوظ في تعلّم الحروف والأرقام وإنجاز التحديات بذكاء وبراعة.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.tajawal(
                            fontSize: 12.5,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : const Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // شارات الإنجاز
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _BadgePill(
                              icon: Icons.star_rounded,
                              label: widget.totalStars > 0
                                  ? '${widget.totalStars} نجمة'
                                  : 'امتياز ⭐',
                              color: const Color(0xFFFFA000),
                            ),
                            const SizedBox(width: 8),
                            const _BadgePill(
                              icon: Icons.favorite_rounded,
                              label: 'بطل القرية 🏆',
                              color: Color(0xFFE91E63),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // الختم والتوقيع
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'التاريخ:',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // ختم التميز
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'ختم التميز الرسمي ✨',
                                style: GoogleFonts.tajawal(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFB78103),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── أزرار الإجراءات ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _shareCertificate,
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    'مشاركة الشهادة',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black38,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'إغلاق',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
