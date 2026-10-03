import 'dart:io';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/ads/village_ads_screen.dart';
import 'package:qurity/features/forum/create_post.dart';
import 'package:qurity/features/legal/legal_advisor_screen.dart';
import 'package:qurity/features/market/add_product.dart';
import 'package:qurity/features/market/market_tabs_screen.dart';
import 'package:qurity/features/medical/medical_home_screen.dart';
import 'package:qurity/features/news/add.dart';
import 'package:qurity/features/occasions/add.dart';
import 'package:qurity/features/phone/add_directory.dart';
import 'package:qurity/features/services/lost_items_screen.dart';
import 'package:qurity/features/services/service_directory_screen.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/services/forum_service.dart';
import 'package:qurity/services/image_upload_service.dart';
import 'package:qurity/services/legal_service.dart';
import 'package:qurity/services/lost_item_service.dart';
import 'package:qurity/services/market_service.dart';
import 'package:qurity/services/news_service.dart';
import 'package:qurity/services/occasion_service.dart';
import 'package:qurity/services/phone_directory_service.dart';
import 'package:qurity/services/user_service.dart';
import 'package:qurity/services/village_ad_service.dart';
import 'package:qurity/widgets/document_field_editor.dart';

/// المحرّر المشترك صار مسار الصور في كل نماذج المحتوى، فاختبار المحرّر وحده
/// (`document_field_editor_test.dart`) لا يكفي: على **كل شاشة** أن تُثبت أنها
/// تركّبه بنفس العقد وأن حالتها تُحدَّث من `onChanged`. لذا كل شاشة تُبنى
/// بحقيقتها على `FakeFirebaseFirestore` وتُقاد بالخمس: إضافة / حذف / استبدال /
/// الوصول للحد / فشل الرفع.
void main() {
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// `appKey` different at the second pump ⇒ شجرة جديدة بالكامل فحالة النموذج
  /// (الصور المرفوعة) تعود فارغة، وإلا ورث الاختبار صور الرحلة الناجحة.
  Future<void> pumpScreen(WidgetTester tester, Widget screen,
      {Key? appKey}) async {
    bigScreen(tester);
    await tester.pumpWidget(MaterialApp(key: appKey, home: screen));
    await tester.pumpAndSettle();
  }

  /// الأوراق تُفتح كما تُفتح في التطبيق (ورقة بارتفاع تحكّمي).
  Future<void> pumpSheet(WidgetTester tester, Widget sheet,
      {Key? appKey}) async {
    bigScreen(tester);
    await tester.pumpWidget(MaterialApp(
      key: appKey,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => sheet,
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

  Future<void> pumpBody(WidgetTester tester, Widget field,
      {Key? appKey}) async {
    bigScreen(tester);
    await tester.pumpWidget(MaterialApp(
        key: appKey,
        home: Scaffold(body: SingleChildScrollView(child: field))));
    await tester.pumpAndSettle();
  }

  Future<void> tapAdd(WidgetTester tester, String fieldKey) async {
    final add = find.byKey(ValueKey('img-add-$fieldKey'));
    expect(add, findsOneWidget, reason: '$fieldKey — زر الرفع المشترك');
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
  }

  Future<void> tapDelete(WidgetTester tester, String fieldKey, int i) async {
    final del = find.byKey(ValueKey('img-delete-$fieldKey-$i'));
    await tester.ensureVisible(del);
    await tester.pumpAndSettle();
    await tester.tap(del);
    await tester.pumpAndSettle();
  }

  int countPreviews(WidgetTester tester, String fieldKey) {
    var n = 0;
    for (var i = 0; i < 10; i++) {
      if (find
          .byKey(ValueKey('img-preview-$fieldKey-$i'))
          .evaluate()
          .isNotEmpty) {
        n++;
      }
    }
    return n;
  }

  String? errorText(WidgetTester tester, String fieldKey) {
    final e = find.byKey(ValueKey('img-error-$fieldKey'));
    return e.evaluate().isEmpty ? null : tester.widget<Text>(e).data;
  }

  const empty = 'لا صورة — ارفع من الجهاز أو الصق رابطًا';

  /// الخمس عمليات على أي شاشة مركّبة للمحرّر.
  Future<void> battery(WidgetTester tester,
      {required String fieldKey,
      required int maxImages,
      bool single = false}) async {
    // 1) الإضافة عبر الخدمة المحقنة.
    expect(find.text(empty), findsOneWidget, reason: fieldKey);
    await tapAdd(tester, fieldKey);
    expect(countPreviews(tester, fieldKey), 1, reason: '$fieldKey بعد الإضافة');

    // 2) الحذف يُرجع الحالة الفارغة (لا صورة شبحية).
    await tapDelete(tester, fieldKey, 0);
    expect(find.text(empty), findsOneWidget, reason: '$fieldKey بعد الحذف');
    expect(countPreviews(tester, fieldKey), 0);

    // 3) الاستبدال: إضافة جديدة بعد الحذف.
    await tapAdd(tester, fieldKey);
    expect(countPreviews(tester, fieldKey), 1, reason: '$fieldKey استبدال');

    // 4) الحد: الامتلاء يُقال سببه، ولا يُبتلع النقر.
    for (var i = countPreviews(tester, fieldKey); i < maxImages; i++) {
      await tapAdd(tester, fieldKey);
      if (countPreviews(tester, fieldKey) == i) {
        fail('لم تُضف صورة عند $fieldKey (حلقة لا تنتهي)');
      }
    }
    expect(countPreviews(tester, fieldKey), maxImages, reason: fieldKey);
    await tapAdd(tester, fieldKey);
    expect(
        errorText(tester, fieldKey),
        contains(single
            ? 'الصورة موجودة بالفعل — احذفها أولًا لرفع غيرها'
            : 'الحد الأقصى $maxImages صور'),
        reason: '$fieldKey عند الحد');
  }

  /// 5) فشل الرفع: رسالة ImgBB كما هي، وأحمر، وبلا صورة كاذبة.
  Future<void> failure(WidgetTester tester, String fieldKey) async {
    await tapAdd(tester, fieldKey);
    final message = errorText(tester, fieldKey);
    expect(message, contains('تعذّر رفع الصورة'), reason: fieldKey);
    expect(message, contains('لم يرجع الخدمة رابط الصورة'),
        reason: '$fieldKey — رسالة ImgBB تصل نصّها');
    expect(find.byKey(ValueKey('img-error-$fieldKey')), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(ValueKey('img-error-$fieldKey')))
            .style!
            .color,
        const Color(0xFFB71C1C),
        reason: '$fieldKey — الفشل أحمر لا باهتًا');
    expect(countPreviews(tester, fieldKey), 0,
        reason: '$fieldKey لا مصغّرة بلا رفع');
  }

  /// شاشة كاملة: رحلتان على شجرتين — ناجحة ثم فاشلة.
  Future<void> runScreen(WidgetTester tester,
      {required Widget Function(ImageUploadService, ImageBytesSource) build,
      required String fieldKey,
      required int maxImages,
      bool single = false,
      bool sheet = false,
      bool body = false}) async {
    final opener = sheet ? pumpSheet : (body ? pumpBody : pumpScreen);
    await opener(tester,
        build(_Uploader(), _bytes));
    await battery(tester,
        fieldKey: fieldKey, maxImages: maxImages, single: single);
    await opener(tester, build(_Uploader(fail: true), _bytes),
        appKey: const Key('fail-run'));
    await failure(tester, fieldKey);
  }

  final fake = FakeFirebaseFirestore();

  group('نماذج المحتوى تقود المحرّر المشترك', () {
    testWidgets('إضافة خبر (حتى 3 صور)', (tester) async {
      await runScreen(tester,
          fieldKey: 'imageUrls',
          maxImages: 3,
          build: (up, src) => AddNewsScreen(
                newsService: NewsService(fake),
                userService: UserService(fake),
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('إضافة مناسبة (مفردة)', (tester) async {
      await runScreen(tester,
          fieldKey: 'imageUrl',
          maxImages: 1,
          single: true,
          build: (up, src) => AddOccasionScreen(
                service: OccasionService(fake),
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('إضافة رقم في دليل الهاتف (مفردة)', (tester) async {
      await runScreen(tester,
          fieldKey: 'photoUrl',
          maxImages: 1,
          single: true,
          build: (up, src) => AddPhoneDirectoryScreen(
                service: PhoneDirectoryService(fake),
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('منشور المندرة (مفردة)', (tester) async {
      await runScreen(tester,
          fieldKey: 'imageUrl',
          maxImages: 1,
          single: true,
          build: (up, src) => CreatePostScreen(
                forumService: ForumService(fake),
                userService: UserService(fake),
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('بيان دليل الخدمات (مفردة)', (tester) async {
      await runScreen(tester,
          sheet: true,
          fieldKey: 'photoUrl',
          maxImages: 1,
          single: true,
          build: (up, src) => ProviderFormSheet(
                category: ServiceCategory.technicians,
                userId: 'u1',
                userName: 'أحمد',
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('إعلان القرية (حتى 3)', (tester) async {
      await runScreen(tester,
          sheet: true,
          fieldKey: 'imageUrls',
          maxImages: 3,
          build: (up, src) => VillageAdFormSheet(
                userId: 'u1',
                service: VillageAdService(fake),
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('تسجيل محامٍ (مفردة)', (tester) async {
      await runScreen(tester,
          sheet: true,
          fieldKey: 'photoUrl',
          maxImages: 1,
          single: true,
          build: (up, src) => LawyerFormSheet(
                service: LawyerService(fake),
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('منتج السوق — حدّه من نوع البائع (بائع عادي = 1)',
        (tester) async {
      await runScreen(tester,
          fieldKey: 'imageUrls',
          maxImages: 1,
          build: (up, src) => AddMarketProductScreen(
                userService: UserService(fake),
                marketService: MarketService(firestore: fake),
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('المفقودات (مفردة)', (tester) async {
      await runScreen(tester,
          sheet: true,
          fieldKey: 'imageUrl',
          maxImages: 1,
          single: true,
          build: (up, src) => LostItemFormSheet(
                userId: 'u1',
                userName: 'أحمد',
                service: LostItemService(fake),
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('حقل الصور الطبي (حتى 3)', (tester) async {
      await runScreen(tester,
          body: true,
          fieldKey: 'medicalImages',
          maxImages: 3,
          build: (up, src) => MedicalImageField(
                maxImages: 3,
                onChanged: (_) {},
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('حقل سوق المحلات/الطلبات/التبرع (حتى 3)', (tester) async {
      await runScreen(tester,
          body: true,
          fieldKey: 'marketImages',
          maxImages: 3,
          build: (up, src) => MarketImageField(
                maxImages: 3,
                onChanged: (_) {},
                uploader: up,
                bytesSource: src,
              ));
    });

    testWidgets('الحقل الطبي المفرد (صورة سجل واحدة)', (tester) async {
      await runScreen(tester,
          body: true,
          fieldKey: 'medicalImages',
          maxImages: 1,
          single: true,
          build: (up, src) => MedicalImageField(
                maxImages: 1,
                onChanged: (_) {},
                uploader: up,
                bytesSource: src,
              ));
    });
  });

  group('عقد المصدر — المحرّر المشترك مساره الوحيد', () {
    test('(٢) كل نموذج إضافة محتوى يركّب ImageListEditor', () {
      for (final path in kContentForms) {
        final src = _read(path);
        expect(src, contains('ImageListEditor('), reason: path);
        expect(src, isNot(contains('ImagePicker(')),
            reason: '$path — لا رافع خاص به بجانب المحرّر المشترك');
      }
    });

    test('(٢) الرافعات الخاصة محصورة في قائمة معروفة', () {
      final strays = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll('\\', '/');
        // المحرّر نفسه يستعمل المعرض — هذا موضعه الصحيح.
        if (path.endsWith('widgets/document_field_editor.dart')) continue;
        if (_read(path).contains('ImagePicker(')) strays.add(path);
      }
      expect(
        strays.toSet(),
        {
          // صور شخصية/إدارية أحادية لا تحتاج مصغّرات ولا حدّ صور:
          'lib/features/admin/admin_dashboard_promos.dart', // صورة الإعلان
          'lib/features/auth/complete_profile.dart', // أفاتار المستخدم
          'lib/features/profile/main.dart', // أفاتار المستخدم
          'lib/features/obituaries/add.dart', // صورة المتوفى + خلفية البطاقة
          'lib/features/village/village_content_admin.dart', // مُضيف `pickAndUploadImage`
        }.toSet(),
        reason: 'أي رافع خاص جديد في نموذج محتوى يعني انقسام المحرّر مرة أخرى',
      );
    });

    test('(٣) صور متعددة تُعرض عبر FullFitImage لا باقتصاص', () {
      final wrap = _read('lib/widgets/image_gallery_wrap.dart');
      expect(wrap, contains('FullFitImage('),
          reason: 'الوست المشترك نفسه هو من يقاس');
      for (final path in [
        'lib/features/market/product_detail.dart',
        'lib/features/market/market_tab_shops.dart',
        'lib/features/market/seller_gallery.dart',
        'lib/features/medical/clinic_detail_screen.dart',
        'lib/features/medical/optical_shop_detail_screen.dart',
        'lib/features/admin/admin_detail.dart',
        'lib/features/village/village_institutions_screen.dart',
      ]) {
        expect(_read(path), contains('ImageGalleryWrap('), reason: path);
      }
      // شريط الطلبات/التبرّعات `PageView` فلا يلتفّ، لكنه يقيس نفس النسب.
      expect(_read('lib/features/market/market_tab_buy_donate.dart'),
          contains('FullFitImage.measure('));
    });

    test('(٤) مفتاح الحذف يُستخرج من الرابط فقط، والمسار القديم يمر بلا حذف',
        () {
      final service = ImageUploadService();
      expect(service.extractDeleteKey('https://i.ibb.co/x/a.jpg?delete_key=k9'),
          'k9');
      expect(service.extractDeleteKey('https://i.ibb.co/x/a.jpg'), isNull,
          reason: 'السجل القديم بلا delete_url يبقى كما هو ولا يُرمى طلب');
      expect(service.extractDeleteKey(''), isNull);
    });

    test('(٤) حذف المستند يزيل الروابط وينادي deleteImage لكل رابط', () {
      // مسار الأدمن الخاص به، ومسار المالك المشترك عبر OwnerContentService.
      for (final path in [
        'lib/services/admin_service.dart',
        'lib/services/owner_content_service.dart',
      ]) {
        final src = _read(path);
        expect(src, contains('deleteImage(url'), reason: path);
        expect(src, contains('for (final url in'), reason: path);
      }
      expect(_read('lib/services/market_service.dart'),
          contains('OwnerContentService.remove(_firestore, \'market_products\''),
          reason: 'حذف البائع لمنتجه يمرّ بالتنظيف المشترك لا نسخة ثانية');
      // زرّ المحرّر يقلّص القائمة التي تصل النموذج — فيُكتب المستند بلا الرابط.
      final editor = _read('lib/widgets/document_field_editor.dart');
      expect(editor, contains('..removeAt(i)'));
      expect(editor, contains('widget.onChanged('));
    });

    test('(٥) حدّ الصور في السوق مشتق من نوع البائع وحده', () {
      final add = _read('lib/features/market/add_product.dart');
      expect(add, contains('_sellerType.maxImages'),
          reason: 'لا رقم ثابت هنا — السلّم في SellerType');
      expect(_read('lib/models/data_models_content.dart'),
          contains('final int maxImages;'));
      expect(add, isNot(contains('maxImages: 5')),
          reason: 'تعداد ثابت يعني حدًّا لا يتبع ترقية البائع');
    });
  });
}

/// نماذج إضافة المحتوى التي يجب أن تركّب المحرّر المشترك (البند ٧ / ٢).
const List<String> kContentForms = [
  'lib/features/market/add_product.dart',
  'lib/features/market/market_tabs_screen.dart',
  'lib/features/news/add.dart',
  'lib/features/medical/medical_home_screen.dart',
  'lib/features/services/service_directory_screen.dart',
  'lib/features/services/lost_items_screen.dart',
  'lib/features/occasions/add.dart',
  'lib/features/phone/add_directory.dart',
  'lib/features/forum/create_post.dart',
  'lib/features/ads/village_ads_screen.dart',
  'lib/features/legal/legal_advisor_screen.dart',
];

String _read(String path) => File(path).readAsStringSync();

/// رافع وهمي: رابط مختلف لكل نداء حتى يُرى الاستبدال لا مجرّد وجود صورة.
class _Uploader implements ImageUploadService {
  _Uploader({this.fail = false});
  final bool fail;
  int calls = 0;

  @override
  Future<String> uploadImage(Uint8List bytes) async {
    calls++;
    if (fail) throw Exception('لم يرجع الخدمة رابط الصورة');
    return 'https://cdn.test/up$calls.jpg';
  }

  @override
  String? extractDeleteKey(String imageUrl) => null;

  @override
  Future<void> deleteImage(String imageUrl) async {}
}

/// مصدر بايتات بلا معرض جهاز: صورة واحدة لكل نقرة على «رفع صورة».
ImageBytesSource get _bytes =>
    (remaining) async => [Uint8List.fromList([1, 2, 3])];
