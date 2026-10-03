import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/admin/admin_edit.dart';
import 'package:qurity/services/image_upload_service.dart';
import 'package:qurity/widgets/document_field_editor.dart';

/// مُحرِّر الوثائق مشترك بين لوحة الإدارة ونماذج المالك، فعلّته أن يُظهر **كل**
/// مفتاح في المستند لا ما تعرفه القائمة، وأن تبقى الصور قابلة للرفع والحذف.
String _read(String path) => File(path).readAsStringSync();

class _FakeUploader implements ImageUploadService {
  _FakeUploader({this.fail = false});
  final bool fail;
  final String result = 'https://cdn.test/uploaded.jpg';
  int calls = 0;

  @override
  Future<String> uploadImage(Uint8List bytes) async {
    calls++;
    if (fail) throw Exception('لم يرجع الخدمة رابط الصورة');
    return result;
  }

  @override
  String? extractDeleteKey(String imageUrl) => null;

  @override
  Future<void> deleteImage(String imageUrl) async {}
}

/// مصدر صور وهمي: بدل معرض الجهاز يعيد بايتات جاهزة بعدد ما يُطلب.
ImageBytesSource _source(int count) =>
    (remaining) async => List.generate(
        count > remaining ? remaining : count, (_) => Uint8List.fromList([1, 2, 3]));

void main() {
  final item = <String, dynamic>{
    'id': 'doc1',
    'title': 'عنوان',
    'subtitle': 'نص طويل جدًا يتجاوز الستين حرفًا بالتأكيد لأنه مكرر '
        'مرات ومرات داخل اختبار المشتقات',
    'price': 25,
    'isApproved': true,
    'views': 3,
    'imageUrls': ['https://cdn.test/a.jpg'],
    'photoUrl': '',
    'likedBy': ['u1', 'u2'],
    'categories': ['أ', 'ب'],
    'createdAt': 'طابع زمني',
    'meta': {'فرعي': 'قيمة'},
  };
  final named = <DocFieldSpec>[
    const DocFieldSpec('title', 'العنوان', required: true),
  ];

  group('deriveMissingFields — كل مفتاح في المستند له موضع', () {
    test('المفاتيح المغطاة لا تتكرر، والبقية كلها تظهر', () {
      final derived = deriveMissingFields(item, {'title'});
      final keys = derived.map((f) => f.key).toSet();
      expect(keys, item.keys.where((k) => k != 'title').toSet(),
          reason: 'لا يُترك حقل بلا عرض — هذا جوهر طلب الأدمن');
      expect(keys.contains('title'), isFalse);
    });

    test('الهوية والموافقة والتواريخ للقراءة فقط', () {
      final derived = deriveMissingFields(item, {'title'});
      Map<String, DocFieldSpec> byKey() =>
          {for (final f in derived) f.key: f};
      final by = byKey();
      for (final k in ['id', 'isApproved', 'createdAt']) {
        expect(by[k]!.kind, DocFieldKind.readOnly, reason: k);
      }
      expect(by['id']!.rawValue, 'doc1',
          reason: 'القيمة الخام تُعرض، لا يُترك الحقل فارغًا');
    });

    test('الأنواع مشتقة من القيمة: رقم ومنطقي ونص متعدد الأسطر', () {
      final by = {
        for (final f in deriveMissingFields(item, {'title'})) f.key: f
      };
      expect(by['price']!.kind, DocFieldKind.number);
      expect(by['views']!.kind, DocFieldKind.number);
      expect(by['subtitle']!.kind, DocFieldKind.multiline);
    });

    test('حقول الصور تُكتشف من اسم المفتاح ولو كانت قيمتها فارغة', () {
      final by = {
        for (final f in deriveMissingFields({
          'photoUrl': '',
          'imageUrls': <String>[],
          'cardBackground': 'azaa2',
        }, const <String>{}))
            f.key: f
      };
      expect(by['photoUrl']!.kind, DocFieldKind.image);
      expect(by['imageUrls']!.kind, DocFieldKind.images);
      // الخلفية قد تكون مفتاح azaa لا رابطًا، فتبقى نصًا حرًا.
      expect(by['cardBackground']!.kind, DocFieldKind.text);
      expect(isImageFieldKey('cardBackground'), isFalse);
      expect(isImageFieldKey('userPhotoUrl'), isTrue);
    });

    test('قائمة صور أو قائمة نصوص، والخريطة للقراءة فقط', () {
      final by = {
        for (final f in deriveMissingFields(item, {'title'})) f.key: f
      };
      expect(by['imageUrls']!.kind, DocFieldKind.images);
      expect(by['likedBy']!.kind, DocFieldKind.list);
      expect(by['categories']!.kind, DocFieldKind.list);
      expect(by['meta']!.kind, DocFieldKind.readOnly,
          reason: 'الكتابة نصًا فوق خريطة تُفسد الوثيقة');
    });

    test('تسميات عربية للمفاتيح المجهولة بدل المفتاح الخام', () {
      expect(docFieldLabel('submittedBy'), contains('معرّف'));
      expect(docFieldLabel('unknownKey'), 'unknownKey');
      expect(docFieldIcon('funeralTime'), Icons.schedule_rounded);
      expect(looksLikeImageUrl('https://x/y.jpg'), isTrue);
      expect(looksLikeImageUrl('azaa1'), isFalse);
    });
  });

  group('DocumentEditor — الحفظ يكتب ما يراه الأدمن فعلًا', () {
    test('البذر ثم الجمع يدوران القيم كما هي', () {
      final specs = [
        ...named,
        ...deriveMissingFields(item, {'title'})
      ];
      final editor = DocumentEditor()..seed(specs, item);
      final data = editor.collect(specs);
      expect(data['title'], 'عنوان');
      expect(data['price'], 25);
      expect(data['views'], 3);
      expect(data['imageUrls'], ['https://cdn.test/a.jpg']);
      expect(data['categories'], ['أ', 'ب']);
      expect(data.containsKey('isApproved'), isFalse,
          reason: 'علامة الموافقة حق إدارة لا تُعاد كتابته من المحرر');
      expect(data.containsKey('createdAt'), isFalse);
      editor.dispose();
    });

    test('حذف آخر صورة يُكتب فارغًا (لا يُتخطّى بصمت)', () {
      final specs = [
        const DocFieldSpec('imageUrls', 'الصور', kind: DocFieldKind.images),
      ];
      final editor = DocumentEditor()..seed(specs, item);
      editor.setImageUrls('imageUrls', []);
      expect(editor.collect(specs)['imageUrls'], <String>[]);
      editor.dispose();
    });

    test('الحقل الاختياري المُفرَّغ يُمسح من الوثيقة', () {
      final specs = const [
        DocFieldSpec('title', 'العنوان'),
        DocFieldSpec('category', 'التصنيف'),
      ];
      final editor = DocumentEditor()
        ..seed(specs, {'title': 'س', 'category': 'قديم'});
      editor.texts['category']!.clear();
      final data = editor.collect(specs);
      expect(data['category'], '', reason: 'التفريغ قرار، لا نسيان');
      editor.dispose();
    });

    test('الصورة المفردة مرآة أول قائمة عند الجمع', () {
      final specs = const [
        DocFieldSpec('imageUrls', 'الصور', kind: DocFieldKind.images),
        DocFieldSpec('imageUrl', 'الرئيسية', kind: DocFieldKind.image),
      ];
      final editor = DocumentEditor()
        ..seed(specs, {
          'imageUrls': ['https://cdn.test/a.jpg', 'https://cdn.test/b.jpg'],
          'imageUrl': 'https://cdn.test/old.jpg'
        });
      final data = editor.collect(specs);
      syncImageMirrors(specs, data);
      expect(data['imageUrl'], 'https://cdn.test/a.jpg');
      editor.dispose();
    });

    test('المرآة العكسية: صورة مفردة وحيدة تُملأ القائمة الفارغة', () {
      final data = <String, dynamic>{
        'imageUrls': <String>[],
        'imageUrl': 'https://cdn.test/only.jpg'
      };
      syncImageMirrors(
          const [
            DocFieldSpec('imageUrls', 'الصور', kind: DocFieldKind.images),
            DocFieldSpec('imageUrl', 'الرئيسية', kind: DocFieldKind.image),
          ],
          data);
      expect(data['imageUrls'], ['https://cdn.test/only.jpg']);
    });

    test('الحقل المطلوب المُفرَّغ يعطي اسمه لا صمتًا', () {
      final specs = const [
        DocFieldSpec('title', 'العنوان', required: true),
        DocFieldSpec('photoUrl', 'الصورة',
            required: true, kind: DocFieldKind.image),
      ];
      final editor = DocumentEditor()..seed(specs, {});
      expect(editor.missingRequiredLabel(specs), 'العنوان');
      editor.texts['title']!.text = 'موجود';
      expect(editor.missingRequiredLabel(specs), 'الصورة');
      editor.dispose();
    });
  });

  group('ImageListEditor — رفع وحذف ولصق', () {
    Future<void> pump(WidgetTester tester, ImageListEditor editor) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: editor)));
      await tester.pumpAndSettle();
    }

    testWidgets('الرفع عبر الخدمة المُحقنة يضيف الصورة', (tester) async {
      final added = <List<String>>[];
      final service = _FakeUploader();
      await pump(
          tester,
          ImageListEditor(
            label: 'صور الخبر',
            fieldKey: 'imageUrls',
            urls: const [],
            onChanged: added.add,
            uploader: service,
            bytesSource: _source(1),
          ));
      expect(find.text('لا صورة — ارفع من الجهاز أو الصق رابطًا'),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('img-add-imageUrls')));
      await tester.pumpAndSettle();
      expect(service.calls, 1);
      expect(added.last, ['https://cdn.test/uploaded.jpg']);
    });

    testWidgets('فشل الرفع يظهر أحمر ولا يختفي أثره', (tester) async {
      await pump(
          tester,
          ImageListEditor(
            label: 'الصورة',
            fieldKey: 'imageUrl',
            single: true,
            urls: const [],
            onChanged: (_) {},
            uploader: _FakeUploader(fail: true),
            bytesSource: _source(1),
          ));
      await tester.tap(find.byKey(const ValueKey('img-add-imageUrl')));
      await tester.pumpAndSettle();
      final error = find.byKey(const ValueKey('img-error-imageUrl'));
      expect(error, findsOneWidget);
      expect(tester.widget<Text>(error).style!.color, const Color(0xFFB71C1C));
      expect(
          tester.widget<Text>(error).data,
          contains('لم يرجع الخدمة رابط الصورة'),
          reason: 'رسالة ImgBB تصل كما هي لا رقم داخلي');
    });

    testWidgets('الرابط غير الصحيح مرفوض برسالة، والصحيح يُضاف', (tester) async {
      final added = <List<String>>[];
      await pump(
          tester,
          ImageListEditor(
            label: 'الصور',
            fieldKey: 'imageUrls',
            urls: const [],
            onChanged: added.add,
          ));
      await tester.tap(find.byKey(const ValueKey('img-paste-imageUrls')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('img-link-imageUrls')), 'ftp://x');
      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();
      expect(added, isEmpty);
      expect(find.text('الرابط يجب أن يبدأ بـ http أو https'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('img-paste-imageUrls')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('img-link-imageUrls')),
          'https://cdn.test/pasted.jpg');
      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();
      expect(added.last, ['https://cdn.test/pasted.jpg']);
    });

    testWidgets('المصغّرة لها زر حذف يوصل القائمة المُقلَّصة', (tester) async {
      final result = <List<String>>[];
      await pump(
          tester,
          ImageListEditor(
            label: 'الصور',
            fieldKey: 'imageUrls',
            urls: const [
              'https://cdn.test/keep.jpg',
              'https://cdn.test/drop.jpg'
            ],
            onChanged: result.add,
          ));
      expect(find.byKey(const ValueKey('img-delete-imageUrls-0')),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('img-delete-imageUrls-1')));
      await tester.pumpAndSettle();
      expect(result.last, ['https://cdn.test/keep.jpg']);
    });

    testWidgets('المفردة مملوءة: النقر يقول السبب لا يصمت', (tester) async {
      await pump(
          tester,
          ImageListEditor(
            label: 'الصورة',
            fieldKey: 'photoUrl',
            single: true,
            urls: const ['https://cdn.test/a.jpg'],
            onChanged: (_) {},
          ));
      final add = find.byKey(const ValueKey('img-add-photoUrl'));
      expect(tester.widget<ButtonStyleButton>(add).onPressed, isNotNull,
          reason: 'الزر مضغوط لأن السبب يُقال، لا لأنه يُعطّل بلا رسالة');
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(
          find.text('الصورة موجودة بالفعل — احذفها أولًا لرفع غيرها'),
          findsOneWidget);
      // لصق رابط في حقل مفرد مملوء: نفس السبب، فلا يُستبدل بصمت.
      await tester.tap(find.byKey(const ValueKey('img-paste-photoUrl')));
      await tester.pump();
      expect(find.byKey(const ValueKey('img-link-photoUrl')), findsNothing);
    });

    testWidgets('الحد الأقصى يُقال للمستخدم لا يُبتلع', (tester) async {
      await pump(
          tester,
          ImageListEditor(
            label: 'الصور',
            fieldKey: 'imageUrls',
            maxImages: 2,
            urls: const ['https://cdn.test/a.jpg', 'https://cdn.test/b.jpg'],
            onChanged: (_) {},
          ));
      expect(find.text('الصور (2/2)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('img-add-imageUrls')));
      await tester.pumpAndSettle();
      expect(find.text('الحد الأقصى 2 صور'), findsOneWidget);
    });
  });

  group('عقد المصدر', () {
    test('شاشة تعديل الأدمن تشتق بقية الحقول ولا تعرض قائمة ثابتة فقط', () {
      final src = _read('lib/features/admin/admin_edit.dart');
      expect(src, contains('deriveMissingFields('));
      expect(src, contains('_editor.collect(_fields)'));
      expect(src, contains('missingRequiredLabel'));
      expect(src, isNot(contains('_FieldSpec')),
          reason: 'الوصف القديم حُلّ محلّه DocFieldSpec المشترك');
      expect(src, isNot(contains('_systemKeys')),
          reason: 'الإخفاء الصامت للحقول المجهولة هو العلّة الأصلية');
    });

    test('كل مجموعة معروفة لها محرر صور في حقل صورها', () {
      final src = _read('lib/features/admin/admin_edit.dart');
      for (final key in [
        "'imageUrls', 'صور الخبر'",
        "'imageUrl', 'صورة المتوفى'",
        "'photoUrl', 'صورة السجل'",
        "'photoUrl', 'صورة الرقم'",
        "'photoUrl', 'صورة المحامي'",
        "'imageUrl', 'صورة العيادة'",
      ]) {
        expect(src, contains(key), reason: key);
      }
      expect(src, contains('DocFieldKind.images'));
      expect(src, contains('DocFieldKind.image'));
    });

    test('الحقول المحرَّرة تُرسل كاملة: تفريغ الصورة يكتبها', () {
      final src = _read('lib/widgets/document_field_editor.dart');
      expect(src, contains('case DocFieldKind.readOnly:'));
      expect(src, contains('data[f.key] = List<String>.from('));
      expect(src, contains('kDocReadOnlyKeys.contains(entry.key)'));
      expect(src, contains("'isApproved'"));
    });
  });
}
