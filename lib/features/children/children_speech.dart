import 'package:flutter_tts/flutter_tts.dart';

/// 🔊 النطق الصوتي لركن الأطفال — اللهجة المصرية بأفضل مجهود ممكن:
/// tried `ar-EG` ثم رجوعًا إلى `ar`، وتطبيع النص قبل النطق (إزالة التشكيل
/// الزائد والرموز التي تخطئ محركات النطق قراءتها)، وابتلاع أي فشل بهدوء.
class ChildrenSpeech {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;
  static bool _failed = false;

  /// 🧹 تطبيع النص لمساعدة محرك النطق (قابل للاختبار بمعزل عن المنصة).
  static String normalize(String text) {
    var t = text;
    t = t.replaceAll('ﷺ', ' صلى الله عليه وسلم ');
    t = t.replaceAll('ﷲ', 'الله');
    // إزالة التشكيل والتطويل — محركات النطق المصرية تخطئ مع التشكيل الكامل.
    t = t.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');
    // إزالة علامات الاقتباس العربية واللاتينية التي تُنطق أحيانًا.
    t = t
        .replaceAll('«', '')
        .replaceAll('»', '')
        .replaceAll(RegExp(r'["“”‘’]'), '');
    // الشرطات الطويلة والـellipsis تتحول إلى وقفة.
    t = t
        .replaceAll(RegExp(r'[—–]'), '،')
        .replaceAll('...', '،');
    // «؟ـ» في لعبة الحروف تصبح «؟».
    t = t.replaceAll('؟ـ', '؟').replaceAll('ـ؟', '؟');
    // الأرقام العربية الهندية تبقى كما هي (تنطقها المحركات صحيحة غالبًا).
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  static Future<void> _ensure() async {
    if (_ready || _failed) return;
    try {
      // اللهجة المصرية أولًا، ثم العربية الفصحى كخطة بديلة.
      final ok = await _tts.setLanguage('ar-EG');
      if (ok != true) await _tts.setLanguage('ar');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.05);
      _ready = true;
    } catch (_) {
      _failed = true;
    }
  }

  static Future<void> speak(String text) async {
    await _ensure();
    if (_failed) return;
    try {
      await _tts.stop();
      await _tts.speak(normalize(text));
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (_failed) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
