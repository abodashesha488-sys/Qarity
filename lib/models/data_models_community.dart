part of 'data_models.dart';

/// مجموعات أقارب المتوفى. العنوان يتصرف بحسب نوع المتوفى: `label` للمذكر
/// و`feminineLabel` للمؤنث، لأن «عم كلاً من» لرجل تصبح «عمّة كلاً من» لامرأة.
/// آخر عشرة قيم للتسجيلات القديمة فقط: لا تُعرض في نموذج الإضافة الجديد لكنها
/// تظل تُقرأ وتُعرض كما أدخلها صاحبها.
enum RelativeType {
  children('والد كلاً من', 'والدة كلاً من', Icons.child_care_rounded,
      'أسماء أبناء المتوفى وبناته', 'أسماء أبنائها وبناتها'),
  siblings('شقيق كلاً من', 'شقيقة كلاً من', Icons.diversity_3_rounded,
      'أسماء أشقائه', 'أسماء شقيقاتها'),
  grandchildren('جد كلاً من', 'جدة كلاً من', Icons.elderly_rounded,
      'أسماء أحفاده', 'أسماء أحفادها'),
  paternalUncles('عم كلاً من', 'عمّة كلاً من', Icons.man_rounded,
      'أسماء أعمامه', 'أسماء عمّاتها'),
  maternalUncles('خال كلاً من', 'خالة كلاً من', Icons.woman_rounded,
      'أسماء أخواله', 'أسماء خالاتها'),
  paternalCousins('ابن عم كلاً من', 'ابنة عم كلاً من', Icons.people_alt_rounded,
      'أسماء أبناء عمومته', 'أسماء بنات عمومتها'),
  maternalCousins('ابن خال كلاً من', 'ابنة خال كلاً من', Icons.people_alt_rounded,
      'أسماء أبناء خالته', 'أسماء بنات خالتها'),
  paternalAuntCousins('ابن عمة كلاً من', 'ابنة عمة كلاً من',
      Icons.people_alt_rounded, 'أسماء أبناء عمّته', 'أسماء بنات عمّتها'),
  maternalAuntCousins('ابن خالة كلاً من', 'ابنة خالة كلاً من',
      Icons.people_alt_rounded, 'أسماء أبناء خالته', 'أسماء بنات خالتها'),
  inLaws('نسيب كلاً من', 'نسيبة كلاً من', Icons.family_restroom_rounded,
      'أسماء النسايب', 'أسماء النسايب'),
  families('قريب عائلات', 'قريبة عائلات', Icons.location_city_rounded,
      'أسماء العائلات', 'أسماء العائلات'),
  friends('صديق كلاً من', 'صديقة كلاً من', Icons.favorite_rounded,
      'أسماء أصدقاء المتوفى', 'أسماء صديقاتها'),

  // قيم تراثية — تُقرأ من المستندات القديمة ولا تُدخل من النموذج الجديد
  son('أبناء', null, Icons.boy_rounded, '', ''),
  daughter('بنات', null, Icons.girl_rounded, '', ''),
  brother('إخوة', null, Icons.man_rounded, '', ''),
  sister('أخوات', null, Icons.woman_rounded, '', ''),
  paternalUncle('أعمام', null, Icons.man_rounded, '', ''),
  paternalAunt('عمات', null, Icons.woman_rounded, '', ''),
  maternalUncle('أخوال', null, Icons.man_rounded, '', ''),
  maternalAunt('خالات', null, Icons.woman_rounded, '', ''),
  inLaw('نسايب', null, Icons.family_restroom_rounded, '', ''),
  other('أخرى', null, Icons.person_rounded, '', '');

  final String label;
  final String? feminineLabel;
  final IconData icon;
  final String hint;
  final String feminineHint;
  const RelativeType(this.label, this.feminineLabel, this.icon, this.hint,
      this.feminineHint);

  /// العنوان العربي بحسب نوع المتوفى المحفوظ؛ المذكر هو الوضع الافتراضي
  /// لأي سجل قديم بلا نوع.
  String labelFor(String gender) =>
      gender == kObituaryGenderFemale && feminineLabel != null
          ? feminineLabel!
          : label;

  String hintFor(String gender) =>
      gender == kObituaryGenderFemale && feminineHint.isNotEmpty
          ? feminineHint
          : hint;

  bool get isEditableGroup => feminineLabel != null;
}

/// المجموعات الاثنتا عشرة التي يعرضها نموذج الإضافة والتفاصيل بالترتيب المطلوب؛
/// «شقيق كلاً من» تأتي مباشرة بعد «والد كلاً من»، وأبناء العم والخال والعمّة
/// والخالة متجاورون.
const List<RelativeType> kObituaryRelativeGroups = [
  RelativeType.children,
  RelativeType.siblings,
  RelativeType.grandchildren,
  RelativeType.paternalUncles,
  RelativeType.maternalUncles,
  RelativeType.paternalCousins,
  RelativeType.maternalCousins,
  RelativeType.paternalAuntCousins,
  RelativeType.maternalAuntCousins,
  RelativeType.inLaws,
  RelativeType.families,
  RelativeType.friends,
];

/// التسميات القديمة الباقية في سجلات مُحشَرة قبل إعادة التنسيق.
const List<RelativeType> kLegacyRelativeGroups = [
  RelativeType.son,
  RelativeType.daughter,
  RelativeType.brother,
  RelativeType.sister,
  RelativeType.paternalUncle,
  RelativeType.paternalAunt,
  RelativeType.maternalUncle,
  RelativeType.maternalAunt,
  RelativeType.inLaw,
  RelativeType.other,
];

/// أنواع المتوفى: نص عربي كما يُخزَّن، لأن تسميات مجموعات الأقارب تُشتق منه.
const String kObituaryGenderMale = 'رجل';
const String kObituaryGenderFemale = 'امرأة';
const List<String> kObituaryGenders = [kObituaryGenderMale, kObituaryGenderFemale];

/// الصلوات التي يُحدَّد بها وقت صلاة الجنازة ووقت العزاء: نص عربي مخزَّن كما
/// يُعرض، فلا هجرة ولا فهرس، والسجل القديم بغير الحقل يبقى فارغًا.
const List<String> kObituaryPrayers = [
  'صلاة الظهر',
  'صلاة العصر',
  'صلاة المغرب',
  'صلاة العشاء',
  'صلاة الفجر',
];

/// الموعد مع اسم الصلاة في نص واحد («10:30 ص — صلاة الظهر»): السجل القديم بلا
/// صلاة يعرض موعده كما هو، ومن اختار صلاة بلا وقت تُعرض صلاته وحدها.
String obituaryTimeWithPrayer(String time, String prayer) {
  if (prayer.isEmpty) return time;
  if (time.isEmpty) return prayer;
  return '$time — $prayer';
}

/// قائمة أقارب خام (كما هي في الوثيقة) في سطر عربي مقروء: «عنوان: أسماء».
/// النوع المكتوب يدويًا يبقى عنوانه حرفيًا، والمفهرس يُصرَّف بالنوع المُمرَّر
/// (فارغ ⇒ المذكر، وهو الوضع الافتراضي لأي سجل قديم). تستعملها لوحة الإدارة
/// حيث تُعرض القائمة للقراءة فقط، فلا يُرى dumps الخرائط الخام.
String obituaryRelativesReadable(dynamic raw, {String gender = ''}) {
  final labels = <String>[];
  final names = <String, List<String>>{};
  for (final r in _obituaryRelativesOf(raw)) {
    final name = r.name.trim();
    if (name.isEmpty) continue;
    final custom = r.typeLabel.trim();
    final label = custom.isNotEmpty
        ? custom
        : (r.type.isEditableGroup ? r.type.labelFor(gender) : r.type.label);
    if (!names.containsKey(label)) {
      labels.add(label);
      names[label] = <String>[];
    }
    names[label]!.add(name);
  }
  if (labels.isEmpty) return 'لا يوجد';
  return [for (final label in labels) '$label: ${names[label]!.join('، ')}']
      .join(' | ');
}

/// قائمة الأقارب تتخطى أي عنصر ليس خريطة: مستند أُفسدت قائمته (نصوص مفصولة
/// بالفاصلة بدل خرائط) يجب أن يُعرض ببقية بياناته، لا أن يرمي فيُفرغ صفحة
/// السجل كاملة.
List<Relative> _obituaryRelativesOf(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => Relative.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

class Relative {
  final String id;
  final String name;
  final RelativeType type;

  /// نوع القرابة كما كتبه صاحب البيان حرفيًا (كتلة «قرابة أخرى — اكتبها
  /// بنفسك»). نصّ فارغ في المجموعات الاثنتي عشرة وفي كل سجل قديم، فيُكتفى
  /// بمفتاح `type` وتُصرَّف تسميته بالنوع كما هو.
  final String typeLabel;
  final String? phone;
  final int order;

  const Relative({
    required this.id,
    required this.name,
    required this.type,
    this.typeLabel = '',
    this.phone,
    this.order = 0,
  });

  factory Relative.fromJson(Map<String, dynamic> json) {
    return Relative(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: RelativeType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'other'),
        orElse: () => RelativeType.other,
      ),
      phone: json['phone'] as String?,
      typeLabel: json['typeLabel'] as String? ?? '',
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'typeLabel': typeLabel,
      'phone': phone,
      'order': order,
    };
  }

  Relative copyWith({
    String? id,
    String? name,
    RelativeType? type,
    String? typeLabel,
    String? phone,
    int? order,
  }) {
    return Relative(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      typeLabel: typeLabel ?? this.typeLabel,
      phone: phone ?? this.phone,
      order: order ?? this.order,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// OBITUARY MODEL
// ═══════════════════════════════════════════════════════════════
class Obituary implements BaseModel {
  @override
  final String id;
  final String name;
  final String age;
  final String gender;
  final String dateOfDeath;
  final String funeralDate;
  final String funeralLocation;

  /// موعد صلاة الجنازة نصًا مقروءًا («10:30 ص») لا طابع زمني، فالنموذج يسأل
  /// وقتًا فقط والسجل القديم بلا الحقل يبقى صحيح العرض.
  final String funeralTime;

  /// اسم الصلاة المصاحبة لموعد الجنازة من `kObituaryPrayers` — فارغ في السجل
  /// القديم فلا يُختلق موعد لم يسأله أحد.
  final String funeralPrayer;
  final String burialLocation;
  final String condolenceLocation;

  /// موعد العزاء نصًا مقروءًا، يُعرض تحت مكان العزاء في البطاقة والتفاصيل.
  final String condolenceTime;

  /// اسم الصلاة المصاحبة لموعد العزاء من `kObituaryPrayers`.
  final String condolencePrayer;
  final String mosque;
  final String cardBackground;
  final String? imageUrl;
  final String? description;
  final List<Relative> relatives;
  final bool isApproved;
  final String? submittedBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  @override
  final DateTime? createdAt;

  const Obituary({
    required this.id,
    required this.name,
    required this.age,
    required this.dateOfDeath,
    this.gender = '',
    this.funeralDate = '',
    this.funeralLocation = '',
    this.funeralTime = '',
    this.funeralPrayer = '',
    this.burialLocation = '',
    this.condolenceLocation = '',
    this.condolenceTime = '',
    this.condolencePrayer = '',
    this.mosque = '',
    this.cardBackground = '',
    this.imageUrl,
    this.description,
    this.relatives = const [],
    this.isApproved = false,
    this.submittedBy,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
  });

  factory Obituary.fromJson(Map<String, dynamic> json, String docId) {
    return Obituary(
      id: docId,
      name: json['name'] as String? ?? '',
      age: json['age'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      dateOfDeath:
          json['dateOfDeath'] as String? ?? json['date'] as String? ?? '',
      funeralDate: json['funeralDate'] as String? ?? '',
      funeralLocation:
          json['funeralLocation'] as String? ?? json['place'] as String? ?? '',
      funeralTime: json['funeralTime'] as String? ?? '',
      funeralPrayer: json['funeralPrayer'] as String? ?? '',
      burialLocation: json['burialLocation'] as String? ?? '',
      condolenceLocation: json['condolenceLocation'] as String? ?? '',
      condolenceTime: json['condolenceTime'] as String? ?? '',
      condolencePrayer: json['condolencePrayer'] as String? ?? '',
      mosque: json['mosque'] as String? ?? '',
      cardBackground: json['cardBackground'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      relatives: _obituaryRelativesOf(json['relatives']),
      isApproved: json['isApproved'] as bool? ?? false,
      submittedBy: json['submittedBy'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? _parseTimestamp(json['approvedAt'])
          : null,
      createdAt:
          json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'dateOfDeath': dateOfDeath,
      'funeralDate': funeralDate,
      'funeralLocation': funeralLocation,
      'funeralTime': funeralTime,
      'funeralPrayer': funeralPrayer,
      'burialLocation': burialLocation,
      'condolenceLocation': condolenceLocation,
      'condolenceTime': condolenceTime,
      'condolencePrayer': condolencePrayer,
      'mosque': mosque,
      'cardBackground': cardBackground,
      'imageUrl': imageUrl,
      'description': description,
      'relatives': relatives.map((e) => e.toJson()).toList(),
      'isApproved': isApproved,
      'submittedBy': submittedBy,
      'approvedBy': approvedBy,
      'approvedAt':
          approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // getters للتوافق الرجعي
  String get date => dateOfDeath;
  String get place => funeralLocation;
  String get formattedDateOfDeath => dateOfDeath;
  String get formattedFuneralDate => funeralDate;

  List<Relative> get sons =>
      relatives.where((r) => r.type == RelativeType.son).toList();
  List<Relative> get daughters =>
      relatives.where((r) => r.type == RelativeType.daughter).toList();
  List<Relative> get brothers =>
      relatives.where((r) => r.type == RelativeType.brother).toList();
  List<Relative> get sisters =>
      relatives.where((r) => r.type == RelativeType.sister).toList();
  List<Relative> get paternalUncles =>
      relatives.where((r) => r.type == RelativeType.paternalUncle).toList();
  List<Relative> get paternalAunts =>
      relatives.where((r) => r.type == RelativeType.paternalAunt).toList();
  List<Relative> get maternalUncles =>
      relatives.where((r) => r.type == RelativeType.maternalUncle).toList();
  List<Relative> get maternalAunts =>
      relatives.where((r) => r.type == RelativeType.maternalAunt).toList();
  List<Relative> get inLaws =>
      relatives.where((r) => r.type == RelativeType.inLaw).toList();
  List<Relative> get others =>
      relatives.where((r) => r.type == RelativeType.other).toList();

  /// المرأة تصرف تسميات مجموعات الأقارب إلى المؤنث؛ السجل القديم بلا نوع
  /// يبقى بالتذكير.
  bool get isFemale => gender == kObituaryGenderFemale;

  /// الفعل يتصرف بالنوع: «انتقل» للرجل و«انتقلت» للمرأة.
  String get transitionPhrase =>
      isFemale ? 'انتقلت إلى رحمة الله تعالى' : 'انتقل إلى رحمة الله تعالى';

  String get prayerPhrase => isFemale ? 'صُلِّيَ عليها' : 'صُلِّيَ عليه';

  List<Relative> relativesOf(RelativeType group) =>
      relatives.where((r) => r.type == group).toList();

  /// أسماء مجموعة مفهرسة واحدة، مرتبة بحقل `order` كما أُدخِلت؛ الأسماء الفارغة أو
  /// المسافات وحدها لا تُعرض، فلا يظهر عنوان مجموعة بلا أسماء تحته. entries
  /// لها نوع مكتوب يدويًا تُترك هنا لأن `customRelativeSections` تعرضها
  /// بعنوانها الحرفي، وإلا ظهرت مرة تحت «أخرى» ومرة تحت اسمها.
  List<String> namesOf(RelativeType group) {
    final list = relativesOf(group)
        .where((r) => r.typeLabel.trim().isEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list
        .map((r) => r.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
  }

  /// الأنواع المكتوبة يدويًا: قسم مستقل لكل نوع بعنوانه الحرفي (بلا صرف
  /// بالنوع، لأن الكاتب اختار لفظه بنفسه)، وأسماء النوع الواحد في سطر واحد
  /// بترتيب الإدخال.
  List<RelativeSection> get customRelativeSections {
    final typed = relatives
        .where((r) => r.typeLabel.trim().isNotEmpty && r.name.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final labels = <String>[];
    final names = <String, List<String>>{};
    for (final r in typed) {
      final label = r.typeLabel.trim();
      if (!names.containsKey(label)) {
        labels.add(label);
        names[label] = <String>[];
      }
      names[label]!.add(r.name.trim());
    }
    return [
      for (final label in labels)
        RelativeSection(RelativeType.other, label, names[label]!),
    ];
  }

  /// أي مجموعة تحمل أسماء، بما فيها التسميات التراثية، حتى لا تختفي بيانات
  /// سجل قديم عندما لا يندرج تحت التسع الجديدة.
  bool get hasRelatives => relatives.any((r) => r.name.trim().isNotEmpty);

  /// أقسام الأقارب غير الفارغة بترتيب العرض وتسمياتها المصروفة حسب النوع،
  /// ثم الأنواع المكتوبة يدويًا بعنوانها الحرفي، ثم التسميات التراثية.
  /// تستعملها بطاقة المشاركة وصفحة التفاصيل ولوحة الإدارة، فلا تتفارق
  /// التسميات بين موضعٍ وأخيه.
  List<RelativeSection> get relativeSections => [
        for (final group in kObituaryRelativeGroups)
          if (namesOf(group).isNotEmpty)
            RelativeSection(group, group.labelFor(gender), namesOf(group)),
        ...customRelativeSections,
        for (final group in kLegacyRelativeGroups)
          if (namesOf(group).isNotEmpty)
            RelativeSection(group, group.label, namesOf(group)),
      ];
}

/// مجموعة أقارب واحدة جاهزة للعرض: المفتاح المخزَّن، عنوانها المصروف، وأسماءها.
class RelativeSection {
  const RelativeSection(this.group, this.label, this.names);

  final RelativeType group;
  final String label;
  final List<String> names;

  String get namesLine => names.join('، ');
}

// ═══════════════════════════════════════════════════════════════
// OCCASION MODEL
// ═══════════════════════════════════════════════════════════════
class Occasion implements BaseModel {
  @override
  final String id;
  final String title;
  final String date;
  final String description;
  final String location;
  final String? imageUrl;
  final bool isApproved;
  final String? organizer;

  /// صاحب المناسبة — الحقل يُكتب في الوثيقة وقت الإنشاء (`submittedBy`)، وكان
  /// النموذج يهمله فلا تعرف شاشة التفاصيل مَنْ يملكها (البند ٨).
  final String? submittedBy;
  @override
  final DateTime? createdAt;

  const Occasion({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.location,
    this.imageUrl,
    this.isApproved = false,
    this.organizer,
    this.submittedBy,
    this.createdAt,
  });

  factory Occasion.fromJson(Map<String, dynamic> json, String docId) {
    return Occasion(
      id: docId,
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      organizer: json['organizer'] as String?,
      submittedBy: json['submittedBy'] as String?,
      createdAt:
          json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'isApproved': isApproved,
      'organizer': organizer,
      'submittedBy': submittedBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// EMERGENCY CONTACT MODEL
// ═══════════════════════════════════════════════════════════════
class EmergencyContact implements BaseModel {
  @override
  final String id;
  final String name;
  final String phone;
  final String type;
  final String? secondaryPhone;
  final String? description;
  final bool isActive;
  final int priority;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.secondaryPhone,
    this.description,
    this.isActive = true,
    this.priority = 0,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json, String docId) {
    return EmergencyContact(
      id: docId,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      type: json['type'] as String? ?? '',
      secondaryPhone: json['secondaryPhone'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'type': type,
      'secondaryPhone': secondaryPhone,
      'description': description,
      'isActive': isActive,
      'priority': priority,
    };
  }

  @override
  DateTime? get createdAt => null;

  bool get isEmergency => type == 'emergency';
}

// ═══════════════════════════════════════════════════════════════
// VILLAGE INFO MODEL
// ═══════════════════════════════════════════════════════════════
class VillageInfo implements BaseModel {
  @override
  final String id;
  final String name;
  final String description;
  final String population;
  final String area;
  final String founded;
  final List<Map<String, dynamic>> history;
  final List<Map<String, dynamic>> institutions;
  final List<String> archive;

  /// سبب التسمية (لماذا سميت أبودشيشة؟).
  final String nameOrigin;

  /// الموقع الجغرافي.
  final String location;

  /// التبعية الإدارية (مركز/محافظة).
  final String administrative;

  /// طبيعة القرية (زراعية/سكنية...).
  final String nature;

  /// ما تشتهر به القرية.
  final String famousFor;

  /// صورة حقيقية للقرية (رابط ImgBB).
  final String imageUrl;

  /// رابط الموقع على خرائط جوجل.
  final String mapUrl;

  const VillageInfo({
    required this.id,
    required this.name,
    this.description = '',
    this.population = '',
    this.area = '',
    this.founded = '',
    this.history = const [],
    this.institutions = const [],
    this.archive = const [],
    this.nameOrigin = '',
    this.location = '',
    this.administrative = '',
    this.nature = '',
    this.famousFor = '',
    this.imageUrl = '',
    this.mapUrl = '',
  });

  factory VillageInfo.fromJson(Map<String, dynamic> json, String docId) {
    return VillageInfo(
      id: docId,
      name: json['name'] as String? ?? 'قرية أبوديشيشة',
      description: json['description'] as String? ?? '',
      population: json['population'] as String? ?? '',
      area: json['area'] as String? ?? '',
      founded: json['founded'] as String? ?? '',
      history: _listOfMaps(json['history']),
      institutions: _listOfMaps(json['institutions']),
      archive: (json['archive'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      nameOrigin: json['nameOrigin'] as String? ?? '',
      location: json['location'] as String? ?? '',
      administrative: json['administrative'] as String? ?? '',
      nature: json['nature'] as String? ?? '',
      famousFor: json['famousFor'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      mapUrl: json['mapUrl'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'population': population,
      'area': area,
      'founded': founded,
      'history': history,
      'institutions': institutions,
      'archive': archive,
      'nameOrigin': nameOrigin,
      'location': location,
      'administrative': administrative,
      'nature': nature,
      'famousFor': famousFor,
      'imageUrl': imageUrl,
      'mapUrl': mapUrl,
    };
  }

  @override
  DateTime? get createdAt => null;

  static VillageInfo defaults() => const VillageInfo(
        id: 'main',
        name: 'قرية أبوديشيشة',
        description:
            'قرية أبوديشيشة إحدى قرى مركز أبو تشت بمحافظة قنا، تتميز بطبيعتها الجميلة وموقعها على ضفاف النيل، وتعد من القرى العريقة التي تجمع بين الأصالة والحداثة.',
        population: 'حوالي 12,000 نسمة',
        area: 'حوالي 8 كم²',
        founded: 'أوائل القرن العشرين',
        history: [
          {'year': '1900', 'event': 'تأسيس القرية كتجمع سكاني زراعي'},
          {'year': '1950', 'event': 'إنشاء أول مدرسة ومستوصف طبي'},
          {'year': '1980', 'event': 'تطوير البنية التحتية والطرق'},
          {'year': '2020', 'event': 'إطلاق منصة الخدمات الرقمية للقرية'},
        ],
        institutions: [
          {'name': 'مدرسة الأمل الابتدائية', 'location': 'حي الوسط'},
          {'name': 'الوحدة الصحية', 'location': 'وسط القرية'},
          {'name': 'مسجد الفلاح', 'location': 'حي الفلاح'},
          {'name': 'الجمعية الزراعية', 'location': 'حي الفلاح'},
        ],
        archive: [
          'الوثائق التاريخية',
          'الصور القديمة',
          'سجلات المواليد',
          'سجلات الوفيات',
        ],
      );
}

List<Map<String, dynamic>> _listOfMaps(dynamic value) {
  if (value is List) {
    return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return const [];
}

// ═══════════════════════════════════════════════════════════════
// SERVICE REQUEST MODEL
// ═══════════════════════════════════════════════════════════════
class ServiceRequest implements BaseModel {
  @override
  final String id;
  final String userId;
  final String userName;
  final String type;
  final String description;
  final String location;
  final String status;
  final String? imageUrl;
  @override
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedTo;
  final String? notes;

  const ServiceRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.description,
    required this.location,
    this.status = 'pending',
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.notes,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json, String docId) {
    return ServiceRequest(
      id: docId,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      imageUrl: json['imageUrl'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : null,
      assignedTo: json['assignedTo'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type,
      'description': description,
      'location': location,
      'status': status,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'assignedTo': assignedTo,
      'notes': notes,
    };
  }

  static const Map<String, String> _statusLabels = {
    'pending': 'قيد الانتظار',
    'in_progress': 'قيد المعالجة',
    'completed': 'مكتمل',
    'cancelled': 'ملغي',
  };

  static const Map<String, Color> _statusColors = {
    'pending': Color(0xFFFF9800),
    'in_progress': Color(0xFF1E88E5),
    'completed': Color(0xFF6F4E37),
    'cancelled': Color(0xFFE53935),
  };

  String get statusLabel => resolveStatusLabel(_statusLabels, status);
  Color get statusColor => resolveStatusColor(_statusColors, status);
}

// ═══════════════════════════════════════════════════════════════
// FORUM POST MODEL
// ═══════════════════════════════════════════════════════════════
class ForumPost implements BaseModel {
  @override
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String title;
  final String category;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int views;
  final List<String> likedBy;
  @override
  final DateTime createdAt;
  final bool isApproved;
  final bool isPinned;
  final String? userRole;       // دور الناشر للتلوين/الشارة
  final String? userSellerType; // نوع البائع إن كان بائعاً

  const ForumPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    this.title = '',
    this.category = 'عام',
    required this.content,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    this.views = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.isApproved = false,
    this.isPinned = false,
    this.userRole,
    this.userSellerType,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json, String docId) {
    return ForumPost(
      id: docId,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhotoUrl: json['userPhotoUrl'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'عام',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: _parseTimestamp(json['createdAt']),
      isApproved: json['isApproved'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      userRole: json['userRole'] as String?,
      userSellerType: json['userSellerType'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'title': title,
      'category': category,
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'comments': comments,
      'views': views,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isApproved': isApproved,
      'isPinned': isPinned,
      if (userRole != null) 'userRole': userRole,
      if (userSellerType != null) 'userSellerType': userSellerType,
    };
  }

  bool isLikedBy(String userId) => likedBy.contains(userId);
}

// ═══════════════════════════════════════════════════════════════
// PHONE DIRECTORY MODEL
// ═══════════════════════════════════════════════════════════════
class PhoneDirectoryEntry implements BaseModel {
  @override
  final String id;
  final String name;
  final String title;
  final String phone;
  final String? secondaryPhone;
  final String? job;
  final String? address;
  final String? email;
  final String? photoUrl;
  final bool isPublic;
  final bool isApproved;
  final String? submittedBy; // من أدخل البيان — ليرى إدخالاته المعلقة

  const PhoneDirectoryEntry({
    required this.id,
    required this.name,
    required this.title,
    required this.phone,
    this.secondaryPhone,
    this.job,
    this.address,
    this.email,
    this.photoUrl,
    this.isPublic = true,
    this.isApproved = false,
    this.submittedBy,
  });

  factory PhoneDirectoryEntry.fromJson(
      Map<String, dynamic> json, String docId) {
    return PhoneDirectoryEntry(
      id: docId,
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      secondaryPhone: json['secondaryPhone'] as String?,
      job: json['job'] as String?,
      address: json['address'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      isApproved: json['isApproved'] as bool? ?? false,
      submittedBy: json['submittedBy'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'phone': phone,
      'secondaryPhone': secondaryPhone,
      'job': job,
      'address': address,
      'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'isPublic': isPublic,
      'isApproved': isApproved,
      if (submittedBy != null) 'submittedBy': submittedBy,
    };
  }

  @override
  DateTime? get createdAt => null;
}

// ═══════════════════════════════════════════════════════════════
// REVIEW MODEL
// ═══════════════════════════════════════════════════════════════
class Review implements BaseModel {
  @override
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String sellerId;
  final int rating;
  final String comment;
  @override
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.sellerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json, String docId) {
    return Review(
      id: docId,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'مستخدم',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      sellerId: json['sellerId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      if (userPhotoUrl != null && userPhotoUrl!.isNotEmpty) 'userPhotoUrl': userPhotoUrl,
      'sellerId': sellerId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// ORDER MODEL
// ═══════════════════════════════════════════════════════════════
class AppOrder implements BaseModel {
  @override
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final String status;
  @override
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  const AppOrder({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.sellerId,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  factory AppOrder.fromJson(Map<String, dynamic> json, String docId) {
    return AppOrder(
      id: docId,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      buyerId: json['buyerId'] as String? ?? '',
      buyerName: json['buyerName'] as String? ?? '',
      buyerPhone: json['buyerPhone'] as String? ?? '',
      sellerId: json['sellerId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : null,
      notes: json['notes'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'sellerId': sellerId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'notes': notes,
    };
  }

  static const Map<String, String> _statusLabels = {
    'pending': 'قيد الانتظار',
    'processing': 'قيد المعالجة',
    'shipped': 'تم الشحن',
    'delivered': 'تم التسليم',
    'cancelled': 'ملغي',
  };

  static const Map<String, Color> _statusColors = {
    'pending': Color(0xFFFF9800),
    'processing': Color(0xFF1E88E5),
    'shipped': Color(0xFF6F4E37),
    'delivered': Color(0xFF6F4E37),
    'cancelled': Color(0xFFE53935),
  };

  String get statusLabel => resolveStatusLabel(_statusLabels, status);
  Color get statusColor => resolveStatusColor(_statusColors, status);
}

