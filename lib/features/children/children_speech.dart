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

  /// 🇪🇬 تحويل النص إلى اللهجة المصرية الواضحة والمفهومة للأطفال
  /// يمنع أي التباس في معاني الكلمات (مثل جمل/جُمَل، أسد/أسُدّ، علم/عِلْم)
  /// ويحوّل التراكيب المعقدة والجامدة إلى لهجة مصرية بسيطة ومحببة.
  static String toEgyptianSpeech(String text) {
    var t = text;

    // استبدال أسماء الحروف المفردة التي قد يخلط المحرك بينها وبين أفعال أو كلمات أخرى
    // التأكد من وضع سياق يوضح للمحرك أن الكلمة اسم كائن/حيوان/شيء
    const singleWordReplacements = {
      'أَسَد': 'كلمة أسد',
      'اسد': 'كلمة أسد',
      'أسد': 'كلمة أسد',
      'جَمَل': 'كلمة جمل',
      'جمل': 'كلمة جمل',
      'عَلَم': 'كلمة علم',
      'علم': 'كلمة علم',
      'هَرَم': 'كلمة هرم',
      'هرم': 'كلمة هرم',
      'قِطّة': 'كلمة قطة',
      'قطة': 'كلمة قطة',
      'طائِرة': 'طيارة',
      'طائرة': 'طيارة',
      'كُرة': 'كورة',
      'كرة': 'كورة',
    };

    if (singleWordReplacements.containsKey(t.trim())) {
      return singleWordReplacements[t.trim()]!;
    }

    // استبدال الأرقام والعد إلى العامية المصرية
    t = t
        .replaceAll('اثنان', 'اتنين')
        .replaceAll('إثنان', 'اتنين')
        .replaceAll('ثلاثة', 'تلاتة')
        .replaceAll('ثمانية', 'تمانية')
        .replaceAll('ثلاث مرات', 'تلات مرات')
        .replaceAll('ثلاثًا', 'تلات مرات')
        .replaceAll('ثلاثا', 'تلات مرات')
        .replaceAll('ثلاث', 'تلات')
        .replaceAll('ثمان', 'تمان');

    // مصطلحات الوضوء والصلاة والآداب لتنطق بالمصرية السلسة
    t = t
        .replaceAll('أميّجه', 'أمضمض فمي')
        .replaceAll('أميجه', 'أمضمض فمي')
        .replaceAll('الاستنثار', 'أخرج المية')
        .replaceAll('مع الخللة', 'وبين الصوابع')
        .replaceAll('سبعة أعظ', 'سبع أعضاء')
        .replaceAll('أستاك', 'أغسل سناني')
        .replaceAll('أحنى ظهري', 'أركع بضهري')
        .replaceAll('يديّ', 'إيديا')
        .replaceAll('يدي', 'إيدي')
        .replaceAll('كفيّ', 'كفوف إيديا')
        .replaceAll('بيميني', 'بإيدي اليمين')
        .replaceAll('بشمالي', 'بإيدي الشمال')
        .replaceAll('بيساري', 'بإيدي الشمال')
        .replaceAll('رأسي', 'راسي')
        .replaceAll('أذنيّ', 'وداني')
        .replaceAll('أذني', 'ودني')
        .replaceAll('قدمي', 'رجلي')
        .replaceAll('قدميّ', 'رجلَي')
        .replaceAll('الذقن', 'الدقن')
        .replaceAll('الأذن', 'الودن')
        .replaceAll('الماء', 'المية')
        .replaceAll('في بداية الكلمة', 'في أول الكلمة')
        .replaceAll('في وسط الكلمة', 'في نص الكلمة')
        .replaceAll('في نهاية الكلمة', 'في آخر الكلمة')
        .replaceAll('مفرد', 'لوحده');

    // عبارات قصص الأنبياء والتوجيهات لتسهيل الفهم
    t = t
        .replaceAll('ريحاً صرصراً عاتية', 'ريح قوية جداً')
        .replaceAll('شطر الإيمان', 'نص الإيمان')
        .replaceAll('بوائقه', 'أذاه')
        .replaceAll('عُذّبت في هرّة', 'دخلت النار في قطة')
        .replaceAll('سقى كلباً', 'سقى كلب عطشان فربنا غفر له')
        .replaceAll('محبوب', 'بيحبه ربنا')
        .replaceAll('أسمع لهما', 'أسمع كلامهم')
        .replaceAll('ولا أرفع صوتي عليهما', 'وما أرفعش صوتي عليهم')
        .replaceAll('أتجنّب المزاح الكاذب', 'مابكدبش أبداً حتى في الهزار');

    return t;
  }

  static Future<void> _ensure() async {
    if (_ready) return;
    try {
      // تفعيل انتظار اكتمال النطق لانتظام الأحداث
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}

      // 1. ضبط اللغة — نفضل اللهجة المصرية ar-EG أولاً
      const arabicLocales = [
        'ar-EG',
        'ar_EG',
        'ar-XA',
        'ar-SA',
        'ar',
        'ar-AE',
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

      // 2. فحص وضبط الصوت العربي المفضل (اللهجة المصرية)
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
                  name.contains('egypt') ||
                  name.contains('masri')) {
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

      // 3. سرعة صوتية طبيعية وبشرية مريحة وواضحة للأطفال
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);

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

  /// 🎙️ بدء نطق النص أو إعادة تشغيله باللهجة المصرية العامية الواضحة.
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensure();
    if (_failed) return;
    try {
      await _tts.stop();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      currentText = text;
      playState.value = TtsPlayState.playing;
      final egyptian = toEgyptianSpeech(text);
      await _tts.speak(normalize(egyptian));
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
