import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 🏆 إنجازات ركن الأطفال (محليًا فقط): أفضل نتيجة ونجوم لكل لعبة،
/// عدد مرات اللعب، وعدّاد أخطاء الحروف لتقرير الأهل.
class KidsProgress {
  KidsProgress._();

  static const _kBest = 'kids_best_';
  static const _kStars = 'kids_stars_';
  static const _kPlays = 'kids_plays_';
  static const _kMisses = 'kids_letter_misses';

  static const String lettersGame = 'letters';
  static const String numbersGame = 'numbers';

  static String labelFor(String game) =>
      game == lettersGame ? 'لعبة الحروف' : 'لعبة الأرقام';

  static Future<void> recordGameResult(
      String game, int score, int stars) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (score > (prefs.getInt(_kBest + game) ?? 0)) {
        await prefs.setInt(_kBest + game, score);
      }
      if (stars > (prefs.getInt(_kStars + game) ?? 0)) {
        await prefs.setInt(_kStars + game, stars);
      }
      await prefs.setInt(_kPlays + game, (prefs.getInt(_kPlays + game) ?? 0) + 1);
    } catch (_) {}
  }

  static Future<void> recordLetterMiss(String letter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _readMisses(prefs);
      map[letter] = (map[letter] ?? 0) + 1;
      await prefs.setString(_kMisses, jsonEncode(map));
    } catch (_) {}
  }

  static Map<String, int> _readMisses(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_kMisses);
      if (raw == null) return {};
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static Future<KidsSnapshot> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final misses = _readMisses(prefs);
      return KidsSnapshot(
        bestScores: {
          lettersGame: prefs.getInt(_kBest + lettersGame) ?? 0,
          numbersGame: prefs.getInt(_kBest + numbersGame) ?? 0,
        },
        stars: {
          lettersGame: prefs.getInt(_kStars + lettersGame) ?? 0,
          numbersGame: prefs.getInt(_kStars + numbersGame) ?? 0,
        },
        plays: {
          lettersGame: prefs.getInt(_kPlays + lettersGame) ?? 0,
          numbersGame: prefs.getInt(_kPlays + numbersGame) ?? 0,
        },
        weakestLetters: (misses.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .where((e) => e.value >= 2)
            .take(8)
            .map((e) => MapEntry(e.key, e.value))
            .toList(),
      );
    } catch (_) {
      return const KidsSnapshot(
          bestScores: {}, stars: {}, plays: {}, weakestLetters: []);
    }
  }
}

class KidsSnapshot {
  const KidsSnapshot({
    required this.bestScores,
    required this.stars,
    required this.plays,
    required this.weakestLetters,
  });

  final Map<String, int> bestScores;
  final Map<String, int> stars;
  final Map<String, int> plays;
  final List<MapEntry<String, int>> weakestLetters;

  int get totalStars => stars.values.fold(0, (a, b) => a + b);
  int get totalPlays => plays.values.fold(0, (a, b) => a + b);
}
