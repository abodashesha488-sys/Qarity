import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/utils/firebase_ts.dart';

/// لون قسم «إعلانات القرية» المميز — لا يتكرر مع أي قسم آخر في التطبيق.
const Color kVillageAdsColor = Color(0xFF311B92);

/// أنواع الإعلانات المقبولة في القسم — تجارية / خدمية / إنشائية.
const List<String> kVillageAdKinds = ['تجارية', 'خدمية', 'إنشائية'];

/// الحد الأقصى لصور الإعلان الواحد — ثلاث صور تكفي لإظهار المنتج أو الورشة
/// أو موقع العمل بلا إثقال القراءة ولا الحفظ.
const int kVillageAdMaxImages = 3;

IconData villageAdKindIcon(String kind) => switch (kind) {
      'خدمية' => Icons.handyman_rounded,
      'إنشائية' => Icons.construction_rounded,
      _ => Icons.storefront_rounded,
    };

/// تسمية الإعلان في العناوين والإشعارات («إعلان تجاري»).
String villageAdKindLabel(String kind) => switch (kind) {
      'خدمية' => 'إعلان خدمي',
      'إنشائية' => 'إعلان إنشائي',
      _ => 'إعلان تجاري',
    };

/// إعلان تجاري/خدمي/إنشائي لأهل القرية (مجموعة village_ads).
/// يُنشره صاحبه غير معتمد، فلا يظهر للقرية قبل موافقة الإدارة.
class VillageAd {
  const VillageAd({
    this.id = '',
    required this.title,
    this.kind = 'تجارية',
    this.businessName = '',
    this.description = '',
    this.phone = '',
    this.location = '',
    this.imageUrls = const [],
    this.userId = '',
    this.userName = '',
    this.isApproved = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String kind;
  final String businessName;
  final String description;
  final String phone;
  final String location;
  final List<String> imageUrls;
  final String userId;
  final String userName;
  final bool isApproved;
  final DateTime? createdAt;

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  String get kindLabel => villageAdKindLabel(kind);
  IconData get kindIcon => villageAdKindIcon(kind);

  factory VillageAd.fromJson(Map<String, dynamic> json, String docId) {
    final urls = (json['imageUrls'] as List<dynamic>?)
            ?.map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    return VillageAd(
      id: docId,
      title: json['title'] as String? ?? '',
      kind: kVillageAdKinds.contains(json['kind'])
          ? json['kind'] as String
          : 'تجارية',
      businessName: json['businessName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      imageUrls: urls,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: tsToDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        ...toWriteMap(),
        'isApproved': isApproved,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  /// الحقول التي يكتبها صاحب الإعلان نفسه — خالية من `isApproved` عمدًا:
  /// قواعد Firestore تسمح للمالك بالتعديل ما دامت الموافقة لم تتغيّر، فأي
  /// كتابة تحتوي الحقل قيمتها `false` كانت ستُخفي إعلانًا معتمدًا عن الجمهور.
  Map<String, dynamic> toWriteMap() => {
        'title': title,
        'kind': kVillageAdKinds.contains(kind) ? kind : 'تجارية',
        'businessName': businessName,
        'description': description,
        'phone': phone,
        'location': location,
        'imageUrls': imageUrls,
        'userId': userId,
        'userName': userName,
      };

  VillageAd copyWith({
    String? title,
    String? kind,
    String? businessName,
    String? description,
    String? phone,
    String? location,
    List<String>? imageUrls,
  }) =>
      VillageAd(
        id: id,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        businessName: businessName ?? this.businessName,
        description: description ?? this.description,
        phone: phone ?? this.phone,
        location: location ?? this.location,
        imageUrls: imageUrls ?? this.imageUrls,
        userId: userId,
        userName: userName,
        isApproved: isApproved,
        createdAt: createdAt,
      );
}
