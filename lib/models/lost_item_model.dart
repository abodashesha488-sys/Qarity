import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/utils/firebase_ts.dart';

/// لون خدمة «المفقودات» المميز — لا يتكرر مع أي خدمة أخرى في الدليل.
const Color kLostItemsColor = Color(0xFF5E35B1);

/// إعلان شيء مفقود أو موجود في القرية (مجموعة lost_items).
class LostItem {
  const LostItem({
    this.id = '',
    required this.title,
    this.type = 'lost',
    this.description = '',
    this.location = '',
    this.date,
    this.phone = '',
    this.imageUrl = '',
    this.userId = '',
    this.userName = '',
    this.isResolved = false,
    this.isApproved = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String type; // lost | found
  final String description;
  final String location;
  final DateTime? date;
  final String phone;
  final String imageUrl;
  final String userId;
  final String userName;
  final bool isResolved;
  final bool isApproved;
  final DateTime? createdAt;

  bool get isLostType => type != 'found';
  String get typeLabel => isLostType ? 'مفقود' : 'موجود';

  factory LostItem.fromJson(Map<String, dynamic> json, String docId) {
    return LostItem(
      id: docId,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'lost',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      date: tsToDateTime(json['date']),
      phone: json['phone'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      isResolved: json['isResolved'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: tsToDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'description': description,
        'location': location,
        if (date != null) 'date': Timestamp.fromDate(date!),
        'phone': phone,
        if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        'userId': userId,
        'userName': userName,
        'isResolved': isResolved,
        'isApproved': false,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  LostItem copyWith({bool? isResolved}) => LostItem(
        id: id,
        title: title,
        type: type,
        description: description,
        location: location,
        date: date,
        phone: phone,
        imageUrl: imageUrl,
        userId: userId,
        userName: userName,
        isResolved: isResolved ?? this.isResolved,
        isApproved: isApproved,
        createdAt: createdAt,
      );
}
