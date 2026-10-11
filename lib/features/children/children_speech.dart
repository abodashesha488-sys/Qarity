import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 🎵 حالة تشغيل الصوت في ركن الأطفال.
enum TtsPlayState { stopped, playing, paused }

/// 🔊 النطق الصوتي لركن الأطفال — اللهجة المصرية بأفضل مجهود ممكن:
/// اختيار صوت `ar-EG`، وتطبيع النص بذكاء، مع إمكانية التشغيل والإيقاف المؤقت
/// والاستئناف (Play / Pause / Resume / Stop) مع إشعار تفاعلي للواجهات.
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

    // إزالة التشكيل والتطويل — محركات النطق المصرية تخطئ مع التشكيل الكامل.
    t = t.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');

    // إزالة علامات الاقتباس العربية واللاتينية التي قد تُنطق ككلمات.
    t = t
        .replaceAll('«', '')
        .replaceAll('»', '')
        .replaceAll(RegExp(r'["“”‘’]'), '');

    // الشرطات والوقفات تتحول إلى وقفة.
    t = t
        .replaceAll(RegExp(r'[—–]'), '،')
        .replaceAll('...', '،');

    // «؟ـ» في لعبة الحروف تصبح «؟».
    t = t.replaceAll('؟ـ', '؟').replaceAll('ـ؟', '؟');

    // تنظيم المسافات.
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  static Future<void> _ensure() async {
    if (_ready || _failed) return;
    try {
      // محاولة اختيار صوت مصري ar-EG من الأصوات المثبتة إن توفرت.
      try {
        final dynamic voices = await _tts.getVoices;
        if (voices is List) {
          for (final v in voices) {
            if (v is Map) {
              final locale =
                  (v['locale'] ?? v['lang'] ?? '').toString().toLowerCase();
              if (locale.contains('ar-eg') || locale.contains('ar_eg')) {
                await _tts.setVoice({
                  'name': v['name']?.toString() ?? '',
                  'locale': v['locale']?.toString() ?? 'ar-EG',
                });
                break;
              }
            }
          }
        }
      } catch (_) {}

      final ok = await _tts.setLanguage('ar-EG');
      if (ok != true) await _tts.setLanguage('ar');

      // نبرة وسرعة صوتية مناسبة ولطيفة للأطفال (هادئة وواضحة).
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.08);

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
    } catch (_) {
      _failed = true;
    }
  }

  /// 🎙️ بدء نطق النص أو إعادة تشغيله.
  static Future<void> speak(String text) async {
    await _ensure();
    if (_failed) return;
    try {
      await _tts.stop();
      currentText = text;
      playState.value = TtsPlayState.playing;
      await _tts.speak(normalize(text));
    } catch (_) {
      playState.value = TtsPlayState.stopped;
    }
  }

  /// ⏸️ إيقاف مؤقت للصوت.
  static Future<void> pause() async {
    if (_failed) return;
    try {
      await _tts.pause();
      playState.value = TtsPlayState.paused;
    } catch (_) {
      await stop();
    }
  }

  /// ▶️ استئناف الصوت بعد الإيقاف المؤقت.
  static Future<void> resume() async {
    if (_failed) return;
    if (currentText.isEmpty) return;
    try {
      // إن تعذر الاستئناف عبر المحرك (على بعض الأجهزة)، نعيد نطق النص.
      playState.value = TtsPlayState.playing;
      await _tts.speak(normalize(currentText));
    } catch (_) {
      playState.value = TtsPlayState.stopped;
    }
  }

  /// ⏹️ إيقاف كامل للصوت.
  static Future<void> stop() async {
    if (_failed) return;
    try {
      await _tts.stop();
    } catch (_) {}
    playState.value = TtsPlayState.stopped;
    currentText = '';
  }

  /// 🔀 تبديل التشغيل والإيقاف المؤقت لنص معين (Play / Pause / Resume).
  static Future<void> togglePlayPause(String text) async {
    final clean = normalize(text);
    final curClean = normalize(currentText);

    if (isPlaying && clean == curClean) {
      await pause();
    } else if (isPaused && clean == curClean) {
      await resume();
    } else {
      await speak(text);
    }
  }
}
