import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_models.dart';
import 'cache_service.dart';

class PhoneDirectoryService {
  final FirebaseFirestore _firestore;
  PhoneDirectoryService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  Future<List<PhoneDirectoryEntry>> getApprovedEntriesList({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getPhoneDirectory();
      if (cached != null) {
        return cached.map((json) => PhoneDirectoryEntry.fromJson(json, 'cache')).toList();
      }
    }
    final snapshot = await _firestore.collection('phone_directory').where('isApproved', isEqualTo: true).get();
    final entries = snapshot.docs.map((doc) => PhoneDirectoryEntry.fromJson(doc.data(), doc.id)).toList();
    await CacheService.savePhoneDirectory(entries.map((e) => e.toJson()).toList());
    return entries;
  }

  Future<List<PhoneDirectoryEntry>> getEntriesList() async {
    final snapshot = await _firestore.collection('phone_directory').get();
    return snapshot.docs.map((doc) => PhoneDirectoryEntry.fromJson(doc.data(), doc.id)).toList();
  }

  /// المعتمدة للجميع + إدخالات المستخدم نفسه المعلقة (يراها بوسم «قيد المراجعة»).
  Future<List<PhoneDirectoryEntry>> getVisibleEntriesList(String? userId) async {
    final all = await getEntriesList();
    await CacheService.savePhoneDirectory(
        all.where((e) => e.isApproved).map((e) => e.toJson()).toList());
    return all
        .where((e) => e.isApproved || (userId != null && e.submittedBy == userId))
        .toList();
  }
  
  Stream<List<PhoneDirectoryEntry>> getApprovedEntriesStream() {
    return _firestore
        .collection('phone_directory')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PhoneDirectoryEntry.fromJson(doc.data(), doc.id)).toList());
  }
  
  Stream<List<PhoneDirectoryEntry>> getAllEntriesStream() {
    return _firestore.collection('phone_directory').snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => PhoneDirectoryEntry.fromJson(doc.data(), doc.id)).toList());
  }
  
  Future<void> addPhoneDirectoryEntry(PhoneDirectoryEntry entry) async {
    await _firestore.collection('phone_directory').add(entry.toJson());
    await CacheService.invalidatePhoneDirectory();
  }
}
