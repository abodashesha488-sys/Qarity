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
      // قائمة المواد الكاملة (كل الأقسام) معروضة، وآخرها «غير ذلك».
      expect(find.byKey(const ValueKey('edu-subject-غير ذلك')), findsOneWidget);
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
      expect(find.text('اختر مادة واحدة على الأقل'), findsOneWidget);
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

    testWidgets('السجل متعدد المراحل يظهر مرة واحدة مع رقائقه',
        (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());

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
      expect(find.byKey(const Key('filter-private-switch')), findsOneWidget);
    });

    testWidgets('تصفية الصفة: مدرسة فقط ثم الكل', (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());

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

      await tester.tap(find.byKey(const Key('filter-private-switch')));
      await tester.pumpAndSettle();
      expect(find.text('أ. منى'), findsOneWidget);
      expect(find.text('مدرسة النور'), findsNothing);
      expect(find.text('أ. سالم'), findsNothing);
    });

    testWidgets('تصفية المرحلة تطابق السجل متعدد المراحل', (tester) async {
      bigScreen(tester);
      await pumpScreen(tester, await seed());

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
      await tester.enterText(find.byType(TextField).first, 'فيزياء');
      await tester.pumpAndSettle();
      expect(find.text('أ. منى'), findsOneWidget);
      expect(find.text('أ. سالم'), findsNothing);
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
