import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/market_extra_models.dart';
import 'package:qurity/services/admin_service.dart';
import 'package:qurity/services/buy_request_service.dart';
import 'package:qurity/services/cache_service.dart';
import 'package:qurity/services/donation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String src(String path) => File(path).readAsStringSync();

/// يُسقط تعليقات الأسطر ليبقى الكود وحده: التعليقات في خدمتَي «مطلوب / تبرعات»
/// تسمّي مرشّح الحالة نهيًا عنها، فمسح النص كاملًا كان يثبّت ما ينفيه.
String stripComments(String text) => text
    .split('\n')
    .map((line) {
      final cut = line.indexOf('//');
      return cut < 0 ? line : line.substring(0, cut);
    })
    .join('\n');

/// يقطع جسم دالة من **نص** مصدري إلى أول سطر يبدأ بالوسم التالي (بإزاحة العضو
/// الاعتيادية: سطرين). العقد سطر واحد لأن ملفات المستودع CRLF، فأي `contains`
/// متعدد الأسطر لا يطابق.
String bodyOf(String text, String signature, String nextMarker) {
  final start = text.indexOf(signature);
  expect(start, isNonNegative, reason: 'لا وجود لـ$signature');
  final rest = text.substring(start + signature.length);
  final end = rest.indexOf('\n  $nextMarker');
  expect(end, isNonNegative, reason: 'لا حدّ لـ$signature بعد $nextMarker');
  return rest.substring(0, end);
}

/// النسخة التي تأخذ مسارًا بدل النص.
String body(String file, String signature, String nextMarker) =>
    bodyOf(src(file), signature, nextMarker);

/// يقطع حالة `case` داخل `switch` مُزاح ستة أسطر (محرّر وثائق الإدارة)، لأن
/// مُقطع الأعضاء بسطرين لا يطابق أبدًا داخله.
String caseBlock(String text, String collection) {
  final head = "\n      case '$collection':";
  final start = text.indexOf(head);
  expect(start, isNonNegative, reason: 'لا حالة لـ$collection');
  final rest = text.substring(start + head.length);
  final end = rest.indexOf(RegExp(r"\n      (?:case '|default:)"));
  expect(end, isNonNegative, reason: 'لا نهاية لحالة $collection');
  return rest.substring(0, end);
}

/// كتلة مجموعة في القواعد، مقصوصة إلى إبراز إغلاقها نفسه لا إلى نافذة بايتات:
/// النافذة الثابتة كانت تتجاوز الكتلة إلى جارتها فتمرّ الإجابات على نصّها.
String rulesBlock(String collection) {
  final rules = src('firestore.rules');
  final head = 'match /$collection/{docId}';
  final start = rules.indexOf(head);
  expect(start, isNonNegative, reason: 'لا كتلة لـ$collection في القواعد');
  final rest = rules.substring(start);
  final end = rest.indexOf('\n    }');
  expect(end, isNonNegative, reason: 'لا إغلاق لكتلة $collection');
  return rest.substring(0, end);
}

/// خريطة مجموعة → موضوع FCM، وهي عمود صفر فتُقطع إلى `};` التالي مباشرة.
String pushTopicMap() {
  final text = src('lib/services/remote_push_service.dart');
  const head = 'kPushTopicForCollection = {';
  final start = text.indexOf(head);
  expect(start, isNonNegative, reason: 'لا خريطة مواضيع');
  final rest = text.substring(start);
  final end = rest.indexOf('\n};');
  expect(end, isNonNegative, reason: 'لا إغلاق لخريطة المواضيع');
  return rest.substring(0, end);
}

/// `fake_cloud_firestore` لا يقبل `FieldValue.serverTimestamp()` الخام في
/// `add`/`set` (يرمي `MockFieldValuePlatform` في الكتابة)، فالكتابة الاختبارية
/// تحمل تاريخًا حقيقيًا؛ وسلوك الإرسال الخادمي عند غاب التاريخ مثبّت في Dart
/// وحده أسفل دون تمريره بالقاعدة الوهمية.
final _seedAt = DateTime(2026);

BuyRequest req(
        {String id = '',
        String userId = 'u1',
        String title = 'طمّام',
        bool approved = false,
        DateTime? at}) =>
    BuyRequest(
      id: id,
      userId: userId,
      userName: 'بائع القرية',
      title: title,
      details: 'من السوق',
      budget: '100',
      isApproved: approved,
      createdAt: at ?? _seedAt,
    );

Donation don(
        {String id = '',
        String userId = 'u1',
        String title = 'بطانية',
        bool approved = false,
        DateTime? at}) =>
    Donation(
      id: id,
      userId: userId,
      userName: 'بائع القرية',
      title: title,
      description: 'حالة جيدة',
      contactPhone: '01000000000',
      isApproved: approved,
      createdAt: at ?? _seedAt,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('الحقل موجود ويصل معلّقًا', () {
    test('كل إضافة تبدأ غير معتمدة والحقل يُكتب في المستند', () {
      expect(req().isApproved, false);
      expect(don().isApproved, false);
      expect(req().toJson()['isApproved'], false);
      expect(don().toJson()['isApproved'], false);
    });

    test('سجل قديم بلا الحقل يبقى ظاهرًا كما كان', () {
      final legacy =
          BuyRequest.fromJson({'title': 'قديم', 'status': 'open'}, 'x');
      expect(legacy.isApproved, true,
          reason: 'لا يُخفى عن السوق ما كان منشورًا قبل البوابة');
      final legacyDon =
          Donation.fromJson({'title': 'قديم', 'status': 'available'}, 'x');
      expect(legacyDon.isApproved, true);
    });

    test('تاريخ غائب يُترك للخادم، لا يُختلق في الكلاينت', () {
      final bare = const BuyRequest(
          id: 'x', userId: 'u1', userName: 'بائع', title: 'سلعة');
      final bareDon = const Donation(
          id: 'x', userId: 'u1', userName: 'بائع', title: 'بطانية');
      expect(bare.toJson()['createdAt'], isA<FieldValue>(),
          reason: 'إرسال الخادم يبقى وحده مصدر وقت الإنشاء');
      expect(bareDon.toJson()['createdAt'], isA<FieldValue>());
      expect(
          req(at: _seedAt).toJson()['createdAt'], isNot(isA<FieldValue>()));
    });

    test('الإضافة من الجهاز لا تملك وجه إمرار اعتماد', () async {
      final fs = FakeFirebaseFirestore();
      await BuyRequestService(fs).create(req(title: 'مروحة', approved: true));
      final snap = await fs.collection('buy_requests').get();
      expect(snap.docs.single.data()['isApproved'], false,
          reason: 'الاعتماد قرار إداري لا كتابة من الجهاز');

      await DonationService(fs).create(don(title: 'كرسي', approved: true));
      final d = await fs.collection('donations').get();
      expect(d.docs.single.data()['isApproved'], false);
    });
  });

  group('البوابة في طبقة القراءة، لا في الاستعلام', () {
    test('السوق يرى المعتمد، وصاحب الإضافة يرى معلّقه وحده', () {
      final items = [
        req(title: 'معتمد', approved: true),
        req(title: 'معلّق لي'),
        req(title: 'معلّق لغيري', userId: 'u2'),
      ];
      expect(
          BuyRequestService.visibleToViewer(items, 'u1').map((r) => r.title),
          ['معتمد', 'معلّق لي']);
      expect(
          BuyRequestService.visibleToViewer(items, 'u2').map((r) => r.title),
          ['معتمد', 'معلّق لغيري']);
      expect(BuyRequestService.visibleToViewer(items, null).map((r) => r.title),
          ['معتمد'],
          reason: 'التصفية في الكلاينت: Firestore يُسقط أي وثيقة بلا الحقل');
      expect(BuyRequestService.visibleToViewer(items, '').map((r) => r.title),
          ['معتمد'], reason: 'معرّف فارغ ليس مالكًا');
    });

    test('نفس البوابة للتبرعات', () {
      final items = [
        don(title: 'معتمد', approved: true),
        don(title: 'معلّق لي'),
        don(title: 'معلّق لغيري', userId: 'u2'),
      ];
      expect(DonationService.visibleToViewer(items, 'u1').map((d) => d.title),
          ['معتمد', 'معلّق لي']);
      expect(
          DonationService.visibleToViewer(items, null).map((d) => d.title),
          ['معتمد']);
    });

    test('لا شرط اعتماد على الخادم في أي من الخدمتين', () {
      for (final file in [
        'lib/services/buy_request_service.dart',
        'lib/services/donation_service.dart',
      ]) {
        expect(src(file), isNot(contains("where('isApproved'")),
            reason: 'قيد على حقل قد يغيب يُسقط السجل صامتًا');
      }
    });

    test('بعد قرار الإدارة يظهر في السوق، ومعلّق لا يظهر لغير صاحبه', () async {
      final fs = FakeFirebaseFirestore();
      final svc = BuyRequestService(fs);
      final id = await svc.create(req(title: 'سقف'));
      await fs
          .collection('buy_requests')
          .add(req(title: 'معتمد', approved: true).toJson());

      expect((await svc.getOpenRequests(forceRefresh: true)).map((r) => r.title),
          ['معتمد']);

      await fs.collection('buy_requests').doc(id).update({'isApproved': true});
      expect(
          (await svc.getOpenRequests(forceRefresh: true))
              .map((r) => r.title)
              .toSet(),
          {'سقف', 'معتمد'});

      final dsvc = DonationService(fs);
      final did = await dsvc.create(don(title: 'فرشة'));
      await fs
          .collection('donations')
          .add(don(title: 'مصباح', approved: true).toJson());
      expect(
          (await dsvc.getAvailableDonations(forceRefresh: true))
              .map((d) => d.title),
          ['مصباح']);
      await fs.collection('donations').doc(did).update({'isApproved': true});
      expect(
          (await dsvc.getAvailableDonations(forceRefresh: true))
              .map((d) => d.title)
              .toSet(),
          {'فرشة', 'مصباح'});
    });

    test('الكاش يخزن كاملة لا مرشّحًا، ويقرأ بنفس بوابة الخادم', () async {
      final fs = FakeFirebaseFirestore();
      final svc = BuyRequestService(fs);
      await svc.create(req(title: 'معلّق'));
      await fs
          .collection('buy_requests')
          .add(req(title: 'معتمد', approved: true).toJson());

      final fromServer = (await svc.getOpenRequests(forceRefresh: true))
          .map((r) => r.title)
          .toList();
      expect(fromServer, ['معتمد'], reason: 'الزائر لا يرى المعلّق');

      final blob = await CacheService.getBuyRequests();
      expect(blob!.length, 2,
          reason: 'الوعاء الخام يبقى كاملًا وإلا ضاع معلّق صاحبه عند أول كاش');

      final fromCache =
          (await svc.getOpenRequests()).map((r) => r.title).toList();
      expect(fromCache, fromServer, reason: 'فرعا القراءة يُرجعان المجموعة نفسها');
    });

    test('طلباتي ترى كل الحالات، فلا يختفي معلّق صاحبه', () async {
      final fs = FakeFirebaseFirestore();
      final svc = BuyRequestService(fs);
      await svc.create(req(title: 'معلّق'));
      await fs
          .collection('buy_requests')
          .add(req(title: 'معتمد', approved: true).toJson());
      final mine = await svc.getMyRequestsStream('u1').first;
      expect(mine.map((r) => r.title).toSet(), {'معلّق', 'معتمد'});
    });

    test('الترتيب الأحدث أولًا حيًّا كان التاريخ أو غاب', () async {
      final fs = FakeFirebaseFirestore();
      await fs
          .collection('buy_requests')
          .add(req(title: 'قدم', approved: true, at: DateTime(2026)).toJson());
      await fs.collection('buy_requests').add(
          req(title: 'حديث', approved: true, at: DateTime(2026, 9)).toJson());
      final docs = await fs.collection('buy_requests').get();
      final items = docs.docs
          .map((d) => BuyRequest.fromJson(d.data(), d.id))
          .where((r) => r.isApproved)
          .toList()
        ..sort((a, b) =>
            (b.createdAt ?? DateTime(1970)).compareTo(
                a.createdAt ?? DateTime(1970)));
      expect(items.map((r) => r.title).toList(), ['حديث', 'قدم']);
    });
  });

  group('لوحة الإدارة: عدّ ومفاتيح وتسميات', () {
    test('العدّ المعلّق يصل عبر fetchPendingCounts', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('buy_requests').add(req(title: 'معلّق').toJson());
      await fs
          .collection('donations')
          .add(don(title: 'أ').toJson());
      await fs
          .collection('donations')
          .add(don(title: 'ب').toJson());
      await fs
          .collection('donations')
          .add(don(title: 'ج', approved: true).toJson());

      final counts =
          await AdminService.withFirestore(fs).fetchPendingCounts();
      expect(counts['buy_requests'], 1);
      expect(counts['donations'], 2, reason: 'المعتمد لا يُعَدّ معلّقًا');
    });

    test('إحصاءات اللوحة فيها المفتاحان', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('buy_requests').add(req(title: 'أ').toJson());
      await fs.collection('donations').add(don(title: 'ب').toJson());
      final stats = await AdminService.withFirestore(fs).getStatistics();
      expect(stats.containsKey('buy_requests'), true);
      expect(stats.containsKey('donations'), true);
    });

    test('شرحا المراجعة موجودان كمجموعتين حقيقيتين', () {
      final dash = src('lib/features/admin/admin_dashboard.dart');
      expect(dash,
          contains("_Cat('buy_requests', 'المطلوب', Icons.request_quote_rounded"));
      expect(dash,
          contains("_Cat('donations', 'التبرعات', Icons.redeem_rounded"));
      expect(dash, isNot(contains("source: 'buy_requests'")),
          reason: 'تبويب عرض على مجموعة أخرى كان سيصنع صفًّا ثانٍ للكتابة');
      expect(dash, isNot(contains("source: 'donations'")));
    });

    test('أيقونتا المجموعتين وتسميتاهما في صفحة التفاصيل', () {
      final detail = src('lib/features/admin/admin_detail.dart');
      expect(detail, contains("case 'buy_requests':"));
      expect(detail, contains('return Icons.request_quote_rounded;'));
      expect(detail, contains('return Icons.redeem_rounded;'),
          reason: 'لا تكرار أيقونة مع قسم آخر');
      expect(detail, contains("return 'طلب شراء (مطلوب)';"));
      expect(detail, contains("return 'تبرع بسلعة';"));
      expect(detail, isNot(contains("'طلب شراء (مطلوب) في السوق'")),
          reason: 'هذه التسمية في وصف بطاقة المراجعة لا هنا');
    });

    test('وصف الإجراء في القائمة الموحّدة يسمّي القسمين', () {
      final review = src('lib/features/admin/admin_dashboard_review.dart');
      expect(review, contains("'buy_requests' => 'طلب شراء (مطلوب) في السوق'"));
      expect(review, contains("'donations' => 'تبرع بسلعة في السوق'"));
    });

    test('رسالة الإدارة وتسميات الحقول والمسار', () {
      final svc = src('lib/services/admin_service.dart');
      expect(svc, contains("=> ('🛍️ طلب شراء جديد (مطلوب)', preview, '/market')"));
      expect(svc, contains("=> ('🎁 تبرع جديد في السوق', preview, '/market')"));
      expect(svc, contains("'buy_requests': 'userId'"));
      expect(svc, contains("'donations': 'userId'"));
    });

    test('لا بثّ قرية-wide لاعتماد هذين القسمين', () {
      final map = pushTopicMap();
      expect(map, isNot(contains("'buy_requests'")),
          reason: 'بثّ قرية-wide لكل طلب كان قرار رقابة لم يُطلب');
      expect(map, isNot(contains("'donations'")));
    });

    test('تفريغ الكاش يستعمل المفتاحين بعد القرار', () {
      final invalidate = body('lib/services/admin_service.dart',
          'void _invalidateContentCache', 'Future<void> _logActivity');
      expect(invalidate, contains("collection == 'buy_requests'"));
      expect(invalidate, contains('CacheService.invalidateBuyRequests()'));
      expect(invalidate, contains("collection == 'donations'"));
      expect(invalidate, contains('CacheService.invalidateDonations()'));
    });

    test('عدّ المعلّقات يقرأ المجموعتين وحقنه في المفاتيح', () {
      final fetch = body('lib/services/admin_service.dart',
          'Future<Map<String, int>> fetchPendingCounts', '///');
      expect(fetch, contains("_pendingCountOnce('buy_requests')"));
      expect(fetch, contains("_pendingCountOnce('donations')"));
      expect(fetch, contains("'buy_requests': results["));
      expect(fetch, contains("'donations': results["));
      final stats = body('lib/services/admin_service.dart',
          'Future<Map<String, int>> getStatistics',
          'Future<int> getActiveUsersCount');
      expect(stats, contains("'buy_requests',"));
      expect(stats, contains("'donations',"));
    });

    test('بطاقة المنتجات في التقارير تقرأ المفتاح الحقيقي', () {
      final reports = src('lib/features/admin/admin_dashboard_reports.dart');
      expect(reports, contains("stats['market_products']"),
          reason: 'كانت تقرأ مفتاحًا لا يولده getStatistics فتطبع صفرًا أبدًا');
      expect(reports, isNot(contains("stats['products']")));
      expect(reports, contains("stats['buy_requests']"));
      expect(reports, contains("stats['donations']"));
    });

    test('لا نموذج مراجعة ثانٍ: نفس المجموعات في المحرر والتفاصيل', () {
      final edit = src('lib/features/admin/admin_edit.dart');
      expect(caseBlock(edit, 'buy_requests'), isNot(contains('isApproved')),
          reason: 'الاعتماد قرار من شاشة المراجعة لا حقل خام في المحرر');
      expect(caseBlock(edit, 'donations'), isNot(contains('isApproved')));
      expect(caseBlock(edit, 'buy_requests'), contains("DocFieldSpec('title'"));
      expect(caseBlock(edit, 'donations'), contains("DocFieldSpec('title'"));
    });

    test('الواجهة تُبقي المعلّق ظاهرًا لصاحبه بشارة صادقة', () {
      final tab = src('lib/features/market/market_tab_buy_donate.dart');
      expect(tab, contains('BuyRequestService.visibleToViewer('));
      expect(tab, contains('DonationService.visibleToViewer('));
      expect(tab, contains("'طلبك • بانتظار موافقة الإدارة'"));
      expect(tab, contains("'تبرعك • بانتظار موافقة الإدارة'"));
      expect(tab, contains("'بانتظار موافقة الإدارة'"));
    });
  });

  group('السجل الذي بلا الحقل يبقى قابلًا للقرار', () {
    /// وثيقة كُتبت قبل بوابة الاعتماد: لا تحمل `isApproved` إطلاقًا. كانت
    /// استعلامات اللوحة (`where isEqualTo: false`) تُسقطها صامتة فلا تصل
    /// للمراجعة أبدًا، بينما يقرأها النموذج `true` فتظهر في السوق.
    Future<void> seedLegacy(FirebaseFirestore fs, String collection,
        String title, String status) async {
      await fs.collection(collection).add({
        'title': title,
        'status': status,
        'userId': 'u9',
        'userName': 'مصري القرية',
        'createdAt': Timestamp.fromDate(_seedAt),
      });
    }

    test('طابور المراجعة يرى المعلّق بلا حقل ويخرج بعد الاعتماد', () async {
      final fs = FakeFirebaseFirestore();
      await seedLegacy(fs, 'buy_requests', 'طمّام قديم', 'open');
      await seedLegacy(fs, 'donations', 'بطانية قديمة', 'available');
      final admin = AdminService.withFirestore(fs);

      final pendingBuy =
          await admin.itemsStream('buy_requests', pendingOnly: true).first;
      expect(pendingBuy, hasLength(1),
          reason: 'غياب الحقل كان يُسقط الوثيقة من الاستعلام المرتَّب عليها');
      expect(pendingBuy.single['title'], 'طمّام قديم');

      final counts = await admin.fetchPendingCounts();
      expect(counts['buy_requests'], 1);
      expect(counts['donations'], 1);

      // كل انبعاثة تُطلقها مجموعةٌ وصول بياناتها، فلا تُقرأ القائمة الموحّدة
      // من أولها — اللوحة تستمع حيًّا فترى المجموعتين في الانبعاثة الأخيرة.
      final emissions = <List<Map<String, dynamic>>>[];
      final mergedSub =
          admin.allPendingStream(['buy_requests', 'donations']).listen(
              emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await mergedSub.cancel();
      expect(emissions, isNotEmpty);
      expect(emissions.last, hasLength(2),
          reason: 'المجموعتان تُجمعان في قائمة واحدة بلا استعلام '
              'مرتَّب على حقل قد يغيب');
      expect(emissions.last.map((e) => e['_collection']).toSet(),
          {'buy_requests', 'donations'});

      await fs
          .collection('buy_requests')
          .doc(pendingBuy.single['id'] as String)
          .update({'isApproved': true});
      expect(
          await admin.itemsStream('buy_requests', pendingOnly: true).first,
          isEmpty);
      expect((await admin.fetchPendingCounts())['buy_requests'], 0);
    });

    test('سجل بلا حقل: ظاهرٌ في السوق ومنتظرٌ قرارًا في اللوحة', () async {
      final fs = FakeFirebaseFirestore();
      await seedLegacy(fs, 'buy_requests', 'طمّام قديم', 'open');
      final visible = await BuyRequestService(fs).getOpenRequestsStream().first;
      expect(visible, hasLength(1),
          reason: 'البوابة العامة تقرأ الغائب معتمدًا حتى لا تختفي إضافات '
              'القرية دفعةً واحدة، واللوحة تطلب له قرارًا — فرق مقصود');
      expect(
          await AdminService.withFirestore(fs)
              .itemsStream('buy_requests', pendingOnly: true)
              .first,
          hasLength(1));
    });

    test('الستريم نفسه يكتب الكاش: فرع offline لا يكون فارغًا', () async {
      final fs = FakeFirebaseFirestore();
      await fs
          .collection('buy_requests')
          .add(req(title: 'مروحة معلّقة').toJson());
      await fs
          .collection('buy_requests')
          .add(req(title: 'كمامة معتمدة', approved: true).toJson());

      final visible = await BuyRequestService(fs).getOpenRequestsStream().first;
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final cached = await CacheService.getBuyRequests();
      expect(cached, isNotNull,
          reason: 'كانت writers الكاش لا تُنادى من أي مسار حيّ');
      expect(cached!.map((e) => e['title']).toSet(),
          {'مروحة معلّقة', 'كمامة معتمدة'},
          reason: 'الكتالوج كاملًا لا المرشَّح، وإلا جفّ كل قارئ آخر');
      expect(visible.map((e) => e.title), ['كمامة معتمدة'],
          reason: 'التصفية تبقى طبقة عرض بعد الكاش');
    });

    test('تبرعات: نفس الكتابة الكاشية من الستريم', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('donations').add(don(title: 'بطانية معلّقة').toJson());
      await fs
          .collection('donations')
          .add(don(title: 'فرشة معتمدة', approved: true).toJson());

      final visible =
          await DonationService(fs).getAvailableDonationsStream().first;
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final cached = await CacheService.getDonations();
      expect(cached, isNotNull);
      expect(cached!.map((e) => e['title']).toSet(),
          {'بطانية معلّقة', 'فرشة معتمدة'});
      expect(visible.map((e) => e.title), ['فرشة معتمدة']);
    });
  });

  group('عقد المصدر: الفرز الكلاينت للمعلّق', () {
    test('المجموعتان المحجوزتان للفرز الكلاينت هما هاتان فقط', () {
      final admin = src('lib/services/admin_service.dart');
      final decl = bodyOf(admin,
          'static const Set<String> _clientFilteredPending = {',
          'static bool _isPendingDoc');
      expect(decl, contains("'buy_requests'"));
      expect(decl, contains("'donations'"));
      expect(RegExp("'[a-z_]+',").allMatches(decl).length, 2,
          reason: 'لا مجموعة مراجعة أخرى تُنقل إلى الكلاينت بغير قياس');
      expect(admin, contains("data['isApproved'] != true"),
          reason: 'الحالة الوحيدة التي تجعل بلا-حقل معلّقًا لا معتمدًا');
    });

    test('الستريم والعدّ كلاهما يمرّ بالمجموعة كاملة', () {
      final admin = src('lib/services/admin_service.dart');
      final stream = bodyOf(admin,
          'Stream<List<Map<String, dynamic>>> _pendingStream(String collection) {',
          'Stream<List<Map<String, dynamic>>> _approvedStream');
      expect(stream, contains('_allStream(collection)'));
      expect(stream, contains('where(_isPendingDoc)'),
          reason: 'الفرع الكلاينت هو وحده من يرى بلا-حقل معلّقًا');
      expect(stream, contains('_clientFilteredPending.contains(collection)'),
          reason: 'فرع الخادم يبقى لبقية المجموعات كما كان');

      final count = bodyOf(admin, 'Future<int> _pendingCountOnce(',
          'Stream<List<Map<String, dynamic>>> getPendingNewsStream');
      expect(count, contains('_clientFilteredPending.contains(collection)'));
      expect(count, contains('.count()'),
          reason: 'بقية المجموعات يبقى عدّها aggregation رخيصًا');
    });

    test('كتابات الكاش موصولة بمسار الستريم الحيّ، لا بالمرة الواحدة', () {
      final buy = bodyOf(
          src('lib/services/buy_request_service.dart'),
          'Stream<List<BuyRequest>> getOpenRequestsStream() {',
          'Stream<List<BuyRequest>> getMyRequestsStream');
      final don = bodyOf(
          src('lib/services/donation_service.dart'),
          'Stream<List<Donation>> getAvailableDonationsStream() {',
          'Stream<List<Donation>> getMyDonationsStream');
      expect(buy, contains('CacheService.saveBuyRequests('));
      expect(don, contains('CacheService.saveDonations('));
      expect(buy, contains('unawaited('),
          reason: 'الكتابة الكاشية لا تُنتظر قبل تسليم القائمة للواجهة');
      expect(don, contains('unawaited('));
    });
  });

  group('قواعد Firestore', () {
    test('الإنشاء يبدأ غير معتمد ومن صاحبه، في المجموعتين', () {
      for (final c in ['buy_requests', 'donations']) {
        final block = rulesBlock(c);
        expect(block, contains('request.resource.data.isApproved == false'));
        expect(block,
            contains('request.auth.uid == request.resource.data.userId'));
      }
    });

    test('المالك: حالته فقط، أو اسمه المطبّق، أو تعديل كامل يعيده للمراجعة', () {
      for (final c in ['buy_requests', 'donations']) {
        final block = rulesBlock(c);
        expect(block, contains(".affectedKeys().hasOnly(['status'])"));
        expect(block, contains(".affectedKeys().hasOnly(['userName'])"),
            reason: 'user_service تزامن اسم صاحب المحتوى من ملفه');
        expect(block, contains('ownerEdit(resource.data.userId'));
        expect(block, contains('ownerDelete(resource.data.userId)'));
      }
    });

    test('لا كتابة مالكية مفتوحة: بوابتان على الاعتماد ومالك محروس', () {
      for (final c in ['buy_requests', 'donations']) {
        final block = rulesBlock(c);
        final update = block.substring(block.indexOf('allow update'));
        final uptoDelete =
            update.substring(0, update.indexOf('allow delete'));
        expect(uptoDelete.contains('isAdmin()'), true);
        expect(RegExp(r'accountActive\(\)').allMatches(uptoDelete).length, 2,
            reason: 'فرعا المالك المقيّدان فقط؛ ownerEdit يحرس اعتماده بنفسه');
        expect(block, isNot(contains('allow update: if true')));
        expect(block, isNot(contains('allow update: if isSignedIn()')));
      }
    });

    test('الكتلتان محكومتان ولا تتسربان إلى جارتها', () {
      final buy = rulesBlock('buy_requests');
      expect(buy, isNot(contains('match /donations/{docId}')),
          reason: 'القصّ بالنافذة الثابتة كان يبتلع الكتلة التالية');
      expect(buy.contains('allow create'), true);
      expect(buy.contains('allow delete'), true);
    });
  });

  group('قراءة التبويب بعد الاعتماد: الحالة كلاينتًا والكاش ملاذًا', () {
    test('معتمد بلا حقل الحالة يصل إلى السوق، والمغلق وحده يُخفى', () async {
      final fs = FakeFirebaseFirestore();
      final bare = <String, dynamic>{
        ...req(title: 'بلا حالة', approved: true).toJson(),
      }..remove('status');
      await fs.collection('buy_requests').add(bare);
      await fs.collection('buy_requests').add(<String, dynamic>{
        ...req(title: 'مغلق', approved: true).toJson(),
        'status': 'closed',
      });

      final open = await BuyRequestService(fs).getOpenRequests(
          forceRefresh: true);
      expect(open.map((r) => r.title), ['بلا حالة'],
          reason: 'غياب الحالة يعني «مفتوح» إرثيًا، فلا يُعاقب السجل بالاختفاء');
      expect(bare.containsKey('status'), false);
    });

    test('نفس القراءة للتبرعات: بلا حالة = معروضة، ومنتهية = مخفية', () async {
      final fs = FakeFirebaseFirestore();
      final bare = <String, dynamic>{
        ...don(title: 'بلا حالة', approved: true).toJson(),
      }..remove('status');
      await fs.collection('donations').add(bare);
      await fs.collection('donations').add(<String, dynamic>{
        ...don(title: 'تُبرع بها', approved: true).toJson(),
        'status': 'donated',
      });

      final open = await DonationService(fs).getAvailableDonations(
          forceRefresh: true);
      expect(open.map((d) => d.title), ['بلا حالة']);
    });

    test('الستريم نفسه يقرأ المجموعة كاملة ثم يفرز كلاينتًا', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('buy_requests').add(<String, dynamic>{
        ...req(title: 'بلا حالة', approved: true).toJson(),
      }..remove('status'));

      final seen = await BuyRequestService(fs).getOpenRequestsStream().first;
      expect(seen.map((r) => r.title), ['بلا حالة']);

      final donSeen = await DonationService(fs)
          .getAvailableDonationsStream()
          .first;
      expect(donSeen, isEmpty, reason: 'المجموعة خالية فلا قائمة مفبركة');
    });

    test('كود الخدمة لا يذكر مرشّح الحالة على الخادم في أي من المجموعتين', () {
      for (final file in [
        'lib/services/buy_request_service.dart',
        'lib/services/donation_service.dart',
      ]) {
        final code = stripComments(src(file));
        expect(code, isNot(contains("where('status'")),
            reason: 'مساواة على حقل قد يغيب تُسقط الوثيقة صامتًا فتغيب عن '
                'التبويب بينما اللوحة الحيّة تقرأ المجموعة كاملة');
        expect(code, contains('_col.snapshots()'));
        expect(code, contains('_col.get()'));
      }
    });

    test('التبويبان يقرأان الستريم أولًا ولا يستسلمان للراية العالقة', () {
      final tab = src('lib/features/market/market_tab_buy_donate.dart');
      expect(RegExp('cacheFirst: false').allMatches(tab).length, 2,
          reason: 'موضعان فقط في الملف: «مطلوب» و«تبرعات»');
      for (final marker in [
        'OfflineStreamBuilder<List<BuyRequest>>(',
        'OfflineStreamBuilder<List<Donation>>(',
      ]) {
        final from = tab.indexOf(marker);
        expect(from, isNonNegative, reason: 'لا وجود لـ$marker');
        final body = tab.substring(from);
        expect(body.indexOf('cacheFirst: false'), lessThan(
            body.indexOf('onlineBuilder:')),
            reason: 'الوسيط يجب أن يسبق الفرعين ليطبّق عليهما');
      }
    });

    test('فرع cacheFirst=false لا يستشير الشبكة أبدًا', () {
      final w = src('lib/widgets/offline_stream_builder.dart');
      final start = w.indexOf('if (!widget.cacheFirst) {');
      expect(start, isNonNegative);
      final branch =
          w.substring(start, w.indexOf('return StreamBuilder<bool>(', start));
      expect(branch, contains('StreamBuilder<T>('));
      expect(branch, isNot(contains('ConnectivityManager')),
          reason: 'لا بوابة اتصال تُعلَق فتُرسم لقطة أقدم من قرار الإدارة');
      expect(branch, isNot(contains('cacheBuilder(')),
          reason: 'الكاش يبقى ملاذ ما قبل أول انبعاثة داخل _onlineView');
    });
  });
}
