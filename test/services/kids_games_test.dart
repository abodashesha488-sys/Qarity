import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/children/children_screen.dart';
import 'package:qurity/features/children/coloring_screen.dart';
import 'package:qurity/features/children/kids_progress.dart';
import 'package:qurity/features/children/numbers_game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('arabic digits conversion', () {
    expect(toArabicDigits(1), '١');
    expect(toArabicDigits(10), '١٠');
    expect(toArabicDigits(7), '٧');
  });

  test('مجموع رموز لعبة الأرقام لا يحتوي فارغًا ولا رموزًا مركّبة', () {
    expect(kNumbersEmojiPool, hasLength(8));
    for (final e in kNumbersEmojiPool) {
      expect(e.isNotEmpty, isTrue);
      expect(e.runes.length, 1, reason: 'رمز أحادي النقطة فقط: $e');
    }
  });

  testWidgets('لعبة الأرقام لا تعرض سؤالًا بلا صورة أبدًا', (tester) async {
    for (final seed in [1, 2, 3, 4, 5, 6, 7, 8]) {
      await tester.pumpWidget(
          MaterialApp(home: NumbersGameScreen(random: Random(seed))));
      await tester.pump();
      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      final texts = wrap.children.cast<Text>();
      expect(texts, isNotEmpty, reason: 'seed $seed — لا جولات فارغة');
      for (final t in texts) {
        expect(kNumbersEmojiPool, contains(t.data), reason: 'seed $seed');
      }
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  test('kids progress stores best score and weakest letters', () async {
    SharedPreferences.setMockInitialValues({});
    await KidsProgress.recordGameResult(KidsProgress.lettersGame, 40, 2);
    await KidsProgress.recordGameResult(KidsProgress.lettersGame, 30, 3);
    for (var i = 0; i < 3; i++) {
      await KidsProgress.recordLetterMiss('ش');
    }
    await KidsProgress.recordLetterMiss('ض');

    final snap = await KidsProgress.load();
    expect(snap.bestScores[KidsProgress.lettersGame], 40);
    expect(snap.stars[KidsProgress.lettersGame], 3);
    expect(snap.plays[KidsProgress.lettersGame], 2);
    expect(snap.weakestLetters.first.key, 'ش');
    expect(snap.weakestLetters.map((e) => e.key), isNot(contains('ض')));
  });

  testWidgets('numbers game renders and a correct pick scores',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: NumbersGameScreen(random: Random(3)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text('كَم عدد الأشياء؟'), findsOneWidget);

    // عدد الإيموجي المعروض = الهدف (يُقرأ من المجموع العامة نفسها).
    var count = 0;
    for (final e in kNumbersEmojiPool.toSet()) {
      count += tester.widgetList(find.text(e)).length;
    }
    expect(count, greaterThanOrEqualTo(1));
    expect(count, lessThanOrEqualTo(10));

    await tester.tap(find.text(toArabicDigits(count)).first);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('2 / 10'), findsOneWidget);
  });

  testWidgets('coloring board draws and clears without errors',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ColoringScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('لوحة التلوين'), findsOneWidget);

    // تراجع/مسح معطّلان قبل أي رسمة
    final undos = tester
        .widgetList<IconButton>(
            find.widgetWithIcon(IconButton, Icons.undo_rounded))
        .toList();
    expect(undos.single.onPressed, isNull);

    await tester.drag(
        find.byKey(const ValueKey('coloring-canvas')), const Offset(80, 40));
    await tester.pump();
    expect(tester.takeException(), isNull);

    final undosAfter = tester
        .widgetList<IconButton>(
            find.widgetWithIcon(IconButton, Icons.undo_rounded))
        .toList();
    expect(undosAfter.single.onPressed, isNotNull);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.undo_rounded));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('portal lists four activities and opens parents report',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ChildrenScreen()));
    await tester.pumpAndSettle();

    expect(find.text('تعلّم الحروف'), findsOneWidget);
    expect(find.text('لعبة الحروف'), findsOneWidget);
    expect(find.text('لعبة الأرقام'), findsOneWidget);
    expect(find.text('لوحة التلوين'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.assessment_outlined));
    await tester.pumpAndSettle();
    expect(find.text('تقرير الأهل'), findsOneWidget);
    expect(find.textContaining('أداء رائع'), findsOneWidget);
  });
}
