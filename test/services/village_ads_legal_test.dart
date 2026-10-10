import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/legal_reference_egypt.dart';
import 'package:qurity/core/constants/promo_placements.dart';
import 'package:qurity/models/legal_models.dart';
import 'package:qurity/models/village_ad_model.dart';
import 'package:qurity/routes/app_routes.dart';
import 'package:qurity/services/legal_service.dart';
import 'package:qurity/services/remote_push_service.dart';
import 'package:qurity/services/village_ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// صفحتا «إعلانات القرية» و«مستشار القرية»: نماذجها وخدماتها وعقود ربطها
/// بالقواعد ولوحة الإدارة والإشعارات، ومرجعها القانوني الثابت.
void main() {
  String src(String path) => File(path).readAsStringSync();

  // `cloud_firestore` يثبّت مصنع FieldValue عند أول استخدام له في الـisolate
  // (`static final _factory = FieldValueFactoryPlatform.instance`). بناء Fake
  // هنا قبل أي اختبار يقرأ `toJson()` (الذي يحمل serverTimestamp) يُجبر ذلك
  // المصنع على النسخة الوهمية، وإلا انفصلت الكتابة عن fakeCloudFirestore.
  setUpAll(() => FakeFirebaseFirestore());

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('VillageAd', () {
    test('سجل قديم أو ناقص لا يكسر القراءة', () {
      final ad = VillageAd.fromJson({'title': 'محل أعواد'}, 'a1');
      expect(ad.kind, 'تجارية');
      expect(ad.isApproved, false);
      expect(ad.imageUrl, '');
      expect(ad.createdAt, isNull);
    });

    test('نوع مجهول يرتد للتجارية والصور الفارغة تُهمّش', () {
      final ad = VillageAd.fromJson({
        'kind': 'سيارات',
        'imageUrls': ['https://x/1.jpg', '', null],
      }, 'a2');
      expect(ad.kind, 'تجارية');
      expect(ad.imageUrls, ['https://x/1.jpg']);
      expect(ad.imageUrl, 'https://x/1.jpg');
    });

    test('أنواع الإعلان الثلاثة لها تسمية وأيقونة', () {
      expect(villageAdKindLabel('تجارية'), 'إعلان تجاري');
      expect(villageAdKindLabel('خدمية'), 'إعلان خدمي');
      expect(villageAdKindLabel('إنشائية'), 'إعلان إنشائي');
      expect(kVillageAdKinds, ['تجارية', 'خدمية', 'إنشائية']);
      expect(villageAdKindIcon('خدمية'), Icons.handyman_rounded);
      expect(villageAdKindIcon('إنشائية'), Icons.construction_rounded);
      expect(villageAdKindIcon('تجارية'), Icons.storefront_rounded);
    });

    test('كتابة المالك لا تحمل الموافقة ولا التاريخ', () {
      final ad = VillageAd.fromJson({
        'title': 'ورشة',
        'isApproved': true,
      }, 'a3');
      expect(ad.toWriteMap().containsKey('isApproved'), false);
      expect(ad.toWriteMap().containsKey('createdAt'), false);
      // الحفظ الكامل (الإنشاء) هو وحده من يكتب الموافقة، وتبدأ معلّقة.
      expect(const VillageAd(title: 'ورشة').toJson()['isApproved'], false);
    });
  });

  group('VillageAdService', () {
    test('الإنشاء يبدأ غير معتمد ومنسوب لصاحبه', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageAdService(fake);
      await svc.create(const VillageAd(
        title: 'معرض أدوات منزلية',
        kind: 'إنشائية',
        businessName: 'معرض النور',
        userId: 'u1',
        userName: 'أحمد',
      ));
      final doc = (await fake.collection('village_ads').get()).docs.single;
      expect(doc.data()['isApproved'], false);
      expect(doc.data()['kind'], 'إنشائية');
      expect(doc.data()['userId'], 'u1');
      expect(doc.data()['businessName'], 'معرض النور');
    });

    test('دليل القرية يخفي المعلّق ويرتّب الأحدث أولًا', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageAdService(fake);
      final now = DateTime(2026, 10);
      await fake.collection('village_ads').add({
        'title': 'قديم معتمد',
        'isApproved': true,
        'createdAt': now.subtract(const Duration(days: 5)),
      });
      await fake.collection('village_ads').add({
        'title': 'جديد معتمد',
        'isApproved': true,
        'createdAt': now,
      });
      await fake.collection('village_ads')
          .add({'title': 'معلّق', 'isApproved': false});
      final ads = await svc.watchApproved().first;
      expect(ads.map((a) => a.title).toList(), ['جديد معتمد', 'قديم معتمد']);
    });

    test('وثيقة بلا createdAt لا تختفي من الدليل', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('village_ads')
          .add({'title': 'بلا تاريخ', 'isApproved': true});
      final ads = await VillageAdService(fake).watchApproved().first;
      expect(ads.single.title, 'بلا تاريخ');
    });

    test('إعلاناتي ترى معلّقي، ودليل القرية لا يراه', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageAdService(fake);
      await fake
          .collection('village_ads')
          .add({'title': 'معلّق لي', 'isApproved': false, 'userId': 'u1'});
      await fake
          .collection('village_ads')
          .add({'title': 'معتمد لغيري', 'isApproved': true, 'userId': 'u2'});
      final mine = await svc.watchMine('u1').first;
      expect(mine.map((a) => a.title), ['معلّق لي']);
      final feed = await svc.watchApproved().first;
      expect(feed.map((a) => a.title), ['معتمد لغيري']);
    });

    test('تعديل المالك يعيد الإعلان إلى المراجعة', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageAdService(fake);
      final ref = await fake.collection('village_ads').add({
        'title': 'محل',
        'isApproved': true,
        'userId': 'u1',
        'description': 'نبذة قديمة',
      });
      final stored = (await ref.get()).data()!;
      await svc.update(
          ref.id, VillageAd.fromJson(stored, ref.id).copyWith(description: 'نبذة جديدة'));
      final data = (await ref.get()).data()!;
      expect(data['description'], 'نبذة جديدة');
      // البند ٨: التعديل محتوى جديد فلا يُنشر بلا مراجعة الأدمن.
      expect(data['isApproved'], false);
      expect(data['userId'], 'u1');
    });

    test('getById بمعرّف فارغ لا يلمس Firestore', () async {
      expect(await VillageAdService(FakeFirebaseFirestore()).getById(''), isNull);
    });
  });

  group('Lawyer وLegalConsultation', () {
    test('سجل المحامي: التسامح مع الناقص ومرآة التخصصات', () {
      final l = Lawyer.fromJson({'name': 'م/سمير'}, 'l1');
      expect(l.specializations, isEmpty);
      expect(l.specializationsLine, '');
      expect(l.isApproved, false);
      final full = Lawyer.fromJson({
        'name': 'م/سمير',
        'specializations': ['أحوال شخصية', '', 'تنفيذ أحكام'],
      }, 'l2');
      expect(full.specializationsLine, 'أحوال شخصية، تنفيذ أحكام');
    });

    test('كتابة المالك بلا الموافقة، والصورة تُكتب دائمًا لتُرمَّم', () {
      final w = const Lawyer(name: 'م/سمير', submittedBy: 'u1').toWriteMap();
      expect(w.containsKey('isApproved'), false);
      expect(w['photoUrl'], '');
      expect(w['submittedBy'], 'u1');
    });

    test('الاستشارة: المالك لا يعتمد نفسه ولا يكتب رد المستشار', () {
      const c = LegalConsultation(
        question: 'ما مدة دعوى الجبابة؟',
        answer: 'رد.try',
        isApproved: true,
      );
      // الإنشاء يمر بـtoJson: الموافقة قسرًا false والرد يُرسَل ليقرأه المالك فقط.
      expect(c.toJson()['isApproved'], false);
      // وتعديله يمر بـtoWriteMap: لا answer ولا isApproved ولا createdAt.
      expect(c.toWriteMap().containsKey('answer'), false);
      expect(c.toWriteMap().containsKey('isApproved'), false);
      expect(c.hasAnswer, true);
    });

    test('تصنيف مجهول أو قديم يرتد للاستشارات العامة', () {
      final c = LegalConsultation.fromJson(
          {'question': 'س', 'category': 'قضايا بحر'}, 'c1');
      expect(c.category, 'استشارات عامة');
      final ok = LegalConsultation.fromJson(
          {'question': 'س', 'category': 'قضايا جنائية'}, 'c2');
      expect(ok.category, 'قضايا جنائية');
    });
  });

  group('LegalConsultationService وLawyerService', () {
    test('إنشاء الاستشارة يبدأ معلّقًا ومنسوبًا لصاحبه', () async {
      final fake = FakeFirebaseFirestore();
      await LegalConsultationService(fake).create(const LegalConsultation(
        question: 'حكم بيع المال المشترك',
        userId: 'u1',
        userName: 'حسن',
      ));
      final doc =
          (await fake.collection('legal_consultations').get()).docs.single;
      expect(doc.data()['isApproved'], false);
      expect(doc.data()['userId'], 'u1');
    });

    test('الاستشارات المعتمدة فقط للقرية، والأحدث أولًا', () async {
      final fake = FakeFirebaseFirestore();
      final svc = LegalConsultationService(fake);
      final now = DateTime(2026, 10);
      await fake.collection('legal_consultations').add({
        'question': 'قديمة',
        'isApproved': true,
        'createdAt': now.subtract(const Duration(days: 3)),
      });
      await fake.collection('legal_consultations').add({
        'question': 'حديثة',
        'isApproved': true,
        'createdAt': now,
      });
      await fake
          .collection('legal_consultations')
          .add({'question': 'معلّقة', 'isApproved': false});
      final list = await svc.watchApproved().first;
      expect(list.map((c) => c.question).toList(), ['حديثة', 'قديمة']);
    });

    test('سجل المحامين: المحامي بلا تاريخ تسجيل يبقى ظاهرًا', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('lawyers')
          .add({'name': 'م/كرم', 'isApproved': true});
      final list = await LawyerService(fake).watchApproved().first;
      expect(list.single.name, 'م/كرم');
    });

    test('getById يعيد null للمعرّف الفارغ والوثيقة المحذوفة', () async {
      final svc = LawyerService(FakeFirebaseFirestore());
      expect(await svc.getById(''), isNull);
      expect(await svc.getById('محو'), isNull);
    });
  });

  group('الظهور المباشر بعد الاعتماد (مستشار القرية)', () {
    // fake يطلق انبعاثاته لا متزامنة، والكتابة الواحدة قد تُنتج أكثر من
    // انبعاثة، فالقياس بمهلة محدودة على عدد الانبعاثات لا بضخّ إطار واحد.
    Future<void> waitCount<T>(List<List<T>> sink, int target) async {
      for (var i = 0; i < 80 && sink.length < target; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    }

    test('اعتماد سجل محامٍ يظهره في الدليل على نفس الاشتراك', () async {
      final fake = FakeFirebaseFirestore();
      final svc = LawyerService(fake);
      final sink = <List<Lawyer>>[];
      final sub = svc.watchApproved().listen(sink.add);
      await waitCount<Lawyer>(sink, 1);
      expect(sink.first, isEmpty);

      final ref = await fake.collection('lawyers').add({
        'name': 'م/سمير',
        'submittedBy': 'u1',
        'isApproved': false,
        'createdAt': DateTime(2026, 10),
      });
      await waitCount<Lawyer>(sink, 2);
      expect(sink.last.any((l) => l.name == 'م/سمير'), isFalse,
          reason: 'غير المعتمد لا يظهر للقرية');

      await fake.collection('lawyers').doc(ref.id).update({'isApproved': true});
      await waitCount<Lawyer>(sink, 3);
      expect(sink.last.map((l) => l.name).toList(), ['م/سمير'],
          reason: 'قرار الإدارة وحده هو ما يُظهر السجل، على نفس الاشتراك');
      await sub.cancel();
    });

    test('اعتماد استشارة يظهرها مباشرة في تبويب الاستشارات', () async {
      final fake = FakeFirebaseFirestore();
      final svc = LegalConsultationService(fake);
      final sink = <List<LegalConsultation>>[];
      final sub = svc.watchApproved().listen(sink.add);
      await waitCount<LegalConsultation>(sink, 1);
      expect(sink.first, isEmpty);

      final ref = await fake.collection('legal_consultations').add({
        'question': 'مدة دعوى الجبابة',
        'userId': 'u1',
        'isApproved': false,
        'createdAt': DateTime(2026, 10),
      });
      await waitCount<LegalConsultation>(sink, 2);
      expect(sink.last, isEmpty);

      await fake
          .collection('legal_consultations')
          .doc(ref.id)
          .update({'isApproved': true, 'answer': 'خمسة عشر يومًا'});
      await waitCount<LegalConsultation>(sink, 3);
      expect(sink.last.single.question, 'مدة دعوى الجبابة');
      expect(sink.last.single.hasAnswer, isTrue);
      await sub.cancel();
    });

    test('تبديل التبويب إلى «تسجيلي» ثم العودة إلى الدليل لا يُبقي الشاشة دوّارة',
        () async {
      final fake = FakeFirebaseFirestore();
      final svc = LawyerService(fake);
      final feed = svc.watchApproved();
      final sink = <List<Lawyer>>[];

      var sub = feed.listen(sink.add);
      await waitCount<Lawyer>(sink, 1);
      await sub.cancel();

      // كما يفعل StreamBuilder في التبويب: يلغي الدليل ويستمع «تسجيلي» ثم يعود.
      final mine = svc.watchMine('u1');
      sub = mine.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await sub.cancel();

      sub = feed.listen(sink.add);
      // لا عقد على انبعاثة الاستئناف (البثّ يسقط ما صدر بلا مستمع)، فالكتابة
      // تكون بعد إعادة الاشتراك وحدها هي الدليل على أن التدفّق ما يزال حيًّا.
      final written = sink.length;
      await fake.collection('lawyers').add({
        'name': 'م/رجع',
        'isApproved': true,
        'createdAt': DateTime(2026, 10, 5),
      });
      await waitCount<Lawyer>(sink, written + 1);
      expect(sink.last.map((l) => l.name).toList(), contains('م/رجع'),
          reason: 'العودة إلى نفس التدفّق تُكمل الاشتراك ولا ترمي');
      await sub.cancel();
    });

    test('عقد المصدر: التدفقات الأربعة بثّية والبناءتان تفيشآن الخطأ', () {
      final code = src('lib/services/legal_service.dart')
          .split('\n')
          .where((l) => !l.trim().startsWith('//'))
          .join('\n');
      // أربع تدفقات (محامون/استشارات × الدليل/تسجيلي) — كلُّها بثّية، وإلا
      // عاد العلّة نفسها: «Stream has already been listened to» دوّارًا أبدا.
      expect(code.split('asBroadcastStream()').length - 1, 4);
      // القراءة كاملة للمجموعة والفرز والاعتماد كلاينتيًا (عقد المشروع).
      expect(code, isNot(contains("where('isApproved'")));
      expect(code, isNot(contains('orderBy(')));

      final screen = src('lib/features/legal/legal_advisor_screen.dart');
      expect(screen.split('snap.hasError').length - 1, 2,
          reason: 'تبويبا المحامين والاستشارات يفيشآن الخطأ لا يدوّران');
      expect(screen.split('late final Stream').length - 1, 2,
          reason: 'التدفق مثبّت لكل حالة ولا يُعاد بناؤه في build');
      expect(screen.split('??= _service.watchMine').length - 1, 2);
    });
  });

  group('المرجع القانوني الثابت', () {
    test('كل موضوع له عنوان وملخّص ونقاط مقروءة', () {
      expect(kLegalReferenceTopics.length, greaterThanOrEqualTo(10));
      for (final t in kLegalReferenceTopics) {
        expect(t.title.trim(), isNotEmpty);
        expect(t.summary.trim().length, greaterThan(40));
        expect(t.points.length, greaterThanOrEqualTo(3));
        for (final p in t.points) {
          expect(p.trim().length, greaterThan(20), reason: t.title);
        }
      }
      expect(kLegalReferenceTopics.map((t) => t.title).toSet().length,
          kLegalReferenceTopics.length,
          reason: 'لا موضوع يتكرر');
    });

    test('زيادة المعلومات: ثلاثة عشر موضوعًا إضافيًا بعد الأربعة عشر', () {
      expect(kLegalReferenceTopics.length, 27);
      expect(kLegalReferenceTopics.length, greaterThan(14));
    });

    test('نصوص المرجع عربية خالصة: لا حرف لاتيني في عنوان أو ملخّص أو نقطة', () {
      final latin = RegExp(
        '['
        '${String.fromCharCode(65)}-${String.fromCharCode(90)}'
        '${String.fromCharCode(97)}-${String.fromCharCode(122)}'
        ']',
      );
      for (final t in kLegalReferenceTopics) {
        final body = [t.title, t.summary, ...t.points].join(' ');
        expect(latin.hasMatch(body), isFalse, reason: t.title);
      }
    });

    test('افتتاحيته خريطة نظم القضاء المصري، والتنبيه صريح', () {
      expect(kLegalReferenceTopics.first.title, contains('نظم القضاء المصري'));
      expect(kLegalReferenceDisclaimer, contains('ليست بديلًا'));
      expect(kLegalReferenceDisclaimer, contains('محامٍ'));
    });

    test('المرجع بيانات مضمّنة: لا Firestore ولا شبكة فيه', () {
      final file = src('lib/core/constants/legal_reference_egypt.dart');
      expect(file, isNot(contains('cloud_firestore')));
      expect(file, isNot(contains('http')));
    });
  });

  group('عقود الربط', () {
    test('القواعد: العامة تقرأ، والكتابة تبدأ معلّقة، والرد إداري', () {
      final rules = src('firestore.rules');
      String blockOf(String collection) {
        final start = rules.indexOf('match /$collection/{docId}');
        expect(start, greaterThan(-1), reason: 'كتلة $collection موجودة');
        final next = rules.indexOf('    match /', start + 8);
        return rules.substring(start, next == -1 ? rules.length : next);
      }

      for (final c in ['village_ads', 'lawyers', 'legal_consultations']) {
        final block = blockOf(c);
        expect(block, contains('request.resource.data.isApproved == false'),
            reason: '$c لا يُنشأ معتمدًا');
        expect(block, contains('accountActive()'),
            reason: '$c يتطلب حسابًا مفعّلًا');
        expect(block, contains('isAdmin()'));
      }
      // إعلانات القرية وسجل المحامين عامان بلا حجب، والاستشارة محجوبة حتى الاعتماد.
      expect(blockOf('village_ads'), contains('allow list, get: if true;'));
      expect(blockOf('lawyers'), contains('allow list, get: if true;'));
      final consult = blockOf('legal_consultations');
      expect(consult, contains('resource.data.isApproved == true'));
      // البند ٨: المالك يصوغ سؤاله في أي وقت فيعود للمراجعة، والرد والمالك
      // والموافقة حقول إدارية — فالتعديل يمرّ بـ ownerEdit (التي تمنع
      // isApproved وuserId) ويُفرغ الرد لأنه صار إجابة عن سؤال لم يعد موجودًا.
      expect(consult, contains('ownerEdit(resource.data.userId'),
          reason: 'تعديل المالك محروس بالمراجعة لا بلمس الموافقة');
      expect(consult, contains("request.resource.data.answer == ''"));
      expect(consult, contains("affectedKeys().hasAny(['userName'])"));
      expect(consult, contains('ownerDelete(resource.data.userId)'));
    });

    test('قراءات الدليل بلا orderBy على حقل قد يغيب', () {
      for (final f in [
        'lib/services/village_ad_service.dart',
        'lib/services/legal_service.dart',
      ]) {
        final code = src(f)
            .split('\n')
            .where((l) => !l.trim().startsWith('//'))
            .join('\n');
        expect(code, isNot(contains('orderBy(')), reason: f);
      }
    });

    test('المسارات الأربعة مسجّلة وثابتة بلا وسائط فئة', () {
      expect(AppRoutes.villageAds, '/ads');
      expect(AppRoutes.villageAdDetail, '/ads/detail');
      expect(AppRoutes.legalAdvisor, '/legal');
      expect(AppRoutes.lawyerDetail, '/legal/lawyer');
      expect(
        AppRoutes.routes.keys,
        containsAll(<String>[
          AppRoutes.villageAds,
          AppRoutes.villageAdDetail,
          AppRoutes.legalAdvisor,
          AppRoutes.lawyerDetail,
        ]),
      );
    });

    test('الشاشة الرئيسية: المستشار بعد الفنيين والإعلانات بعد المزارع', () {
      final home = src('lib/features/home/home.dart');
      final start = home.indexOf('static const _services = [');
      final block = home.substring(start, home.indexOf('];', start));
      final tiles = RegExp(
              r"_ServiceItem\('([^']+)',\s*AppRoutes\.(\w+),\s*'([^']+)'\)")
          .allMatches(block)
          .map((m) => '${m.group(2)}|${m.group(1)}|${m.group(3)}')
          .toList();
      expect(tiles.length, 16);
      expect(tiles[5], 'legalAdvisor|مستشار القرية|assets/images/low.jpg');
      expect(tiles[9], 'villageAds|إعلانات القرية|assets/images/ealan.jpg');
      expect(tiles[4], startsWith('techniciansDirectory|'));
      expect(tiles[10], startsWith('lostItems|'));
    });

    test('الإشعارات: الثلاثة تُبلّغ الإدارة، والاستشارة لا تُبث للقرية', () {
      expect(
        kAdminNotifyCollections,
        containsAll(<String>[
          'village_ads',
          'lawyers',
          'legal_consultations',
        ]),
      );
      expect(kPushTopicForCollection['village_ads'], 'village_market');
      expect(kPushTopicForCollection['lawyers'], 'village_services');
      // نص السؤال القانوني حسّاس: لا موضوع عام له، تُقرأ داخل التبويب فقط.
      expect(kPushTopicForCollection.containsKey('legal_consultations'), false);
    });

    test('لوحة الإدارة تعرف المجموعات الثلاث', () {
      final cats = src('lib/features/admin/admin_dashboard.dart');
      expect(cats, contains("_Cat('village_ads'"));
      expect(cats, contains("_Cat('lawyers'"));
      expect(cats, contains("_Cat('legal_consultations'"));
      final svc = src('lib/services/admin_service.dart');
      expect(svc, contains("'village_ads': 'userId'"));
      expect(svc, contains("'lawyers': 'submittedBy'"));
      expect(svc, contains("case 'village_ads':"));
      expect(svc, contains("case 'legal_consultations':"));
      expect(svc, contains("('📢 إعلان جديد في القرية', preview, '/ads')"));
      final worker = src('api/push.js');
      for (final c in ['village_ads', 'lawyers', 'legal_consultations']) {
        expect(worker, contains(c), reason: 'PENDING_KINDS في العامل');
      }
    });

    test('ممرّيف الإشعار يفتح الإعلان والمحامي مباشرة', () {
      final open = src('lib/features/notifications/notification_open_screen.dart');
      expect(open, contains("case 'village_ads'"));
      expect(open, contains('AppRoutes.villageAdDetail'));
      expect(open, contains("case 'lawyers'"));
      expect(open, contains('AppRoutes.lawyerDetail'));
      // الاستشارة بلا حالة عمدًا: تسقط لمسار القائمة /legal.
      expect(open, isNot(contains("case 'legal_consultations'")));
    });

    test('أماكن الإعلانات للدليلين الجديدين', () {
      expect(kPromoPlacements.map((p) => p.key),
          containsAll(<String>['village_ads', 'legal']));
      expect(promoKeyForRoute(AppRoutes.villageAds, null), 'village_ads');
      expect(promoKeyForRoute(AppRoutes.legalAdvisor, null), 'legal');
      expect(promoKeyForRoute(AppRoutes.villageAdDetail, null), '');
      expect(kPromoInternalLinks.map((l) => l.route),
          containsAll(<String>[AppRoutes.villageAds, AppRoutes.legalAdvisor]));
    });
  });
}
