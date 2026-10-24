import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firebase_ts.dart';

export 'legal_models.dart' show ConsultationReply;

/// تصنيفات الاستشارات الزراعية
const List<String> kAgricultureConsultationCategories = [
  'زراعة محصول',
  'وقاية وآفات',
  'أمراض نباتات',
  'أسمدة وكيماويات',
  'ري وتربة',
  'استشارات عامة',
];

/// استشارة زراعية يطرحها مزارعو وأهالي القرية (مجموعة agriculture_consultations).
/// السؤال يبدأ غير معتمد، وبعد رد الأدمن المختص (أدمن الزراعة / الأدمن العام) يُعتمد ويُنشر.
class AgricultureConsultation {
  const AgricultureConsultation({
    this.id = '',
    required this.question,
    this.details = '',
    this.category = 'استشارات عامة',
    this.cropName = '',
    this.userId = '',
    this.userName = '',
    this.answer = '',
    this.answeredByName = '',
    this.images = const [],
    this.isApproved = false,
    this.createdAt,
    this.answeredAt,
  });

  final String id;
  final String question;
  final String details;
  final String category;
  final String cropName;
  final String userId;
  final String userName;
  final String answer;
  final String answeredByName;
  final List<String> images;
  final bool isApproved;
  final DateTime? createdAt;
  final DateTime? answeredAt;

  bool get hasAnswer => answer.trim().isNotEmpty;

  /// صفة أو اسم المستشار الذي قام بالرد (مثل "أدمن الزراعة" أو "الأدمن العام").
  String get responderTitle => answeredByName.trim().isNotEmpty
      ? answeredByName.trim()
      : 'أدمن الزراعة';

  factory AgricultureConsultation.fromJson(
          Map<String, dynamic> json, String docId) =>
      AgricultureConsultation(
        id: docId,
        question: json['question'] as String? ?? '',
        details: json['details'] as String? ?? '',
        category: kAgricultureConsultationCategories.contains(json['category'])
            ? json['category'] as String
            : 'استشارات عامة',
        cropName: json['cropName'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        answeredByName: json['answeredByName'] as String? ??
            json['responderName'] as String? ??
            '',
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [],
        isApproved: json['isApproved'] as bool? ?? false,
        createdAt: tsToDateTime(json['createdAt']),
        answeredAt: tsToDateTime(json['answeredAt']),
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'details': details,
        'category': kAgricultureConsultationCategories.contains(category)
            ? category
            : 'استشارات عامة',
        'cropName': cropName,
        'userId': userId,
        'userName': userName,
        'answer': answer,
        'answeredByName': answeredByName,
        'images': images,
        'isApproved': false,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        if (answeredAt != null) 'answeredAt': Timestamp.fromDate(answeredAt!),
      };

  /// حقول المالك: سؤاله وتفاصيله وصوره فقط.
  Map<String, dynamic> toWriteMap() => {
        'question': question,
        'details': details,
        'category': kAgricultureConsultationCategories.contains(category)
            ? category
            : 'استشارات عامة',
        'cropName': cropName,
        'userId': userId,
        'userName': userName,
        'images': images,
      };

  AgricultureConsultation copyWith({
    String? question,
    String? details,
    String? category,
    String? cropName,
    String? answeredByName,
    String? answer,
    List<String>? images,
    bool? isApproved,
  }) =>
      AgricultureConsultation(
        id: id,
        question: question ?? this.question,
        details: details ?? this.details,
        category: category ?? this.category,
        cropName: cropName ?? this.cropName,
        userId: userId,
        userName: userName,
        answer: answer ?? this.answer,
        answeredByName: answeredByName ?? this.answeredByName,
        images: images ?? this.images,
        isApproved: isApproved ?? this.isApproved,
        createdAt: createdAt,
        answeredAt: answeredAt,
      );
}
