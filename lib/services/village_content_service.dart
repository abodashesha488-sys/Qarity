import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/village_content_models.dart';

/// خدمة محتوى «تعرف على القرية»: تواريخ، شخصيات، أرشيف صور، منشآت.
/// قراءة عامة والكتابة للأدمن (بقواعد Firestore)، مع هجرة أحادية
/// للمحتوى النصي القديم المخزّن داخل وثيقة village_info/main.
class VillageContentService {
  final FirebaseFirestore _firestore;
  VillageContentService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _firestore.collection(name);

  List<T> _mapDocs<T>(QuerySnapshot<Map<String, dynamic>> s,
          T Function(Map<String, dynamic>, String) f) =>
      s.docs.map((d) => f(d.data(), d.id)).toList();

  /// ترتيب الحقبات تصاعديًا (الأقدم أولًا) — نفس ترتيب سلسلة العمد.
  Stream<List<HistoryEra>> watchEras() => _col('village_history')
      .orderBy('sortOrder')
      .snapshots()
      .map((s) => _mapDocs(s, HistoryEra.fromJson));

  Stream<List<VillageFigure>> watchFigures() => _col('village_figures')
      .orderBy('sortOrder')
      .snapshots()
      .map((s) => _mapDocs(s, VillageFigure.fromJson));

  Stream<List<VillageArchivePhoto>> watchArchivePhotos() =>
      _col('village_archive_photos')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => _mapDocs(s, VillageArchivePhoto.fromJson));

  Stream<List<VillageInstitution>> watchInstitutions() =>
      _col('village_institutions')
          .orderBy('sortOrder')
          .snapshots()
          .map((s) => _mapDocs(s, VillageInstitution.fromJson));

  Future<void> saveEra(HistoryEra e) =>
      e.id.isEmpty ? _col('village_history').add(e.toJson())
          : _col('village_history').doc(e.id).set(e.toJson());

  Future<void> saveFigure(VillageFigure f) =>
      f.id.isEmpty ? _col('village_figures').add(f.toJson())
          : _col('village_figures').doc(f.id).set(f.toJson());

  Future<void> saveArchivePhoto(VillageArchivePhoto p) =>
      p.id.isEmpty ? _col('village_archive_photos').add(p.toJson())
          : _col('village_archive_photos').doc(p.id).set(p.toJson());

  Future<void> saveInstitution(VillageInstitution i) =>
      i.id.isEmpty ? _col('village_institutions').add(i.toJson())
          : _col('village_institutions').doc(i.id).set(i.toJson());

  Future<void> deleteDoc(String collection, String id) =>
      _col(collection).doc(id).delete();

  /// يحوّل القوائم النصية القديمة داخل village_info/main إلى العناصر الجديدة
  /// مرة واحدة فقط (ختم contentMigrated). يعيد عدد العناصر المنقولة.
  Future<int> migrateLegacyIfNeeded() async {
    final mainRef = _col('village_info').doc('main');
    final snap = await mainRef.get();
    if (!snap.exists) return 0;
    final data = snap.data()!;
    if (data['contentMigrated'] == true) return 0;

    var moved = 0;

    final history = (data['history'] as List<dynamic>?) ?? const [];
    var order = 1;
    for (final h in history) {
      if (h is! Map) continue;
      final event = h['event']?.toString().trim() ?? '';
      if (event.isEmpty) continue;
      await _col('village_history').add({
        'title': 'من ذاكرة القرية',
        'years': h['year']?.toString() ?? '',
        'narrative': event,
        'imageUrl': '',
        'sortOrder': order++,
        'createdAt': FieldValue.serverTimestamp(),
      });
      moved++;
    }

    final institutions = (data['institutions'] as List<dynamic>?) ?? const [];
    order = 1;
    for (final ins in institutions) {
      if (ins is! Map) continue;
      final name = ins['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      await _col('village_institutions').add({
        'name': name,
        'type': InstitutionType.guessFromName(name),
        'description': ins['description']?.toString() ?? '',
        'location': ins['location']?.toString() ?? '',
        'phone': '',
        'workingHours': '',
        'imageUrls': const <String>[],
        'sortOrder': order++,
        'createdAt': FieldValue.serverTimestamp(),
      });
      moved++;
    }

    final archive = (data['archive'] as List<dynamic>?) ?? const [];
    for (final a in archive) {
      final title = a?.toString().trim() ?? '';
      if (title.isEmpty) continue;
      await _col('village_archive_photos').add({
        'title': title,
        'year': '',
        'description': '',
        'source': '',
        'imageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      moved++;
    }

    await mainRef.set({'contentMigrated': true}, SetOptions(merge: true));
    return moved;
  }
}
