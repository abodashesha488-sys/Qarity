import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/village_content_models.dart';

/// خدمة محتوى «تعرف على القرية» الموسعة: العائلات، الشخصيات، التراث، المعالم، إلخ.
/// قراءة عامة والكتابة للأدمن (بقواعد Firestore).
///
/// كل القراءات تطلب المجموعة كما هي وتُرتّب في الكلاينت، لأن Firestore يُسقط من
/// نتائج الاستعلام أي وثيقة تفتقد الحقل المرتَّب عليه: نماذج «الشخصيات البارزة»
/// و«شخصيات الذاكرة» لا تكتب `sortOrder` إطلاقًا، فكان `orderBy('sortOrder')`
/// يعيد قائمة فارغة دائمًا — أي أن ما يضيفه الأدمن يُحفظ فعلًا ولا يظهر أبدًا.
/// مُثبت على المجموعة الحيّة: استعلام بترتيب على `village_notable_people` أرجع
/// صفرًا والمستند الوحيد موجود.
class VillageExtendedService {
  final FirebaseFirestore _firestore;
  VillageExtendedService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _firestore.collection(name);

  List<T> _mapDocs<T>(QuerySnapshot<Map<String, dynamic>> s,
          T Function(Map<String, dynamic>, String) f) =>
      s.docs.map((d) => f(d.data(), d.id)).toList();

  /// قراءة المجموعة كاملة ثم الفرز في الكلاينت: لا وثيقة تُفقد بسبب حقل ناقص،
  /// ولا استعلام يحتاج فهرسًا مركّبًا.
  Stream<List<T>> _readSorted<T>(
    String collection,
    T Function(Map<String, dynamic>, String) from,
    int Function(T a, T b) compare,
  ) =>
      _col(collection)
          .snapshots()
          .map((s) => [..._mapDocs(s, from)]..sort(compare));

  // ═══════════════ العائلات (village_families) ═══════════════
  Stream<List<VillageFamily>> watchFamilies() => _readSorted(
        'village_families',
        VillageFamily.fromJson,
        (a, b) =>
            villageByOrderThenNewest(
                a.sortOrder, a.createdAt, b.sortOrder, b.createdAt),
      );

  Future<void> saveFamily(VillageFamily f) => f.id.isEmpty
      ? _col('village_families').add(f.toJson())
      : _col('village_families').doc(f.id).set(f.toJson());

  Future<void> deleteFamily(String id) =>
      _col('village_families').doc(id).delete();

  // ═══════════════ الشخصيات البارزة (village_notable_people) ═══════════════
  Stream<List<VillageNotablePerson>> watchNotablePeople() => _readSorted(
        'village_notable_people',
        VillageNotablePerson.fromJson,
        (a, b) =>
            villageByNameThenNewest(
                a.fullName, a.createdAt, b.fullName, b.createdAt),
      );

  Future<void> saveNotablePerson(VillageNotablePerson p) => p.id.isEmpty
      ? _col('village_notable_people').add(p.toJson())
      : _col('village_notable_people').doc(p.id).set(p.toJson());

  Future<void> deleteNotablePerson(String id) =>
      _col('village_notable_people').doc(id).delete();

  // ═══════════════ شخصيات الذاكرة (village_memorial_people) ═══════════════
  Stream<List<VillageMemorialPerson>> watchMemorialPeople() => _readSorted(
        'village_memorial_people',
        VillageMemorialPerson.fromJson,
        (a, b) =>
            villageByNameThenNewest(
                a.fullName, a.createdAt, b.fullName, b.createdAt),
      );

  Future<void> saveMemorialPerson(VillageMemorialPerson p) => p.id.isEmpty
      ? _col('village_memorial_people').add(p.toJson())
      : _col('village_memorial_people').doc(p.id).set(p.toJson());

  Future<void> deleteMemorialPerson(String id) =>
      _col('village_memorial_people').doc(id).delete();

  // ═══════════════ التراث (village_heritage) ═══════════════
  Stream<List<VillageHeritage>> watchHeritage() => _readSorted(
        'village_heritage',
        VillageHeritage.fromJson,
        (a, b) =>
            villageByOrderThenNewest(
                a.sortOrder, a.createdAt, b.sortOrder, b.createdAt),
      );

  Future<void> saveHeritage(VillageHeritage h) => h.id.isEmpty
      ? _col('village_heritage').add(h.toJson())
      : _col('village_heritage').doc(h.id).set(h.toJson());

  Future<void> deleteHeritage(String id) =>
      _col('village_heritage').doc(id).delete();

  // ═══════════════ المعالم (village_landmarks) ═══════════════
  Stream<List<VillageLandmark>> watchLandmarks() => _readSorted(
        'village_landmarks',
        VillageLandmark.fromJson,
        (a, b) =>
            villageByOrderThenNewest(
                a.sortOrder, a.createdAt, b.sortOrder, b.createdAt),
      );

  Future<void> saveLandmark(VillageLandmark l) => l.id.isEmpty
      ? _col('village_landmarks').add(l.toJson())
      : _col('village_landmarks').doc(l.id).set(l.toJson());

  Future<void> deleteLandmark(String id) =>
      _col('village_landmarks').doc(id).delete();

  // ═══════════════ الأمس واليوم (village_before_after) ═══════════════
  Stream<List<VillageBeforeAfter>> watchBeforeAfter() => _readSorted(
        'village_before_after',
        VillageBeforeAfter.fromJson,
        (a, b) =>
            villageByOrderThenNewest(
                a.sortOrder, a.createdAt, b.sortOrder, b.createdAt),
      );

  Future<void> saveBeforeAfter(VillageBeforeAfter b) => b.id.isEmpty
      ? _col('village_before_after').add(b.toJson())
      : _col('village_before_after').doc(b.id).set(b.toJson());

  Future<void> deleteBeforeAfter(String id) =>
      _col('village_before_after').doc(id).delete();

  // ═══════════════ تاريخ الزراعة (village_agriculture_history) ═══════════════
  Stream<List<VillageAgricultureHistory>> watchAgricultureHistory() => _readSorted(
        'village_agriculture_history',
        VillageAgricultureHistory.fromJson,
        (a, b) =>
            villageByOrderThenNewest(
                a.sortOrder, a.createdAt, b.sortOrder, b.createdAt),
      );

  Future<void> saveAgricultureHistory(VillageAgricultureHistory a) =>
      a.id.isEmpty
          ? _col('village_agriculture_history').add(a.toJson())
          : _col('village_agriculture_history').doc(a.id).set(a.toJson());

  Future<void> deleteAgricultureHistory(String id) =>
      _col('village_agriculture_history').doc(id).delete();

  // ═══════════════ تاريخ التعليم (village_education_history) ═══════════════
  Stream<List<VillageEducationHistory>> watchEducationHistory() => _readSorted(
        'village_education_history',
        VillageEducationHistory.fromJson,
        (a, b) =>
            villageByOrderThenNewest(
                a.sortOrder, a.createdAt, b.sortOrder, b.createdAt),
      );

  Future<void> saveEducationHistory(VillageEducationHistory e) => e.id.isEmpty
      ? _col('village_education_history').add(e.toJson())
      : _col('village_education_history').doc(e.id).set(e.toJson());

  Future<void> deleteEducationHistory(String id) =>
      _col('village_education_history').doc(id).delete();

  // ═══════════════ تطور القرية (village_development_timeline) ═══════════════
  Stream<List<VillageDevelopmentTimeline>> watchDevelopmentTimeline() =>
      _readSorted(
        'village_development_timeline',
        VillageDevelopmentTimeline.fromJson,
        (a, b) =>
            villageByOrderThenNewest(
                a.sortOrder, a.createdAt, b.sortOrder, b.createdAt),
      );

  Future<void> saveDevelopmentTimeline(VillageDevelopmentTimeline d) =>
      d.id.isEmpty
          ? _col('village_development_timeline').add(d.toJson())
          : _col('village_development_timeline').doc(d.id).set(d.toJson());

  Future<void> deleteDevelopmentTimeline(String id) =>
      _col('village_development_timeline').doc(id).delete();

  // ═══════════════ الإنجازات (village_achievements) ═══════════════
  Stream<List<VillageAchievement>> watchAchievements() => _readSorted(
        'village_achievements',
        VillageAchievement.fromJson,
        (a, b) =>
            villageByOrderThenNewest(
                a.sortOrder, a.createdAt, b.sortOrder, b.createdAt),
      );

  Future<void> saveAchievement(VillageAchievement a) => a.id.isEmpty
      ? _col('village_achievements').add(a.toJson())
      : _col('village_achievements').doc(a.id).set(a.toJson());

  Future<void> deleteAchievement(String id) =>
      _col('village_achievements').doc(id).delete();

  // ═══════════════ عناصر الأرشيف الرقمي (village_archive_items) ═══════════════
  Stream<List<VillageArchiveItem>> watchArchiveItems() => _readSorted(
        'village_archive_items',
        VillageArchiveItem.fromJson,
        (a, b) =>
            villageByOrderThenNewest(
                a.sortOrder, a.createdAt, b.sortOrder, b.createdAt),
      );

  /// عناصر الأرشيف المعتمدة فقط (للعرض العام).
  Stream<List<VillageArchiveItem>> watchApprovedArchiveItems() =>
      watchArchiveItems().map((items) => items
          .where((i) => i.approvalStatus == 'approved')
          .toList(growable: false));

  /// كل عناصر الأرشيف بجميع الحالات (للوحة الإدارة داخل القسم).
  Stream<List<VillageArchiveItem>> watchAllArchiveItems() =>
      watchArchiveItems();

  Future<void> saveArchiveItem(VillageArchiveItem a) => a.id.isEmpty
      ? _col('village_archive_items').add(a.toJson())
      : _col('village_archive_items').doc(a.id).set(a.toJson());

  Future<void> deleteArchiveItem(String id) =>
      _col('village_archive_items').doc(id).delete();

  // ═══════════════ المساهمات (village_contributions) ═══════════════
  Stream<List<VillageContribution>> watchContributions() => _readSorted(
        'village_contributions',
        VillageContribution.fromJson,
        (a, b) => villageByNewest(a.createdAt, b.createdAt),
      );

  /// المساهمات المعتمدة والمثبّتة التي تظهر في صفحة «عن القرية».
  Stream<List<VillageContribution>> watchPinnedContributions() =>
      watchContributions().map((items) => items
          .where((item) => item.approvalStatus == 'approved' && item.pinOnHome)
          .toList(growable: false));

  /// مساهمات بانتظار المراجعة (لوحة الإشراف داخل القسم). الفلترة في الكلاينت
  /// لأن `where` + ترتيب على حقل آخر كان يتطلب فهرسًا مركّبًا غير موجود.
  Stream<List<VillageContribution>> watchPendingContributions() =>
      watchContributions()
          .map((items) => items
              .where((item) => item.approvalStatus == 'pending')
              .toList(growable: false));

  Future<void> saveContribution(VillageContribution c) => c.id.isEmpty
      ? _col('village_contributions').add(c.toJson())
      : _col('village_contributions').doc(c.id).set(c.toJson());

  Future<void> approveContribution(String id, String adminUid) =>
      _col('village_contributions').doc(id).set({
        'approvalStatus': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
      }, SetOptions(merge: true));

  Future<void> rejectContribution(String id, String adminUid) =>
      _col('village_contributions').doc(id).set({
        'approvalStatus': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
      }, SetOptions(merge: true));

  Future<void> deleteContribution(String id) =>
      _col('village_contributions').doc(id).delete();

  /// تثبيت/إلغاء تثبيت مساهمة معتمدة على الصفحة الرئيسية لقسم «عن القرية».
  Future<void> pinContribution(String id, bool pin) =>
      _col('village_contributions').doc(id).set(
        {'pinOnHome': pin},
        SetOptions(merge: true),
      );
}
