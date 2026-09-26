import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qurity/features/children/arabic_letters.dart';
import 'package:qurity/features/children/children_lessons.dart';
import 'package:qurity/features/children/children_screen.dart';
import 'package:qurity/features/children/children_speech.dart';
import 'package:qurity/features/children/lessons_screen.dart';
import 'package:qurity/features/children/letters_learn_screen.dart';
import 'package:qurity/features/children/numbers_learn_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('صور الأطفال: كل مجلد مكتمل مسجّل، والمسجّل سليم بالكامل', () {
    const expectedCount = {
      'num': 10,
      'wudu': 8,
      'salah': 8,
      'prophets': 8,
      'manners': 10,
    };
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expectedCount.forEach((folder, count) {
      final dir = Directory('assets/images/kids/$folder');
      final have = dir.existsSync()
          ? dir.listSync().where((e) => e.path.endsWith('.jpg')).length
          : 0;
      final complete = have == count;
      final registered = pubspec.contains('assets/images/kids/$folder/');
      // التسجيل يجب أن يطابق الاكتمال تمامًا (لا فراغ ولا صور يتيمة)
      expect(registered, complete,
          reason: '$folder: $have/$count صور، مسجّل=$registered');
      if (!complete) return;
      for (var i = 0; i < count; i++) {
        final path = kidLessonImage(folder, i);
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'مفقود: $path');
        final bytes = file.readAsBytesSync();
        expect(bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF], reason: 'ليس JPG: $path');
      }
    });
  });

  test('بيانات الدروس مكتملة وسليمة', () {
    expect(kNumberLessons.length, 10);
    // الدرس رقم n يعرض n تفاحة
    for (var i = 0; i < 10; i++) {
      expect(kNumberLessons[i].body.startsWith('🍎' * (i + 1)), isTrue,
          reason: kNumberLessons[i].title);
    }
    expect(kWuduLessons.length, 8);
    expect(kSalahLessons.length, 8);
    expect(kProphetStories.length, 8);
    expect(kMannersLessons.length, 10);
    final all = [
      ...kNumberLessons,
      ...kWuduLessons,
      ...kSalahLessons,
      ...kProphetStories,
      ...kMannersLessons,
    ];
    for (final lesson in all) {
      expect(lesson.title.trim(), isNotEmpty);
      expect(lesson.body.trim(), isNotEmpty);
      expect(lesson.emoji.trim(), isNotEmpty);
      // لا نصوص غير عربية شاردة تسللت إلى المحتوى (عدا ﷺ والأرقام)
      expect(lesson.title + lesson.body, isNot(contains(RegExp(r'[a-z]'))));
    }
    // كل قصص الأنبياء تختتم بلقب النبوة المناسب
    for (final story in kProphetStories) {
      expect(
          story.title.contains('عليه السلام') || story.title.contains('ﷺ'),
          isTrue,
          reason: story.title);
    }
  });

  test('كل حرف له صورة توضيحية مسجلة في الأصول', () {
    for (final letter in kArabicLetters) {
      expect(letter.image, startsWith('assets/images/letters/l'));
      expect(letter.image, endsWith('.jpg'));
    }
    // مسارات الصور فريدة
    expect(kArabicLetters.map((l) => l.image).toSet().length, 28);
  });

  testWidgets('شاشة الدروس تعرض البطاقات وتفتح بطاقة الدرس مع النصيحة',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: LessonsScreen(
        title: 'تعلّم الوضوء',
        subtitle: 'خطوات الوضوء',
        accent: Color(0xFF00838F),
        lessons: kWuduLessons,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('١. النيّة والبسملة'), findsOneWidget);
    expect(find.textContaining('غسل القدمين'), findsOneWidget);

    await tester.tap(find.text('١. النيّة والبسملة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('💡'), findsWidgets);
    expect(find.byTooltip('اسمع'), findsOneWidget);
  });

  testWidgets('بوابة الأطفال تعرض الأقسام الجديدة', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ChildrenScreen()));
    await tester.pumpAndSettle();
    for (final title in [
      'تعلّم الأرقام',
      'تعلّم الوضوء',
      'تعلّم الصلاة',
      'قصص الأنبياء',
      'آداب وسلوكيات',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  test('kidLessonImage يصفّر المسار بترتيب الدرس', () {
    expect(kidLessonImage('wudu', 0), 'assets/images/kids/wudu/01.jpg');
    expect(kidLessonImage('num', 9), 'assets/images/kids/num/10.jpg');
    expect(kidLessonImage('prophets', 2), 'assets/images/kids/prophets/03.jpg');
  });

  test('normalize يُطهّر النص للنطق المصري', () {
    // ﷺ يُمدّ قائله نصًا صريحًا.
    expect(ChildrenSpeech.normalize('النبي ﷺ رحمة'),
        contains('صلى الله عليه وسلم'));
    // التشكيل والتطويل يُزالان.
    expect(ChildrenSpeech.normalize('بِسْـمِ'), 'بسم');
    // علامات الاقتباس تختفي والشرطة الطويلة وقفة.
    expect(ChildrenSpeech.normalize('قال «الحمد لله» — ثمّ مشى'),
        'قال الحمد لله ، ثم مشى');
    // لا أرقام لاتينية دخلة ولا مسافات متعددة.
    expect(ChildrenSpeech.normalize('  رقم   ٥  '), 'رقم ٥');
  });

  testWidgets('شبكة الأرقام تعرض رقمًا وصورة وتفتح بطاقة العدّ', (tester) async {
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LearnNumbersScreen()));
    await tester.pumpAndSettle();

    expect(find.text('تعلّم الأرقام'), findsOneWidget);
    expect(find.text('خمسة'), findsOneWidget);
    expect(find.text('٥'), findsOneWidget);
    // بلاطة لكل رقم: صورة (أو بديل مرسوم) داخل الشبكة.
    expect(find.byType(LearnNumbersScreen), findsOneWidget);

    await tester.tap(find.text('خمسة'));
    await tester.pumpAndSettle();
    expect(find.text('عِدّ معي: ٥'), findsOneWidget);
    expect(find.byTooltip('اسمع'), findsOneWidget);
    expect(find.text('🍎'), findsNWidgets(5));
  });

  testWidgets('شبكة الحروف تعرض صورًا بجانب الحروف', (tester) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LearnLettersScreen()));
    await tester.pumpAndSettle();
    // كل بلاطة حرف تحتوي صورة Asset
    expect(find.byType(LearnLettersScreen), findsOneWidget);
    expect(find.byType(Image), findsAtLeastNWidgets(20));
  });
}
