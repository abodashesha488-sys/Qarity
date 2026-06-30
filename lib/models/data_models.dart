import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// BASE MODEL
// ═══════════════════════════════════════════════════════════════
abstract class BaseModel {
  String get id;
  Map<String, dynamic> toJson();
  DateTime? get createdAt;
}

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
      joinDate: _parseTimestamp(json['joinDate']),
      lastLogin: json['lastLogin'] != null ? _parseTimestamp(json['lastLogin']) : null,
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
      'joinDate': Timestamp.fromDate(joinDate),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'isActive': isActive,
    };
  }

  @override
  DateTime? get createdAt => joinDate;

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator' || role == 'admin';

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? photoUrl,
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
  @override
  final DateTime? createdAt;
  final List<String> tags;

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
    this.createdAt,
    this.tags = const [],
  });

  factory NewsItem.fromJson(Map<String, dynamic> json, String docId) {
    return NewsItem(
      id: docId,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      date: json['date'] as String? ?? '',
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'عام',
      isApproved: json['isApproved'] as bool? ?? false,
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      createdAt: json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
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
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'tags': tags,
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
    List<String>? tags,
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
      tags: tags ?? this.tags,
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
  final bool isOnOffer;
  final double? offerPrice;
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
    this.isOnOffer = false,
    this.offerPrice,
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
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      isFeatured: json['isFeatured'] as bool? ?? false,
      category: json['category'] as String? ?? 'عام',
      sellerName: json['sellerName'] as String? ?? '',
      sellerPhone: json['sellerPhone'] as String? ?? '',
      sellerId: json['sellerId'] as String?,
      isOnOffer: json['isOnOffer'] as bool? ?? false,
      offerPrice: (json['offerPrice'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      isApproved: json['isApproved'] as bool? ?? false,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
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
      'isOnOffer': isOnOffer,
      'offerPrice': offerPrice,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
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
      isOnOffer: isOnOffer,
      offerPrice: offerPrice,
      createdAt: createdAt,
      stock: stock,
      rating: rating,
      reviewCount: reviewCount,
      isApproved: isApproved ?? this.isApproved,
    );
  }

  double get effectivePrice => isOnOffer && offerPrice != null ? offerPrice! : price;
  double get discountPercent => isOnOffer && offerPrice != null
      ? ((price - offerPrice!) / price * 100).roundToDouble()
      : 0.0;
  bool get isInStock => stock > 0;
}

// ═══════════════════════════════════════════════════════════════
// CART ITEM MODEL
// ═══════════════════════════════════════════════════════════════
class CartItem {
  final MarketProduct product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.effectivePrice * quantity;
}

// ═══════════════════════════════════════════════════════════════
// OBITUARY MODEL
// ═══════════════════════════════════════════════════════════════
class Obituary implements BaseModel {
  @override
  final String id;
  final String name;
  final String age;
  final String date;
  final String description;
  final String? place;
  final String? mosque;
  final String? imageUrl;
  final bool isApproved;
  final String? submittedBy;
  @override
  final DateTime? createdAt;

  const Obituary({
    required this.id,
    required this.name,
    required this.age,
    required this.date,
    required this.description,
    this.place,
    this.mosque,
    this.imageUrl,
    this.isApproved = false,
    this.submittedBy,
    this.createdAt,
  });

  factory Obituary.fromJson(Map<String, dynamic> json, String docId) {
    return Obituary(
      id: docId,
      name: json['name'] as String? ?? '',
      age: json['age'] as String? ?? '',
      date: json['date'] as String? ?? '',
      description: json['description'] as String? ?? '',
      place: json['place'] as String?,
      mosque: json['mosque'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      submittedBy: json['submittedBy'] as String?,
      createdAt: json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'date': date,
      'description': description,
      'place': place,
      'mosque': mosque,
      'imageUrl': imageUrl,
      'isApproved': isApproved,
      'submittedBy': submittedBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
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
  final int attendees;
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
    this.attendees = 0,
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
      attendees: (json['attendees'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
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
      'attendees': attendees,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
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
      updatedAt: json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : null,
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

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'in_progress':
        return const Color(0xFF1E88E5);
      case 'completed':
        return const Color(0xFF43A047);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF757575);
    }
  }
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
  });

  factory PhoneDirectoryEntry.fromJson(Map<String, dynamic> json, String docId) {
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
// NOTIFICATION MODEL
// ═══════════════════════════════════════════════════════════════
class AppNotification implements BaseModel {
  @override
  final String id;
  final String title;
  final String body;
  final String type;
  final String? targetId;
  final bool isRead;
  @override
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json, String docId) {
    return AppNotification(
      id: docId,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      targetId: json['targetId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'targetId': targetId,
      'isRead': isRead,
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
      updatedAt: json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : null,
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

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد المعالجة';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'processing':
        return const Color(0xFF1E88E5);
      case 'shipped':
        return const Color(0xFF66BB6A);
      case 'delivered':
        return const Color(0xFF43A047);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF757575);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// UTILITY FUNCTIONS
// ═══════════════════════════════════════════════════════════════
DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.now();
}

