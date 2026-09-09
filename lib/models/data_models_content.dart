part of 'data_models.dart';


// ═══════════════════════════════════════════════════════════════
// USER MODEL
// ═══════════════════════════════════════════════════════════════
class UserModel implements BaseModel {
  @override
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? photoUrl;
  final SellerType? sellerType;
  final DateTime joinDate;
  final DateTime? lastLogin;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'user',
    this.photoUrl,
    this.sellerType,
    required this.joinDate,
    this.lastLogin,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String docId) {
    return UserModel(
      id: docId,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      photoUrl: json['photoUrl'] as String?,
      sellerType: json['sellerType'] != null
          ? SellerType.values.firstWhere(
              (e) => e.name == json['sellerType'],
              orElse: () => SellerType.regular,
            )
          : null,
      joinDate: _parseTimestamp(json['joinDate']),
      lastLogin:
          json['lastLogin'] != null ? _parseTimestamp(json['lastLogin']) : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'photoUrl': photoUrl,
      'sellerType': sellerType?.name,
      'joinDate': Timestamp.fromDate(joinDate),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'isActive': isActive,
    };
  }

  @override
  DateTime? get createdAt => joinDate;

  bool get isAdmin => role == 'admin';
  bool get isModerator =>
      role == 'moderator' || role == 'admin' || role == 'medical_admin';

  static const Map<String, String> _roleLabels = {
    'user': 'مستخدم',
    'seller': 'بائع',
    'moderator': 'مشرف',
    'medical_admin': 'مدير المركز الطبي',
    'admin': 'مدير عام',
  };

  /// الاسم العربي الموحّد للدور — يُستخدم في الملف الشخصي ولوحة التحكم.
  String get roleLabel => _roleLabels[role] ?? role;

  /// هل يُسمح لهذا الدور بفتح لوحة التحكم؟ (المدير العام فقط للوحة الكاملة،
  /// والمدير الطبي والمشرف لواجهاتهما الخاصة).
  bool get canAccessAdminPanel =>
      role == 'admin' || role == 'medical_admin' || role == 'moderator';

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? photoUrl,
    SellerType? sellerType,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      sellerType: sellerType ?? this.sellerType,
      joinDate: joinDate,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NEWS MODEL
// ═══════════════════════════════════════════════════════════════
class NewsItem implements BaseModel {
  @override
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<String> imageUrls;
  final String date;
  final int views;
  final int likes;
  final int comments;
  final String category;
  final bool isApproved;
  final String? authorId;
  final String? authorName;
  final String? authorRole; // لدور الكاتب (تلوين الاسم + شارة)
  final String? authorSellerType;
  @override
  final DateTime? createdAt;

  const NewsItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.date,
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.category = 'عام',
    this.isApproved = false,
    this.authorId,
    this.authorName,
    this.authorRole,
    this.authorSellerType,
    this.createdAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json, String docId) {
    return NewsItem(
      id: docId,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      date: json['date'] as String? ?? '',
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'عام',
      isApproved: json['isApproved'] as bool? ?? false,
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      authorRole: json['authorRole'] as String?,
      authorSellerType: json['authorSellerType'] as String?,
      createdAt:
          json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'date': date,
      'views': views,
      'likes': likes,
      'comments': comments,
      'category': category,
      'isApproved': isApproved,
      'authorId': authorId,
      'authorName': authorName,
      if (authorRole != null) 'authorRole': authorRole,
      if (authorSellerType != null) 'authorSellerType': authorSellerType,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  NewsItem copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    List<String>? imageUrls,
    String? date,
    int? views,
    int? likes,
    int? comments,
    String? category,
    bool? isApproved,
  }) {
    return NewsItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      date: date ?? this.date,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      category: category ?? this.category,
      isApproved: isApproved ?? this.isApproved,
      authorId: authorId,
      authorName: authorName,
      createdAt: createdAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MARKET PRODUCT MODEL
// ═══════════════════════════════════════════════════════════════
class MarketProduct implements BaseModel {
  @override
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> imageUrls;
  final bool isFeatured;
  final String category;
  final String sellerName;
  final String sellerPhone;
  final String? sellerId;
  final String? sellerType; // SellerType enum name — لألوان الاسم والإطارات
  final bool isOnOffer;
  final double? offerPrice;
  final String productStatus;
  @override
  final DateTime? createdAt;
  final int stock;
  final double rating;
  final int reviewCount;
  final bool isApproved;
  final int likes;
  final List<String> likedBy;

  const MarketProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.imageUrls = const [],
    this.isFeatured = false,
    required this.category,
    required this.sellerName,
    required this.sellerPhone,
    this.sellerId,
    this.sellerType,
    this.isOnOffer = false,
    this.offerPrice,
    this.productStatus = 'regular',
    this.createdAt,
    this.stock = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isApproved = false,
    this.likes = 0,
    this.likedBy = const [],
  });

factory MarketProduct.fromJson(Map<String, dynamic> json, String docId) {
    return MarketProduct(
      id: docId,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _parseDouble(json['price']),
      imageUrl: json['imageUrl'] as String? ?? '',
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      isFeatured: json['isFeatured'] as bool? ?? false,
      category: json['category'] as String? ?? 'عام',
      sellerName: json['sellerName'] as String? ?? '',
      sellerPhone: json['sellerPhone'] as String? ?? '',
      sellerId: json['sellerId'] as String?,
      sellerType: json['sellerType'] as String?,
      isOnOffer: json['isOnOffer'] as bool? ?? false,
      offerPrice: _parseDouble(json['offerPrice']),
      productStatus: json['productStatus'] as String? ?? 'regular',
      createdAt:
          json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
      stock: _parseInt(json['stock']),
      rating: _parseDouble(json['rating']),
      reviewCount: _parseInt(json['reviewCount']),
      isApproved: json['isApproved'] as bool? ?? false,
      likes: _parseInt(json['likes']),
      likedBy: (json['likedBy'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'isFeatured': isFeatured,
      'category': category,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'sellerId': sellerId,
      if (sellerType != null) 'sellerType': sellerType,
      'isOnOffer': isOnOffer,
      'offerPrice': offerPrice,
      'productStatus': productStatus,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'stock': stock,
      'rating': rating,
      'reviewCount': reviewCount,
      'isApproved': isApproved,
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  MarketProduct copyWithApproved({bool? isApproved}) {
    return MarketProduct(
      id: id,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      isFeatured: isFeatured,
      category: category,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      sellerId: sellerId,
      sellerType: sellerType,
      isOnOffer: isOnOffer,
      offerPrice: offerPrice,
      createdAt: createdAt,
      stock: stock,
      rating: rating,
      reviewCount: reviewCount,
      isApproved: isApproved ?? this.isApproved,
      likes: likes,
      likedBy: likedBy,
    );
  }

  double get effectivePrice =>
      isOnOffer && offerPrice != null ? offerPrice! : price;
  double get discountPercent => isOnOffer && offerPrice != null
      ? ((price - offerPrice!) / price * 100).roundToDouble()
      : 0.0;
  bool get isInStock => stock > 0;
}

// ═══════════════════════════════════════════════════════════════
// PRODUCT REVIEW MODEL
// ═══════════════════════════════════════════════════════════════
class ProductReview implements BaseModel {
  @override
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final List<String> images;
  final bool isVerifiedPurchase;
  @override
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    this.images = const [],
    this.isVerifiedPurchase = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json, String docId) {
    return ProductReview(
      id: docId,
      productId: json['productId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? const [],
      isVerifiedPurchase: json['isVerifiedPurchase'] as bool? ?? false,
      createdAt:
          json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'images': images,
      'isVerifiedPurchase': isVerifiedPurchase,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// SELLER PROFILE MODEL
// ═══════════════════════════════════════════════════════════════
class SellerProfile implements BaseModel {
  @override
  final String id;
  final String userId;
  final String name;
  final String? bio;
  final String? imageUrl;
  final String phone;
  final String? address;
  final double rating;
  final int reviewCount;
  final int totalProducts;
  final int totalSales;
  final bool isVerified;
  final List<String> categories;
  final String? sellerType; // نوع البائع لألوان الاسم
  @override
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellerProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.bio,
    this.imageUrl,
    required this.phone,
    this.address,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalProducts = 0,
    this.totalSales = 0,
    this.isVerified = false,
    this.categories = const [],
    this.sellerType,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerProfile.fromJson(Map<String, dynamic> json, String docId) {
    return SellerProfile(
      id: docId,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String?,
      imageUrl: json['imageUrl'] as String?,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      totalSales: (json['totalSales'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      categories:
          (json['categories'] as List<dynamic>?)?.cast<String>() ?? const [],
      sellerType: json['sellerType'] as String?,
      createdAt:
          json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'bio': bio,
      'imageUrl': imageUrl,
      'phone': phone,
      'address': address,
      'rating': rating,
      'reviewCount': reviewCount,
      'totalProducts': totalProducts,
      'totalSales': totalSales,
      'isVerified': isVerified,
      'categories': categories,
      if (sellerType != null) 'sellerType': sellerType,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
}
}

// ════════════════════════════════════════════════════════════════
// SELLER REQUEST MODEL
// ═══════════════════════════════════════════════════════════════
class SellerRequest implements BaseModel {
  @override
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String? userPhotoUrl;
  final String shopName;
  final String? shopDescription;
  final String? shopAddress;
  final List<String> categories;
  final String status; // 'pending', 'approved', 'rejected'
  final String requestedSellerType; // 'regular', 'superSeller', 'goldSeller', 'premiumSeller'
  final String? adminNotes;
  @override
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const SellerRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userPhotoUrl,
    required this.shopName,
    this.shopDescription,
    this.shopAddress,
    this.categories = const [],
    this.status = 'pending',
    this.requestedSellerType = 'regular',
    this.adminNotes,
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory SellerRequest.fromJson(Map<String, dynamic> json, String docId) {
    return SellerRequest(
      id: docId,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      shopName: json['shopName'] as String? ?? '',
      shopDescription: json['shopDescription'] as String?,
      shopAddress: json['shopAddress'] as String?,
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? const [],
      status: json['status'] as String? ?? 'pending',
      requestedSellerType: json['requestedSellerType'] as String? ?? 'regular',
      adminNotes: json['adminNotes'] as String?,
      createdAt: json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
      reviewedAt: json['reviewedAt'] != null ? _parseTimestamp(json['reviewedAt']) : null,
      reviewedBy: json['reviewedBy'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userPhotoUrl': userPhotoUrl,
      'shopName': shopName,
      'shopDescription': shopDescription,
      'shopAddress': shopAddress,
      'categories': categories,
      'status': status,
      'requestedSellerType': requestedSellerType,
      'adminNotes': adminNotes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'reviewedAt': reviewedAt != null
          ? Timestamp.fromDate(reviewedAt!)
          : FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
    };
  }

  SellerRequest copyWith({
    String? status,
    String? adminNotes,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return SellerRequest(
      id: id,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      userPhotoUrl: userPhotoUrl,
      shopName: shopName,
      shopDescription: shopDescription,
      shopAddress: shopAddress,
      categories: categories,
      status: status ?? this.status,
      requestedSellerType: requestedSellerType,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  SellerType get sellerTypeEnum => SellerType.values.firstWhere(
        (e) => e.name == requestedSellerType,
        orElse: () => SellerType.regular,
      );

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

// ═══════════════════════════════════════════════════════════════
// ITEM REQUEST MODEL
// ═══════════════════════════════════════════════════════════════
class ItemRequest implements BaseModel {
  @override
  final String id;
  final String itemName;
  final String description;
  final String requestedBy;
  final String status; // 'pending', 'approved', 'completed', 'cancelled'
  final String? requestedByPhone;
  @override
  final DateTime? createdAt;
  final DateTime? fulfilledAt;
  final DateTime? updatedAt;

  const ItemRequest({
    required this.id,
    required this.itemName,
    required this.description,
    required this.requestedBy,
    this.requestedByPhone,
    this.status = 'pending',
    this.fulfilledAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ItemRequest.fromJson(Map<String, dynamic> json, String docId) {
    return ItemRequest(
      id: docId,
      itemName: json['itemName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      requestedBy: json['requestedBy'] as String? ?? '',
      requestedByPhone: json['requestedByPhone'] as String?,
      status: json['status'] as String? ?? 'pending',
      fulfilledAt: json['fulfilledAt'] != null
          ? _parseTimestamp(json['fulfilledAt'])
          : null,
      updatedAt: json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'description': description,
      'requestedBy': requestedBy,
      'requestedByPhone': requestedByPhone,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'fulfilledAt': fulfilledAt != null
          ? Timestamp.fromDate(fulfilledAt!)
          : null,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  String get statusLabel => _statusLabels[status] ?? status;
  Color get statusColor => _statusColors[status] ?? Colors.grey;

  static const Map<String, String> _statusLabels = {
    'pending': 'قيد الانتظار',
    'approved': '已批准',
    'completed': 'مكتمل',
    'cancelled': 'ملغي',
  };

  static const Map<String, Color> _statusColors = {
    'pending': Color(0xFFFF9800),
    'approved': Color(0xFF4CAF50),
    'completed': Color(0xFF43A047),
    'cancelled': Color(0xFFE53935),
  };
}

// ═══════════════════════════════════════════════════════════════
// DONATION ITEM MODEL
// ═══════════════════════════════════════════════════════════════
class DonationItem implements BaseModel {
  @override
  final String id;
  final String itemName;
  final String description;
  final String donatedBy;
  final String status; // 'available', 'claimed', 'completed'
  final String? claimedBy;
  final DateTime? claimedAt;
  final DateTime? completedAt;
  @override
  final DateTime? createdAt;

  const DonationItem({
    required this.id,
    required this.itemName,
    required this.description,
    required this.donatedBy,
    this.status = 'available',
    this.claimedBy,
    this.claimedAt,
    this.completedAt,
    this.createdAt,
  });

  factory DonationItem.fromJson(Map<String, dynamic> json, String docId) {
    return DonationItem(
      id: docId,
      itemName: json['itemName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      donatedBy: json['donatedBy'] as String? ?? '',
      status: json['status'] as String? ?? 'available',
      claimedBy: json['claimedBy'] as String?,
      claimedAt: json['claimedAt'] != null
          ? _parseTimestamp(json['claimedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? _parseTimestamp(json['completedAt'])
          : null,
      createdAt: json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'description': description,
      'donatedBy': donatedBy,
      'status': status,
      'claimedBy': claimedBy,
      'claimedAt': claimedAt != null
          ? Timestamp.fromDate(claimedAt!)
          : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  String get statusLabel => _statusLabels[status] ?? status;
  Color get statusColor => _statusColors[status] ?? Colors.grey;

  static const Map<String, String> _statusLabels = {
    'available': 'متوفر',
    'claimed': '已索取',
    'completed': 'مكتمل',
  };

  static const Map<String, Color> _statusColors = {
    'available': Color(0xFF4CAF50),
    'claimed': Color(0xFF66BB6A),
    'completed': Color(0xFF43A047),
  };
}

// ═══════════════════════════════════════════════════════════════
// RELATIVE MODEL (أقارب المتوفى)
// ═══════════════════════════════════════════════════════════════
enum SellerType {
  regular('بائع عادي', Icons.store_rounded, 3),
  superSeller('بائع سوبر', Icons.storefront_rounded, 7),
  goldSeller('بائع ذهبي', Icons.star_rounded, 15),
  premiumSeller('بائع متميز', Icons.emergency_rounded, 15);

  final String label;
  final IconData icon;
  final int maxImages;

  const SellerType(this.label, this.icon, this.maxImages);
}

