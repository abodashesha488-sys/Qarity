import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qurity/core/utils/firebase_ts.dart';
import 'package:qurity/services/admin_service.dart';

void main() {
  group('AdminService.allPendingStream — قائمة المعلّقات الموحّدة', () {
    late FakeFirebaseFirestore fs;
    late AdminService service;

    setUp(() {
      fs = FakeFirebaseFirestore();
      service = AdminService.withFirestore(fs);
    });

    test('يدمج المجموعات ويوسم كل عنصر بمصدره ويرتّب الأحدث أولاً', () async {
      final older = Timestamp.fromDate(DateTime(2026, 3, 10));
      final newer = Timestamp.fromDate(DateTime(2026, 9, 20));
      await fs
          .collection('news')
          .add({'title': 'خبر قديم', 'isApproved': false, 'createdAt': older});
      await fs.collection('market_products').add(
          {'name': 'منتج جديد', 'isApproved': false, 'createdAt': newer});
      // معلّق لكن في مجموعة غير مطلوبة — يجب ألا يظهر
      await fs
          .collection('obituaries')
          .add({'name': 'نعوة', 'isApproved': false, 'createdAt': newer});
      // معتمد — لا يظهر إطلاقًا
      await fs
          .collection('news')
          .add({'title': 'خبر معتمد', 'isApproved': true, 'createdAt': newer});

      // كل مجموعة تدفع إصدارها فور وصولها، فننتظر الإصدار المستقر الذي يحوي
      // المجموعتين معًا (هذا بالضبط ما تراه الشاشة بعد لحظات).
      final rows = await service
          .allPendingStream(['news', 'market_products'])
          .firstWhere((r) => r.length == 2)
          .timeout(const Duration(seconds: 5));

      expect(rows.length, 2);
      expect(rows[0]['_collection'], 'market_products');
      expect(rows[1]['_collection'], 'news');
      expect(rows.map((r) => r['id']), everyElement(isA<String>()));
      expect(rows.every((r) => r['id'].isNotEmpty), isTrue);
    });

    test('طلب المتاجر يُقرأ من حالة pending لا من isApproved', () async {
      await fs.collection('seller_requests').add({
        'status': 'pending',
        'userName': 'فلان',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 10)),
      });
      await fs.collection('seller_requests').add({
        'status': 'approved',
        'userName': 'علان',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 11)),
      });

      final rows = await service
          .allPendingStream(['seller_requests'])
          .first
          .timeout(const Duration(seconds: 5));

      expect(rows.length, 1);
      expect(rows.single['_collection'], 'seller_requests');
      expect(rows.single['userName'], 'فلان');
    });

    test('مجموعة بلا نتائج لا تُسقط بقية القائمة', () async {
      await fs.collection('news').add({
        'title': 'خبر',
        'isApproved': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9)),
      });

      final rows = await service
          .allPendingStream(['news', 'pharmacies', 'optical_shops'])
          .firstWhere((r) => r.isNotEmpty)
          .timeout(const Duration(seconds: 5));

      expect(rows.length, 1);
      expect(rows.single['_collection'], 'news');
    });

    test('العنصر الجديد يصل حيًّا إلى نفس التدفّق', () async {
      await fs.collection('news').add({
        'title': 'أول',
        'isApproved': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9)),
      });

      // اشتراك واحد: التدفّق يُغلق عند إلغاء الاشتراك (تنظيف الموارد)، لذا
      // لا يصحّ `.first` أكثر من مرة على نفس التدفّق — وهذا عين ما تفعله
      // شاشة المراجعة (اشتراك واحد مثبّت).
      final seen = <List<Map<String, dynamic>>>[];
      final sub = service
          .allPendingStream(['news', 'market_products'])
          .listen(seen.add);

      Future<List<Map<String, dynamic>>> waitFor(int count) async {
        for (var i = 0; i < 250; i++) {
          if (seen.length >= count) return seen.last;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        throw StateError('لم تصل التحديثات');
      }

      expect((await waitFor(1)).length, 1);

      await fs.collection('market_products').add({
        'name': 'منتج',
        'isApproved': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 28)),
      });

      final latest = await waitFor(2);
      expect(latest.length, 2);
      expect(latest.first['_collection'], 'market_products');
      await sub.cancel();
    });
  });

  group('tsToDateTime / تواريخ المستخدم الحقيقية', () {
    test('signupAt يقرأ joinDate (وهو الحقل الفعلي في users)', () {
      final ts = Timestamp.fromDate(DateTime(2026, 5, 4, 9, 30));
      expect(signupAt({'joinDate': ts}), DateTime(2026, 5, 4, 9, 30));
      // المستندات القديمة/الكاش قد تحمل createdAt بدل joinDate
      expect(signupAt({'createdAt': ts}), DateTime(2026, 5, 4, 9, 30));
      expect(signupAt({}), isNull);
    });

    test('lastLoginAt يقرأ lastLogin ويسامح اسم lastSignIn', () {
      final ts = Timestamp.fromDate(DateTime(2026, 9, 26, 18, 5));
      expect(lastLoginAt({'lastLogin': ts}), DateTime(2026, 9, 26, 18, 5));
      expect(lastLoginAt({'lastSignIn': ts}), DateTime(2026, 9, 26, 18, 5));
      // لم يسجّل الدخول بعد: الحقل موجود لكنه null
      expect(lastLoginAt({'lastLogin': null}), isNull);
    });

    test('tsToDateTime يتحمّل Timestamp وDateTime والعدد والنص والقيمة الفاسدة',
        () {
      final date = DateTime(2026, 3, 2, 1, 2);
      expect(tsToDateTime(Timestamp.fromDate(date)), date);
      expect(tsToDateTime(date), date);
      expect(tsToDateTime(date.millisecondsSinceEpoch), date);
      expect(tsToDateTime(date.toIso8601String()), date);
      expect(tsToDateTime('ليس تاريخًا'), isNull);
      expect(tsToDateTime(null), isNull);
      expect(tsOrNow(null), isA<DateTime>());
    });
  });
}
