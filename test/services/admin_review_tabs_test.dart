import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qurity/core/constants/product_categories.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/services/admin_service.dart';

/// طلب المستخدم: تبويب المستلزمات الطبية في المراجعة + تقسيم «سجلات دليل
/// الخدمات» إلى تبويب لكل صفحة، بلا مجموعة جديدة وبلا قواعد وبلا فهرس.
///
/// الآلية واحدة: تبويب **عرض مُصفّى** لمجموعة قائمة (`_Cat.source` +
/// `filterField` + `filterValues`)، والقرارات كلها توجَّه إلى المجموعة
/// الحقيقية عبر `realCollection`. لذلك يُثبت هذا الملف أمرين:
/// (١) عدّ التبويبات سلوكيًا على `FakeFirebaseFirestore` — وهو ما يُقرأ فعلًا
/// في الشارات، وأهم عُقده أن السجل القديم بلا حقل `category` لا يسقط بل يدخل
/// «الباقي»؛ و(٢) عقود مصدر على أن التبويبات معرّفة كذلك وأن لا مسار قرار
/// يقبل المعرّف الوهمي.
void main() {
  late FakeFirebaseFirestore fs;
  late AdminService service;

  setUp(() {
    fs = FakeFirebaseFirestore();
    service = AdminService.withFirestore(fs);
  });

  group('عدّ التبويبات المصفّاة — fetchGroupPendingCounts', () {
    test('المستلزمات الطبية تعدّ معلّقات تصنيفها وحده من market_products',
        () async {
      final pending = Timestamp.fromDate(DateTime(2026, 10));
      await fs.collection('market_products').add({
        'name': 'كمامات',
        'category': kMedicalSuppliesCategory,
        'isApproved': false,
        'createdAt': pending,
      });
      await fs.collection('market_products').add({
        'name': 'محقن معتمد',
        'category': kMedicalSuppliesCategory,
        'isApproved': true,
        'createdAt': pending,
      });
      await fs.collection('market_products').add({
        'name': 'طماطم',
        'category': 'خضار وفواكه',
        'isApproved': false,
        'createdAt': pending,
      });

      final counts = await service.fetchGroupPendingCounts(
          'market_products', 'category', [kMedicalSuppliesCategory]);

      expect(counts[kMedicalSuppliesCategory], 1,
          reason: 'المعتمد وغيره من التصنيفات لا يدخلان رقم التبويب');
      // الباقي = معلّقات السوق التي ليست مستلزمات (منتج الطماطم).
      expect(counts['*'], 1);
    });

    test('تبويبات دليل الخدمات: لكل صفّته عدّه، والباقي يشمل القديم بلا حقل',
        () async {
      final ts = Timestamp.fromDate(DateTime(2026, 10, 2));
      Future<void> pending(String? category, String name) async {
        await fs.collection('service_providers').add({
          'name': name,
          'isApproved': false,
          'createdAt': ts,
          if (category != null) 'category': category,
        });
      }

      await pending(ServiceCategory.technicians, 'كهربائي');
      await pending(ServiceCategory.technicians, 'سبّاك');
      await pending(ServiceCategory.agricultural, 'جرار زراعي');
      await pending(ServiceCategory.educational, 'مدرس رياضيات');
      // سجل قديم لا يملك الحقل إطلاقًا — Firestore يُسقطه من أي استعلام مرتَّب
      // على الحقل، لكنه هنا يدخل «الباقي» بالحساب لا بالتصفية.
      await pending(null, 'سجل قديم');
      // قيمة تصنيف غير معروفة (حرفة أُعيدت تسميتها) — يجب ألا تتيتم.
      await pending('حرف قديم ملغي', 'نجار');
      // معتمد: لا يدخل أي عدّ مراجعة.
      await fs.collection('service_providers').add({
        'name': 'مدرس معتمد',
        'category': ServiceCategory.educational,
        'isApproved': true,
        'createdAt': ts,
      });

      final known = [
        ServiceCategory.technicians,
        ServiceCategory.agricultural,
        ServiceCategory.educational,
      ];
      final counts = await service.fetchGroupPendingCounts(
          'service_providers', 'category', known);

      expect(counts[ServiceCategory.technicians], 2);
      expect(counts[ServiceCategory.agricultural], 1);
      expect(counts[ServiceCategory.educational], 1);
      expect(counts['*'], 2,
          reason: 'القديم بلا الحقل والقيمة المجهولة يرثهما تبويب الحرفيين');
      expect(counts.values.fold<int>(0, (a, b) => a + b), 6,
          reason: 'المجموع == كل المعلّقات: لا رقم يضيع ولا رقم يُحسب مرتين');
    });

    test('«الباقي» لا يصبح سالبًا أبدًا — مهما قرأت التصفية', () async {
      // لا معلّقات: كل عدّ صفر فالباقية صفر لا سالبة.
      final counts = await service.fetchGroupPendingCounts(
          'service_providers', 'category', [ServiceCategory.educational]);
      expect(counts['*'], 0);
      expect(counts['*'], greaterThanOrEqualTo(0));
    });

    test('لا استعلام بـ orderBy: مساواتان فقط — فلا فهرس مركّب جديد', () {
      final text = File('lib/services/admin_service.dart').readAsStringSync();
      final start = text.indexOf('Future<int> _pendingCountWhere(');
      final slice = text.substring(start, start + 520);
      expect(slice, contains("where('isApproved', isEqualTo: false)"));
      expect(slice, contains('where(field, isEqualTo: value)'));
      expect(slice, isNot(contains('orderBy(')));
      expect(slice, contains('count()'));
    });
  });

  group('عقد التبويبات في اللوحة', () {
    final dashboard =
        File('lib/features/admin/admin_dashboard.dart').readAsStringSync();
    final models =
        File('lib/features/admin/admin_dashboard_models.dart')
            .readAsStringSync();

    test('«المستلزمات الطبية» تبويب مُصفّى من المنتجات — لا مجموعة جديدة', () {
      final start = dashboard.indexOf("'tab_med_supplies'");
      expect(start, greaterThan(-1));
      final slice = dashboard.substring(start, start + 320);
      expect(slice, contains("source: 'market_products'"));
      expect(slice, contains("filterField: 'category'"));
      expect(slice, contains('kMedicalSuppliesCategory'));
      // لا مجموعة ولا نموذج ولا قواعد باسم طبي: القراءة هي `market_products`
      // نفسها، فلا مراجعة مزدوجة ولا إجراء نشر مطلوب.
      for (final path in [
        'lib/features/medical/medical_home_screen.dart',
        'lib/services/admin_service.dart',
        'firestore.rules',
      ]) {
        expect(File(path).readAsStringSync(),
            isNot(contains('medical_supplies')),
            reason: '$path ذكر مجموعة وهمية');
      }
    });

    test('دليل الخدمات صار ثلاثة تبويبات، واحد منها يرث الباقي', () {
      for (final id in [
        'tab_svc_technicians',
        'tab_svc_agricultural',
        'tab_svc_educational',
      ]) {
        expect(dashboard, contains("'$id'"), reason: 'لا تبويب $id');
      }
      expect(dashboard, contains('ServiceCategory.technicians'),
          reason: 'تسمية الصفوف من مصدرها لا نص مكرر');
      expect(dashboard, contains('ServiceCategory.agricultural'));
      expect(dashboard, contains('ServiceCategory.educational'));
      // واحد فقط يرث الباقي — وإلا حُسب السجل المجهول في تبويبين.
      expect(RegExp('takesRest: true').allMatches(dashboard).length, 1);
      // السجل الواحد الذي يخلط الصفوف لم يعد موجودًا.
      expect(dashboard, isNot(contains("_Cat('service_providers'")));
      // المصدر مشترك بين الثلاثة فلا يقرأ أحد المجموعة مرة رابعة.
      expect(RegExp("source: 'service_providers'").allMatches(dashboard).length,
          3);
      // «عمال و معدات» أُلغيت ببوابتها وفئتها، فلا وصف لها في المراجعة.
      expect(dashboard, isNot(contains('عمال و معدات')));
      // كل التبويبات المصفّاة في اللوحة = المستلزمات + الثلاث = أربعة.
      expect(RegExp('source: ').allMatches(dashboard).length, 4);
    });

    test('القرارات لا تعرف المعرّفات الوهمية: realCollection في كل ممر', () {
      expect(models, contains('String get realCollection => source ?? collection'));
      final review =
          File('lib/features/admin/admin_dashboard_review.dart').readAsStringSync();
      expect(review, contains('cat.realCollection'),
          reason: 'تيار المراجعة يقرأ المجموعة الحقيقية');
      expect(review, contains("item['_collection'] as String?"),
          reason: 'البطاقة تعرف مجموعة عنصرها الحقيقية');
      expect(review, contains('_realCollections'),
          reason: 'القائمة الموحّدة تُبنى من المجموعات الحقيقية');
      final bulk = File('lib/features/admin/admin_dashboard_review_bulk.dart')
          .readAsStringSync();
      expect(bulk, contains('realCollection'),
          reason: 'الإجراء الجماعي يجدّل المفتاح المُركّب إلى مجموعته');
      // المفتاح المُركّب هو وحده ما يحمل التبويب، فلا يصل وهمي إلى الخدمة.
      expect(bulk, contains('::'));
    });

    test('لا تضخيم في الشارات: التبويبات المصفّاة خارج الجمع الحقيقي', () {
      final guard = dashboard.substring(
          dashboard.indexOf('Map<String, int> get _pendingCounts'),
          dashboard.indexOf('/// عدّادات أعادت الإذاعة قراءتها'));
      expect(guard, contains('_realCollections'));
      expect(dashboard,
          contains('int get _totalPending => _pendingCounts.values.fold'));
      // شريط اللوحة والنظرة العامة لا يجمعان `_counts` الخام.
      expect(dashboard, isNot(contains('_counts.values.fold')));
    });

    test('بطاقات النظرة العامة تُسمّى بتبويبات المراجعة وتفتحها نفسها', () {
      expect(dashboard, contains('Map<String, int> get _reviewTabCounts'));
      expect(dashboard, contains('static Map<String, String> get _reviewTabLabels'));
      expect(dashboard, contains('reviewTabs: _reviewTabCounts'));
      expect(dashboard, contains('reviewLabels: _reviewTabLabels'));
      final overview =
          File('lib/features/admin/admin_dashboard_overview.dart')
              .readAsStringSync();
      expect(overview, contains('final Map<String, String> labels;'));
      expect(overview, contains('labels[e.key] ?? e.key'),
          reason: 'التسمية من التاب، فلا رقم تحت اسم لا يفتحه النقر');
      // تسمية قديمة بمجموعة مقطوفة لم تعد تحلّ إلى أي تبويب.
      expect(overview, isNot(contains("'service_providers': 'دليل الخدمات'")));
    });

    test('تسميات المراجعة تصف الصفحة لا المجموعة', () {
      final review =
          File('lib/features/admin/admin_dashboard_review.dart').readAsStringSync();
      expect(review, contains('kMedicalSuppliesCategory'));
      expect(review, contains('مستلزم طبي من السوق'),
          reason: 'البطاقة تسمّي حقيقيتها: موافقة على مستلزم لا على منتج سوق');
      for (final page in [
        'سجل في صفحة دليل الحرفيين',
        'سجل في صفحة خدمات زراعية',
        'سجل في صفحة خدمات تعليمية',
      ]) {
        expect(review, contains(page), reason: 'لا وصف لـ $page');
      }
      // الفئة أُلغيت ببوابتها، والقيمة التراثية في سجل قديم ترِثها صفحة الحرفيين.
      expect(review, isNot(contains('سجل في صفحة عمال و معدات')),
          reason: 'لا وصف لصفحة لم تعد موجودة');
    });
  });

  group('عقد ضغط صفوف دليل الهاتف', () {
    final directory =
        File('lib/features/phone/directory.dart').readAsStringSync();

    test('الصفوف متلاصقة: بلا هامش للكرت وفاصل 4 فقط', () {
      expect(directory, contains('margin: EdgeInsets.zero'));
      expect(directory, contains('separatorBuilder'));
      expect(directory, contains('SizedBox(height: 4)'));
      expect(directory, contains('vertical: 4'));
    });

    test('العناصر الصغيرة هي التي تحسم الارتفاع (دائرة 16 وزر 34)', () {
      expect(directory, contains('radius: 16'));
      expect(directory, contains('minimumSize: const Size(34, 34)'));
      expect(directory, contains('tapTargetSize: MaterialTapTargetSize.shrinkWrap'));
      expect(directory, contains('padding: EdgeInsets.zero'));
    });

    test('القائمة ما زالت ListView عمودية والاختبارات القائمة عليها سليمة', () {
      expect(directory, contains('ListView.separated'));
      // السمة الخضراء ومفاتيح الأسطر لم تتغير بالضغط.
      expect(directory, contains('kCallButtonColor'));
      expect(directory, contains("key: Key('phone-row-call-\${entry.id}')"));
    });
  });
}
