import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/children/children_lessons.dart';
import 'package:qurity/features/children/children_screen.dart';
import 'package:qurity/features/children/coloring_screen.dart';
import 'package:qurity/features/children/lessons_screen.dart';
import 'package:qurity/features/children/letters_game_screen.dart';
import 'package:qurity/features/children/letters_learn_screen.dart';
import 'package:qurity/features/children/numbers_game_screen.dart';
import 'package:qurity/features/children/numbers_learn_screen.dart';

/// ✅ ركن الأطفال يعمل بلا اتصال: البيانات ثابتة في الكود، وصور الحروف
/// assets محلية، والإنجازات في SharedPreferences، والنطق TTS على الجهاز.
/// هذه الاختبارات تقيم كل الأقسام التسعة بدون أي تهيئة Firebase أو شبكة،
/// فأي استيراد خفي لخدمة بعيدةُسيفشل هنا فورًا.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  Future<void> open(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(wrap(child));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('البوابة تفتح بلا اتصال', (tester) async {
    await open(tester, const ChildrenScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('ركن الأطفال'), findsOneWidget);
  });

  testWidgets('تعلّم الحروف يرسم حروفه المحلية بلا شبكة', (tester) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await open(tester, const LearnLettersScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('تعلّم الحروف'), findsOneWidget);
    // أول حرف (ألف بهمزة) وآخر حرف من الجدول المحلي kArabicLetters
    expect(find.text('أ'), findsWidgets);
    expect(find.text('ي'), findsWidgets);
  });

  testWidgets('تعلّم الأرقام يرسم لوح الأرقام بلا شبكة', (tester) async {
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await open(tester, const LearnNumbersScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('تعلّم الأرقام'), findsOneWidget);
    expect(find.text('خمسة'), findsWidgets);
  });

  testWidgets('لعبة الحروف تعمل بلا شبكة', (tester) async {
    await open(tester, LettersGameScreen(random: Random(1)));
    expect(tester.takeException(), isNull);
    expect(find.text('لعبة الحروف'), findsOneWidget);
  });

  testWidgets('لعبة الأرقام تعمل بلا شبكة', (tester) async {
    await open(tester, NumbersGameScreen(random: Random(2)));
    expect(tester.takeException(), isNull);
    expect(find.text('لعبة الأرقام'), findsOneWidget);
    expect(find.text('كَم عدد الأشياء؟'), findsOneWidget);
  });

  testWidgets('لوحة التلوين تعمل بلا شبكة', (tester) async {
    await open(tester, const ColoringScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('لوحة التلوين'), findsOneWidget);
  });

  testWidgets('الأقسام التعليمية الأربعة تعمل بلا شبكة', (tester) async {
    const sections = [
      ('تعلّم الوضوء', 'wudu', kWuduLessons),
      ('تعلّم الصلاة', 'salah', kSalahLessons),
      ('قصص الأنبياء', 'prophets', kProphetStories),
      ('آداب وسلوكيات', 'manners', kMannersLessons),
    ];
    for (final (title, folder, lessons) in sections) {
      await open(
        tester,
        LessonsScreen(
          title: title,
          subtitle: title,
          accent: const Color(0xFF6F4E37),
          imageFolder: folder,
          lessons: lessons,
        ),
      );
      expect(tester.takeException(), isNull, reason: title);
      // العنوان في الـ AppBar وفي ترويسة القسم
      expect(find.text(title), findsWidgets, reason: title);
      // عنوان أول درس محلي يظهر في القائمة
      expect(find.text(lessons.first.title), findsWidgets, reason: title);
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      await tester.pumpAndSettle();
    }
  });
}
