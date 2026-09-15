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

/// فئات دليل الخدمات العامة.
class ServiceCategory {
  ServiceCategory._();
  static const technicians = 'technicians';
  static const agricultural = 'agricultural';
  static const educational = 'educational';

  static String label(String c) => switch (c) {
        technicians => 'الفنيون',
        agricultural => 'خدمات زراعية',
        educational => 'خدمات تعليمية',
        _ => c,
      };

  static IconData icon(String c) => switch (c) {
        technicians => Icons.engineering_rounded,
        agricultural => Icons.agriculture_rounded,
        educational => Icons.school_rounded,
        _ => Icons.category_rounded,
      };

  static Color color(String c) => switch (c) {
        technicians => const Color(0xFFEF6C00),
        agricultural => const Color(0xFFAD1457),
        educational => const Color(0xFF1565C0),
        _ => Colors.teal,
      };
}

/// مهن وحرف القرية الفنية والمهنية.
const List<String> kTechnicianCrafts = [
  'نجارة',
  'نجارة موبيليا',
  'حدادة ولحام',
  'سباكة',
  'كهرباء',
  'تبريد وتكييف',
  'محارة وتلييس',
  'بناء ومباني',
  'دهانات وتشطيبات',
  'ألمنيوم وزجاج',
  'رخام وبلاط',
  'ميكانيكا وتكاتك',
  'كهربا سيارات',
  'صيانة موبايلات',
  'صيانة أجهزة كهربائية',
  'خياطة وتفصيل',
  'أحذية وجلود',
  'سلالم وأبواب حديد',
  'حرف يدوية وفخار',
  'غير ذلك',
];

/// الخدمات الزراعية المقدمة للمزارعين.
const List<String> kAgriculturalServices = [
  'آلات ومحاريث حرث',
  'جرارات زراعية',
  'ماكينات ومعدات حصاد',
  'دراسات قمح وأرز',
  'طلمبات ومواتير ري',
  'شبكات ري حديث وتنقيط',
  'نقل وحصاد المحاصيل',
  'تطعيم ونخيل',
  'أسمدة ومبيدات',
  'مكافحة آفات وقوارض',
  'تربية ماشية وأغنام',
  'تربية دواجن ونحل',
  'أعلاف ومستلزمات ثروة حيوانية',
  'صوبات زراعية (بيوت محمية)',
  'تجميع وتبريد محصولات',
  'غير ذلك',
];

/// مراحل التعليم حسب نظام جمهورية مصر العربية.
const List<String> kEducationalStages = [
  'رياض الأطفال (KG1 - KG2)',
  'المرحلة الابتدائية (الصفوف ١ - ٦)',
  'المرحلة الإعدادية (الصفوف ١ - ٣)',
  'الصف الأول الثانوي',
  'الصف الثاني الثانوي',
  'الصف الثالث الثانوي (علمي علوم)',
  'الصف الثالث الثانوي (علمي رياضة)',
  'الثانوية الأزهرية',
  'محو الأمية وتعليم الكبار',
];

/// المواد الدراسية الشائعة عبر المراحل.
const List<String> kSchoolSubjects = [
  'اللغة العربية',
  'الرياضيات',
  'العلوم',
  'اللغة الإنجليزية',
  'الدراسات الاجتماعية',
  'التربية الدينية',
  'الفيزياء',
  'الكيمياء',
  'الأحياء',
  'الجيولوجيا وعلوم البيئة',
  'الرياضيات البحتة',
  'الرياضيات التطبيقية (استاتيكا/ديناميكا)',
  'الفلسفة والمنطق',
  'علم النفس والاجتماع',
  'الاقتصاد والإحصاء',
  'اللغة الفرنسية',
  'غير ذلك',
];

/// قائمة المجموعات الفرعية حسب الفئة.
List<String> kSubcategoriesFor(String category) =>
    switch (category) {
      ServiceCategory.technicians => kTechnicianCrafts,
      ServiceCategory.agricultural => kAgriculturalServices,
      ServiceCategory.educational => kSchoolSubjects,
      _ => const [],
    };

// ═══════════════════ مقدم خدمة في دليل الخدمات ═══════════════════
class ServiceProvider {
  final String id;
  final String category; // technicians | agricultural | educational
  final String specialty; // الحرفة / الخدمة / المادة
  final String stage; // مرحلة تعليمية (فئة تعليمية فقط)
  final String name;
  final String phone;
  final String address;
  final String description;
  final String? photoUrl;
  final bool isApproved;
  final bool isFeatured; // بيان مميز من الأدمن — لون ذهبي وشارة «مميز»
  final double rating; // متوسط التقييمات (يُحدَّث ذرياً عند إضافة تقييم)
  final int ratingCount;
  final String? submittedBy;
  final String? submittedByName;
  final DateTime? createdAt;

  const ServiceProvider({
    required this.id,
    required this.category,
    this.specialty = '',
    this.stage = '',
    required this.name,
    this.phone = '',
    this.address = '',
    this.description = '',
    this.photoUrl,
    this.isApproved = false,
    this.isFeatured = false,
    this.rating = 0,
    this.ratingCount = 0,
    this.submittedBy,
    this.submittedByName,
    this.createdAt,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json, String docId) {
    return ServiceProvider(
      id: docId,
      category: json['category'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      stage: json['stage'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      submittedBy: json['submittedBy'] as String?,
      submittedByName: json['submittedByName'] as String?,
      createdAt: _parseTsOrNull(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'specialty': specialty,
        'stage': stage,
        'name': name,
        'phone': phone,
        'address': address,
        'description': description,
        if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
        'isApproved': isApproved,
        'isFeatured': isFeatured,
        'rating': rating,
        'ratingCount': ratingCount,
        'submittedBy': submittedBy,
        'submittedByName': submittedByName,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  /// عنوان العرض داخل القوائم المنسدلة (المادة + المرحلة للتعليمي).
  String get displaySpecialty =>
      category == ServiceCategory.educational && stage.isNotEmpty
          ? '$specialty — $stage'
          : specialty;

  bool get hasContact => phone.trim().isNotEmpty;

  /// اللون المميّز (ذهبي) للبيان المميز، ولون الفئة للعادي.
  Color get accentColor =>
      isFeatured ? const Color(0xFFB8860B) : ServiceCategory.color(category);

  ServiceProvider copyWith({bool? isFeatured}) => ServiceProvider(
        id: id,
        category: category,
        specialty: specialty,
        stage: stage,
        name: name,
        phone: phone,
        address: address,
        description: description,
        photoUrl: photoUrl,
        isApproved: isApproved,
        isFeatured: isFeatured ?? this.isFeatured,
        rating: rating,
        ratingCount: ratingCount,
        submittedBy: submittedBy,
        submittedByName: submittedByName,
        createdAt: createdAt,
      );
}

// ═══════════════════════ تعليق/تقييم على مقدّم خدمة ═══════════════════════
class ServiceProviderComment {
  final String id;
  final String providerId;
  final String userId;
  final String userName;
  final String? photoUrl; // صورة كاتب التعليق من ملفه الشخصي
  final int rating; // من 1 إلى 5
  final String text;
  final DateTime? createdAt;

  const ServiceProviderComment({
    required this.id,
    required this.providerId,
    required this.userId,
    required this.userName,
    this.photoUrl,
    this.rating = 0,
    this.text = '',
    this.createdAt,
  });

  factory ServiceProviderComment.fromJson(
      Map<String, dynamic> json, String docId) {
    return ServiceProviderComment(
      id: docId,
      providerId: json['providerId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      photoUrl: json['userPhotoUrl'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
      createdAt: _parseTsOrNull(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'userId': userId,
        'userName': userName,
        if (photoUrl != null && photoUrl!.isNotEmpty) 'userPhotoUrl': photoUrl,
        'rating': rating,
        'text': text,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
