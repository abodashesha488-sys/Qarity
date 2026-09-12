import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

DateTime? _parseTsOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

// ═══════════════════════ فصائل الدم ═══════════════════════
enum BloodType {
  oPos('O+', 'O موجب'),
  oNeg('O-', 'O سالب'),
  aPos('A+', 'A موجب'),
  aNeg('A-', 'A سالب'),
  bPos('B+', 'B موجب'),
  bNeg('B-', 'B سالب'),
  abPos('AB+', 'AB موجب'),
  abNeg('AB-', 'AB سالب');

  final String code;
  final String label;
  const BloodType(this.code, this.label);

  static BloodType fromCode(String? c) => BloodType.values.firstWhere(
        (e) => e.code == c,
        orElse: () => BloodType.oPos,
      );
}

/// فئات العيادات (للمركز الخيري والعيادات والصيدليات).
const List<String> kClinicSpecialties = [
  'باطنة',
  'أطفال وحديثي الولادة',
  'نساء وتوليد',
  'أسنان',
  'جلدية وتناسلية',
  'عيون',
  'أنف وأذن وحنجرة',
  'عظام ومفاصل',
  'مخ وأعصاب',
  'قلب وأوعية',
  'صدر وحساسية',
  'مسالك بولية',
  'جراحة عامة',
  'تخدير وعلاج ألم',
  'تحاليل طبية',
  'أشعة وتصوير',
  'تغذية وعلاج سمنة',
  'نفسية وعصبية',
  'طوارئ',
  'غير ذلك',
];

// ═══════════════════════ عيادة المركز الطبي الخيري ═══════════════════════
class MedicalCenterClinic {
  final String id;
  final String name;
  final String specialty;
  final String doctorName;
  final String description;
  final List<String> workingDays; // ['السبت','الأحد',...]
  final String workingHours; // '9 ص - 2 م'
  final double fees; // أجر رمزي
  final bool isActive;
  final bool isApproved; // وثائق المركز القديمة تُعتبر معتمدة ضمناً
  final DateTime? updatedAt;

  const MedicalCenterClinic({
    required this.id,
    required this.name,
    this.specialty = 'باطنة',
    this.doctorName = '',
    this.description = '',
    this.workingDays = const [],
    this.workingHours = '',
    this.fees = 0,
    this.isActive = true,
    this.isApproved = true,
    this.updatedAt,
  });

  factory MedicalCenterClinic.fromJson(
      Map<String, dynamic> json, String docId) {
    return MedicalCenterClinic(
      id: docId,
      name: json['name'] as String? ?? '',
      specialty: json['specialty'] as String? ?? 'باطنة',
      doctorName: json['doctorName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      workingDays: (json['workingDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      workingHours: json['workingHours'] as String? ?? '',
      fees: (json['fees'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isApproved: json['isApproved'] as bool? ?? true,
      updatedAt: _parseTsOrNull(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'specialty': specialty,
        'doctorName': doctorName,
        'description': description,
        'workingDays': workingDays,
        'workingHours': workingHours,
        'fees': fees,
        'isActive': isActive,
        'isApproved': isApproved,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  MedicalCenterClinic copyWith({
    String? name,
    String? specialty,
    String? doctorName,
    String? description,
    List<String>? workingDays,
    String? workingHours,
    double? fees,
    bool? isActive,
  }) =>
      MedicalCenterClinic(
        id: id,
        name: name ?? this.name,
        specialty: specialty ?? this.specialty,
        doctorName: doctorName ?? this.doctorName,
        description: description ?? this.description,
        workingDays: workingDays ?? this.workingDays,
        workingHours: workingHours ?? this.workingHours,
        fees: fees ?? this.fees,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt,
      );

  String get scheduleLabel {
    if (workingDays.isEmpty && workingHours.isEmpty) return 'لم تُحدد المواعيد';
    final days = workingDays.isEmpty ? '' : workingDays.join(' • ');
    return [days, workingHours].where((e) => e.isNotEmpty).join(' | ');
  }
}

// ═══════════════════════ عيادة بالقرية (مدخَل مستخدم + موافقة) ═══════════════════════
class VillageClinic {
  final String id;
  final String name;
  final String specialty;
  final String ownerName;
  final String phone;
  final String address;
  final String workingHours;
  final String description;
  final List<String> imageUrls;
  final bool isApproved;
  final String? submittedBy;
  final String? submittedByName;
  final DateTime? createdAt;

  const VillageClinic({
    required this.id,
    required this.name,
    this.specialty = 'غير ذلك',
    this.ownerName = '',
    this.phone = '',
    this.address = '',
    this.workingHours = '',
    this.description = '',
    this.imageUrls = const [],
    this.isApproved = false,
    this.submittedBy,
    this.submittedByName,
    this.createdAt,
  });

  factory VillageClinic.fromJson(Map<String, dynamic> json, String docId) {
    return VillageClinic(
      id: docId,
      name: json['name'] as String? ?? '',
      specialty: json['specialty'] as String? ?? 'غير ذلك',
      ownerName: json['ownerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      workingHours: json['workingHours'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      isApproved: json['isApproved'] as bool? ?? false,
      submittedBy: json['submittedBy'] as String?,
      submittedByName: json['submittedByName'] as String?,
      createdAt: _parseTsOrNull(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'specialty': specialty,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'workingHours': workingHours,
        'description': description,
        'imageUrls': imageUrls,
        'isApproved': isApproved,
        'submittedBy': submittedBy,
        'submittedByName': submittedByName,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}

// ═══════════════════════ صيدلية بالقرية (مدخَل مستخدم + موافقة) ═══════════════════════
class Pharmacy {
  final String id;
  final String name;
  final String ownerName;
  final String phone;
  final String address;
  final String workingHours;
  final bool is24Hours;
  final String description;
  final List<String> imageUrls;
  final bool isApproved;
  final String? submittedBy;
  final String? submittedByName;
  final DateTime? createdAt;

  const Pharmacy({
    required this.id,
    required this.name,
    this.ownerName = '',
    this.phone = '',
    this.address = '',
    this.workingHours = '',
    this.is24Hours = false,
    this.description = '',
    this.imageUrls = const [],
    this.isApproved = false,
    this.submittedBy,
    this.submittedByName,
    this.createdAt,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json, String docId) {
    return Pharmacy(
      id: docId,
      name: json['name'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      workingHours: json['workingHours'] as String? ?? '',
      is24Hours: json['is24Hours'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      isApproved: json['isApproved'] as bool? ?? false,
      submittedBy: json['submittedBy'] as String?,
      submittedByName: json['submittedByName'] as String?,
      createdAt: _parseTsOrNull(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'workingHours': workingHours,
        'is24Hours': is24Hours,
        'description': description,
        'imageUrls': imageUrls,
        'isApproved': isApproved,
        'submittedBy': submittedBy,
        'submittedByName': submittedByName,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}

// ═══════════════════════ معامل التحاليل (مدخل مستخدمين + موافقة) ═══════════════════════
/// تصنيفات المعامل الشائعة.
const List<String> kLabCategories = [
  'تحاليل دم عامة',
  'تحاليل كيمياء',
  'تحاليل هرمونات',
  'ميكروبيولوجي ودقات',
  'أمصال ومناعة',
  'طفيليات وفطريات',
  'أنسجة وباثولوجي',
  'تحاليل ما قبل الزواج',
  'فحوصات حمل ومتابعة',
  'سكر ودهون وكوليسترول',
  'فيروسات (B - C - HIV)',
  'هرمونات غدة درقية',
  'تحاليل أطفال ANA وعوامل مناعة',
  'غير ذلك',
];

class MedicalLab {
  final String id;
  final String name;
  final String category;
  final String ownerName;
  final String phone;
  final String address;
  final String workingHours;
  final bool homeCollection; // سحب عينات بالمنزل
  final String description;
  final List<String> imageUrls;
  final bool isApproved;
  final String? submittedBy;
  final String? submittedByName;
  final DateTime? createdAt;

  const MedicalLab({
    required this.id,
    required this.name,
    this.category = 'غير ذلك',
    this.ownerName = '',
    this.phone = '',
    this.address = '',
    this.workingHours = '',
    this.homeCollection = false,
    this.description = '',
    this.imageUrls = const [],
    this.isApproved = false,
    this.submittedBy,
    this.submittedByName,
    this.createdAt,
  });

  factory MedicalLab.fromJson(Map<String, dynamic> json, String docId) {
    return MedicalLab(
      id: docId,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'غير ذلك',
      ownerName: json['ownerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      workingHours: json['workingHours'] as String? ?? '',
      homeCollection: json['homeCollection'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      isApproved: json['isApproved'] as bool? ?? false,
      submittedBy: json['submittedBy'] as String?,
      submittedByName: json['submittedByName'] as String?,
      createdAt: _parseTsOrNull(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'workingHours': workingHours,
        'homeCollection': homeCollection,
        'description': description,
        'imageUrls': imageUrls,
        'isApproved': isApproved,
        'submittedBy': submittedBy,
        'submittedByName': submittedByName,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}

// ═══════════════════════ متبرع بالدم ═══════════════════════
class BloodDonor {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final BloodType bloodType;
  final int age;
  final String gender; // 'ذكر' | 'أنثى'
  final String address;
  final DateTime? lastDonation;
  final bool isAvailable;
  final bool isApproved;
  final DateTime? createdAt;

  const BloodDonor({
    required this.id,
    required this.userId,
    required this.name,
    this.phone = '',
    this.bloodType = BloodType.oPos,
    this.age = 0,
    this.gender = '',
    this.address = '',
    this.lastDonation,
    this.isAvailable = true,
    this.isApproved = false,
    this.createdAt,
  });

  factory BloodDonor.fromJson(Map<String, dynamic> json, String docId) {
    return BloodDonor(
      id: docId,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      bloodType: BloodType.fromCode(json['bloodType'] as String?),
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? '',
      address: json['address'] as String? ?? '',
      lastDonation: _parseTsOrNull(json['lastDonation']),
      isAvailable: json['isAvailable'] as bool? ?? true,
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: _parseTsOrNull(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'phone': phone,
        'bloodType': bloodType.code,
        'age': age,
        'gender': gender,
        'address': address,
        'lastDonation':
            lastDonation != null ? Timestamp.fromDate(lastDonation!) : null,
        'isAvailable': isAvailable,
        'isApproved': isApproved,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}

// ═══════════════════════ طلب تبرع بالدم ═══════════════════════
class BloodRequest {
  final String id;
  final String userId;
  final String requesterName;
  final String phone;
  final String patientName;
  final BloodType bloodType;
  final int units;
  final String hospital;
  final String urgency; // 'عادي' | 'مستعجل' | 'طارئ'
  final String notes;
  final String status; // 'open' | 'closed'
  final bool isApproved;
  final DateTime? createdAt;

  const BloodRequest({
    required this.id,
    required this.userId,
    required this.requesterName,
    this.phone = '',
    this.patientName = '',
    this.bloodType = BloodType.oPos,
    this.units = 1,
    this.hospital = '',
    this.urgency = 'عادي',
    this.notes = '',
    this.status = 'open',
    this.isApproved = false,
    this.createdAt,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json, String docId) {
    return BloodRequest(
      id: docId,
      userId: json['userId'] as String? ?? '',
      requesterName: json['requesterName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      bloodType: BloodType.fromCode(json['bloodType'] as String?),
      units: (json['units'] as num?)?.toInt() ?? 1,
      hospital: json['hospital'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'عادي',
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: _parseTsOrNull(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'requesterName': requesterName,
        'phone': phone,
        'patientName': patientName,
        'bloodType': bloodType.code,
        'units': units,
        'hospital': hospital,
        'urgency': urgency,
        'notes': notes,
        'status': status,
        'isApproved': isApproved,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  bool get isOpen => status == 'open';
  Color get urgencyColor => switch (urgency) {
        'طارئ' => Colors.red,
        'مستعجل' => Colors.orange,
        _ => Colors.green,
      };
  String get statusLabel => isOpen ? 'مفتوح' : 'مغلق';
}
