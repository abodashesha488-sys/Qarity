/// عقود موجة «كارت المحامي»: طلب المستخدم نصًا —
/// «اجعل كارت المحامي عبارة عن ثلاث أعمدة: الأول صورة المحامي والعمود الثاني
///  اسمه + عنوانه + تليفونه والعمود الثالث تخصصاته، اجعل حجم الكارت 5 أسطر
///  وحجم الصورة تملأ العمود الخاص بها مهما كان حجمها ولا يتم قص أي جزء من
///  الصورة مع مراعاة عرض الصورة بحيث تكون الصورة مقصوصة من الأعلى فقط».
///
/// الملف يثبّت أمرين: (أ) بصمة المصدر — ثلاثة أعمدة، ارتفاع محسوب بخمسة أسطر،
/// والاقتصاص من الأعلى وحده عبر `BoxFit.cover` مع `Alignment.bottomCenter`؛
/// و(ب) السلوك على مقاس الهاتف — الكارت لا يفيض ولا يتجاوز الارتفاع المحسوب،
/// محتلنًا 125dp للعامة و171dp مع شريط الحالة.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/legal/legal_advisor_screen.dart';
import 'package:qurity/models/legal_models.dart';

const String _kScreen = 'lib/features/legal/legal_advisor_screen.dart';

/// مقطع الكارت وحده: من `LawyerCard` حتى قبل `_LawyerAvatar` — لأن صورة
/// المحامي (`_LawyerPhoto`) تعيش داخل هذا المقطع، ولأن بقية الملف فيها
/// `FullFitImage(` في نموذج الإضافة وهو غير معني بالطلب.
String cardRegion(String src) {
  final from = src.indexOf('class LawyerCard extends StatelessWidget {');
  final to = src.indexOf('class _LawyerAvatar extends StatelessWidget {');
  expect(from, greaterThan(-1), reason: 'LawyerCard must exist');
  expect(to, greaterThan(from), reason: '_LawyerAvatar must follow LawyerCard');
  return src.substring(from, to);
}

int count(String haystack, String needle) =>
    haystack.split(needle).length - 1;

void main() {
  String src() => File(_kScreen).readAsStringSync();

  group('بصمة المصدر: الأعمدة الثلاثة والارتفاع المحسوب', () {
    test('الهندسة ثابتة: سطر 21dp والجسم خمسة أسطر والصورة 96dp', () {
      final s = src();
      expect(s, contains('const double _kLawyerLineHeight = 21.0;'));
      expect(s, contains('const double _kLawyerCardBody = _kLawyerLineHeight * 5;'));
      expect(s, contains('const double _kLawyerPhotoWidth = 96.0;'));
      expect(s, contains('const int _kLawyerSpecVisible = 4;'));
    });

    test('ارتفاع الكارت يُحسب من الجسم + الحشو (بلا ارتفاع صورة)', () {
      final region = cardRegion(src());
      expect(region, contains('height: _kLawyerCardBody +'));
      expect(region, contains('2 * _kLawyerCardPadding'));
      expect(region, contains('showStatus ? _kLawyerStatusRowHeight + _kLawyerStatusGap : 0'));
      // العرض لا يُترك لمحتوى: لا SizedBox(height: رقمي) حول الصورة.
      expect(region, isNot(contains('height: 9')));
    });

    test('ثلاثة أعمدة: صورة ثم flex 5 للبيان ثم flex 4 للتخصصات', () {
      final region = cardRegion(src());
      expect(region, contains('CrossAxisAlignment.stretch'));
      expect(region, contains('width: _kLawyerPhotoWidth'));
      expect(region, contains('flex: 5'));
      expect(region, contains('flex: 4'));
      expect(count(region, 'Expanded('), 3);
    });

    test('العمود الثاني: الاسم ثم العنوان ثم الهاتف (بلا سيرة ولا مواعيد)', () {
      final region = cardRegion(src());
      expect(region, contains('lawyer.name'));
      expect(region, contains('lawyer.office'));
      expect(region, contains('lawyer.phone'));
      expect(region, isNot(contains('lawyer.bio')));
      expect(region, isNot(contains('lawyer.workingHours')));
    });

    test('العمود الثالث capped بأربعة تخصصات + عدّاد الزائد', () {
      final region = cardRegion(src());
      expect(region, contains('specs.take(_kLawyerSpecVisible)'));
      expect(region, contains('if (extra > 0) _specChip('));
    });

    test('الصورة تملأ عمودها وتُقصّ من الأعلى فقط', () {
      final region = cardRegion(src());
      expect(region, contains('class _LawyerPhoto extends StatelessWidget {'));
      expect(region, contains('ClipRRect('));
      expect(region, contains('fit: BoxFit.cover'));
      expect(region, contains('alignment: Alignment.bottomCenter'));
      expect(region, contains('memCacheWidth: (width * 3).ceil()'));
      // لا بدائل مربّعة متجاهلة المقاس: avatar يأخذ عرض وارتفاع العمود.
      expect(count(region, '_LawyerAvatar(width: width, height: height)'), 3);
    });

    test('التمركز الرأسي بـExpanded وحده — بلا mainAxisAlignment زائدة', () {
      final region = cardRegion(src());
      expect(region, isNot(contains('mainAxisAlignment')));
    });

    test('الكارت لا يستعمل FullFitImage (فهو contain لا يقطع أبدًا)', () {
      expect(cardRegion(src()), isNot(contains('FullFitImage(')));
    });
  });

  group('السلوك على مقاس الهاتف (عرض الكارت 362dp)', () {
    Widget page(Widget child) => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(width: 362, child: child),
              ),
            ),
          ),
        );

    testWidgets('العامة: خمسة أسطر = 125dp بالضبط وبلا فيضان', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(page(LawyerCard(
        lawyer: const Lawyer(
          id: 'l1',
          name: 'محمود محمد جبر',
          phone: '01068587150',
          office: 'ابودشيشه عزبه ابوجبر',
          specializations: kLegalSpecializations,
          isApproved: true,
        ),
        onTap: () {},
      )));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Card)), const Size(362, 125));
    });

    testWidgets('أطول الاسم والعنوان لا يفيضان ولا يتجاوز 125dp', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(page(LawyerCard(
        lawyer: const Lawyer(
          id: 'l2',
          name: 'الأستاذ الدكتور محمد عبدالرحمن السيد الشناوي',
          phone: '01123456789',
          office: 'قرية أبوديشيشة — عزبة أبوجبر — بجوار المسجد الكبير',
          specializations: ['أحوال شخصية'],
        ),
        onTap: () {},
      )));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Card)), const Size(362, 125));
    });

    testWidgets('مع شريط الحالة: 171dp (125 + 46) وبلا فيضان', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(page(LawyerCard(
        lawyer: const Lawyer(
          id: 'l3',
          name: 'صبري عبدالباسط',
          phone: '01032231330',
          office: 'أبودشيشة',
          specializations: kLegalSpecializations,
        ),
        onTap: () {},
        showStatus: true,
        onEdit: () {},
        onDelete: () {},
      )));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Card)), const Size(362, 171));
    });

    testWidgets('بلا صورة ولا تخصصات: نفس الارتفاع وبلا استثناء', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(page(LawyerCard(
        lawyer: const Lawyer(id: 'l4', name: 'محامٍ'),
        onTap: () {},
      )));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Card)), const Size(362, 125));
    });
  });
}
