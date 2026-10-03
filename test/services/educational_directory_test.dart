import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/admin/admin_edit.dart';
import 'package:qurity/features/services/service_directory_screen.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/services/admin_service.dart';
import 'package:qurity/services/service_provider_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات إعادة تنسيق «خدمات تعليمية»: نموذج متعدد الاختيار + تصفية + شارات.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// النموذج وشاشة الفئة أطول من viewport الاختبار الافتراضي.
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tapKey(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openEduForm(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showModalBottomSheet<ServiceProvider>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ProviderFormSheet(
                  category: ServiceCategory.educational,
                  userId: 'u1',
                  userName: 'أحمد',
                ),
              ),
              child: const Text('افتح النموذج'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('افتح النموذج'));
    await tester.pumpAndSettle();
  }

  Future<void> fillBasics(WidgetTester tester,
      {String name = 'أ. منى', String label = 'اسم المدرّس'}) async {
    await tester.enterText(find.widgetWithText(TextField, label), name);
    await tester.enterText(find.widgetWithText(TextField, 'رقم الهاتف'), '0100');
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    final button = find.text('إرسال للمراجعة');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('نموذج إضافة الخدمات التعليمية', () {
    testWidgets('يعرض الصفة وأنواع التعليم والمراحل وكل المواد',
        (tester) async {
      bigScreen(tester);
      await openEduForm(tester);

      expect(find.byKey(const ValueKey('edu-kind-مدرس')), findsOneWidget);
      expect(find.byKey(const ValueKey('edu-kind-مدرسة')), findsOneWidget);
      for (final t in kEduTypes) {
        expect(find.byKey(ValueKey('edu-type-$t')), findsOneWidget);
      }
      for (final s in kEduStages) {
        expect(find.byKey(ValueKey('edu-stage-$s')), findsOneWidget);
      }
      expect(find.byKey(const Key('edu-subject-search')), findsOneWidget);
      expect(find.byKey(const Key('edu-private-toggle')), findsOneWidget);
      // «غير ذلك» لم تعد خيارًا: المادة بلا قائمة تُكتب يدويًا في الحقل المخصص.
      expect(find.byKey(const ValueKey('edu-subject-غير ذلك')), findsNothing);
      expect(find.byKey(const ValueKey('edu-subject-محفظ قرآن كريم')),
          findsOneWidget);
      expect(find.byKey(const Key('edu-subject-custom')), findsOneWidget);
      expect(find.byKey(const ValueKey('edu-subject-النحو والصرف')),
          findsOneWidget);
      // حقل التخصص الجامعي مخفي حتى تُختار مرحلة «جامعي».
      expect(find.byKey(const Key('edu-university-note')), findsNothing);
    });

    testWidgets('لا يرسل بلا نوع تعليم ولا مرحلة ولا مادة', (tester) async {
      bigScreen(tester);
      await openEduForm(tester);
      await fillBasics(tester);
      await send(tester);

      expect(find.text('اختر نوع التعليم (عام / أزهري / خاص)'), findsOneWidget);
      expect(find.text('إرسال للمراجعة'), findsOneWidget,
          reason: 'النموذج لا يزال مفتوحاً');

      await tapKey(tester, const ValueKey('edu-type-تعليم عام'));
      await send(tester);
      expect(find.text('اختر مرحلة تعليمية واحدة على الأقل'), findsOneWidget);

      await tapKey(tester, const ValueKey('edu-stage-ابتدائي'));
      await send(tester);
      expect(find.textContaining('اختر مادة واحدة على الأقل'), findsOneWidget);
    });

    testWidgets('التخصص المكتوب يدويًا يدخل قائمة المواد مرتّبًا بعد القوائم',
        (tester) async {
      bigScreen(tester);
      ServiceProvider? captured;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  captured = await showModalBottomSheet<ServiceProvider>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const ProviderFormSheet(
                      category: ServiceCategory.educational,
                      userId: 'u1',
                      userName: 'أحمد',
                    ),
                  );
                },
                child: const Text('افتح النموذج'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('افتح النموذج'));
      await tester.pumpAndSettle();

      await fillBasics(tester);
      await tapKey(tester, const ValueKey('edu-type-تعليم عام'));
      await tapKey(tester, const ValueKey('edu-stage-ثانوي'));
      // بلا أي اختيار من القوائم — فقط النص الحر.
      await tester.enterText(
          find.byKey(const Key('edu-subject-custom')), 'ميكروبيولوجي، جبر خطي');
      await send(tester);

      expect(captured, isNotNull);
      expect(captured!.subjects, ['ميكروبيولوجي', 'جبر خطي']);
      expect(captured!.toJson()['specialty'], 'ميكروبيولوجي، جبر خطي');
    });

    testWidgets('تنبيه المراجعة الأخير أحمر', (tester) async {
      bigScreen(tester);
      await openEduForm(tester);
      const red = Color(0xFFB71C1C);
      final text = tester.widget<Text>(find.text(
          'ستتم مراجعة الإضافة من الإدارة قبل نشرها في الدليل'));
      expect(text.style!.color, red);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    });

    testWidgets('اختيار متعدد للمرحلة والنوع والمادة + تدريس خاص',
        (tester) async {
      bigScreen(tester);
      ServiceProvider? captured;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  captured = await showModalBottomSheet<ServiceProvider>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const ProviderFormSheet(
                      category: ServiceCategory.educational,
                      userId: 'u1',
                      userName: 'أحمد',
                    ),
                  );
                },
                child: const Text('افتح النموذج'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('افتح النموذج'));
      await tester.pumpAndSettle();

      await fillBasics(tester);
      await tapKey(tester, const ValueKey('edu-type-خاص'));
      await tapKey(tester, const ValueKey('edu-type-تعليم عام'));
      await tapKey(tester, const ValueKey('edu-stage-ثانوي'));
      await tapKey(tester, const ValueKey('edu-stage-إعدادي'));
      await tapKey(tester, const ValueKey('edu-subject-الفيزياء'));
      await tapKey(tester, const ValueKey('edu-subject-الرياضيات'));
      await tapKey(tester, const Key('edu-private-toggle'));
      await send(tester);

      expect(captured, isNotNull);
      expect(captured!.providerKind, kEduKindTeacher);
      // الترتيب canonical من القوائم المصدرية مهما كان ترتيب النقر.
      expect(captured!.eduTypes, [kEduTypePublic, kEduTypePrivate]);
      expect(captured!.stages, [kEduStagePrep, kEduStageSecondary]);
      expect(captured!.subjects, ['الرياضيات', 'الفيزياء']);
      expect(captured!.offersPrivateTutoring, isTrue);
      expect(captured!.isApproved, isFalse);
      expect(captured!.toJson()['stage'], 'إعدادي، ثانوي');
    });

    testWidgets('المدرسة: اسم مختلف وبلا مفتاح تدريس خاص', (tester) async {
      bigScreen(tester);
      ServiceProvider? captured;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  captured = await showModalBottomSheet<ServiceProvider>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const ProviderFormSheet(
                      category: ServiceCategory.educational,
                      userId: 'u1',
                      userName: 'أحمد',
                    ),
                  );
                },
                child: const Text('افتح النموذج'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('افتح النموذج'));
      await tester.pumpAndSettle();

      await tapKey(tester, const ValueKey('edu-kind-مدرسة'));
      expect(find.widgetWithText(TextField, 'اسم المدرسة'), findsOneWidget);
      expect(find.byKey(const Key('edu-private-tile')), findsNothing);

      await fillBasics(tester, name: 'مدرسة النور', label: 'اسم المدرسة');
      await tapKey(tester, const ValueKey('edu-type-خاص'));
      await tapKey(tester, const ValueKey('edu-stage-ابتدائي'));
      await tapKey(tester, const ValueKey('edu-subject-الرياضيات'));
      await send(tester);

      expect(captured, isNotNull);
      expect(captured!.providerKind, kEduKindSchool);
      expect(captured!.isSchool, isTrue);
      expect(captured!.offersPrivateTutoring, isFalse);
    });

    testWidgets('التخصص الجامعي يظهر مع «جامعي» ويُمسح عند إلغائها',
        (tester) async {
      bigScreen(tester);
      ServiceProvider? captured;
      Future<void> openCapturing() async {
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    captured = await showModalBottomSheet<ServiceProvider>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const ProviderFormSheet(
                        category: ServiceCategory.educational,
                        userId: 'u1',
                        userName: 'أحمد',
                      ),
                    );
                  },
                  child: const Text('افتح النموذج'),
                ),
              ),
            ),
          ),
        ));
        await tester.tap(find.text('افتح النموذج'));
        await tester.pumpAndSettle();
      }

      await openCapturing();
      await tapKey(tester, const ValueKey('edu-stage-جامعي'));
      final note = find.byKey(const Key('edu-university-note'));
      expect(note, findsOneWidget);
      await tester.enterText(note, 'هندسة، حاسبات');
      await tester.pumpAndSettle();

      await fillBasics(tester);
      await tapKey(tester, const ValueKey('edu-type-تعليم عام'));
      await tapKey(tester, const ValueKey('edu-subject-البرمجة'));
      await send(tester);
      expect(captured!.universityNote, 'هندسة، حاسبات');
      expect(captured!.stages, [kEduStageUniversity]);

      // إلغاء «جامعي» يخفي الحقل ويسقط قيمته.
      await openCapturing();
      await tapKey(tester, const ValueKey('edu-stage-جامعي'));
      await tester.enterText(
          find.byKey(const Key('edu-university-note')), 'طب');
      await tester.pumpAndSettle();
      await tapKey(tester, const ValueKey('edu-stage-جامعي'));
      expect(find.byKey(const Key('edu-university-note')), findsNothing);
      await fillBasics(tester);
      await tapKey(tester, const ValueKey('edu-type-تعليم عام'));
      await tapKey(tester, const ValueKey('edu-stage-ثانوي'));
      await tapKey(tester, const ValueKey('edu-subject-الفيزياء'));
      await send(tester);
      expect(captured!.stages, [kEduStageSecondary]);
      expect(captured!.universityNote, isEmpty);
      expect(captured!.subjects, ['الفيزياء']);
    });

    testWidgets('بحث المواد يرشّح الرقائق المعروضة', (tester) async {
      bigScreen(tester);
      await openEduForm(tester);

      await tester.enterText(
          find.byKey(const Key('edu-subject-search')), 'فيز');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edu-subject-الفيزياء')), findsOneWidget);
      expect(find.byKey(const ValueKey('edu-subject-اللغة العربية')),
          findsNothing);

      await tester.enterText(find.byKey(const Key('edu-subject-search')), '');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edu-subject-اللغة العربية')),
          findsOneWidget);
    });

    testWidgets('دائرة الصورة: mal للمدرّس وfemal للمدرسة بلا رفع',
        (tester) async {
      bigScreen(tester);
      await openEduForm(tester);

      String circleAsset() {
        final found = find.descendant(
            of: find.byType(CircleAvatar), matching: find.byType(Image));
        expect(found, findsOneWidget, reason: 'الصورة الافتراضية تملأ الدائرة');
        final p = tester.widget<Image>(found).image;
        return p is ResizeImage
            ? (p.imageProvider as AssetImage).assetName
            : (p as AssetImage).assetName;
      }

      expect(circleAsset(), 'assets/images/mal.jpg');
      await tapKey(tester, const ValueKey('edu-kind-مدرسة'));
      expect(circleAsset(), 'assets/images/femal.jpg');
    });

    testWidgets('نموذج غير تعليمي: دائرته أيقونة شخص بلا صورة صفة',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showModalBottomSheet<ServiceProvider>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const ProviderFormSheet(
                    category: ServiceCategory.technicians,
                    userId: 'u1',
                    userName: 'أحمد',
                  ),
                ),
                child: const Text('افتح النموذج'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('افتح النموذج'));
      await tester.pumpAndSettle();

      expect(
          find.descendant(
              of: find.byType(CircleAvatar), matching: find.byType(Image)),
          findsNothing);
      expect(
          find.descendant(
              of: find.byType(CircleAvatar),
              matching: find.byIcon(Icons.person_rounded)),
          findsOneWidget);
    });
  });

  group('عرض وتصفية صفحة الخدمات التعليمية', () {
    Future<FakeFirebaseFirestore> seed() async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('service_providers').add({
        'category': 'educational',
        'name': 'أ. منى',
        'phone': '0100',
        'isApproved': true,
        'providerKind': 'مدرس',
        'eduTypes': ['تعليم عام'],
        'stages': ['ثانوي'],
        'subjects': ['الفيزياء'],
        'offersPrivateTutoring': true,
      });
      await fake.collection('service_providers').add({
        'category': 'educational',
        'name': 'مدرسة النور',
        'phone': '0101',
        'isApproved': true,
        'providerKind': 'مدرسة',
        'eduTypes': ['خاص'],
        'stages': ['ابتدائي', 'إعدادي'],
        'subjects': ['الرياضيات'],
        'offersPrivateTutoring': false,
      });
      // سجل قديم: مادة ومرحلة مفردتان بلا قوائم.
      await fake.collection('service_providers').add({
        'category': 'educational',
        'name': 'أ. سالم',
        'phone': '0102',
        'isApproved': true,
        'specialty': 'الرياضيات',
        'stage': 'الصف الأول الثانوي',
      });
      return fake;
    }

    Future<void> pumpScreen(WidgetTester tester, FakeFirebaseFirestore fake) async {
      await tester.pumpWidget(MaterialApp(
        home: ProviderCategoryScreen(
          category: ServiceCategory.educational,
          service: ServiceProviderService(fake),
        ),
      ));
      await tester.pumpAndSettle();
    }

    /// كارت البحث والمرشّحات مطويّ افتراضيًا لتوفير مساحة العرض؛
    /// يفتحه الاختبار قبل اللمس على أي مرشّح.
    Future<void> openFilters(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('filters-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('provider-search')), findsOneWidget);
    }

    testWidgets('السجل متعدد المراحل يظهر مرة واحدة مع رقائقه',
        (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());
      await openFilters(tester);

      expect(find.text('أ. منى'), findsOneWidget);
      expect(find.text('مدرسة النور'), findsOneWidget,
          reason: 'لا تكرار رغم خدمتها لمرحلتين');
      expect(find.text('أ. سالم'), findsOneWidget);
      // رقائق المدرسة: المرحلتان + نوع التعليم + الصفة.
      expect(find.text('ابتدائي'), findsOneWidget);
      expect(find.text('إعدادي'), findsOneWidget);
      expect(find.text('خاص'), findsOneWidget);
      expect(find.text('مدرسة'), findsWidgets); // شارة البطاقة + شريحة التصفية
      // شارة التدريس الخاص: على بطاقة واحدة + تسمية مفتاح التصفية.
      expect(find.text('تدريس خاص'), findsNWidgets(2));
      // السجل القديم تُرجم إلى «ثانوي».
      expect(find.text('ثانوي'), findsNWidgets(2));
      expect(find.byKey(const Key('filter-kind-مدرسة')), findsOneWidget);
      expect(find.byKey(const Key('filter-stage')), findsOneWidget);
      expect(find.byKey(const Key('filter-edu-type')), findsOneWidget);
      expect(find.byKey(const Key('filter-private-only')), findsOneWidget);
      expect(find.byKey(const Key('filter-subject')), findsOneWidget);
    });

    testWidgets('تصفية الصفة: مدرسة فقط ثم الكل', (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());
      await openFilters(tester);

      await tester.tap(find.byKey(const Key('filter-kind-مدرسة')));
      await tester.pumpAndSettle();
      expect(find.text('مدرسة النور'), findsOneWidget);
      expect(find.text('أ. منى'), findsNothing);
      expect(find.text('أ. سالم'), findsNothing);

      await tester.tap(find.byKey(const Key('filter-kind-all')));
      await tester.pumpAndSettle();
      expect(find.text('أ. منى'), findsOneWidget);
      expect(find.text('أ. سالم'), findsOneWidget);
    });

    testWidgets('مفتاح «تدريس خاص فقط»', (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());
      await openFilters(tester);

      await tester.tap(find.byKey(const Key('filter-private-only')));
      await tester.pumpAndSettle();
      expect(find.text('أ. منى'), findsOneWidget);
      expect(find.text('مدرسة النور'), findsNothing);
      expect(find.text('أ. سالم'), findsNothing);
    });

    testWidgets('مرشّح «المواد التعليمية» يطابق القوائم والمرآة القديمة',
        (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());
      await openFilters(tester);

      await tester.tap(find.byKey(const Key('filter-subject')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الرياضيات').last);
      await tester.pumpAndSettle();

      // مدرسة النور: subjects=['الرياضيات'] · أ. سالم: specialty مرآة قديمة.
      expect(find.text('مدرسة النور'), findsOneWidget);
      expect(find.text('أ. سالم'), findsOneWidget);
      expect(find.text('أ. منى'), findsNothing);
    });

    testWidgets('بطاقة تعليمية: صورة بثلث العرض واتصال أخضر ومشاركة أزرق',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = await seed();
      await pumpScreen(tester, fake);

      final ids = (await fake.collection('service_providers').get())
          .docs
          .map((d) => d.id)
          .toList();
      Color? bg(FilledButton b) => b.style?.backgroundColor?.resolve(const {});
      final buttons =
          tester.widgetList<FilledButton>(find.byType(FilledButton)).toList();
      expect(
          buttons.where((b) => bg(b) == kCallButtonColor).length, ids.length,
          reason: 'زر اتصال أخضر لكل بطاقة');
      expect(
          buttons.where((b) => bg(b) == kShareButtonColor).length, ids.length,
          reason: 'زر مشاركة أزرق لكل بطاقة');

      final image = find.byKey(ValueKey('card-image-${ids.first}'));
      final card = find.ancestor(of: image, matching: find.byType(InkWell));
      final ratio = tester.getSize(image).width / tester.getSize(card).width;
      expect(ratio, inInclusiveRange(0.27, 0.37));
    });

    testWidgets('بطاقة بلا صورة مرفوعة: صورة الصفة الافتراضية بدل حرف الاسم',
        (tester) async {
      bigScreen(tester);
      final fake = await seed();
      await pumpScreen(tester, fake);

      // السجلات الثلاثة مزروعة بلا photoUrl.
      final docs = (await fake.collection('service_providers').get()).docs;
      final byName = {for (final d in docs) d.data()['name'] as String: d.id};

      String cardAsset(String label, String id) {
        final found = find.descendant(
            of: find.byKey(ValueKey('card-image-$id')),
            matching: find.byType(Image));
        expect(found, findsOneWidget, reason: '$label تعرض صورة، لا حرفًا');
        final p = tester.widget<Image>(found).image;
        return p is ResizeImage
            ? (p.imageProvider as AssetImage).assetName
            : (p as AssetImage).assetName;
      }

      expect(cardAsset('المدرّس', byName['أ. منى']!), 'assets/images/mal.jpg');
      expect(cardAsset('المدرسة', byName['مدرسة النور']!),
          'assets/images/femal.jpg');
      // السجل القديم بلا providerKind ⇒ يُعامل كمدرّس.
      expect(cardAsset('السجل القديم', byName['أ. سالم']!),
          'assets/images/mal.jpg');
    });

    testWidgets('تصفية المرحلة تطابق السجل متعدد المراحل', (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());
      await openFilters(tester);

      await tester.tap(find.byKey(const Key('filter-stage')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إعدادي').last);
      await tester.pumpAndSettle();

      expect(find.text('مدرسة النور'), findsOneWidget);
      expect(find.text('أ. منى'), findsNothing);
      expect(find.text('أ. سالم'), findsNothing);
    });

    testWidgets('تصفية نوع التعليم + البحث في الحقول الجديدة',
        (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());
      await openFilters(tester);

      await tester.tap(find.byKey(const Key('filter-edu-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعليم عام').last);
      await tester.pumpAndSettle();
      expect(find.text('أ. منى'), findsOneWidget);
      expect(find.text('أ. سالم'), findsOneWidget,
          reason: 'السجل القديم استُنتج نوعه «تعليم عام»');
      expect(find.text('مدرسة النور'), findsNothing);

      await tester.tap(find.byKey(const Key('filter-kind-all')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('provider-search')), 'فيزياء');
      await tester.pumpAndSettle();
      expect(find.text('أ. منى'), findsOneWidget);
      expect(find.text('أ. سالم'), findsNothing);
    });

    testWidgets(
        'كارت «بحث وتصفية» مطويّ أول الفتح: السجلات ظاهرة والمرشّحات مخفية',
        (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());

      expect(find.byKey(const Key('provider-search')), findsNothing);
      expect(find.byKey(const Key('filter-kind-مدرسة')), findsNothing);
      expect(find.text('أ. منى'), findsOneWidget,
          reason: 'الطيّ للمرشّحات لا للمحتوى');

      await tester.tap(find.byKey(const Key('filters-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('provider-search')), findsOneWidget);
      expect(find.byKey(const Key('filter-stage')), findsOneWidget);

      await tester.tap(find.byKey(const Key('filters-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('provider-search')), findsNothing);
    });

    testWidgets('المرشّح المفعّل لا يختفي بالطيّ: شارة العدد + الملخص + المسح',
        (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());
      await openFilters(tester);

      await tester.tap(find.byKey(const Key('filter-private-only')));
      await tester.pumpAndSettle();
      expect(find.text('مدرسة النور'), findsNothing);

      await tester.tap(find.byKey(const Key('filters-toggle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filters-count')), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('filters-count')),
              matching: find.text('1')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('filters-toggle')),
              matching: find.text('تدريس خاص')),
          findsOneWidget,
          reason: 'الملخص يلصق الكارت مطويًا');
      expect(find.text('أ. منى'), findsOneWidget,
          reason: 'التصفية سارية والكارت مطويّ');

      await tester.tap(find.byKey(const Key('filters-clear')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filters-count')), findsNothing);
      expect(find.text('مدرسة النور'), findsOneWidget);
    });
  });

  group('تعديل الأدمن للسجل التعليمي', () {
    const eduItem = <String, dynamic>{
      'category': 'educational',
      'name': 'أ. منى',
      'providerKind': kEduKindTeacher,
      'eduTypes': [kEduTypePublic, kEduTypePrivate],
      'stages': [kEduStagePrep, kEduStageSecondary],
      'subjects': ['الرياضيات'],
      'universityNote': 'هندسة',
      'offersPrivateTutoring': true,
      'phone': '0100',
    };

    Future<void> openEdit(WidgetTester tester, Map<String, dynamic> item,
        {AdminService? service}) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => AdminEditScreen(
                              collection: 'service_providers',
                              docId: 'p1',
                              item: item,
                              service: service,
                            ))),
                child: const Text('افتح التعديل'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('افتح التعديل'));
      await tester.pumpAndSettle();
    }

    Finder field(String label) =>
        find.widgetWithText(TextFormField, label);

    testWidgets('حقل الصورة في محرر المستند يحمّل الصورة المخزنة', (tester) async {
      bigScreen(tester);
      await openEdit(tester, {
        ...eduItem,
        'photoUrl': 'https://i.ibb.co/abc/upload.jpg',
      });

      // الصورة الواحدة: محرر صور بمصغّرة واحدة قابلة للحذف، لا حقل نصّ.
      expect(find.byKey(const Key('img-editor-photoUrl')), findsOneWidget);
      expect(find.byKey(const Key('img-delete-photoUrl-0')), findsOneWidget);
      expect(find.text('لا صورة — ارفع من الجهاز أو الصق رابطًا'), findsNothing);
    });

    testWidgets('سجل بلا صورة: المحرر ظاهر ولصق الرابط يُرفده بدل حذف السجل',
        (tester) async {
      bigScreen(tester);
      await openEdit(tester, eduItem);

      expect(find.byKey(const Key('img-editor-photoUrl')), findsOneWidget);
      expect(find.byKey(const Key('img-delete-photoUrl-0')), findsNothing);
      expect(find.text('لا صورة — ارفع من الجهاز أو الصق رابطًا'), findsOneWidget);

      await tester.tap(find.byKey(const Key('img-paste-photoUrl')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('img-link-photoUrl')), 'i-not-a-url');
      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();
      expect(find.text('الرابط يجب أن يبدأ بـ http أو https'), findsOneWidget,
          reason: 'رابط خام مقبول صامتًا هو نفس خطأ ضياع الصورة');

      await tester.tap(find.byKey(const Key('img-paste-photoUrl')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('img-link-photoUrl')),
          'https://i.ibb.co/repair/x.jpg');
      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('img-delete-photoUrl-0')), findsOneWidget);
    });

    testWidgets('حقول التعليمية: قوائم نصية وبلا حقل الحرفة', (tester) async {
      bigScreen(tester);
      await openEdit(tester, eduItem);

      expect(field('الصفة (مدرس / مدرسة)'), findsOneWidget);
      expect(
          tester
              .widget<TextFormField>(
                  field('أنواع التعليم (تعليم عام، أزهري، خاص)'))
              .controller!
              .text,
          'تعليم عام، خاص');
      expect(
          tester
              .widget<TextFormField>(field('المواد الدراسية'))
              .controller!
              .text,
          'الرياضيات');
      expect(field('التخصص الجامعي'), findsOneWidget);
      expect(find.text('تدريس خاص (دروس خصوصية)'), findsOneWidget);
      // حقل الحرفة للسجلات غير التعليمية لا يظهر هنا.
      expect(field('الحرفة / الخدمة'), findsNothing);
      expect(find.text('افصل بين القيم بفاصلة'), findsWidgets);
    });

    testWidgets('سجل غير تعليمي: حقل الحرفة وحده وبلا حقول القوائم',
        (tester) async {
      bigScreen(tester);
      await openEdit(tester, const {
        'category': 'technicians',
        'name': 'ورشة أحمد',
        'specialty': 'نجارة',
        'phone': '0100',
      });

      expect(field('الحرفة / الخدمة'), findsOneWidget);
      expect(field('المواد الدراسية'), findsNothing);
      expect(field('الصفة (مدرس / مدرسة)'), findsNothing);
      expect(find.text('تدريس خاص (دروس خصوصية)'), findsNothing);
    });

    testWidgets('الحفظ يقسّم القوائم ويعيد مزامنة المرآتين', (tester) async {
      bigScreen(tester);
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('service_providers')
          .doc('p1')
          .set(Map<String, dynamic>.from(eduItem));
      await openEdit(tester, eduItem,
          service: AdminService.withFirestore(fake));

      // فاصلة عربية وإنجليزية معاً + فراغات زائدة.
      await tester.enterText(
          field('المواد الدراسية'), ' الرياضيات،الفيزياء, الكيمياء ');
      await tester.ensureVisible(find.text('حفظ التعديلات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ التعديلات'));
      await tester.pumpAndSettle();

      expect(find.text('تم الحفظ بنجاح'), findsOneWidget);
      final data =
          (await fake.collection('service_providers').doc('p1').get()).data()!;
      expect(data['subjects'], ['الرياضيات', 'الفيزياء', 'الكيمياء']);
      expect(data['stages'], [kEduStagePrep, kEduStageSecondary]);
      // المرآتان اللتان تقرأهما النسخ المثبّتة القديمة.
      expect(data['specialty'], 'الرياضيات، الفيزياء، الكيمياء');
      expect(data['stage'], 'إعدادي، ثانوي');
      expect(data['offersPrivateTutoring'], true);
      expect(data['universityNote'], 'هندسة');
    });

    testWidgets('حفظ سجل غير تعليمي لا يكتب مفاتيح التعليم', (tester) async {
      bigScreen(tester);
      final fake = FakeFirebaseFirestore();
      const item = <String, dynamic>{
        'category': 'technicians',
        'name': 'ورشة أحمد',
        'specialty': 'نجارة',
        'phone': '0100',
      };
      await fake
          .collection('service_providers')
          .doc('p1')
          .set(Map<String, dynamic>.from(item));
      await openEdit(tester, item, service: AdminService.withFirestore(fake));

      await tester.enterText(field('الحرفة / الخدمة'), 'نجارة، أثاث');
      await tester.ensureVisible(find.text('حفظ التعديلات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ التعديلات'));
      await tester.pumpAndSettle();

      final data =
          (await fake.collection('service_providers').doc('p1').get()).data()!;
      expect(data['specialty'], 'نجارة، أثاث');
      expect(data.containsKey('subjects'), isFalse);
      expect(data.containsKey('stages'), isFalse);
      expect(data.containsKey('providerKind'), isFalse);
    });
  });
}
