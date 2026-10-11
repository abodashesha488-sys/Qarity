import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 🎵 حالة تشغيل الصوت في ركن الأطفال.
enum TtsPlayState { stopped, playing, paused }

/// 🔊 النطق الصوتي لركن الأطفال — اللغة العربية بلهجة مصرية واضحة وبسيطة:
/// اختيار صوت `ar-EG`، مع مخارج حروف سليمة ومضبوطة وتطبيع ذكي للنص،
/// ودعم كامل للتشغيل والإيقاف المؤقت والاستئناف مع إشعار تفاعلي للواجهات.
class ChildrenSpeech {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;
  static bool _failed = false;

  /// 📢 مخطر حالة الصوت للواجهات التفاعلية (لتغيير الأيقونات تلقائياً).
  static final ValueNotifier<TtsPlayState> playState =
      ValueNotifier<TtsPlayState>(TtsPlayState.stopped);

  /// النص الذي يُنطق حالياً.
  static String currentText = '';

  static bool get isPlaying => playState.value == TtsPlayState.playing;
  static bool get isPaused => playState.value == TtsPlayState.paused;
  static bool get isStopped => playState.value == TtsPlayState.stopped;

  /// 🧹 تطبيع النص لمساعدة محرك النطق (قابل للاختبار بمعزل عن المنصة).
  static String normalize(String text) {
    var t = text;
    t = t.replaceAll('ﷺ', ' صلى الله عليه وسلم ');
    t = t.replaceAll('ﷲ', 'الله');

    // إزالة التشكيل والتطويل لمساعدة محركات النطق
    t = t.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');

    // إزالة علامات الاقتباس العربية واللاتينية التي قد تُنطق ككلمات.
    t = t
        .replaceAll('«', '')
        .replaceAll('»', '')
        .replaceAll(RegExp(r'["“”‘’]'), '');

    // الشرطات والوقفات تتحول إلى وقفة.
    t = t
        .replaceAll(RegExp(r'[—–]'), '،')
        .replaceAll('...', '،')
        .replaceAll('..', '،');

    // «؟ـ» في لعبة الحروف تصبح «؟».
    t = t.replaceAll('؟ـ', '؟').replaceAll('ـ؟', '؟');

    // استبدال أي أرقام لاتينية منفردة بكلمات عربية لمنع نطقها بالإنجليزية إطلاقاً
    t = t.replaceAllMapped(RegExp(r'\b(10|[0-9])\b'), (m) {
      const latinToWord = {
        '0': 'صفر',
        '1': 'واحد',
        '2': 'اثنان',
        '3': 'ثلاثة',
        '4': 'أربعة',
        '5': 'خمسة',
        '6': 'ستة',
        '7': 'سبعة',
        '8': 'ثمانية',
        '9': 'تسعة',
        '10': 'عشرة',
      };
      return latinToWord[m[0]] ?? m[0]!;
    });

    // تنظيم المسافات.
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  static Future<void> _ensure() async {
    if (_ready) return;
    try {
      // تفعيل انتظار اكتمال النطق لانتظام الأحداث
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}

      // 1. ضبط اللغة — نجرب المصرية أولاً ثم البدائل العربية لمنع الرجوع للإنجليزية
      const arabicLocales = [
        'ar-EG',
        'ar-SA',
        'ar',
        'ar-AE',
        'ar-XA',
        'ar_EG',
        'ar_SA',
      ];

      bool langSet = false;
      for (final loc in arabicLocales) {
        try {
          final dynamic isAvail = await _tts.isLanguageAvailable(loc);
          if (isAvail == true || (isAvail is num && isAvail >= 0)) {
            final dynamic res = await _tts.setLanguage(loc);
            if (res == true || (res is num && res >= 0)) {
              langSet = true;
              break;
            }
          }
        } catch (_) {}
      }

      if (!langSet) {
        for (final loc in arabicLocales) {
          try {
            final dynamic res = await _tts.setLanguage(loc);
            if (res == true || (res is num && res >= 0)) {
              langSet = true;
              break;
            }
          } catch (_) {}
        }
      }

      // 2. فحص وضبط الصوت العربي المفضل (اللهجة المصرية أو العربية الفصحى)
      try {
        final dynamic voices = await _tts.getVoices;
        if (voices is List && voices.isNotEmpty) {
          Map<String, String>? preferredVoice;

          for (final v in voices) {
            if (v is Map) {
              final locale =
                  (v['locale'] ?? v['lang'] ?? '').toString().toLowerCase();
              final name = (v['name'] ?? '').toString().toLowerCase();

              if (locale.contains('ar-eg') ||
                  locale.contains('ar_eg') ||
                  name.contains('ar-eg') ||
                  name.contains('ar_eg') ||
                  name.contains('egypt')) {
                preferredVoice = {
                  'name': v['name']?.toString() ?? '',
                  'locale': v['locale']?.toString() ?? 'ar-EG',
                };
                break;
              } else if (preferredVoice == null &&
                  (locale.startsWith('ar') || name.contains('arabic'))) {
                preferredVoice = {
                  'name': v['name']?.toString() ?? '',
                  'locale': v['locale']?.toString() ?? 'ar-SA',
                };
              }
            }
          }

          if (preferredVoice != null && preferredVoice['name']!.isNotEmpty) {
            await _tts.setVoice(preferredVoice);
          }
        }
      } catch (e) {
        debugPrint('[ChildrenSpeech] voice selection error: $e');
      }

      // 3. نبرة وسرعة صوتية مريحة وواضحة جداً للأطفال لضبط مخارج الحروف
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.05);

      // ربط أحداث المشغل لتحديث الواجهات التفاعلية.
      _tts.setStartHandler(() {
        playState.value = TtsPlayState.playing;
      });
      _tts.setCompletionHandler(() {
        playState.value = TtsPlayState.stopped;
        currentText = '';
      });
      _tts.setCancelHandler(() {
        playState.value = TtsPlayState.stopped;
        currentText = '';
      });
      _tts.setPauseHandler(() {
        playState.value = TtsPlayState.paused;
      });
      _tts.setContinueHandler(() {
        playState.value = TtsPlayState.playing;
      });
      _tts.setErrorHandler((_) {
        playState.value = TtsPlayState.stopped;
        currentText = '';
      });

      _ready = true;
      _failed = false;
    } catch (e) {
      debugPrint('[ChildrenSpeech] _ensure error: $e');
      _ready = false;
    }
  }

  /// 🎙️ بدء نطق النص أو إعادة تشغيله.
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensure();
    if (_failed) return;
    try {
      await _tts.stop();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      currentText = text;
      playState.value = TtsPlayState.playing;
      await _tts.speak(normalize(text));
    } catch (e) {
      debugPrint('[ChildrenSpeech] speak error: $e');
      playState.value = TtsPlayState.stopped;
      currentText = '';
    }
  }

  /// ⏸️ إيقاف مؤقت للصوت.
  static Future<void> pause() async {
    try {
      await _tts.pause();
      playState.value = TtsPlayState.paused;
    } catch (_) {
      await stop();
    }
  }

  /// ▶️ استئناف الصوت بعد الإيقاف المؤقت.
  static Future<void> resume() async {
    if (currentText.isEmpty) return;
    try {
      playState.value = TtsPlayState.playing;
      await _tts.speak(normalize(currentText));
    } catch (_) {
      playState.value = TtsPlayState.stopped;
      currentText = '';
    }
  }

  /// ⏹️ إيقاف كامل وفوري للصوت.
  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    playState.value = TtsPlayState.stopped;
    currentText = '';
  }

  /// 🔀 تبديل التشغيل والإيقاف الفوري: إن كان يعمل يوقف، وإن كان متوقفاً يُشغل.
  static Future<void> togglePlayPause(String text) async {
    if (isPlaying) {
      await stop();
    } else {
      await speak(text);
    }
  }

  /// 🔀 دالة صريحة للتشغيل والإيقاف الفوري.
  static Future<void> togglePlayStop(String text) => togglePlayPause(text);
}
