import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qurity/services/admin_service.dart';

/// البند ٦ — شارة «بانتظار المراجعة» تتزامن بعد قرار واحد.
///
/// القرارات تُتخذ في ثلاث شاشات (لوحة التحكم، تفاصيل العنصر، محرّر التعديل)،
/// وكانت اللوحة والتقارير يعرفان عدّاداتهما من نسخة خُزنتا عند الفتح فقط،
/// فقرارٌ في شاشة التفاصيل يبقى عدّه قديماً في اللوحة حتى تُغلق وتُعاد.
/// المُصلَح هو إذاعة واحدة في `AdminService` تنشر اسم المجموعة، تشترك فيها
/// الشاشتان وتُلغيان اشتراكهما في `dispose`، وتكتفي بعدّ المجموعة وحدها.
///
/// لا يمكن اختبار النشر سلوكيًا من الخدمة نفسها: كل قرار يقرأ
/// `FirebaseAuth.instance` (و`_announceApproval` خلفه) فلا يقوم بلا تهيئة
/// Firebase، ولا مُحاكٍ لـ`firebase_auth` في تبعيات الاختبار. لذلك النشر
/// مُثبَت بعقد مصدر على مواضع النداء داخل جسم كل دالة قرار، أما العدّ البديل
/// فسلوكي تمامًا على `FakeFirebaseFirestore`.
void main() {
  group('recountPending — عدّ مجموعة واحدة بدل العشرين', () {
    late FakeFirebaseFirestore fs;
    late AdminService service;

    setUp(() {
      fs = FakeFirebaseFirestore();
      service = AdminService.withFirestore(fs);
    });
    test('يعدّ المعلّقات بـ isApproved == false ولا يمسّ المعتمد', () async {
      await fs.collection('news').add({'title': 'أ', 'isApproved': false});
      await fs.collection('news').add({'title': 'ب', 'isApproved': false});
      await fs.collection('news').add({'title': 'ج', 'isApproved': true});
      await fs.collection('news').add({'title': 'بلا الحقل'});

      expect(await service.recountPending('news'), 2);
    });

    test('طلبات المتاجر تُعدّ بـ status == pending لا بـ isApproved', () async {
      await fs.collection('seller_requests').add({'status': 'pending'});
      await fs.collection('seller_requests').add({'status': 'approved'});
      // وثيقة معلّقة بلا حالة: لا تدخل العدّ لأن عقدها هو `status` وحده.
      await fs.collection('seller_requests').add({'isApproved': false});

      expect(await service.recountPending('seller_requests'), 1);
    });

    test('المجموعة غير الموجودة تعدّها صفرًا لا استثناءً', () async {
      expect(await service.recountPending('lawyers'), 0);
    });

    test('fetchPendingCounts و recountPending يعطيان الرقم نفسه', () async {
      await fs
          .collection('pharmacies').add({'name': 'ص', 'isApproved': false});
      await fs.collection('pharmacies').add({'name': 'ص2', 'isApproved': true});
      await fs.collection('seller_requests').add({'status': 'pending'});

      final all = await service.fetchPendingCounts();
      expect(all['pharmacies'], await service.recountPending('pharmacies'));
      expect(
          all['seller_requests'], await service.recountPending('seller_requests'));
      expect(all['pharmacies'], 1);
      expect(all['seller_requests'], 1);
    });

    test('القرار يُنقص عدّ المجموعة نفسها — لا يبقى رقم ما قبل الموافقة', () async {
      final doc = await fs
          .collection('news').add({'title': 'خبر', 'isApproved': false});
      expect(await service.recountPending('news'), 1);
      // الحذف هو القرار الذي يمر بمسار نظيف (بلا إشعارات ولا مصادقة معقّدة)،
      // فبه يُثبت أن العدد الحيّ يتبع محتوى المجموعة لا نسخة مخزّنة.
      await fs.collection('news').doc(doc.id).delete();
      expect(await service.recountPending('news'), 0);
    });
  });

  group('إذاعة pendingCountEvents — العقد العام', () {
    final text = File('lib/services/admin_service.dart').readAsStringSync();

    test('التدفّق بثّ (broadcast) لا واحد، فالشاشات ثلاث مشترِكات', () {
      expect(text, contains('StreamController<String>.broadcast()'));
      expect(text, contains('static Stream<String> get pendingCountEvents'));
    });

    test('كل قرار إداري ينشر مجموعته داخل جسمه', () {
      // كل دالة تُقطَع من توقيعها إلى بداية الكائن التالي لها في الملف؛ وجود
      // النداء داخل هذا المقطع هو الدليل على أن النشر في مسار القرار نفسه.
      const decisions = <String, (String start, String endMark)>{
        'approveItem': (
          'Future<void> approveItem(',
          '/// حقل المالك/المقدم لكل مجموعة'
        ),
        'rejectItem': ('Future<void> rejectItem(', 'Future<void> deleteItem('),
        'deleteItem': (
          'Future<void> deleteItem(',
          'void _invalidateContentCache(String collection)'
        ),
        'publishContent': (
          'Future<String> publishContent(',
          'Future<void> setUserRole('
        ),
        '_update': (
          'Future<void> _update(',
          'Stream<List<Map<String, dynamic>>> _allStream('
        ),
        'approveSellerRequest': (
          'Future<void> approveSellerRequest(',
          'Future<void> rejectSellerRequest('
        ),
        'rejectSellerRequest': (
          'Future<void> rejectSellerRequest(',
          '/// إشعار شخصي لصاحب طلب البائعية'
        ),
      };
      for (final entry in decisions.entries) {
        final start = text.indexOf(entry.value.$1);
        expect(start, greaterThan(-1), reason: 'لم يُعثر على ${entry.key}');
        final end = text.indexOf(entry.value.$2, start + entry.value.$1.length);
        expect(end, greaterThan(start),
            reason: 'نهاية ${entry.key} غير معروفة — حدّث العلامة');
        final slice = text.substring(start, end);
        expect(slice, contains('_emitPendingCountEvent('),
            reason: '${entry.key} لا ينشر تغيّر عدّ معلّقاته');
      }
    });

    test('قرارا المتاجر ينشران `seller_requests` نصًّا لا مجموعة أخرى', () {
      final start = text.indexOf('Future<void> approveSellerRequest(');
      final slice = text.substring(
          start, text.indexOf('Future<void> rejectSellerRequest(', start));
      expect(slice, contains("_emitPendingCountEvent('seller_requests')"));
    });

    test('العدّ البديل صارم: الفشل لا يُبدَّل بصفر في شارة حيّة', () {
      final start = text.indexOf('Future<int> recountPending(');
      expect(start, greaterThan(-1));
      final slice = text.substring(start, start + 400);
      expect(slice, contains('_statusPendingCount(collection, strict: true)'));
      expect(slice, contains('_pendingCountOnce(collection, strict: true)'));
      // المسار غير الصارم (عدّادات `fetchPendingCounts` العادية) يبقى كما هو:
      // الفشل فيه صفرٌ لأن اللوحة تعرضه مع غيره وتُسحَب للتحديث.
      expect(text, contains('if (strict) rethrow;'));
    });

    test('نداء النشر لا يُرسل على مجموعة مجهولة ولا بعد إغلاق التدفّق', () {
      final start = text.indexOf('static void _emitPendingCountEvent(');
      expect(start, greaterThan(-1));
      final slice = text.substring(start, start + 240);
      expect(slice, contains('collection.isEmpty'));
      expect(slice, contains('_pendingCountEvents.isClosed'));
    });
  });

  group('المشترِكون: اللوحة والتقارير', () {
    final dashboard =
        File('lib/features/admin/admin_dashboard.dart').readAsStringSync();
    final reports =
        File('lib/features/admin/admin_dashboard_reports.dart')
            .readAsStringSync();

    test('لوحة التحكم تشترك في الإذاعة وتُلغي الاشتراك في dispose', () {
      final init = dashboard.substring(dashboard.indexOf('void initState() {'));
      expect(
          init.substring(
              0, init.indexOf('unawaited(_backfillSellerTypesOnce')),
          contains('AdminService.pendingCountEvents.listen('),
          reason: 'الاشتراك عند الفتح لا بعد أول قرار');

      final dispose =
          dashboard.substring(dashboard.indexOf('void dispose() {'));
      expect(
          dispose.substring(0, dispose.indexOf('super.dispose();')),
          contains('_pendingSub?.cancel()'),
          reason: 'بلا إلغاء اشتراك يبقى المعالِج يعمل على حالة ميتة');
    });

    test('معالِج اللوحة يعدّ مجموعة واحدة ولا يجلب العدّادات العشرين', () {
      // المقطع ينتهي عند أول سطر توثيق بعد الدالة، فلا يحسب شرحًا يذكر
      // `fetchPendingCounts` نداءً فعليًا داخل الجسم.
      final handler = dashboard.substring(
          dashboard.indexOf('Future<void> _applyPendingCount('),
          dashboard.indexOf('/// الإحصاءات وحدها بعد قرار'));
      expect(handler, contains('recountPending(collection)'));
      expect(handler, isNot(contains('fetchPendingCounts')));
      // مجموعة لا لها تبويب مراجعة تُتجاهل (لا عدّ بلا معنى).
      expect(handler, contains('_cats.any('));
      // فشل العدّ يبقي الرقم القديم ولا يكتب صفرًا.
      expect(handler, contains('catch (_)'));
      expect(handler, isNot(contains('count = 0')));
      // الإجراء الجماعي: قرار أثناء الجري يُعاد عدّه وإلا بقي الأقدم.
      expect(handler, contains('_recountInFlight.add(collection)'));
      expect(handler, contains('_recountAgain'));
    });

    test('مسار القرار في اللوحة لم يعد يجلب العدّادات العشرين', () {
      expect(dashboard, isNot(contains('_refreshAll')));
      final action =
          dashboard.substring(dashboard.indexOf('Future<void> _handleAction('));
      expect(action, contains('_refreshStats();'));
      expect(action, isNot(contains('fetchPendingCounts')));
      // «السحب للتحديث» يبقى ممرّ الاستعادة الكامل: العشرون مقصودة هناك.
      final start = dashboard.indexOf('Future<void> _refreshDashboard()');
      final refresh = dashboard.substring(
          start, dashboard.indexOf('@override', start));
      expect(refresh, contains('_loadPendingCounts()'));
      // نتيجة العدّ الحيّ تُدمج فوق القراءة الكاملة حتى لا تكتب الأقدم فوق الأحدث.
      final load = dashboard.substring(
          dashboard.indexOf('Future<void> _loadPendingCounts()'),
          dashboard.indexOf('Future<void> _applyPendingCount('));
      expect(load, contains('counts.addAll(_recounted)'));
    });

    test('معالِج اللوحة لا يجلب إحصاءات الثلاثة والعشرين عدًّا لكل ضغطة', () {
      final stats = dashboard.substring(
          dashboard.indexOf('Future<void> _refreshStats()'),
          dashboard.indexOf('Future<void> _refreshDashboard()'));
      expect(stats, contains('_loadStats()'));
      expect(stats, isNot(contains('_loadPendingCounts')));
      // حارس الدفعة: ضغطة على عشرين عنصرًا = عدّ إحصاءات واحد.
      expect(stats, contains('_statsInFlight'));
      expect(stats, contains('_statsAgain'));
      expect(stats, contains('finally'));
    });

    test('تبويب التقارير يشترك هو الآخر ويُلغي اشتراكه', () {
      final init = reports.substring(reports.indexOf('void initState() {'));
      expect(init.substring(0, init.indexOf('}')),
          contains('AdminService.pendingCountEvents.listen('));
      final dispose = reports.substring(reports.indexOf('void dispose() {'));
      expect(dispose.substring(0, dispose.indexOf('super.dispose();')),
          contains('_pendingSub?.cancel()'));

      final handler = reports.substring(
          reports.indexOf('Future<void> _applyPendingCount('),
          reports.indexOf('Future<void> _loadReportData()'));
      expect(handler, contains('recountPending(collection)'));
      expect(handler, isNot(contains('fetchPendingCounts')));
      // لا صفر زائف: الرفض يُترك والرقم القديم كما هو.
      expect(handler, contains('catch (_)'));
      expect(handler, isNot(contains('_loadReportData();')));
      // لا يُضاف تبويب لا يعرفه التقرير (لا قراءات عبثية).
      expect(handler, contains('containsKey(collection)'));
    });
  });
}
