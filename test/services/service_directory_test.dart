import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/medical_models.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/services/medical_service.dart';
import 'package:qurity/services/service_provider_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ServiceProviderService', () {
    test('create persists with isApproved=false and category', () async {
      final fake = FakeFirebaseFirestore();
      final svc = ServiceProviderService(fake);
      await svc.create(const ServiceProvider(
        id: '',
        category: ServiceCategory.technicians,
        specialty: 'نجارة',
        name: 'ورشة أحمد',
        phone: '0100',
        submittedBy: 'u1',
      ));
      final snap = await fake.collection('service_providers').get();
      final data = snap.docs.single.data();
      expect(data['isApproved'], false);
      expect(data['category'], 'technicians');
      expect(data['specialty'], 'نجارة');
    });

    test('getApprovedByCategory filters approved + category only', () async {
      final fake = FakeFirebaseFirestore();
      final svc = ServiceProviderService(fake);
      await fake.collection('service_providers').add({
        'category': 'technicians', 'name': 'فني معتمد', 'isApproved': true,
      });
      await fake.collection('service_providers').add({
        'category': 'technicians', 'name': 'معلق', 'isApproved': false,
      });
      await fake.collection('service_providers').add({
        'category': 'educational', 'name': 'مدرس معتمد', 'isApproved': true,
      });
      final techs = await svc
          .getApprovedByCategory(ServiceCategory.technicians)
          .first;
      expect(techs.length, 1);
      expect(techs.single.name, 'فني معتمد');
    });

    test('السجل التعليمي القديم يُترجم إلى المراحل والأنواع الجديدة', () {
      final p = ServiceProvider.fromJson(
        {
          'category': 'educational',
          'name': 'أ. محمد',
          'specialty': 'الرياضيات',
          'stage': 'الصف الأول الثانوي',
        },
        'x',
      );
      expect(p.isApproved, isFalse);
      expect(p.isFeatured, isFalse);
      expect(p.ratingCount, 0);
      expect(p.stages, [kEduStageSecondary]);
      expect(p.eduTypes, [kEduTypePublic]);
      expect(p.subjects, ['الرياضيات']);
      expect(p.providerKindLabel, kEduKindTeacher);
      expect(p.offersPrivateTutoring, isFalse);
      expect(p.displaySpecialty, 'الرياضيات');
    });

    test('الثانوية الأزهرية القديمة ⇒ ثانوي + أزهري', () {
      final p = ServiceProvider.fromJson({
        'category': 'educational',
        'name': 'أ. سيد',
        'specialty': 'الفقه',
        'stage': 'الثانوية الأزهرية',
      }, 'x');
      expect(p.stages, [kEduStageSecondary]);
      expect(p.eduTypes, [kEduTypeAzhar]);
    });

    test('مرحلة قديمة بلا مقابل تبقى ظاهرة تحت «مراحل أخرى»', () {
      final p = ServiceProvider.fromJson({
        'category': 'educational',
        'name': 'أ. فؤاد',
        'specialty': 'القراءة والخط العربي',
        'stage': 'محو الأمية وتعليم الكبار',
      }, 'x');
      expect(p.stages, isEmpty);
      expect(p.stageChips, ['محو الأمية وتعليم الكبار']);
    });

    test('السجل الجديد يكتب القوائم ومرآتيها للنسخ القديمة', () {
      const p = ServiceProvider(
        id: '',
        category: ServiceCategory.educational,
        name: 'أ. منى',
        phone: '0100',
        eduTypes: [kEduTypePublic, kEduTypePrivate],
        stages: [kEduStagePrep, kEduStageSecondary],
        subjects: ['الرياضيات', 'الفيزياء'],
        offersPrivateTutoring: true,
      );
      final json = p.toJson();
      expect(json['providerKind'], kEduKindTeacher);
      expect(json['eduTypes'], [kEduTypePublic, kEduTypePrivate]);
      expect(json['stages'], [kEduStagePrep, kEduStageSecondary]);
      expect(json['subjects'], ['الرياضيات', 'الفيزياء']);
      expect(json['offersPrivateTutoring'], true);
      // المرآتان: النص القديم الذي تقرأه النسخ المثبّتة على الأجهزة.
      expect(json['specialty'], 'الرياضيات، الفيزياء');
      expect(json['stage'], 'إعدادي، ثانوي');
    });

    test('سجل غير تعليمي لا يحمل حقول التعليم', () {
      const p = ServiceProvider(
          id: '',
          category: ServiceCategory.technicians,
          specialty: 'نجارة',
          name: 'ورشة');
      final json = p.toJson();
      expect(json.containsKey('stages'), isFalse);
      expect(json.containsKey('subjects'), isFalse);
      expect(json.containsKey('providerKind'), isFalse);
      expect(p.displaySpecialty, 'نجارة');
    });

    test('المدرسة لا تحمل «تدريس خاص» حتى لو كُتبت في المستند', () {
      final p = ServiceProvider.fromJson({
        'category': 'educational',
        'name': 'مدرسة النور',
        'providerKind': kEduKindSchool,
        'offersPrivateTutoring': true,
        'eduTypes': [kEduTypePrivate],
        'stages': [kEduStagePrimary],
        'subjects': ['الرياضيات'],
      }, 'x');
      expect(p.isSchool, isTrue);
      expect(p.offersPrivateTutoring, isFalse);
    });

    test('قائمة المواد المصرية كاملة وبلا تكرار وبلا «غير ذلك»', () {
      expect(kEgyptSubjects.length, greaterThan(40));
      expect(kEgyptSubjects.toSet().length, kEgyptSubjects.length,
          reason: 'بلا تكرار');
      // المادة التي لا قائمة لها تُكتب يدويًا في الحقل المخصص، لا «غير ذلك».
      expect(kEgyptSubjects, isNot(contains('غير ذلك')));
      expect(
          kEgyptSubjects,
          containsAll([
            'اللغة العربية',
            'الفيزياء',
            'الرياضيات البحتة (جبر وهندسة فراغية)',
            'الاقتصاد والإحصاء',
            'النحو والصرف',
            'التفسير وعلوم القرآن',
            'محفظ قرآن كريم',
          ]));
      // كل قسم غير فارغ، وكل قيمة فيه موجودة في القائمة المسطّحة.
      for (final entry in kEgyptSubjectSections.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key);
        expect(kEgyptSubjects, containsAll(entry.value));
      }
    });

    test('المراحل خمسة والأنواع ثلاثة والصفة خياران', () {
      expect(kEduStages,
          ['تمهيدي', 'ابتدائي', 'إعدادي', 'ثانوي', 'جامعي']);
      expect(kEduTypes, ['تعليم عام', 'أزهري', 'خاص']);
      expect(kEduKinds, ['مدرس', 'مدرسة']);
    });

    test('featured provider gets gold accent', () {
      const p = ServiceProvider(
          id: 'x', category: 'technicians', name: 'نجار', isFeatured: true);
      expect(p.accentColor.toARGB32(), 0xFFB8860B);
      expect(p.toJson()['isFeatured'], true);
    });

    test('حِرف الفنيون تشمل كاميرات مراقبة ودش وأعمال منزلية', () {
      final crafts = kSubcategoriesFor(ServiceCategory.technicians);
      expect(crafts, containsAll(['كاميرات مراقبة ودش', 'أعمال منزلية']));
      // «غير ذلك» يبقى الخيار الأخير في القائمة المنسدلة ونموذج الإضافة.
      expect(crafts.last, 'غير ذلك');
      expect(crafts.toSet().length, crafts.length, reason: 'بلا تكرار');
    });

    test('getApprovedByCategory lists featured first', () async {
      final fake = FakeFirebaseFirestore();
      final svc = ServiceProviderService(fake);
      await fake.collection('service_providers').add({
        'category': 'technicians', 'name': 'أ عادي', 'isApproved': true, 'isFeatured': false,
      });
      await fake.collection('service_providers').add({
        'category': 'technicians', 'name': 'ب مميز', 'isApproved': true, 'isFeatured': true,
      });
      final list = await svc
          .getApprovedByCategory(ServiceCategory.technicians)
          .first;
      expect(list.first.isFeatured, isTrue);
      expect(list.first.name, 'ب مميز');
    });
  });

  group('ServiceProvider comments + ratings', () {
    Future<String> seedProvider(FirebaseFirestore fake) async {
      final ref = await fake.collection('service_providers').add({
        'category': 'technicians',
        'name': 'ورشة',
        'isApproved': true,
        'rating': 0,
        'ratingCount': 0,
      });
      return ref.id;
    }

    test('addComment stores comment and updates aggregate rating', () async {
      final fake = FakeFirebaseFirestore();
      final id = await seedProvider(fake);
      final svc = ServiceProviderService(fake);
      await svc.addComment(ServiceProviderComment(
          id: '',
          providerId: id,
          userId: 'u1',
          userName: 'مستخدم ١',
          rating: 5,
          text: 'ممتاز'));
      final doc = await fake.collection('service_providers').doc(id).get();
      expect((doc.data()!['rating'] as num).toDouble(), 5.0);
      expect(doc.data()!['ratingCount'], 1);

      final comments = await svc.getCommentsStream(id).first;
      expect(comments.single.userName, 'مستخدم ١');
    });

    test('second user rating updates average', () async {
      final fake = FakeFirebaseFirestore();
      final id = await seedProvider(fake);
      final svc = ServiceProviderService(fake);
      await svc.addComment(ServiceProviderComment(
          id: '', providerId: id, userId: 'u1', userName: 'أ', rating: 5));
      await svc.addComment(ServiceProviderComment(
          id: '', providerId: id, userId: 'u2', userName: 'ب', rating: 4));
      final doc = await fake.collection('service_providers').doc(id).get();
      expect((doc.data()!['rating'] as num).toDouble(), 4.5);
      expect(doc.data()!['ratingCount'], 2);
    });

    test('same user rating replaces previous (no duplicates)', () async {
      final fake = FakeFirebaseFirestore();
      final id = await seedProvider(fake);
      final svc = ServiceProviderService(fake);
      await svc.addComment(ServiceProviderComment(
          id: '', providerId: id, userId: 'u1', userName: 'أ', rating: 2));
      await svc.addComment(ServiceProviderComment(
          id: '', providerId: id, userId: 'u1', userName: 'أ', rating: 5));
      final doc = await fake.collection('service_providers').doc(id).get();
      expect(doc.data()!['ratingCount'], 1);
      expect((doc.data()!['rating'] as num).toDouble(), 5.0);
    });

    test('provider comment stores userPhotoUrl and rating', () async {
      final fake = FakeFirebaseFirestore();
      final id = await seedProvider(fake);
      final svc = ServiceProviderService(fake);
      await svc.addComment(ServiceProviderComment(
          id: '',
          providerId: id,
          userId: 'u1',
          userName: 'علي',
          photoUrl: 'https://x/p.jpg',
          rating: 5));
      final comments = await svc.getCommentsStream(id).first;
      expect(comments.single.userName, 'علي');
      expect(comments.single.photoUrl, 'https://x/p.jpg');
    });
  });

  group('MedicalLabService', () {
    test('create persists unapproved lab with homeCollection', () async {
      final fake = FakeFirebaseFirestore();
      final svc = MedicalLabService(fake);
      await svc.create(const MedicalLab(
        id: '',
        name: 'معمل النور',
        category: 'تحاليل هرمونات',
        homeCollection: true,
        phone: '0100',
        submittedBy: 'u1',
      ));
      final snap = await fake.collection('medical_labs').get();
      final data = snap.docs.single.data();
      expect(data['isApproved'], false);
      expect(data['homeCollection'], true);
      expect(data['category'], 'تحاليل هرمونات');
    });

    test('getApprovedStream shows only approved, home-collection first',
        () async {
      final fake = FakeFirebaseFirestore();
      final svc = MedicalLabService(fake);
      await fake.collection('medical_labs').add({
        'name': 'ب معتمد منزلي', 'isApproved': true, 'homeCollection': true,
      });
      await fake.collection('medical_labs').add({
        'name': 'أ معتمد', 'isApproved': true, 'homeCollection': false,
      });
      await fake.collection('medical_labs').add({
        'name': 'معلق', 'isApproved': false, 'homeCollection': true,
      });
      final list = await svc.getApprovedStream().first;
      expect(list.length, 2);
      expect(list.first.name, 'ب معتمد منزلي');
    });
  });

  group('MedicalCenterClinic approval field', () {
    test('legacy docs without isApproved parse as approved', () {
      final c = MedicalCenterClinic.fromJson({'name': 'عيادة'}, 'x');
      expect(c.isApproved, isTrue);
    });

    test('addClinic with isApproved=false stays pending', () async {
      final fake = FakeFirebaseFirestore();
      final svc = MedicalCenterService(fake);
      await svc.addClinic(const MedicalCenterClinic(
        id: '',
        name: 'عيادة جديدة',
        isApproved: false,
      ));
      final snap = await fake.collection('medical_center_clinics').get();
      expect(snap.docs.single.data()['isApproved'], false);
    });

    test('public clinic toJson carries isApproved flag', () {
      const c = VillageClinic(id: 'x', name: 'عيادة');
      expect(c.toJson()['isApproved'], false);
    });
  });
}
