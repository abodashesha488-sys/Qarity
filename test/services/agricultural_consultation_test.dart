import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/agriculture_consultation_model.dart';
import 'package:qurity/services/admin_service.dart';
import 'package:qurity/services/agriculture_consultation_service.dart';
import 'package:qurity/services/owner_content_service.dart';
import 'package:qurity/services/phone_directory_service.dart';
import 'package:qurity/services/remote_push_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  String src(String path) => File(path).readAsStringSync();

  setUpAll(() => FakeFirebaseFirestore());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AgricultureConsultation Model', () {
    test('إنشاء النموذج بقيم افتراضية وتصنيف افتراضي سليم', () {
      final c = AgricultureConsultation.fromJson({
        'question': 'ما هو أفضل ميعاد لزراعة القمح؟',
        'details': 'أرض طينية في قرية أبوديشيشة',
      }, 'c1');

      expect(c.id, 'c1');
      expect(c.question, 'ما هو أفضل ميعاد لزراعة القمح؟');
      expect(c.category, 'استشارات عامة');
      expect(c.isApproved, false);
      expect(c.hasAnswer, false);
      expect(c.responderTitle, 'أدمن الزراعة');
    });

    test('تصنيف معروف وصاحب رد معتمد', () {
      final c = AgricultureConsultation.fromJson({
        'question': 'مكافحة دودة الحشد في الذرة',
        'category': 'وقاية وآفات',
        'cropName': 'ذرة شامية',
        'answer': 'استخدم المبيد الحيوي المعتمد عند الفقس المبكر.',
        'answeredByName': 'مهندس أحمد (أدمن الزراعة)',
        'isApproved': true,
      }, 'c2');

      expect(c.category, 'وقاية وآفات');
      expect(c.cropName, 'ذرة شامية');
      expect(c.hasAnswer, true);
      expect(c.responderTitle, 'مهندس أحمد (أدمن الزراعة)');
      expect(c.isApproved, true);
    });

    test('تصنيف غير معروف يرتد لاستشارات عامة', () {
      final c = AgricultureConsultation.fromJson({
        'question': 'استفسار',
        'category': 'تصنيف غريب غير مسجل',
      }, 'c3');

      expect(c.category, 'استشارات عامة');
    });

    test('حقول المالك toWriteMap لا تملك الموافقة ولا التاريخ ولا الرد', () {
      const c = AgricultureConsultation(
        id: 'c4',
        question: 'سؤال معدل',
        details: 'تفاصيل إضافية',
        category: 'أمراض نباتات',
        cropName: 'طماطم',
        userId: 'u1',
        userName: 'مزارع القرية',
        answer: 'رد قديم',
        isApproved: true,
      );

      final write = c.toWriteMap();
      expect(write.containsKey('isApproved'), false);
      expect(write.containsKey('createdAt'), false);
      expect(write.containsKey('answer'), false);
      expect(write.containsKey('answeredByName'), false);
      expect(write['question'], 'سؤال معدل');
      expect(write['cropName'], 'طماطم');
    });
  });

  group('AgricultureConsultationService', () {
    late FakeFirebaseFirestore fs;
    late AgricultureConsultationService service;

    setUp(() {
      fs = FakeFirebaseFirestore();
      service = AgricultureConsultationService(fs);
    });

    test('create يبدأ غير معتمد ويُحفظ في المجموعة الصحيحة', () async {
      final id = await service.create(const AgricultureConsultation(
        question: 'سؤال جديد',
        details: 'تفاصيل السؤال',
        category: 'أسمدة وكيماويات',
        userId: 'user-123',
        userName: 'محمد',
      ));

      final doc = await fs.collection('agriculture_consultations').doc(id).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['question'], 'سؤال جديد');
      expect(data['isApproved'], false);
      expect(data['userId'], 'user-123');
      expect(data['category'], 'أسمدة وكيماويات');
    });

    test('watchApproved يعيد المعتمد فقط ويهمل غير المعتمد', () async {
      await fs.collection('agriculture_consultations').add({
        'question': 'سؤال معتمد',
        'isApproved': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 10)),
      });
      await fs.collection('agriculture_consultations').add({
        'question': 'سؤال معلق',
        'isApproved': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 2)),
      });

      final approved = await service.watchApproved().first;
      expect(approved.length, 1);
      expect(approved.first.question, 'سؤال معتمد');
    });

    test('submitAnswer يحفظ الرد واسم المستشار ويعتمد الاستشارة', () async {
      final ref = await fs.collection('agriculture_consultations').add({
        'question': 'سؤال بحاجة لرد',
        'isApproved': false,
        'userId': 'user-456',
      });

      await service.submitAnswer(
        ref.id,
        'هذا هو الرد الإرشادي الزراعي المعتمد',
        answeredByName: 'أدمن الزراعة',
      );

      final updated = await ref.get();
      final data = updated.data()!;
      expect(data['isApproved'], true);
      expect(data['answer'], 'هذا هو الرد الإرشادي الزراعي المعتمد');
      expect(data['answeredByName'], 'أدمن الزراعة');
    });

    test('تعديل صاحب الاستشارة يعيدها للمراجعة ويفرغ الرد السابق', () async {
      final ref = await fs.collection('agriculture_consultations').add({
        'question': 'سؤال قديم',
        'details': 'تفاصيل قديمة',
        'answer': 'رد قديم كان معتمداً',
        'answeredByName': 'أدمن الزراعة',
        'userId': 'user-789',
        'isApproved': true,
      });

      await service.update(
        ref.id,
        const AgricultureConsultation(
          question: 'سؤال معدل بعد التغيير',
          details: 'تفاصيل جديدة',
          userId: 'user-789',
        ),
      );

      final updated = await ref.get();
      final data = updated.data()!;
      expect(data['question'], 'سؤال معدل بعد التغيير');
      expect(data['isApproved'], false, reason: 'التعديل يعود للمراجعة');
      expect(data['answer'], '', reason: 'تعديل السؤال يفرغ الرد السابق');
    });
  });

  group('Phone Directory Dispute & Admin Approval', () {
    late FakeFirebaseFirestore fs;
    late AdminService adminService;
    late PhoneDirectoryService phoneService;

    setUp(() {
      fs = FakeFirebaseFirestore();
      adminService = AdminService.withFirestore(fs);
      phoneService = PhoneDirectoryService(fs);
    });

    test('submitPhoneDispute ينشئ طلباً معلقاً يحمل بيانات النزاع', () async {
      final oldEntry = await fs.collection('phone_directory').add({
        'name': 'الاسم القديم',
        'phone': '01012345678',
        'isApproved': true,
        'isPublic': true,
      });

      await phoneService.submitPhoneDispute(
        phone: '01012345678',
        newName: 'الاسم الجديد الصحيح',
        oldEntryId: oldEntry.id,
        oldEntryName: 'الاسم القديم',
        reason: 'هذا رقمي الشخصي والاسم القديم غير صحيح',
        job: 'مهندس',
      );

      final query = await fs
          .collection('phone_directory')
          .where('isDispute', isEqualTo: true)
          .get();

      expect(query.docs.length, 1);
      final disputeDoc = query.docs.first.data();
      expect(disputeDoc['isApproved'], false);
      expect(disputeDoc['oldEntryId'], oldEntry.id);
      expect(disputeDoc['name'], 'الاسم الجديد الصحيح');
      expect(disputeDoc['phone'], '01012345678');
      expect(disputeDoc['job'], 'مهندس');
    });

    test('اعتماد طلب النزاع يحدّث السجل الأصلي ويحذف طلب المراجعة', () async {
      final oldEntry = await fs.collection('phone_directory').add({
        'name': 'الاسم القديم',
        'phone': '01099998888',
        'title': 'تاجر',
        'isApproved': true,
        'isPublic': true,
      });

      final disputeEntry = await fs.collection('phone_directory').add({
        'name': 'الاسم الجديد المعتمد',
        'phone': '01099998888',
        'job': 'طبيب',
        'isApproved': false,
        'isDispute': true,
        'oldEntryId': oldEntry.id,
        'oldEntryName': 'الاسم القديم',
        'disputeReason': 'تم شراء الخط وتغيير الملكية',
      });

      await adminService.approveItem('phone_directory', disputeEntry.id);

      final updatedOldDoc =
          await fs.collection('phone_directory').doc(oldEntry.id).get();
      expect(updatedOldDoc.exists, true);
      expect(updatedOldDoc.data()!['name'], 'الاسم الجديد المعتمد');
      expect(updatedOldDoc.data()!['job'], 'طبيب');
      expect(updatedOldDoc.data()!['title'], 'طبيب');

      final deletedDisputeDoc =
          await fs.collection('phone_directory').doc(disputeEntry.id).get();
      expect(deletedDisputeDoc.exists, false,
          reason: 'طلب النزاع يُحذف بعد تطبيق التحديث');
    });

    test('فحص صلاحية أدمن الزراعة isAgriculturalAdmin', () async {
      await fs.collection('users').doc('u_agri').set({
        'role': 'agricultural_admin',
        'name': 'أدمن الزراعة',
      });
      await fs.collection('users').doc('u_admin').set({
        'role': 'admin',
        'name': 'المدير العام',
      });
      await fs.collection('users').doc('u_assistant').set({
        'role': 'assistant_admin',
        'name': 'المساعد',
      });
      await fs.collection('users').doc('u_normal').set({
        'role': 'user',
        'name': 'مستخدم عادي',
      });

      expect(await adminService.isAgriculturalAdmin('u_agri'), true);
      expect(await adminService.isAgriculturalAdmin('u_admin'), true);
      expect(await adminService.isAgriculturalAdmin('u_assistant'), true);
      expect(await adminService.isAgriculturalAdmin('u_normal'), false);
    });
  });

  group('عقود الربط في القواعد والمشروع', () {
    test('firestore.rules تغطي agriculture_consultations بـ isAgriculturalAdmin', () {
      final rules = src('firestore.rules');
      expect(rules, contains('match /agriculture_consultations/{docId}'));
      expect(rules, contains('isAgriculturalAdmin()'));
      expect(rules, contains('ownerEdit(resource.data.userId'));
      expect(rules, contains('ownerDelete(resource.data.userId)'));
    });

    test('AdminService تسجل agriculture_consultations في مراجعة الإدارة', () {
      final adminSrc = src('lib/services/admin_service.dart');
      expect(adminSrc, contains("'agriculture_consultations'"));
      expect(adminSrc, contains('/services/agricultural-advisor'));
      expect(adminSrc, contains('الاستشارة الزراعية'));
    });

    test('RemotePushService يرسل تنبيهاً للإدارة عند إضافة استشارة زراعية', () {
      expect(kAdminNotifyCollections.contains('agriculture_consultations'), true);
    });

    test('المحرك الموحد OwnerContentService يغطي agriculture_consultations', () {
      expect(OwnerContentService.editableCollections.contains('agriculture_consultations'), true);
      final spec = OwnerContentService.specFor('agriculture_consultations');
      expect(spec, isNotNull);
      expect(spec!.titleField, 'question');
      expect(spec.route, '/services/agricultural-advisor');
    });
  });
}
