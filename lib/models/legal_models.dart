import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/utils/firebase_ts.dart';

/// لون قسم «مستشار القرية» المميز — لا يتكرر مع أي قسم آخر في التطبيق.
const Color kLegalAdvisorColor = Color(0xFF006064);

/// تخصصات المحاماة المتاحة في السجل وفي تصفية الاستشارات.
const List<String> kLegalSpecializations = [
  'أحوال شخصية',
  'قضايا جنائية',
  'دعاوى مدنية',
  'عقارات وأراضٍ',
  'شركات وتجارة',
  'عمال وتأمينات',
  'منازعات إدارية',
  'تعويضات',
  'تنفيذ أحكام',
  'توثيق وشهر عقاري',
  'استشارات عامة',
  'غير ذلك',
];

/// محامٍ مقيد بسجل «مستشار القرية» (مجموعة lawyers).
/// يُضاف غير معتمد ويظهر للسجل بعد موافقة الإدارة.
class Lawyer {
  const Lawyer({
    this.id = '',
    required this.name,
    this.phone = '',
    this.specializations = const [],
    this.office = '',
    this.workingHours = '',
    this.bio = '',
    this.photoUrl = '',
    this.submittedBy = '',
    this.submittedByName = '',
    this.isApproved = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final List<String> specializations;
  final String office;
  final String workingHours;
  final String bio;
  final String photoUrl;
  final String submittedBy;
  final String submittedByName;
  final bool isApproved;
  final DateTime? createdAt;

  String get specializationsLine => specializations.join('، ');

  factory Lawyer.fromJson(Map<String, dynamic> json, String docId) => Lawyer(
        id: docId,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        specializations: (json['specializations'] as List<dynamic>?)
                ?.map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [],
        office: json['office'] as String? ?? '',
        workingHours: json['workingHours'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        photoUrl: json['photoUrl'] as String? ?? '',
        submittedBy: json['submittedBy'] as String? ?? '',
        submittedByName: json['submittedByName'] as String? ?? '',
        isApproved: json['isApproved'] as bool? ?? false,
        createdAt: tsToDateTime(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        ...toWriteMap(),
        'isApproved': isApproved,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  /// حقول المالك — بلا `isApproved` (راجع سبب ذلك في `VillageAd.toWriteMap`).
  Map<String, dynamic> toWriteMap() => {
        'name': name,
        'phone': phone,
        'specializations': specializations,
        'office': office,
        'workingHours': workingHours,
        'bio': bio,
        'photoUrl': photoUrl,
        'submittedBy': submittedBy,
        'submittedByName': submittedByName,
      };

  Lawyer copyWith({
    String? name,
    String? phone,
    List<String>? specializations,
    String? office,
    String? workingHours,
    String? bio,
    String? photoUrl,
  }) =>
      Lawyer(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        specializations: specializations ?? this.specializations,
        office: office ?? this.office,
        workingHours: workingHours ?? this.workingHours,
        bio: bio ?? this.bio,
        photoUrl: photoUrl ?? this.photoUrl,
        submittedBy: submittedBy,
        submittedByName: submittedByName,
        isApproved: isApproved,
        createdAt: createdAt,
      );
}

/// استشارة قانونية يطرحها أحد الأهالي (مجموعة legal_consultations).
/// السؤال يبدأ غير معتمد، وبعد الموافقة يُنشر مع رد الإدارة إن كُتب.
class LegalConsultation {
  const LegalConsultation({
    this.id = '',
    required this.question,
    this.details = '',
    this.category = 'استشارات عامة',
    this.userId = '',
    this.userName = '',
    this.answer = '',
    this.isApproved = false,
    this.createdAt,
  });

  final String id;
  final String question;
  final String details;
  final String category;
  final String userId;
  final String userName;
  final String answer;
  final bool isApproved;
  final DateTime? createdAt;

  bool get hasAnswer => answer.trim().isNotEmpty;

  factory LegalConsultation.fromJson(
          Map<String, dynamic> json, String docId) =>
      LegalConsultation(
        id: docId,
        question: json['question'] as String? ?? '',
        details: json['details'] as String? ?? '',
        category: kLegalSpecializations.contains(json['category'])
            ? json['category'] as String
            : 'استشارات عامة',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        isApproved: json['isApproved'] as bool? ?? false,
        createdAt: tsToDateTime(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'details': details,
        'category': kLegalSpecializations.contains(category)
            ? category
            : 'استشارات عامة',
        'userId': userId,
        'userName': userName,
        'answer': answer,
        'isApproved': false,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  /// حقول المالك: سؤاله وتصنيفه فقط. الرد حقل إداري، فكتابته من المالك
  /// ستُنسب زورًا للمستشار في واجهة كل القرية.
  Map<String, dynamic> toWriteMap() => {
        'question': question,
        'details': details,
        'category': kLegalSpecializations.contains(category)
            ? category
            : 'استشارات عامة',
        'userId': userId,
        'userName': userName,
      };

  LegalConsultation copyWith({
    String? question,
    String? details,
    String? category,
  }) =>
      LegalConsultation(
        id: id,
        question: question ?? this.question,
        details: details ?? this.details,
        category: category ?? this.category,
        userId: userId,
        userName: userName,
        answer: answer,
        isApproved: isApproved,
        createdAt: createdAt,
      );
}
