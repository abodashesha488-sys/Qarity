import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show ByteData;
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
  final GlobalKey _boundaryKey = GlobalKey();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);

  bool _isGeneratingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _shareCertificateFallbackText(String name) {
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

  Future<void> _shareCertificateAsImage() async {
    if (_isGeneratingImage) return;

    final name = _nameController.text.trim().isEmpty
        ? 'بطل القرية الصغير'
        : _nameController.text.trim();

    setState(() => _isGeneratingImage = true);

    try {
      FocusScope.of(context).unfocus();
      // انتظار اكتمال الإطار واختفاء التركيز عن الحقل ليظهر كاسم مطبوع رسمي
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _shareCertificateFallbackText(name);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) {
        _shareCertificateFallbackText(name);
        return;
      }

      final bytes = byteData.buffer.asUint8List();

      if (!mounted) return;
      await ShareService.shareKidsCertificateAsImage(
        context: context,
        imageBytes: bytes,
        childName: name,
        totalStars: widget.totalStars,
        gameTitle: widget.gameTitle,
      );
    } catch (e) {
      if (!mounted) return;
      _shareCertificateFallbackText(name);
    } finally {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayName = _nameController.text.trim().isEmpty
        ? 'بطل القرية الصغير'
        : _nameController.text.trim();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── لوحة إدخال وتعديل اسم الطفل بكل سهولة ووضوح ──
            Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232336) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFD4AF37),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded,
                          color: Color(0xFFD4AF37), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'اسم البطل / الطفل (يظهر في الشهادة):',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF3E2723),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.done,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.amber : const Color(0xFFC2185B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'اكتب اسم الطفل هنا بكل سهولة...',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFFFFDF5),
                      prefixIcon: const Icon(Icons.child_care_rounded,
                          color: Color(0xFFC2185B)),
                      suffixIcon: _nameController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              tooltip: 'مسح',
                              onPressed: () {
                                _nameController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color:
                                const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFC2185B), width: 2),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),

            // ── بطاقة الشهادة الذهبية المجهزة للتصوير والمشاركة ──
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
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

                    // ── شعار القرية الرسمي في منتصف الشهادة كعلامة مائية فخمة ──
                    Positioned.fill(
                      child: Center(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: isDark ? 0.08 : 0.12,
                            child: Image.asset(
                              'assets/images/Qurity.png',
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // الترويسة مع شعار القرية واسم الركن
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipOval(
                                  child: Image.asset(
                                    'assets/images/Qurity.png',
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.cover,
                                  ),
                                ),
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
                                const Text('🌟', style: TextStyle(fontSize: 18)),
                              ],
                            ),
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
                              size: 38,
                              color: Colors.white,
                            ),
                          ).animate().scale(duration: 350.ms),
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 10),
                          // اسم الطفل المطبوع في الشهادة بكل فخامة ووضوح
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                            child: Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFC2185B),
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
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
                          ),
                          const SizedBox(height: 16),
                          // ── الختم والتوقيع: شعار التطبيق بحجم واضح ومقروء ──
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
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
                                const SizedBox(width: 24),
                                // ── ختم الشهادة الرسمي: شعار التطبيق بحجم واضح ومقروء ──
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'الختم الرسمي',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFFB78103),
                                          ),
                                        ),
                                        Text(
                                          'تطبيق قرية أبوديشيشة',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white70 : const Color(0xFF3E2723),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 66,
                                      height: 66,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: const Color(0xFFD4AF37),
                                          width: 2.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.all(2.5),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFB78103).withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Image.asset(
                                              'assets/images/Qurity.png',
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── أزرار الإجراءات المتجاوبة ──
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isGeneratingImage ? null : _shareCertificateAsImage,
                  icon: _isGeneratingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    _isGeneratingImage ? 'جارٍ تجهيز الصورة...' : 'مشاركة الشهادة كصورة',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                ),
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
