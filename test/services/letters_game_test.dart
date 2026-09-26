import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/children/arabic_letters.dart';
import 'package:qurity/features/children/letters_game_screen.dart';

void main() {
  test('28 unique letters and each word starts with its letter', () {
    expect(kArabicLetters.length, 28);
    expect(kArabicLetters.map((l) => l.letter).toSet().length, 28);
    for (final l in kArabicLetters) {
      final w = l.word.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
      expect(w.startsWith(l.letter), isTrue,
          reason: '${l.name}: "$w" لا يبدأ بـ ${l.letter}');
    }
  });

  testWidgets('letters game renders and a correct pick scores',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LettersGameScreen(random: Random(7)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text('أكمل الكلمة بالحرف الناقص'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    final letterSet = kArabicLetters.map((l) => l.letter).toSet();
    final optionTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where(letterSet.contains)
        .toList();
    expect(optionTexts.length, 4);
    expect(optionTexts.toSet().length, 4);

    // استخرج الحرف الصحيح من الكلمة المعروضة (؟ـ + بقية الكلمة بدون تشكيل)
    final shown = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((t) => t.startsWith('؟ـ'))
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '');
    final target = kArabicLetters.firstWhere((l) =>
        '؟ـ${l.word.substring(1).replaceAll(RegExp(r'[\u064B-\u0652]'), '')}' ==
        shown);

    await tester.tap(find.text(target.letter).first);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('2 / 10'), findsOneWidget);
  });
}
