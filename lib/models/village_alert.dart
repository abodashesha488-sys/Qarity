import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firebase_ts.dart';

/// مستويات ظهور التنبيه/الخبر العاجل (تحددها لوحة الأدمن):
/// display = عرض على الشاشة فقط — push = + إشعار لجميع المشتركين —
/// sound = + صوت واهتزاز عند ظهور البانر داخل التطبيق.
class VillageAlertMode {
  VillageAlertMode._();
  static const String display = 'display';
  static const String push = 'push';
  static const String sound = 'sound';
}

/// تنبيه/خبر القرية العاجل — وثيقتان في `village_alerts`:
/// `current` (تنبيه أحمر يعلو «حكمة اليوم») و`breaking` (خبر أصفر بدل «طقس القرية»).
/// الصلاحية تلقائية اختيارية عبر expiresAt، والنمط يحدد الإشعار والصوت.
class VillageAlert {
  final String message;
  final bool isActive;
  final String mode;
  final DateTime? expiresAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  const VillageAlert({
    this.message = '',
    this.isActive = false,
    this.mode = VillageAlertMode.push,
    this.expiresAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory VillageAlert.fromJson(Map<String, dynamic> json) {
    return VillageAlert(
      message: (json['message'] as String? ?? '').trim(),
      isActive: json['isActive'] as bool? ?? false,
      mode: json['mode'] as String? ?? VillageAlertMode.push,
      expiresAt: tsToDateTime(json['expiresAt']),
      updatedBy: json['updatedBy'] as String?,
      updatedAt: tsToDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'isActive': isActive,
        'mode': mode,
        'expiresAt':
            expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
        if (updatedBy != null) 'updatedBy': updatedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// فعّال للعرض في لحظة معينة — رسالة غير فارغة + مُفعّل + داخل المدة.
  bool liveAt(DateTime now) =>
      isActive &&
      message.isNotEmpty &&
      (expiresAt == null || now.isBefore(expiresAt!));

  bool get isLive => liveAt(DateTime.now());
}
