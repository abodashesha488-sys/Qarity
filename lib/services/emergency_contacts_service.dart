import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/data_models.dart';
import 'cache_service.dart';

class EmergencyContactsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _ref = FirebaseFirestore.instance.collection('emergency_contacts');

  Stream<List<EmergencyContact>> getContactsStream() {
    return _ref
        .orderBy('priority')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyContact.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<List<EmergencyContact>> getContactsList({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getEmergencyContacts();
      if (cached != null) {
        return cached.map((json) => EmergencyContact.fromJson(json, 'cache')).toList();
      }
    }
    final snapshot = await _ref.orderBy('priority').get();
    final contacts = snapshot.docs
        .map((doc) => EmergencyContact.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    await CacheService.saveEmergencyContacts(contacts.map((c) => c.toJson()).toList());
    return contacts;
  }

  // Seed real, working national emergency numbers the first time only.
  // The village admin can later edit/extend these via the Firebase console.
  Future<void> seedIfEmpty() async {
    final snapshot = await _ref.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final defaults = [
      {
        'name': 'الشرطة',
        'phone': '122',
        'type': 'emergency',
        'description': 'الخط الساخن للشرطة',
        'priority': 0,
        'isActive': true,
      },
      {
        'name': 'الإسعاف',
        'phone': '123',
        'type': 'emergency',
        'description': 'الإسعاف والطوارئ الطبية',
        'priority': 1,
        'isActive': true,
      },
      {
        'name': 'الإطفاء',
        'phone': '180',
        'type': 'emergency',
        'description': 'الدفاع المدني والإطفاء',
        'priority': 2,
        'isActive': true,
      },
      {
        'name': 'النجدة',
        'phone': '112',
        'type': 'emergency',
        'description': 'رقم النجدة الموحد',
        'priority': 3,
        'isActive': true,
      },
    ];

    final batch = _firestore.batch();
    for (final data in defaults) {
      batch.set(_ref.doc(), data);
    }
    await batch.commit();
    await CacheService.invalidateEmergencyContacts();
  }
}
