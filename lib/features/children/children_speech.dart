import 'package:flutter_tts/flutter_tts.dart';

/// 🔊 نطق عربي لألعاب الأطفال — يُهيَّأ مرة واحدة ويتجاهل أي فشل
/// (منصة بلا صوت / ويب غير داعم) حتى لا تتعطل اللعبة أبدًا.
class ChildrenSpeech {
  ChildrenSpeech._();

  static FlutterTts? _tts;
  static bool _ready = false;
  static bool _failed = false;

  static Future<void> _ensure() async {
    if (_ready || _failed) return;
    try {
      final tts = FlutterTts();
      await tts.setLanguage('ar');
      await tts.setSpeechRate(0.42);
      await tts.setPitch(1.1);
      _tts = tts;
      _ready = true;
    } catch (_) {
      _failed = true;
    }
  }

  static Future<void> speak(String text) async {
    try {
      await _ensure();
      if (_ready) await _tts?.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
