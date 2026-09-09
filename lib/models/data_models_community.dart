part of 'data_models.dart';

enum RelativeType {
  son('أبناء', Icons.boy_rounded),
  daughter('بنات', Icons.girl_rounded),
  brother('إخوة', Icons.man_rounded),
  sister('أخوات', Icons.woman_rounded),
  paternalUncle('أعمام', Icons.man_rounded),
  paternalAunt('عمات', Icons.woman_rounded),
  maternalUncle('أخوال', Icons.man_rounded),
  maternalAunt('خالات', Icons.woman_rounded),
  inLaw('نسايب', Icons.family_restroom_rounded),
  other('أخرى', Icons.person_rounded);

  final String label;
  final IconData icon;
  const RelativeType(this.label, this.icon);
}

class Relative {
  final String id;
  final String name;
  final RelativeType type;
  final String? phone;
  final int order;

  const Relative({
    required this.id,
    required this.name,
    required this.type,
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
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'phone': phone,
      'order': order,
    };
  }

  Relative copyWith({
    String? id,
    String? name,
    RelativeType? type,
    String? phone,
    int? order,
  }) {
    return Relative(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
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
  final String dateOfDeath;
  final String funeralDate;
  final String funeralLocation;
  final String condolenceLocation;
  final String mosque;
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
    this.funeralDate = '',
    this.funeralLocation = '',
    this.condolenceLocation = '',
    this.mosque = '',
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
      dateOfDeath:
          json['dateOfDeath'] as String? ?? json['date'] as String? ?? '',
      funeralDate: json['funeralDate'] as String? ?? '',
      funeralLocation:
          json['funeralLocation'] as String? ?? json['place'] as String? ?? '',
      condolenceLocation: json['condolenceLocation'] as String? ?? '',
      mosque: json['mosque'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      relatives: (json['relatives'] as List<dynamic>? ?? [])
          .map((e) => Relative.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      'dateOfDeath': dateOfDeath,
      'funeralDate': funeralDate,
      'funeralLocation': funeralLocation,
      'condolenceLocation': condolenceLocation,
      'mosque': mosque,
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
    'completed': Color(0xFF43A047),
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
  final bool isPublic;
  final bool isApproved;

  const PhoneDirectoryEntry({
    required this.id,
    required this.name,
    required this.title,
    required this.phone,
    this.secondaryPhone,
    this.job,
    this.address,
    this.email,
    this.isPublic = true,
    this.isApproved = false,
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
      isPublic: json['isPublic'] as bool? ?? true,
      isApproved: json['isApproved'] as bool? ?? false,
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
      'isPublic': isPublic,
      'isApproved': isApproved,
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
  final String sellerId;
  final int rating;
  final String comment;
  @override
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
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
    'shipped': Color(0xFF66BB6A),
    'delivered': Color(0xFF43A047),
    'cancelled': Color(0xFFE53935),
  };

  String get statusLabel => resolveStatusLabel(_statusLabels, status);
  Color get statusColor => resolveStatusColor(_statusColors, status);
}

