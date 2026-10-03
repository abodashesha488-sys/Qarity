import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qurity/services/owner_content_service.dart';
import 'package:qurity/widgets/owner_actions.dart';

/// البند ٨ والبند ٩: المالك يعدّل ويحذف في أي وقت — التعديل يعود للأدمن والحذف
/// فوري — لكل مجموعة يقبل الإنشاء من مستخدم، وبالعنصر الموحّد `OwnerActions`.

const List<String> kOwnerEditableCollections = <String>[
  'news',
  'market_products',
  'shops',
  'obituaries',
  'occasions',
  'forum_posts',
  'phone_directory',
  'service_providers',
  'lost_items',
  'village_clinics',
  'pharmacies',
  'medical_labs',
  'optical_shops',
  'blood_requests',
  'blood_donors',
  'village_ads',
  'lawyers',
  'legal_consultations',
];

/// المجموعات الثلاث بلا شاشة تفاصيل — أزرارها على الكارت/الحوار نفسه.
const List<String> kOwnerCardCollections = <String>[
  'blood_donors',
  'blood_requests',
  'phone_directory',
  'legal_consultations',
];

String _src(String path) => File(path).readAsStringSync();

/// مقطع كتلة مجموعة في `firestore.rules`.
String _rulesBlock(String collection) {
  final rules = _src('firestore.rules');
  final start = rules.indexOf('match /$collection/{docId}');
  expect(start, greaterThan(-1), reason: 'كتلة $collection موجودة');
  final next = rules.indexOf('    match /', start + 8);
  return rules.substring(start, next == -1 ? rules.length : next);
}

void main() {
  group('عقد المجموعات (١) — المحرك والقواعد', () {
    test('المحرك يغطي الثماني عشرة مجموعة ولا مجموعة زائدة', () {
      expect(OwnerContentService.editableCollections,
          unorderedEquals(kOwnerEditableCollections));
      for (final c in kOwnerEditableCollections) {
        final spec = OwnerContentService.specFor(c)!;
        expect(spec.collection, c);
        expect(spec.ownerField, isNotEmpty, reason: '$c بلا حقل مالك');
        expect(spec.itemLabel, isNotEmpty, reason: '$c بلا تسمية عربية');
        expect(spec.titleField, isNotEmpty);
        expect(spec.route, startsWith('/'), reason: '$c بلا مسار قسم');
      }
      expect(OwnerContentService.specFor('medical_center_clinics'), isNull,
          reason: 'عيادات المركز بلا حقل مالك — لا مالك يعدّلها');
    });

    test('القواعد: تعديل المالك يبدأ معلّقًا وحذفه فوري، للمجموعات كلها', () {
      final rules = _src('firestore.rules');
      for (final c in kOwnerEditableCollections) {
        final block = _rulesBlock(c);
        expect(block, contains('ownerEdit('), reason: '$c بلا رخصة تعديل مالك');
        expect(block, contains('ownerDelete('), reason: '$c بلا رخصة حذف مالك');
      }
      // العقد عامّ في المتحقّقين، لا مكررًا في كل كتلة على حدة.
      expect(rules, contains('function ownerEdit(ownerId, incomingOwnerId)'));
      expect(rules, contains('function ownerDelete(ownerId)'));
      expect(rules, contains('request.resource.data.isApproved == false'),
          reason: 'ownerEdit تحسم أن الوثيقة الناتجة غير معتمدة، فكل تعديل يعود '
              'للمراجعة ولا يملك المالك أن يمنح نفسه اعتمادًا');
      // والحذف فوري: لا شرط مراجعة ولا موافقة فيه.
      final deleteHelper =
          rules.substring(rules.indexOf('function ownerDelete(ownerId)'));
      expect(deleteHelper.split('}').first, isNot(contains('isApproved')));
    });

    test('لا مجموعة في الواجهة تمر بمسار حذف أو تعديل خارج المحرك', () {
      final engine = _src('lib/services/owner_content_service.dart');
      expect(RegExp(r"collection: '").allMatches(engine).length, 18);
      for (final f in [
        'lib/services/news_service.dart',
        'lib/services/obituary_service.dart',
        'lib/services/phone_directory_service.dart',
        'lib/services/village_ad_service.dart',
        'lib/services/legal_service.dart',
      ]) {
        expect(_src(f), contains('OwnerContentService.edit('), reason: f);
        expect(_src(f), contains('OwnerContentService.remove('), reason: f);
      }
    });
  });

  group('سلوك المحرك', () {
    test('التعديل يفرض العودة للمراجعة ولا يلمس النسبة ولا المعرّف', () async {
      final fs = FakeFirebaseFirestore();
      final ref = await fs.collection('forum_posts').add({
        'title': 'منشور',
        'body': 'نص قديم',
        'userId': 'u1',
        'userName': 'صاحب الحساب',
        'userPhotoUrl': 'https://x/p.jpg',
        'isApproved': true,
        'isPinned': true,
        'likes': 12,
        'likedBy': ['a', 'b'],
        'createdAt': 'قديم',
      });
      await OwnerContentService.edit(fs, 'forum_posts', ref.id, {
        'title': 'منشور',
        'body': 'نص جديد',
        'userId': 'someone-else',
        'userName': 'اسم.try-change',
        'isPinned': false,
        'likes': 0,
        'createdAt': 'جديد',
        'isApproved': true,
      });
      final data = (await ref.get()).data()!;
      expect(data['body'], 'نص جديد');
      expect(data['isApproved'], false, reason: 'التعديل يعود إلى المراجعة');
      expect(data['userId'], 'u1', reason: 'النسبة لا تلمسها رقعة المالك');
      expect(data['userName'], 'صاحب الحساب');
      expect(data['userPhotoUrl'], 'https://x/p.jpg');
      expect(data['isPinned'], true, reason: 'التثبيت قرار إداري لا نسخة قديمة');
      expect(data['likes'], 12, reason: 'العدّادات خارج رقعة المالك');
      expect(data['createdAt'], 'قديم');
    });

    test('الفصل يرفض مجموعة بلا مالك ومعرّفًا فارغًا', () async {
      final fs = FakeFirebaseFirestore();
      expect(
          () => OwnerContentService.edit(
              fs, 'medical_center_clinics', 'x', {'name': 'y'}),
          throwsA(isA<Exception>()));
      final ref = await fs.collection('news').add({'title': 'خبر'});
      await expectLater(
          OwnerContentService.edit(fs, 'news', '', {'title': 'y'}),
          throwsA(isA<Exception>()));
      expect((await ref.get()).data()!['title'], 'خبر');
    });

    test('الاستشارة: التعديل يفرّغ رد المستشار', () async {
      final fs = FakeFirebaseFirestore();
      final ref = await fs.collection('legal_consultations').add({
        'question': 'سؤال قديم',
        'userId': 'u1',
        'answer': 'ردّ قديم عن سؤال لم يعد موجودًا',
        'isApproved': true,
      });
      await OwnerContentService.edit(fs, 'legal_consultations', ref.id, {
        'question': 'سؤال جديد',
        'answer': 'ردّ قديم عن سؤال لم يعد موجودًا',
      });
      final data = (await ref.get()).data()!;
      expect(data['question'], 'سؤال جديد');
      expect(data['answer'], '');
      expect(data['isApproved'], false);
    });

    test('الحذف يمرّ بتنظيف الأيتام ويُلغي الوثيقة', () async {
      final fs = FakeFirebaseFirestore();
      final ref = await fs.collection('news').add({
        'title': 'خبر',
        'authorId': 'u1',
        'imageUrl': 'https://x/1.jpg',
        'isApproved': true,
      });
      await ref.collection('comments').add({'text': 'تعليق'});
      await OwnerContentService.remove(fs, 'news', ref.id);
      expect((await ref.get()).exists, isFalse);
      final comments = await ref.collection('comments').get();
      expect(comments.docs, isEmpty, reason: 'البند ٨ (٦): التنظيف قبل الحذف');
    });

    test('الحذف لا يتعطل بفشل تنظيف ثانوي في مجموعة بلا صور', () async {
      final fs = FakeFirebaseFirestore();
      final ref = await fs
          .collection('blood_requests')
          .add({'userId': 'u1', 'patientName': 'مريض', 'status': 'open'});
      await OwnerContentService.remove(fs, 'blood_requests', ref.id);
      expect((await ref.get()).exists, isFalse);
    });
  });

  group('OwnerActions — العنصر الموحّد (البند ٩)', () {
    Widget host(Widget child) => MaterialApp(
          home: Scaffold(body: Center(child: child)),
        );

    testWidgets('صاحب الإضافة يرى الزرّين بأسلوب موحّد', (tester) async {
      var edited = 0;
      await tester.pumpWidget(host(OwnerActions(
        keyTag: 'probe',
        ownerId: 'u1',
        currentUserId: 'u1',
        itemName: 'المحل',
        editLabel: 'تعديل المحل',
        deleteLabel: 'حذف المحل',
        onEdit: () => edited++,
        onDelete: () async => true,
      )));

      expect(find.byKey(const ValueKey<String>('probe-edit')), findsOne);
      expect(find.byKey(const ValueKey<String>('probe-delete')), findsOne);
      expect(find.text('تعديل المحل'), findsOne);
      expect(find.text('حذف المحل'), findsOne);
      expect(find.byIcon(Icons.edit_rounded), findsOne);
      expect(find.byIcon(Icons.delete_rounded), findsOne);
      // زرّان متساويان بعرض كامل.
      final widths = find
          .descendant(
              of: find.byType(Row), matching: find.byType(Expanded))
          .evaluate()
          .length;
      expect(widths, 2);

      await tester.tap(find.byKey(const ValueKey<String>('probe-edit')));
      expect(edited, 1);
    });

    testWidgets('غير صاحب ولا إدارة: لا يُرسم شيء', (tester) async {
      await tester.pumpWidget(host(OwnerActions(
        keyTag: 'probe',
        ownerId: 'u1',
        currentUserId: 'u2',
        onEdit: () {},
        onDelete: () async => true,
      )));
      expect(find.byKey(const ValueKey<String>('probe-edit')), findsNothing);
      expect(find.byKey(const ValueKey<String>('probe-delete')), findsNothing);

      // معرّف مالك فارغ (إضافة نظام لا إضافة أحد) = لا أزرار.
      await tester.pumpWidget(host(OwnerActions(
        keyTag: 'probe',
        ownerId: '',
        currentUserId: '',
        onEdit: () {},
        onDelete: () async => true,
      )));
      expect(find.byKey(const ValueKey<String>('probe-edit')), findsNothing);
    });

    testWidgets('isAdmin توسّع الرؤية حيث يسمح القسم', (tester) async {
      await tester.pumpWidget(host(OwnerActions(
        keyTag: 'probe',
        ownerId: 'u1',
        currentUserId: 'admin-uid',
        isAdmin: true,
        onEdit: () {},
        onDelete: () async => true,
      )));
      expect(find.byKey(const ValueKey<String>('probe-delete')), findsOne);
    });

    testWidgets('الحذف: تأكيد صريح، والإلغاء لا يحذف', (tester) async {
      var deletes = 0;
      await tester.pumpWidget(host(OwnerActions(
        keyTag: 'probe',
        ownerId: 'u1',
        currentUserId: 'u1',
        itemName: 'إعلانى',
        onEdit: () {},
        onDelete: () async {
          deletes++;
          return true;
        },
      )));
      await tester.tap(find.byKey(const ValueKey<String>('probe-delete')));
      await tester.pumpAndSettle();
      expect(find.text('سيُحذف «إعلانى» نهائيًا ولن يظهر لأحد.'), findsOne);

      await tester.tap(find.byKey(const ValueKey<String>('probe-delete-cancel')));
      await tester.pumpAndSettle();
      expect(deletes, 0, reason: 'بلا حذف قبل التأكيد');
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('الحذف المؤكد: شريط نجاح يذكر الاسم', (tester) async {
      var deletes = 0;
      await tester.pumpWidget(host(OwnerActions(
        keyTag: 'probe',
        ownerId: 'u1',
        currentUserId: 'u1',
        itemName: 'بيان الهاتف',
        onEdit: () {},
        onDelete: () async {
          deletes++;
          return true;
        },
      )));
      await tester.tap(find.byKey(const ValueKey<String>('probe-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('probe-delete-confirm')));
      await tester.pump(); // الشريط يبدأ بعد اكتمال الانتظار
      await tester.pump();
      expect(deletes, 1);
      expect(find.text('تم حذف «بيان الهاتف»'), findsOne);
    });

    testWidgets('الرفض لا يطبع نجاحًا: شريط أحمر صريح', (tester) async {
      for (final failing in <Future<bool> Function()>[
        () async => false,
        () async => throw Exception('PERMISSION_DENIED'),
      ]) {
        await tester.pumpWidget(host(OwnerActions(
          keyTag: 'probe',
          ownerId: 'u1',
          currentUserId: 'u1',
          itemName: 'السؤال',
          onEdit: () {},
          onDelete: failing,
        )));
        await tester.tap(find.byKey(const ValueKey<String>('probe-delete')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('probe-delete-confirm')));
        await tester.pump();
        await tester.pump();
        expect(find.text('تم حذف «السؤال»'), findsNothing);
        expect(
            find.text('تعذّر الحذف — تحقّق من الصلاحيات أو من الاتصال ثم أعد '
                'المحاولة.'),
            findsOne);
        // شريط واحد لكل حالة حتى لا يتراكب في التكرار التالي.
        ScaffoldMessenger.of(tester.element(find.byType(OwnerActions)))
            .clearSnackBars();
        await tester.pump();
      }
    });

    test('canManage هو البوابة الوحيدة', () {
      expect(OwnerActions.canManage('u1', 'u1', false), isTrue);
      expect(OwnerActions.canManage('u1', 'u2', false), isFalse);
      expect(OwnerActions.canManage('', '', false), isFalse,
          reason: 'إضافة بلا مالك لا أزرار لها');
      expect(OwnerActions.canManage('u1', 'admin', true), isTrue);
    });
  });

  group('عقد الواجهة', () {
    test('شاشات التفاصيل تمرّ بالعنصر الموحّد لا بأزرار خاصة', () {
      for (final f in [
        'lib/features/news/view.dart',
        'lib/features/market/product_detail.dart',
        'lib/features/market/market_tab_shops.dart',
        'lib/features/obituaries/detail.dart',
        'lib/features/occasions/detail.dart',
        'lib/features/forum/post_detail.dart',
        'lib/features/services/service_provider_detail_screen.dart',
        'lib/features/services/lost_items_screen.dart',
        'lib/features/medical/clinic_detail_screen.dart',
        'lib/features/medical/optical_shop_detail_screen.dart',
        'lib/features/ads/village_ad_detail_screen.dart',
        'lib/features/legal/lawyer_detail_screen.dart',
      ]) {
        expect(_src(f), contains('OwnerActions('), reason: f);
      }
      // المجموعات الأربع بلا شاشة تفاصيل: الأزرار على الكارت/الحوار نفسه.
      expect(_src('lib/features/medical/medical_home_screen.dart'),
          contains('OwnerActions('));
      expect(_src('lib/features/phone/directory.dart'),
          contains('OwnerActions('));
      expect(_src('lib/features/legal/legal_advisor_screen.dart'),
          contains('OwnerActions('));
      expect(kOwnerCardCollections, hasLength(4));
    });

    test('لا شاشة تستعمل العنصر الموحّد تعيد اختراع نافذة حذف الإضافة', () {
      // نافذة التأكيد ونصّاه ملك `OwnerActions` وحدها — وإلا انشقت رسالتان
      // لحدث واحد فتختلف الصيغة بين قسم وقسم.
      final widget = _src('lib/widgets/owner_actions.dart');
      expect(widget, contains('سيُحذف'));
      expect(widget, contains('تعذّر الحذف'));
      final screens = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => _src(f.path).contains('OwnerActions('))
          .where((f) => !f.path.endsWith('owner_actions.dart'))
          .toList();
      expect(screens, isNotEmpty);
      for (final f in screens) {
        expect(_src(f.path), isNot(contains('نهائيًا ولن يظهر لأحد')),
            reason: '${f.path} يرسم تأكيده الخاص فوق التأكيد الموحّد');
      }
      expect(widget, contains('نهائيًا ولن يظهر لأحد'));
    });
  });
}
