import 'package:cloud_firestore/cloud_firestore.dart';

/// تنبيه القرية العاجل — وثيقة واحدة `village_alerts/current`.
/// عند تفعيله يظهر بدل «حكمة اليوم» أعلى الشاشة الرئيسية ويُرسَل كإشعار فوري.
class VillageAlert {
  final String message;
  final bool isActive;
  final String? updatedBy;
  final DateTime? updatedAt;

  const VillageAlert({
    this.message = '',
    this.isActive = false,
    this.updatedBy,
    this.updatedAt,
  });

  factory VillageAlert.fromJson(Map<String, dynamic> json) {
    return VillageAlert(
      message: (json['message'] as String? ?? '').trim(),
      isActive: json['isActive'] as bool? ?? false,
      updatedBy: json['updatedBy'] as String?,
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'isActive': isActive,
        if (updatedBy != null) 'updatedBy': updatedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// تنبيه فعّال للعرض — رسالة غير فارغة ومُفعَّل.
  bool get isLive => isActive && message.isNotEmpty;
}
