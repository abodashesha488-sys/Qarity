import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firebase_ts.dart';

/// نوع المركبة المطلوبة في خدمة «وصّلني»
enum WassalniVehicleType {
  tuktuk,
  privateCar;

  static WassalniVehicleType fromCode(String? code) =>
      code == 'private_car' ? WassalniVehicleType.privateCar : WassalniVehicleType.tuktuk;
}

extension WassalniVehicleTypeX on WassalniVehicleType {
  String get code =>
      this == WassalniVehicleType.privateCar ? 'private_car' : 'tuktuk';

  String get labelArabic => this == WassalniVehicleType.privateCar
      ? 'سيارة ملاكي خاصة 🚗'
      : 'توك توك 🛺';

  String get shortLabel =>
      this == WassalniVehicleType.privateCar ? 'سيارة خاصة' : 'توك توك';

  String get capacityHint => this == WassalniVehicleType.privateCar
      ? 'حتى 4 ركاب · مكيفة ومريحة للمشوار الطويل'
      : 'حتى 3 ركاب · سريع وموفر للمشوار القريب';
}

/// حالة رحلة «وصّلني»
enum WassalniStatus {
  searching, // جاري البحث عن سائق / بانتظار التخصيص
  accepted, // تم تعيين السائق وفي طريقه إليك
  arrived, // السائق وصل نقطة الانطلاق
  onTrip, // الرحلة جارية الآن
  completed, // تم الوصول بالسلامة
  cancelled; // ملغي

  static WassalniStatus fromCode(String? code) => WassalniStatusX.fromCode(code);
}

extension WassalniStatusX on WassalniStatus {
  String get code {
    switch (this) {
      case WassalniStatus.searching:
        return 'searching';
      case WassalniStatus.accepted:
        return 'accepted';
      case WassalniStatus.arrived:
        return 'arrived';
      case WassalniStatus.onTrip:
        return 'on_trip';
      case WassalniStatus.completed:
        return 'completed';
      case WassalniStatus.cancelled:
        return 'cancelled';
    }
  }

  String get labelArabic {
    switch (this) {
      case WassalniStatus.searching:
        return 'جاري تأكيد السائق ⏳';
      case WassalniStatus.accepted:
        return 'تم تعيين السائق ✅';
      case WassalniStatus.arrived:
        return 'السائق عند نقطة الانطلاق 📍';
      case WassalniStatus.onTrip:
        return 'الرحلة جارية 🛣️';
      case WassalniStatus.completed:
        return 'تم الوصول بالسلامة 🎉';
      case WassalniStatus.cancelled:
        return 'ملغي ❌';
    }
  }

  static WassalniStatus fromCode(String? code) {
    switch (code) {
      case 'accepted':
        return WassalniStatus.accepted;
      case 'arrived':
        return WassalniStatus.arrived;
      case 'on_trip':
        return WassalniStatus.onTrip;
      case 'completed':
        return WassalniStatus.completed;
      case 'cancelled':
        return WassalniStatus.cancelled;
      default:
        return WassalniStatus.searching;
    }
  }
}

/// نموذج رحلة خدمة «وصّلني»
class WassalniRide {
  const WassalniRide({
    required this.id,
    required this.rideNumber,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.vehicleType = WassalniVehicleType.tuktuk,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.isRoundTrip = false,
    this.scheduledTimeText = 'الآن فوراً',
    this.passengersCount = 1,
    this.estimatedFare = 0.0,
    this.finalFare = 0.0,
    this.driverId = '',
    this.driverName = '',
    this.driverPhone = '',
    this.vehicleInfo = '',
    this.notes = '',
    this.status = WassalniStatus.searching,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String rideNumber; // WAS-YYYYMMDD-XXXX
  final String userId;
  final String userName;
  final String userPhone;
  final WassalniVehicleType vehicleType;
  final String pickupLocation;
  final String dropoffLocation;
  final bool isRoundTrip;
  final String scheduledTimeText;
  final int passengersCount;
  final double estimatedFare;
  final double finalFare;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String vehicleInfo;
  final String notes;
  final WassalniStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  double get effectiveFare => finalFare > 0 ? finalFare : estimatedFare;

  factory WassalniRide.fromJson(Map<String, dynamic> json, String docId) {
    return WassalniRide(
      id: docId,
      rideNumber: (json['rideNumber'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      userName: (json['userName'] as String?) ?? '',
      userPhone: (json['userPhone'] as String?) ?? '',
      vehicleType: WassalniVehicleType.fromCode(json['vehicleType'] as String?),
      pickupLocation: (json['pickupLocation'] as String?) ?? '',
      dropoffLocation: (json['dropoffLocation'] as String?) ?? '',
      isRoundTrip: (json['isRoundTrip'] as bool?) ?? false,
      scheduledTimeText:
          (json['scheduledTimeText'] as String?) ?? 'الآن فوراً',
      passengersCount: ((json['passengersCount'] as num?)?.toInt() ?? 1).clamp(1, 8),
      estimatedFare: (json['estimatedFare'] as num?)?.toDouble() ?? 0.0,
      finalFare: (json['finalFare'] as num?)?.toDouble() ?? 0.0,
      driverId: (json['driverId'] as String?) ?? '',
      driverName: (json['driverName'] as String?) ?? '',
      driverPhone: (json['driverPhone'] as String?) ?? '',
      vehicleInfo: (json['vehicleInfo'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      status: WassalniStatus.fromCode(json['status'] as String?),
      createdAt: tsOrNow(json['createdAt']),
      completedAt:
          json['completedAt'] != null ? tsOrNow(json['completedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rideNumber': rideNumber,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'vehicleType': vehicleType.code,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'isRoundTrip': isRoundTrip,
      'scheduledTimeText': scheduledTimeText,
      'passengersCount': passengersCount,
      'estimatedFare': estimatedFare,
      'finalFare': finalFare,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleInfo': vehicleInfo,
      'notes': notes,
      'status': status.code,
      'createdAt': Timestamp.fromDate(createdAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    };
  }
}
