import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// صوت/اهتزاز التنبيهات العاجلة داخل التطبيق — يقرع ding.wav (نفس صوت
/// الإعلانات) مرة واحدة فقط لكل نسخة من التنبيه (مفتاح = updatedAt).
class AlertSound {
  AlertSound._();

  static final AudioPlayer _player = AudioPlayer();
  static final Set<String> _ringedThisSession = {};

  static void resetForTest() => _ringedThisSession.clear();

  static Future<void> ringOnce(String alertKey) async {
    if (_ringedThisSession.contains(alertKey)) return;
    _ringedThisSession.add(alertKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(alertKey) ?? false) return;
      await prefs.setBool(alertKey, true);
    } catch (_) {}
    unawaited(HapticFeedback.vibrate()
        .catchError((_) {}));
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/ding.wav'), volume: 1.0);
    } catch (_) {}
  }
}
