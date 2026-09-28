import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/utils/firebase_ts.dart';

/// فئات دليل الخدمات العامة.
class ServiceCategory {
  ServiceCategory._();
  static const technicians = 'technicians';
  static const agricultural = 'agricultural';
  static const educational = 'educational';
  static const farmerWorkersEquipment = 'farmerWorkersEquipment';

  static String label(String c) => switch (c) {
        technicians => 'دليل الحرفيين',
        agricultural => 'خدمات المزارع',
        educational => 'خدمات تعليمية',
        farmerWorkersEquipment => 'عمال و معدات',
        _ => c,
      };

  static IconData icon(String c) => switch (c) {
        technicians => Icons.engineering_rounded,
        agricultural => Icons.agriculture_rounded,
        educational => Icons.school_rounded,
        farmerWorkersEquipment => Icons.engineering_rounded,
        _ => Icons.category_rounded,
      };

  static Color color(String c) => switch (c) {
        technicians => const Color(0xFFEF6C00),
        agricultural => const Color(0xFFAD1457),
        educational => const Color(0xFF1565C0),
        farmerWorkersEquipment => const Color(0xFFEF6C00),
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
  'كاميرات مراقبة ودش',
  'أعمال منزلية',
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

// ═══════════════════ الخدمات التعليمية ═══════════════════

/// صفة مقدّم الخدمة التعليمية.
const String kEduKindTeacher = 'مدرس';
const String kEduKindSchool = 'مدرسة';
const List<String> kEduKinds = [kEduKindTeacher, kEduKindSchool];

/// أنواع التعليم المتاحة (يمكن لمقدّم واحد الجمع بينها).
const String kEduTypePublic = 'تعليم عام';
const String kEduTypeAzhar = 'أزهري';
const String kEduTypePrivate = 'خاص';
const List<String> kEduTypes = [kEduTypePublic, kEduTypeAzhar, kEduTypePrivate];

/// المراحل التعليمية الخمس (يمكن الجمع بينها).
const String kEduStageKinder = 'تمهيدي';
const String kEduStagePrimary = 'ابتدائي';
const String kEduStagePrep = 'إعدادي';
const String kEduStageSecondary = 'ثانوي';
const String kEduStageUniversity = 'جامعي';
const List<String> kEduStages = [
  kEduStageKinder,
  kEduStagePrimary,
  kEduStagePrep,
  kEduStageSecondary,
  kEduStageUniversity,
];

/// تسمية مجموعة السجلات القديمة التي لا مرحلة لها ضمن الخمس (محو الأمية مثلاً).
const String kEduStageOther = 'مراحل أخرى';

/// كل مواد نظام جمهورية مصر العربية، مقسّمة لأقسام لتسهيل الاختيار.
const Map<String, List<String>> kEgyptSubjectSections = {
  'مواد مشتركة': [
    'اللغة العربية',
    'اللغة الإنجليزية',
    'الرياضيات',
    'العلوم',
    'الدراسات الاجتماعية',
    'التربية الدينية',
    'التربية الوطنية',
    'الحاسب الآلي وتكنولوجيا المعلومات',
    'التربية الفنية',
    'التربية الموسيقية',
    'التربية الرياضية',
    'القيم واحترام الآخر',
    'الاقتصاد المنزلي',
    'التربية المهنية',
  ],
  'لغات أجنبية': [
    'اللغة الفرنسية',
    'اللغة الألمانية',
    'اللغة الإيطالية',
    'اللغة الإسبانية',
    'اللغة الصينية',
    'اللغة الروسية',
    'اللغة التركية',
  ],
  'مهارات أساسية': [
    'القراءة والخط العربي',
    'الإملاء والتعبير',
    'القرآن الكريم',
  ],
  'رياضيات': [
    'الجبر',
    'الهندسة',
    'الرياضيات البحتة (جبر وهندسة فراغية)',
    'الرياضيات التطبيقية (استاتيكا وديناميكا)',
    'التفاضل والتكامل',
  ],
  'علوم': [
    'الفيزياء',
    'الكيمياء',
    'الأحياء',
    'الجيولوجيا وعلوم البيئة',
    'العلوم المتكاملة',
  ],
  'أدبي واجتماعيات': [
    'التاريخ',
    'الجغرافيا',
    'الفلسفة والمنطق',
    'علم النفس والاجتماع',
    'الاقتصاد والإحصاء',
  ],
  'مواد أزهرية': [
    'التفسير وعلوم القرآن',
    'الحديث الشريف وعلومه',
    'الفقه',
    'أصول الفقه',
    'التوحيد والعقيدة',
    'السيرة النبوية',
    'النحو والصرف',
    'البلاغة والعروض',
    'الأدب العربي والنصوص',
    'المنطق',
    'الثقافة الإسلامية',
  ],
  'جامعي ومهارات': [
    'التنمية البشرية والمهارات الحياتية',
    'البرمجة',
    'لغات أجنبية مكثفة',
    'محو الأمية وتعليم الكبار',
    'اختبارات قدرات واستعدادات',
  ],
  'أخرى': [
    'غير ذلك',
  ],
};

/// قائمة المواد المسطّحة المشتقة من الأقسام.
final List<String> kEgyptSubjects =
    List.unmodifiable(kEgyptSubjectSections.values.expand((s) => s));

/// ترجمة قيمة «المرحلة» القديمة (تسعة خيارات تفصيلية) إلى المراحل الخمس.
/// سجل «محو الأمية وتعليم الكبار» لا مقابل له ⇒ قائمة فارغة، ويبقى نصه القديم
/// ظاهراً تحت [kEduStageOther].
List<String> legacyEduStagesOf(String oldStage) {
  final s = oldStage.trim();
  if (s.isEmpty) return const [];
  if (s.contains('رياض الأطفال') || s.contains('تمهيدي') || s.contains('KG')) {
    return const [kEduStageKinder];
  }
  if (s.contains('ابتدائي')) return const [kEduStagePrimary];
  if (s.contains('إعدادي') || s.contains('اعدادي')) return const [kEduStagePrep];
  if (s.contains('الأزهرية') || s.contains('ازهرية')) {
    return const [kEduStageSecondary];
  }
  if (s.contains('ثانوي')) return const [kEduStageSecondary];
  if (s.contains('جامعي') || s.contains('جامعة')) return const [kEduStageUniversity];
  return const [];
}

/// نوع التعليم المستنتج من قيمة المرحلة القديمة (الأزهرية ⇒ أزهري، وإلا عام).
List<String> legacyEduTypesOf(String oldStage) {
  final s = oldStage.trim();
  if (s.isEmpty) return const [];
  return (s.contains('الأزهرية') || s.contains('ازهرية'))
      ? const [kEduTypeAzhar]
      : const [kEduTypePublic];
}

/// قائمة المجموعات الفرعية حسب الفئة.
List<String> kSubcategoriesFor(String category) =>
    switch (category) {
      ServiceCategory.technicians => kTechnicianCrafts,
      ServiceCategory.agricultural => kAgriculturalServices,
      ServiceCategory.educational => kEgyptSubjects,
      _ => const [],
    };

List<String> _stringList(dynamic v) {
  if (v is List) {
    return v
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (v is String && v.trim().isNotEmpty) return [v.trim()];
  return const [];
}

// ═══════════════════ مقدم خدمة في دليل الخدمات ═══════════════════
class ServiceProvider {
  final String id;
  final String category; // technicians | agricultural | educational
  final String specialty; // الحرفة / الخدمة (وللتعليمي: مرآة قائمة المواد)
  final String stage; // مرحلة تعليمية (وللتعليمي: مرآة قائمة المراحل)
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

  // ── الخدمات التعليمية (اختيار متعدد) ──
  final String providerKind; // مدرّس | مدرسة
  final List<String> eduTypes; // تعليم عام | أزهري | خاص
  final List<String> stages; // تمهيدي | ابتدائي | إعدادي | ثانوي | جامعي
  final List<String> subjects; // مواد من kEgyptSubjects
  final String universityNote; // يكتبها المدرّس عند اختيار «جامعي»
  final bool offersPrivateTutoring; // «تدريس خاص» — للمدرّس فقط
  final String legacyStage; // نص المرحلة القديم عند غياب [stages]

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
    this.providerKind = kEduKindTeacher,
    this.eduTypes = const [],
    this.stages = const [],
    this.subjects = const [],
    this.universityNote = '',
    this.offersPrivateTutoring = false,
    this.legacyStage = '',
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json, String docId) {
    final category = json['category'] as String? ?? '';
    final specialty = json['specialty'] as String? ?? '';
    final legacyStage = (json['stage'] as String? ?? '').trim();
    final isEdu = category == ServiceCategory.educational;
    final kind = (json['providerKind'] as String? ?? '').trim().isEmpty
        ? kEduKindTeacher
        : (json['providerKind'] as String).trim();
    final rawStages = _stringList(json['stages']);
    final rawSubjects = _stringList(json['subjects']);
    final rawEduTypes = _stringList(json['eduTypes']);
    // سجل قديم = لا قوائم جديدة فيه إطلاقًا ⇒ تُستنتج قيمه من المرحلة المفردة.
    final isLegacyEdu = isEdu && rawStages.isEmpty && rawSubjects.isEmpty;
    return ServiceProvider(
      id: docId,
      category: category,
      specialty: specialty,
      stage: legacyStage,
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
      createdAt: tsToDateTime(json['createdAt']),
      providerKind: kind,
      eduTypes: isEdu
          ? (rawEduTypes.isNotEmpty
              ? rawEduTypes
              : (isLegacyEdu ? legacyEduTypesOf(legacyStage) : const []))
          : const [],
      // السجل القديم يخزّن مرحلة واحدة تفصيلية ⇒ تُترجم إلى المراحل الخمس.
      stages: isEdu
          ? (rawStages.isNotEmpty
              ? rawStages
              : (isLegacyEdu ? legacyEduStagesOf(legacyStage) : const []))
          : const [],
      subjects: isEdu
          ? (rawSubjects.isNotEmpty
              ? rawSubjects
              : (isLegacyEdu && specialty.trim().isNotEmpty
                  ? [specialty.trim()]
                  : const []))
          : const [],
      universityNote: json['universityNote'] as String? ?? '',
      offersPrivateTutoring: kind == kEduKindSchool
          ? false
          : (json['offersPrivateTutoring'] as bool? ?? false),
      legacyStage: legacyStage,
    );
  }

  Map<String, dynamic> toJson() {
    final isEdu = category == ServiceCategory.educational;
    // المرآتان `specialty`/`stage` تُبقيان النسخ القديمة المثبّتة على الأجهزة
    // قادرة على عرض السجل التعليمي الجديد.
    final specialtyMirror =
        isEdu && subjects.isNotEmpty ? subjects.join('، ') : specialty;
    final stageMirror = isEdu && stages.isNotEmpty ? stages.join('، ') : stage;
    return {
      'category': category,
      'specialty': specialtyMirror,
      'stage': stageMirror,
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
      if (isEdu) ...{
        'providerKind': providerKind,
        'eduTypes': eduTypes,
        'stages': stages,
        'subjects': subjects,
        'universityNote': universityNote,
        'offersPrivateTutoring': offersPrivateTutoring,
      },
    };
  }

  bool get isEducational => category == ServiceCategory.educational;

  bool get isSchool => providerKind == kEduKindSchool;

  /// صفة المقدّم بالعربية (فارغة لغير الفئة التعليمية).
  String get providerKindLabel =>
      isEducational ? (isSchool ? kEduKindSchool : kEduKindTeacher) : '';

  /// المراحل المعروضة كرقائق: الخمس الجديدة، أو نص المرحلة القديم عند غيابها.
  List<String> get stageChips => stages.isNotEmpty
      ? stages
      : (legacyStage.isEmpty ? const <String>[] : [legacyStage]);

  String get subjectsLine => subjects.join('، ');

  String get stagesLine => stageChips.join('، ');

  String get eduTypesLine => eduTypes.join('، ');

  /// عنوان العرض داخل القوائم والبطاقات.
  String get displaySpecialty {
    if (!isEducational) return specialty;
    if (subjects.isNotEmpty) return subjectsLine;
    if (specialty.isNotEmpty) return specialty;
    return stagesLine;
  }

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
        providerKind: providerKind,
        eduTypes: eduTypes,
        stages: stages,
        subjects: subjects,
        universityNote: universityNote,
        offersPrivateTutoring: offersPrivateTutoring,
        legacyStage: legacyStage,
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
      createdAt: tsToDateTime(json['createdAt']),
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
