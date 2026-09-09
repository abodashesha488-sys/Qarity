import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medical_models.dart';

/// خدمة المركز الطبي الخيري — عيادات بأجور رمزية مع المواعيد.
/// يديرها «مدير المركز الطبي» (الدور medical_admin) أو المدير العام، والعام للقراءة.
class MedicalCenterService {
  final FirebaseFirestore _firestore;
  MedicalCenterService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('medical_center_clinics');

  Future<String> addClinic(MedicalCenterClinic clinic) async {
    final ref = await _col.add(clinic.toJson());
    return ref.id;
  }

  Future<void> updateClinic(String id, Map<String, dynamic> data) async {
    await _col
        .doc(id)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteClinic(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> setActive(String id, bool active) async {
    await _col.doc(id).update({'isActive': active});
  }

  Stream<List<MedicalCenterClinic>> getClinicsStream() {
    return _col.snapshots().map((s) {
      final list = s.docs
          .map((d) => MedicalCenterClinic.fromJson(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// يضيف قائمة العيادات الافتراضية أول مرة فقط، ويمكن لمدير المركز تعديلها لاحقاً.
  Future<void> seedIfEmpty() async {
    final snap = await _col.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final defaults = const <MedicalCenterClinic>[
      MedicalCenterClinic(
          id: '',
          name: 'عيادة الباطنة',
          doctorName: 'د. —',
          workingDays: [
            'السبت',
            'الأحد',
            'الاثنين',
            'الثلاثاء',
            'الأربعاء'
          ],
          workingHours: '9 ص - 2 م',
          fees: 20),
      MedicalCenterClinic(
          id: '',
          name: 'عيادة الأطفال',
          specialty: 'أطفال وحديثي الولادة',
          doctorName: 'د. —',
          workingDays: ['السبت', 'الاثنين', 'الأربعاء'],
          workingHours: '10 ص - 1 م',
          fees: 20),
      MedicalCenterClinic(
          id: '',
          name: 'عيادة النساء والتوليد',
          specialty: 'نساء وتوليد',
          doctorName: 'د. —',
          workingDays: ['الأحد', 'الثلاثاء'],
          workingHours: '11 ص - 2 م',
          fees: 25),
      MedicalCenterClinic(
          id: '',
          name: 'عيادة الأسنان',
          specialty: 'أسنان',
          doctorName: 'د. —',
          workingDays: [
            'السبت',
            'الأحد',
            'الاثنين',
            'الثلاثاء',
            'الأربعاء'
          ],
          workingHours: '9 ص - 3 م',
          fees: 30),
      MedicalCenterClinic(
          id: '',
          name: 'عيادة الجلدية',
          specialty: 'جلدية وتناسلية',
          doctorName: 'د. —',
          workingDays: ['الاثنين', 'الأربعاء'],
          workingHours: '10 ص - 1 م',
          fees: 20),
      MedicalCenterClinic(
          id: '',
          name: 'عيادة العيون',
          specialty: 'عيون',
          doctorName: 'د. —',
          workingDays: ['الثلاثاء'],
          workingHours: '12 م - 3 م',
          fees: 25),
      MedicalCenterClinic(
          id: '',
          name: 'عيادة الأنف والأذن',
          specialty: 'أنف وأذن وحنجرة',
          doctorName: 'د. —',
          workingDays: ['الأحد', 'الثلاثاء'],
          workingHours: '10 ص - 1 م',
          fees: 20),
      MedicalCenterClinic(
          id: '',
          name: 'عيادة العظام',
          specialty: 'عظام ومفاصل',
          doctorName: 'د. —',
          workingDays: ['السبت', 'الاثنين'],
          workingHours: '11 ص - 2 م',
          fees: 25),
      MedicalCenterClinic(
          id: '',
          name: 'معامل التحاليل',
          specialty: 'تحاليل طبية',
          workingDays: [
            'السبت',
            'الأحد',
            'الاثنين',
            'الثلاثاء',
            'الأربعاء'
          ],
          workingHours: '8 ص - 2 م',
          fees: 10),
      MedicalCenterClinic(
          id: '',
          name: 'قسم الأشعة',
          specialty: 'أشعة وتصوير',
          workingDays: ['السبت', 'الاثنين', 'الأربعاء'],
          workingHours: '10 ص - 1 م',
          fees: 30),
    ];
    final batch = _firestore.batch();
    for (final c in defaults) {
      batch.set(_col.doc(), c.toJson());
    }
    await batch.commit();
  }
}

/// خدمة عيادات القرية — مدخلات مستخدمين تحتاج موافقة الأدمن.
class VillageClinicService {
  final FirebaseFirestore _firestore;
  VillageClinicService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('village_clinics');

  Future<String> create(VillageClinic clinic) async {
    final ref = await _col.add(clinic.toJson());
    return ref.id;
  }

  Stream<List<VillageClinic>> getApprovedStream() {
    return _col.where('isApproved', isEqualTo: true).snapshots().map((s) {
      final list =
          s.docs.map((d) => VillageClinic.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return list;
    });
  }

  Future<List<VillageClinic>> getMine(String userId) async {
    final snap = await _col.where('submittedBy', isEqualTo: userId).get();
    return snap.docs
        .map((d) => VillageClinic.fromJson(d.data(), d.id))
        .toList();
  }
}

/// خدمة صيدليات القرية — مدخلات مستخدمين تحتاج موافقة الأدمن.
class PharmacyService {
  final FirebaseFirestore _firestore;
  PharmacyService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('pharmacies');

  Future<String> create(Pharmacy pharmacy) async {
    final ref = await _col.add(pharmacy.toJson());
    return ref.id;
  }

  Stream<List<Pharmacy>> getApprovedStream() {
    return _col.where('isApproved', isEqualTo: true).snapshots().map((s) {
      final list =
          s.docs.map((d) => Pharmacy.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) {
        if (a.is24Hours != b.is24Hours) return a.is24Hours ? -1 : 1;
        return (b.createdAt ?? DateTime(1970))
            .compareTo(a.createdAt ?? DateTime(1970));
      });
      return list;
    });
  }

  Future<List<Pharmacy>> getMine(String userId) async {
    final snap = await _col.where('submittedBy', isEqualTo: userId).get();
    return snap.docs.map((d) => Pharmacy.fromJson(d.data(), d.id)).toList();
  }
}

/// خدمة بنك الدم — متبرعون وطلبات تبرع (تحتاج موافقة الأدمن للظهور العام).
class BloodBankService {
  final FirebaseFirestore _firestore;
  BloodBankService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _donors =>
      _firestore.collection('blood_donors');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('blood_requests');

  // ── المتبرعون ──
  Future<String> addDonor(BloodDonor donor) async {
    final ref = await _donors.add(donor.toJson());
    return ref.id;
  }

  Future<void> updateDonor(String id, Map<String, dynamic> data) async {
    await _donors.doc(id).update(data);
  }

  Stream<List<BloodDonor>> getApprovedDonorsStream() {
    return _donors.where('isApproved', isEqualTo: true).snapshots().map((s) {
      final list =
          s.docs.map((d) => BloodDonor.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) => b.bloodType.code.compareTo(a.bloodType.code));
      return list;
    });
  }

  Future<List<BloodDonor>> getMyDonorRecords(String userId) async {
    final snap = await _donors.where('userId', isEqualTo: userId).get();
    return snap.docs.map((d) => BloodDonor.fromJson(d.data(), d.id)).toList();
  }

  /// عدد المتبرعين المتاحين لكل فصيلة (لعرض ملخص البنك).
  Future<Map<String, int>> countAvailableByType() async {
    final snap = await _donors
        .where('isApproved', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .get();
    final map = <String, int>{};
    for (final d in snap.docs) {
      final code = (d.data()['bloodType'] ?? '') as String;
      map[code] = (map[code] ?? 0) + 1;
    }
    return map;
  }

  // ── طلبات التبرع ──
  Future<String> createRequest(BloodRequest request) async {
    final ref = await _requests.add(request.toJson());
    return ref.id;
  }

  Stream<List<BloodRequest>> getOpenApprovedRequestsStream() {
    return _requests
        .where('isApproved', isEqualTo: true)
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => BloodRequest.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return list;
    });
  }

  Stream<List<BloodRequest>> getMyRequestsStream(String userId) {
    return _requests.where('userId', isEqualTo: userId).snapshots().map((s) {
      final list =
          s.docs.map((d) => BloodRequest.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return list;
    });
  }

  Future<void> closeRequest(String id) async {
    await _requests.doc(id).update({'status': 'closed'});
  }
}
