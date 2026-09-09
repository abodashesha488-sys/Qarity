import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

DateTime _parseTs(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

// ═══════════════════════ SHOP (محلات القرية) ═══════════════════════
/// المتجر هو منصة تسويقية لصاحبها؛ منتجاته تُربط عبر ownerUid (نفس sellerId).
class Shop {
  final String id;
  final String ownerUid;
  final String ownerName;
  final String name;
  final String category;
  final String description;
  final String? logoUrl;
  final String? coverUrl;
  final List<String> imageUrls;
  final String whatsapp;
  final bool isActive;
  final bool isApproved;
  final DateTime? createdAt;

  const Shop({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.name,
    this.category = 'عام',
    this.description = '',
    this.logoUrl,
    this.coverUrl,
    this.imageUrls = const [],
    this.whatsapp = '',
    this.isActive = true,
    this.isApproved = false,
    this.createdAt,
  });

  factory Shop.fromJson(Map<String, dynamic> json, String docId) {
    return Shop(
      id: docId,
      ownerUid: json['ownerUid'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'عام',
      description: json['description'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      whatsapp: json['whatsapp'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? _parseTs(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'name': name,
        'category': category,
        'description': description,
        'logoUrl': logoUrl,
        'coverUrl': coverUrl,
        'imageUrls': imageUrls,
        'whatsapp': whatsapp,
        'isActive': isActive,
        'isApproved': isApproved,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  String get imageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : (logoUrl ?? coverUrl ?? '');

  Shop copyWith(
          {String? name,
          String? category,
          String? description,
          String? logoUrl,
          String? coverUrl,
          List<String>? imageUrls,
          String? whatsapp,
          bool? isActive}) =>
      Shop(
        id: id,
        ownerUid: ownerUid,
        ownerName: ownerName,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        logoUrl: logoUrl ?? this.logoUrl,
        coverUrl: coverUrl ?? this.coverUrl,
        imageUrls: imageUrls ?? this.imageUrls,
        whatsapp: whatsapp ?? this.whatsapp,
        isActive: isActive ?? this.isActive,
        isApproved: isApproved,
        createdAt: createdAt,
      );
}

// ═══════════════════════ BUY REQUEST (سلع مطلوبة) ═══════════════════════
class BuyRequest {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String details;
  final String budget;
  final List<String> imageUrls;
  final String status; // open | closed
  final DateTime? createdAt;

  const BuyRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    this.details = '',
    this.budget = '',
    this.imageUrls = const [],
    this.status = 'open',
    this.createdAt,
  });

  factory BuyRequest.fromJson(Map<String, dynamic> json, String docId) {
    return BuyRequest(
      id: docId,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      details: json['details'] as String? ?? '',
      budget: json['budget'] as String? ?? '',
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      status: json['status'] as String? ?? 'open',
      createdAt: json['createdAt'] != null ? _parseTs(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'title': title,
        'details': details,
        'budget': budget,
        'imageUrls': imageUrls,
        'status': status,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  bool get isOpen => status == 'open';
  String get statusLabel => isOpen ? 'مفتوح' : 'مغلق';
  Color get statusColor => isOpen ? const Color(0xFF43A047) : Colors.grey;
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}

// ═══════════════════════ DONATION (تبرعات) ═══════════════════════
class Donation {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String category;
  final List<String> imageUrls;
  final String contactPhone;
  final String status; // available | donated
  final DateTime? createdAt;

  const Donation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    this.description = '',
    this.category = 'عام',
    this.imageUrls = const [],
    this.contactPhone = '',
    this.status = 'available',
    this.createdAt,
  });

  factory Donation.fromJson(Map<String, dynamic> json, String docId) {
    return Donation(
      id: docId,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'عام',
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      contactPhone: json['contactPhone'] as String? ?? '',
      status: json['status'] as String? ?? 'available',
      createdAt: json['createdAt'] != null ? _parseTs(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'title': title,
        'description': description,
        'category': category,
        'imageUrls': imageUrls,
        'contactPhone': contactPhone,
        'status': status,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  bool get isAvailable => status == 'available';
  String get statusLabel => isAvailable ? 'متبرَّع به' : 'تم التبريع';
  Color get statusColor => isAvailable ? const Color(0xFF2E7D32) : Colors.grey;
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}
