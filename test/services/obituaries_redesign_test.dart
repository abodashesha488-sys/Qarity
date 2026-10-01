import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/obituary_card_assets.dart';
import 'package:qurity/features/obituaries/add.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/widgets/obituary_share_card.dart';

/// إعادة تصميم «سجل العزاء»: النوع يصرف تسميات القرابة، الأماكن ثلاثة،
/// المجموعات تسع تقبل أسماء متعددة، الخلفية مختارة من صور azaa، وبلا سؤال
/// عن العمر. السجلات القديمة تظل تُقرأ كما هي.
void main() {
  Relative relOf(String name, RelativeType type, {int order = 0}) =>
      Relative(id: 'id_$name', name: name, type: type, order: order);

  Obituary obitOf({
    String gender = kObituaryGenderMale,
    String age = '',
    String mosque = '',
    String burialLocation = '',
    List<Relative> relatives = const [],
  }) =>
      Obituary(
        id: 'o1',
        name: 'فلان',
        age: age,
        gender: gender,
        dateOfDeath: '2026-09-28',
        funeralDate: '2026-09-29',
        funeralLocation: 'مسجد القرية الكبير',
        burialLocation: burialLocation,
        condolenceLocation: 'منزل العائلة',
        mosque: mosque,
        cardBackground: 'azaa2',
        relatives: relatives,
      );

  ui.Image solidImage(int w, int h) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        ui.Paint()..color = const Color(0xFF123456));
    return recorder.endRecording().toImageSync(w, h);
  }

  Widget cardOf(Obituary o, {double width = 340}) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: ObituaryShareCard(
              obituary: o,
              background: solidImage(60, 80),
              photo: solidImage(40, 50),
              width: width,
            ),
          ),
        ),
      );

  group('تسميات القرابة المصروفة حسب النوع', () {
    test('التسع مجموعات لها مذكر ومؤنث مختلفان لكل عنوان', () {
      expect(kObituaryRelativeGroups, hasLength(9));
      for (final group in kObituaryRelativeGroups) {
        expect(group.isEditableGroup, isTrue, reason: group.name);
        expect(group.labelFor(kObituaryGenderMale), group.label);
        expect(group.labelFor(kObituaryGenderFemale), group.feminineLabel);
        expect(group.labelFor(kObituaryGenderFemale), isNot(group.label),
            reason: '${group.name} لا يتصرف');
        // السجل القديم بلا نوع يبقى بالتذكير.
        expect(group.labelFor(''), group.label);
      }
    });

    test('العناوين كما طلبها المستخدم، مع جد/جدة', () {
      const expected = {
        RelativeType.children: ('والد كلاً من', 'والدة كلاً من'),
        RelativeType.grandchildren: ('جد كلاً من', 'جدة كلاً من'),
        RelativeType.paternalUncles: ('عم كلاً من', 'عمّة كلاً من'),
        RelativeType.maternalUncles: ('خال كلاً من', 'خالة كلاً من'),
        RelativeType.paternalCousins: ('ابن عم كلاً من', 'ابنة عم كلاً من'),
        RelativeType.maternalCousins: ('ابن خال كلاً من', 'ابنة خال كلاً من'),
        RelativeType.inLaws: ('نسيب كلاً من', 'نسيبة كلاً من'),
        RelativeType.families: ('قريب عائلات', 'قريبة عائلات'),
        RelativeType.friends: ('صديق كلاً من', 'صديقة كلاً من'),
      };
      expect(expected.keys, hasLength(9));
      expected.forEach((group, pair) {
        expect(group.label, pair.$1);
        expect(group.feminineLabel, pair.$2);
      });
    });

    test('التسميات التراثية تُقرأ ولا تُعرض للإدخال', () {
      expect(kLegacyRelativeGroups.every((g) => !g.isEditableGroup), isTrue);
      expect(
        kObituaryRelativeGroups.length + kLegacyRelativeGroups.length,
        RelativeType.values.length,
      );
      expect(RelativeType.son.labelFor(kObituaryGenderFemale), 'أبناء');
    });

    test('relativeSections: الترتيب والتصرف وترتيب الأسماء كما أُدخلت', () {
      final o = obitOf(
        gender: kObituaryGenderFemale,
        relatives: [
          relOf('ثالثة', RelativeType.children, order: 2),
          relOf('أولى', RelativeType.children),
          relOf('ثانية', RelativeType.children, order: 1),
          relOf('عمها', RelativeType.paternalUncles),
          relOf('ابنها', RelativeType.son), // تراثية
          relOf('   ', RelativeType.friends), // فارغ لا يظهر
        ],
      );
      final sections = o.relativeSections;
      expect(
        sections.map((s) => s.label).toList(),
        ['والدة كلاً من', 'عمّة كلاً من', 'أبناء'],
      );
      expect(sections.first.names, ['أولى', 'ثانية', 'ثالثة']);
      expect(sections.first.namesLine, 'أولى، ثانية، ثالثة');
      expect(o.namesOf(RelativeType.friends), isEmpty);
      expect(o.hasRelatives, isTrue);
    });
  });

  group('الحقول الجديدة والتسامح مع السجل القديم', () {
    test('toJson يكتب النوع ومكان الدفن ومفتاح الخلفية دائمًا', () {
      final json = obitOf(gender: kObituaryGenderFemale).toJson();
      expect(json['gender'], 'امرأة');
      expect(json['burialLocation'], '');
      expect(json['cardBackground'], 'azaa2');
    });

    test('سجل قديم بلا الحقول الثلاثة يُقرأ ويحتفظ بعمره ومسجده', () {
      final o = Obituary.fromJson({
        'name': 'قديم',
        'age': '70',
        'dateOfDeath': '2025-01-01',
        'funeralLocation': 'المسجد القديم',
        'mosque': 'مسجد الحي',
        'relatives': [
          {'id': 'a', 'name': 'ولده', 'type': 'son', 'order': 0}
        ],
      }, 'legacy1');
      expect(o.gender, '');
      expect(o.isFemale, isFalse);
      expect(o.burialLocation, '');
      expect(o.cardBackground, '');
      expect(o.age, '70');
      expect(o.transitionPhrase, 'انتقل إلى رحمة الله تعالى');
      expect(o.relatives.single.type, RelativeType.son);
      expect(o.relativeSections.single.label, 'أبناء');
    });

    test('مفتاح غير معروف للخلفية يرجع للبطاقة الأولى', () {
      expect(obituaryCardAssetFor('azaa3'), 'assets/images/azaa 3.jpeg');
      expect(obituaryCardAssetFor(''), 'assets/images/azaa 1.jpeg');
      expect(obituaryCardAssetFor('azaa 9'), 'assets/images/azaa 1.jpeg');
      expect(obituaryCardAssetFor(null), 'assets/images/azaa 1.jpeg');
      expect(kObituaryCardBackgroundKeys, hasLength(4));
      expect(kObituaryCardBackgroundLabels, hasLength(4));
      expect(kObituaryDeceasedFallbackAsset, 'assets/images/azaa 0.jpeg');
    });

    test('صور azaa الخمس موجودة فعلًا في حزمة الأصول', () async {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/images/'));
      for (var i = 0; i <= 4; i++) {
        final path = 'assets/images/azaa $i.jpeg';
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(1000), reason: path);
      }
    });
  });

  group('بطاقة المشاركة', () {
    testWidgets('امرأة: الصرف المؤنث والأماكن الثلاثة والتوقيع',
        (tester) async {
      await tester.pumpWidget(cardOf(obitOf(
        gender: kObituaryGenderFemale,
        burialLocation: 'مقابر القرية',
        relatives: [
          relOf('ابنها الأكبر', RelativeType.children),
          relOf('عمتها', RelativeType.paternalUncles),
        ],
      )));
      expect(tester.takeException(), isNull);
      expect(find.text('انتقلت إلى رحمة الله تعالى'), findsOne);
      expect(find.text('قريبات المتوفاة'), findsOne);
      // عناوين المجموعات تُرسم داخل RichText (عنوان عريض + أسماء)، فلا
      // يطابقها find.text إلا بتفعيل findRichText.
      expect(find.textContaining('والدة كلاً من', findRichText: true),
          findsOne);
      expect(find.textContaining('عمّة كلاً من', findRichText: true), findsOne);
      expect(find.text('مكان صلاة الجنازة'), findsOne);
      expect(find.text('مكان الدفن'), findsOne);
      expect(find.text('مكان العزاء'), findsOne);
      expect(find.text('تصميم من خلال تطبيق قرية أبوديشيشة'), findsOne);
      expect(find.text('«إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ»'),
          findsOne);
      // لا عمر في السجل الحديث.
      expect(find.textContaining('العمر'), findsNothing);
    });

    testWidgets('رجل + سجل قديم بالعمر والمسجد والتسمية التراثية',
        (tester) async {
      await tester.pumpWidget(cardOf(obitOf(
        age: '70',
        mosque: 'مسجد الحي',
        relatives: [relOf('ولده الأكبر', RelativeType.son)],
      )));
      expect(tester.takeException(), isNull);
      expect(find.text('انتقل إلى رحمة الله تعالى'), findsOne);
      expect(find.text('أقارب المتوفى'), findsOne);
      expect(find.text('العمر 70'), findsOne);
      // السجل التراثي يحفظ مفتاحه القديم، وعنوانه يبقى كما هو بلا تصرف.
      expect(find.textContaining('أبناء: ولده الأكبر', findRichText: true),
          findsOne);
      // بلا مكان دفن محفوظ يظهر المسجد كما كان.
      expect(find.text('المسجد'), findsOne);
      expect(find.text('مكان الدفن'), findsNothing);
    });

    testWidgets('أسماء كثيرة وعناوين طويلة تلتف بلا فيضان', (tester) async {
      final relatives = <Relative>[];
      for (final group in kObituaryRelativeGroups) {
        for (var i = 0; i < 4; i++) {
          relatives
              .add(relOf('اسم طويل جدًا للمتوفى ${group.name}$i', group,
                  order: i));
        }
      }
      await tester.pumpWidget(cardOf(obitOf(
        gender: kObituaryGenderFemale,
        burialLocation: 'مقابر القرية القديمة بجانب المسجد الكبير',
        relatives: relatives,
      )));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('صديقة كلاً من', findRichText: true),
          findsOne);
    });
  });

  group('نموذج إضافة التعزية', () {
    Widget formScreen() => const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: AddObituaryScreen(),
          ),
        );

    // نافذة طويلة كي يبني `ListView` كل الأقسام (يُبني المرئي فقط)،
    // فيمكن اختبار المجموعات التسع دون تمرير.
    void useTallView(WidgetTester tester) {
      tester.view.physicalSize = const Size(1170, 12000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    // أقسام النموذج تدخل بحركات `flutter_animate`، وكل حركة تؤجّل
    // `Future.delayed`؛ بلا ضخّ زمن يبقى المؤجل معلّقًا وتفشل نهاية الاختبار.
    Future<void> openForm(WidgetTester tester) async {
      useTallView(tester);
      await tester.pumpWidget(formScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    }

    Future<void> tapAndWait(WidgetTester tester, Finder target) async {
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 400));
    }

    /// شريط الرسالة يبقى أربع ثوانٍ، و`ScaffoldMessenger` يطبّر التالي خلفه
    /// فلا يُرسم حتى ينقضي عمر السابق — والإقفال لا يُوثَق بضخّ زمن بل بإفراغ
    /// الطابور صراحةً، فتُقرأ كل رسالة لحظة ظهورها.
    Future<void> clearMessages(WidgetTester tester) async {
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .clearSnackBars();
      await tester.pump();
    }

    testWidgets('لا يسأل عن العمر، ويسأل النوع والأماكن الثلاثة',
        (tester) async {
      await openForm(tester);

      final src = File('lib/features/obituaries/add.dart').readAsStringSync();
      expect(src, isNot(contains('العمر')));
      expect(src, isNot(contains('_ageController')));
      expect(find.text('نوع المتوفى *'), findsOne);
      expect(find.byKey(const Key('obituary-gender-رجل')), findsOne);
      expect(find.byKey(const Key('obituary-gender-امرأة')), findsOne);
      expect(find.text('صلاة الجنازة'), findsOne);
      expect(find.text('مكان الدفن'), findsOne);
      expect(find.text('مكان العزاء'), findsOne);
      expect(find.text('خلفية بطاقة المشاركة'), findsOne);
      for (final key in kObituaryCardBackgroundKeys) {
        expect(find.byKey(Key('card-bg-$key')), findsOne);
      }
      // بلا نوع محدد بعد: المجموعات تنتظر الاختيار.
      expect(find.textContaining('اختر نوع المتوفى أولًا'), findsOne);
    });

    testWidgets('اختيار امرأة يصرف عناوين المجموعات التسع فورًا',
        (tester) async {
      await openForm(tester);

      await tapAndWait(tester, find.byKey(const Key('obituary-gender-رجل')));
      expect(find.text('أقارب المتوفى'), findsOne);
      for (final group in kObituaryRelativeGroups) {
        expect(find.byKey(Key('relative-name-${group.name}')), findsOne);
        expect(find.text(group.label), findsOne, reason: group.name);
        expect(find.text(group.feminineLabel!), findsNothing);
      }

      await tapAndWait(tester, find.byKey(const Key('obituary-gender-امرأة')));
      expect(find.text('قريبات المتوفاة'), findsOne);
      for (final group in kObituaryRelativeGroups) {
        expect(find.text(group.feminineLabel!), findsOne, reason: group.name);
        expect(find.text(group.label), findsNothing);
      }
    });

    testWidgets('إضافة أسماء متعددة ومنع المكرر', (tester) async {
      await openForm(tester);
      await tapAndWait(tester, find.byKey(const Key('obituary-gender-رجل')));

      final addBtn = find.byKey(const Key('relative-add-children'));
      final nameField = find.byKey(const Key('relative-name-children'));

      // اسم فارغ مرفوض بعبارة صريحة.
      await tapAndWait(tester, addBtn);
      expect(find.text('اكتب اسمًا أولاً'), findsOne);
      await clearMessages(tester);

      await tester.enterText(nameField, 'أحمد');
      await tapAndWait(tester, addBtn);
      await tester.enterText(nameField, 'محمود');
      await tapAndWait(tester, addBtn);
      await tester.enterText(nameField, 'علي');
      await tapAndWait(tester, addBtn);
      expect(find.byKey(const Key('relative-chip-children-أحمد')), findsOne);
      expect(find.byKey(const Key('relative-chip-children-محمود')), findsOne);

      await tester.enterText(nameField, 'أحمد');
      await tapAndWait(tester, addBtn);
      expect(find.text('«أحمد» مضاف بالفعل في «والد كلاً من»'), findsOne);
      await clearMessages(tester);

      // حذف اسم يعيد ترتيب الباقي: يبقى «محمود» و«علي» بمكانهما.
      // أيقونة الحذف في `InputChip` هي `Icons.clear` (افتراضي Material 3)،
      // لا `Icons.cancel` كما توهم الاختبار الأول.
      final deleteIcon = find.descendant(
        of: find.byKey(const Key('relative-chip-children-أحمد')),
        matching: find.byIcon(Icons.clear),
      );
      expect(deleteIcon, findsOne);
      await tapAndWait(tester, deleteIcon);
      expect(find.byKey(const Key('relative-chip-children-أحمد')), findsNothing);
      expect(find.byKey(const Key('relative-chip-children-محمود')), findsOne);
      expect(find.byKey(const Key('relative-chip-children-علي')), findsOne);
    });

    testWidgets('اختيار الخلفية يحددها بلا تجميد الباقي', (tester) async {
      await openForm(tester);

      double borderWidth(String key) {
        final container = tester.widgetList<AnimatedContainer>(
          find.descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(AnimatedContainer)),
        ).first;
        final border = (container.decoration! as BoxDecoration).border!;
        return border.top.width;
      }

      expect(borderWidth('card-bg-azaa1'), 2.4);
      expect(borderWidth('card-bg-azaa3'), 1.0);
      await tapAndWait(tester, find.byKey(const Key('card-bg-azaa3')));
      expect(borderWidth('card-bg-azaa3'), 2.4);
      expect(borderWidth('card-bg-azaa1'), 1.0);
    });

    testWidgets('نص زر الإرسال أبيض لا لون الثيم، فالخلفية بنية',
        (tester) async {
      await openForm(tester);

      final button = tester.widget<FilledButton>(
          find.ancestor(of: find.text('إرسال التعزية للمراجعة'),
              matching: find.byType(FilledButton)));
      final states = const <WidgetState>{};
      expect(button.style!.foregroundColor!.resolve(states), Colors.white);
      final background = button.style!.backgroundColor!.resolve(states)!;
      final label = tester.widget<Text>(find.descendant(
          of: find.byWidget(button), matching: find.byType(Text)));
      // اللون البني الأساسي نصًا عليه كان يجعل الزر غير مقروء.
      expect(label.style!.color, Colors.white);
      expect(
          Colors.white.computeLuminance() - background.computeLuminance(),
          greaterThan(0.4));
    });

    test('الإرسال يكتب age فارغًا ولا يكتب المسجد', () {
      final src = File('lib/features/obituaries/add.dart').readAsStringSync();
      expect(src, contains("age: '',"));
      expect(src, contains("'يجب اختيار نوع المتوفى (رجل أو امرأة)'"));
      expect(src, contains('cardBackground: _cardBackground'));
      expect(src, contains('burialLocation: _burialLocationController'));
      expect(src, isNot(contains('mosque:')));
    });
  });

  group('عقود المصدر', () {
    final add = File('lib/features/obituaries/add.dart').readAsStringSync();
    final detail =
        File('lib/features/obituaries/detail.dart').readAsStringSync();
    final list = File('lib/features/obituaries/list.dart').readAsStringSync();
    final share = File('lib/services/share_service.dart').readAsStringSync();
    final card =
        File('lib/widgets/obituary_share_card.dart').readAsStringSync();

    test('الزرّان المصابان بلون الثيم البني صارا أبيض صريحًا', () {
      expect(add, contains('إرسال التعزية للمراجعة'));
      expect(add, contains('foregroundColor: Colors.white'));
      expect(detail, contains('foregroundColor: done'));
      // لا نص زر يرث لون الثيم البني فوق خلفية بنية.
      for (final src in [add, detail]) {
        for (final match in RegExp(r'label: Text\([\s\S]{0,240}?\)(?=,)')
            .allMatches(src)) {
          expect(match.group(0), isNot(contains('textTheme')),
              reason: 'نص زر يرث لون الثيم');
        }
      }
    });

    test('الأماكن الثلاثة في التفاصيل، ولا «مكان الصلاة» القديمة', () {
      expect(detail, contains('صلاة الجنازة'));
      expect(detail, contains('مكان الدفن'));
      expect(detail, contains('مكان العزاء'));
      expect(detail, isNot(contains('مكان الصلاة')));
      expect(card, contains("label: 'مكان صلاة الجنازة'"));
      expect(card, contains("label: 'مكان الدفن'"));
    });

    test('azaa 0 هي الرجوع في المواضع الثلاثة', () {
      expect(list, contains('kObituaryDeceasedFallbackAsset'));
      expect(detail, contains('kObituaryDeceasedFallbackAsset'));
      expect(card, contains('_loadAsset(kObituaryDeceasedFallbackAsset)'));
      // نموذج الإضافة لا يرسم الرجوع بنفسه: المعاينة تمر عبر البطاقة.
      expect(add, contains('ObituaryShareCardPreview'));
      expect(
          File('lib/core/utils/obituary_card_assets.dart').readAsStringSync(),
          contains("kObituaryDeceasedFallbackAsset = 'assets/images/azaa 0"));
    });

    test('كارت السجل يعرض النوع بدل العمر ويستعمل الشارة', () {
      expect(list, contains('_GenderBadge(isFemale: obituary.isFemale)'));
      expect(list, contains('if (obituary.age.isNotEmpty)'));
    });

    test('التعازي مرقمة بترتيبها الزمني ومعها الإجمالي', () {
      expect(detail, contains("Key('condolence-number-"));
      expect(detail, contains('condolence-total'));
      expect(detail, contains('number: total - i'));
      expect(detail, contains('الإجمالي'));
    });

    test('البطاقة شجرة واجهات تُلتقط، لا رسم بالإحداثيات', () {
      expect(card, contains('class ObituaryShareCard extends StatelessWidget'));
      expect(card, contains('RenderRepaintBoundary'));
      expect(share, contains('ObituaryCardCapturer.capture'));
      expect(share, contains('ObituaryShareCard('));
      expect(share, contains('ObituaryCardAssets.loadBackground'));
      expect(share, contains('ObituaryCardAssets.loadPhoto'));
      expect(share, isNot(contains('generateMemorialCard(Obituary')));
    });

    test('الخلفية المختارة تُرى فعلًا: تبييض خفيف وإطار واضح', () {
      // السبب: بتبييض 0.88 وإطار 16 كانت الخلفيات الأربع تتطابق في الناتج،
      // فيصير اختيار «البطاقة الأولى/الثانية/الثالثة/الرابعة» بلا معنى.
      final wash = RegExp(
              r'Color\(0xFFFDF6E9\)\.withValues\(alpha: ([\d.]+)\)')
          .firstMatch(card);
      expect(wash, isNotNull, reason: 'تغيّرت طبقة التبييض فوق الخلفية');
      expect(double.parse(wash!.group(1)!), lessThanOrEqualTo(0.6),
          reason: 'التبييض الثقيل يمحو ملامح azaa المختارة');

      final frameStart = card.indexOf('_CoverImage(image: background)');
      final frame =
          RegExp(r'EdgeInsets\.all\((\d+)\)').firstMatch(card.substring(frameStart));
      expect(frame, isNotNull);
      expect(int.parse(frame!.group(1)!), greaterThanOrEqualTo(24),
          reason: 'إطار ضيّق لا يُظهر الرسم');

      // وضوح النص مسؤوليته اللوح الداخلي، لا حجب الخلفية.
      expect(card, contains('Colors.white.withValues(alpha: 0.95)'));
    });

    test('لوحة الإدارة تعرف الحقول الثلاثة وتسميها للعزاء وحده', () {
      final edit =
          File('lib/features/admin/admin_edit.dart').readAsStringSync();
      final adminDetail =
          File('lib/features/admin/admin_detail.dart').readAsStringSync();
      expect(edit, contains("_FieldSpec('gender', 'نوع المتوفى (رجل أو امرأة)')"));
      expect(edit, contains("_FieldSpec('burialLocation', 'مكان الدفن')"));
      expect(edit, contains('خلفية البطاقة (azaa1 / azaa2 / azaa3 / azaa4)'));
      expect(adminDetail, contains("widget.collection == 'obituaries'"));
      expect(adminDetail, contains("'cardBackground': 'خلفية بطاقة المشاركة'"));
      expect(adminDetail, contains('group.first.labelFor(gender)'));
    });
  });
}
