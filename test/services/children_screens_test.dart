import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/children/children_screen.dart';
import 'package:qurity/features/children/letters_learn_screen.dart';

void main() {
  testWidgets('children portal lists both activities', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChildrenScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('تعلّم والعب معنا! 🎈'), findsOneWidget);
    expect(find.text('تعلّم الحروف'), findsOneWidget);
    expect(find.text('لعبة الحروف'), findsOneWidget);
  });

  testWidgets('learn screen shows 28 letters and opens a letter card',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: LearnLettersScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ألف'), findsOneWidget);
    expect(find.text('ياء'), findsOneWidget);

    await tester.tap(find.text('ب').first);
    await tester.pumpAndSettle();

    expect(find.text('حرف باء'), findsOneWidget);
    expect(find.textContaining('بَطَّة'), findsOneWidget);
    expect(find.text('بالوسط'), findsOneWidget);
  });
}
