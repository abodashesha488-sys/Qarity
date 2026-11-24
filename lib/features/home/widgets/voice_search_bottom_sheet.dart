import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/constants/app_colors.dart';

/// شيت البحث الصوتي المخصص لسهولة الاستخدام لكبار السن والبسطاء
class VoiceSearchBottomSheet extends StatefulWidget {
  const VoiceSearchBottomSheet({super.key});

  @override
  State<VoiceSearchBottomSheet> createState() => _VoiceSearchBottomSheetState();
}

class _VoiceSearchBottomSheetState extends State<VoiceSearchBottomSheet>
    with SingleTickerProviderStateMixin {
  late final stt.SpeechToText _speech;
  bool _isAvailable = false;
  bool _isListening = false;
  String _words = '';
  String _statusMessage = 'جاري الاتصال بخدمة التعرف على الصوت...';
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _initAndListen();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    try {
      _speech.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initAndListen() async {
    try {
      final available = await _speech.initialize(
        onError: (val) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _statusMessage = 'توقف الاستماع أو لم يتم التقاط صوت واضح.';
            });
          }
        },
        onStatus: (val) {
          if (mounted) {
            if (val == 'listening') {
              setState(() {
                _isListening = true;
                _statusMessage = 'أنا أستمع إليك الآن... تفضل بالتحدث';
              });
            } else if (val == 'done' || val == 'notListening') {
              setState(() => _isListening = false);
            }
          }
        },
      );
      if (mounted) {
        setState(() => _isAvailable = available);
      }
      if (available) {
        _startListening();
      } else {
        if (mounted) {
          setState(() {
            _statusMessage =
                'البحث الصوتي غير مدعوم على هذا الجهاز أو لم يتم منح إذن الميكروفون.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAvailable = false;
          _statusMessage = 'تعذّر تشغيل الميكروفون: $e';
        });
      }
    }
  }

  void _startListening() {
    if (!_isAvailable) return;
    setState(() {
      _words = '';
      _isListening = true;
      _statusMessage = 'تحدث الآن باسم الطبيب، أو الحرفة، أو الخدمة...';
    });
    try {
      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _words = result.recognizedWords;
              if (result.finalResult && _words.trim().isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 350), () {
                  if (mounted) Navigator.pop(context, _words.trim());
                });
              }
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'ar_EG',
          listenMode: stt.ListenMode.search,
        ),
      );
    } catch (_) {}
  }

  void _stopListening() {
    try {
      _speech.stop();
    } catch (_) {}
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط السحب العلوي
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // عنوان الشيت
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'البحث الصوتي بالقرية',
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // حالة الاستماع التوجيهية
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 13,
                color: _isListening
                    ? AppColors.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 24),

            // زر الميكروفون التفاعلي مع تأثير النبض
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final scale =
                    _isListening ? 1.0 + (_pulseCtrl.value * 0.14) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? AppColors.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 20 * _pulseCtrl.value + 8,
                                  spreadRadius: 6 * _pulseCtrl.value,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        size: 42,
                        color: _isListening
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              _isListening ? 'الميكروفون يعمل الآن' : 'اضغط للتحدث مجدداً',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            // عرض الكلمات الملتقطة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _words.isNotEmpty
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                _words.isNotEmpty
                    ? _words
                    : '«قل مثلاً: دكتور أطفال، كهربائي، صيدلية، جرار...»',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight:
                      _words.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                  color: _words.isNotEmpty
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // أزرار التأكيد أو الإلغاء
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        Text('إلغاء', style: GoogleFonts.tajawal(fontSize: 14)),
                  ),
                ),
                if (_words.trim().isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, _words.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(
                        'بحث بهذه النتيجة',
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
