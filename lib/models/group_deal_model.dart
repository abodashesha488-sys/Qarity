import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firebase_ts.dart';

/// نموذج بيانات صفقة الشراء الجماعي بسعر الجملة
class GroupDealModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double marketPrice; // السعر في السوق
  final double dealPrice; // سعر الصفقة الجماعية (سعر الجملة)
  final double depositAmount; // قيمة عربون جدية الحجز للوحدة
  final int targetCount; // العدد المطلوب لاكتمال الصفقة
  final int currentCount; // العدد الفعلي المؤكد حتى الآن
  final DateTime endTime; // وقت انتهاء العرض
  final bool isActive; // هل الصفقة معروضة ونشطة
  final bool isCompleted; // هل اكتمل العدد أو أغلقت
  final String category; // تصنيف السلعة (أغذية، تموين، أعلاف، إلخ)
  final String unitName; // اسم الوحدة (كرتونة، شيكارة، كيلو، إلخ)
  final String createdBy; // معرف الأدمن المنشئ
  final DateTime? createdAt;

  const GroupDealModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.marketPrice,
    required this.dealPrice,
    required this.depositAmount,
    required this.targetCount,
    this.currentCount = 0,
    required this.endTime,
    this.isActive = true,
    this.isCompleted = false,
    this.category = 'تموين وأغذية',
    this.unitName = 'حصة',
    this.createdBy = '',
    this.createdAt,
  });

  /// الوفر للوحدة الواحدة (جنيه)
  double get savingsPerUnit => (marketPrice - dealPrice).clamp(0, double.infinity);

  /// نسبة الخصم المئوية
  int get discountPercentage {
    if (marketPrice <= 0) return 0;
    final pct = ((marketPrice - dealPrice) / marketPrice) * 100;
    return pct.clamp(0, 100).round();
  }

  /// إجمالي الوفر المالي لأهالي القرية حتى الآن من هذه الصفقة
  double get totalVillageSavings => currentCount * savingsPerUnit;

  /// إجمالي قيمة المبيعات المتوقعة أو المحققة
  double get totalDealValue => currentCount * dealPrice;

  /// إجمالي العربون المؤكد استلامه
  double get totalDepositsCollected => currentCount * depositAmount;

  /// إجمالي المتبقي للتحصيل عند التسليم
  double get totalRemainingToCollect => currentCount * (dealPrice - depositAmount);

  /// نسبة اكتمال الصفقة (من 0.0 إلى 1.0)
  double get progressRatio {
    if (targetCount <= 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// عدد الحصص المتبقية لتفعيل سعر الجملة
  int get remainingCount => (targetCount - currentCount).clamp(0, targetCount);

  /// هل انتهى وقت الصفقة
  bool get isExpired => DateTime.now().isAfter(endTime);

  /// هل الصفقة متاحة للحجز حالياً
  bool get isAvailableForBooking => isActive && !isCompleted && !isExpired && remainingCount > 0;

  factory GroupDealModel.fromJson(Map<String, dynamic> json, String docId) {
    return GroupDealModel(
      id: docId,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      marketPrice: (json['marketPrice'] as num?)?.toDouble() ?? 0.0,
      dealPrice: (json['dealPrice'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      targetCount: (json['targetCount'] as num?)?.toInt() ?? 1,
      currentCount: (json['currentCount'] as num?)?.toInt() ?? 0,
      endTime: tsToDateTime(json['endTime']) ?? DateTime.now().add(const Duration(days: 3)),
      isActive: json['isActive'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
      category: json['category'] as String? ?? 'تموين وأغذية',
      unitName: json['unitName'] as String? ?? 'حصة',
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: tsToDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'marketPrice': marketPrice,
      'dealPrice': dealPrice,
      'depositAmount': depositAmount,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'endTime': Timestamp.fromDate(endTime),
      'isActive': isActive,
      'isCompleted': isCompleted,
      'category': category,
      'unitName': unitName,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  GroupDealModel copyWith({
    String? title,
    String? description,
    String? imageUrl,
    double? marketPrice,
    double? dealPrice,
    double? depositAmount,
    int? targetCount,
    int? currentCount,
    DateTime? endTime,
    bool? isActive,
    bool? isCompleted,
    String? category,
    String? unitName,
  }) {
    return GroupDealModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      marketPrice: marketPrice ?? this.marketPrice,
      dealPrice: dealPrice ?? this.dealPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      unitName: unitName ?? this.unitName,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}

/// نموذج حجز المشترك في صفقة الجملة
class DealParticipantModel {
  final String id;
  final String dealId;
  final String userId;
  final String userName;
  final String userPhone;
  final int quantity; // عدد الحصص المطلوبة
  final String paymentMethod; // فودافون كاش / إنستاباي / مندوب القرية
  final String claimCode; // كود الاستلام السري المكون من 4 أرقام
  final bool isConfirmedByAdmin; // هل تم تأكيد استلام العربون وزيادة العداد
  final DateTime? confirmedAt;
  final String confirmedBy;
  final bool isDelivered; // هل استلم العميل بضاعته
  final DateTime? deliveredAt;
  final String deliveredBy; // معرف عامل التوصيل أو الأدمن المسلم
  final String notes;
  final DateTime? createdAt;

  const DealParticipantModel({
    required this.id,
    required this.dealId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.quantity = 1,
    this.paymentMethod = 'مندوب القرية',
    required this.claimCode,
    this.isConfirmedByAdmin = false,
    this.confirmedAt,
    this.confirmedBy = '',
    this.isDelivered = false,
    this.deliveredAt,
    this.deliveredBy = '',
    this.notes = '',
    this.createdAt,
  });

  /// حساب إجمالي العربون المستحق لهذا المشترك
  double depositRequired(double unitDeposit) => quantity * unitDeposit;

  /// حساب إجمالي المبلغ الكلي للحصة
  double totalAmount(double dealPrice) => quantity * dealPrice;

  /// المبلغ المتبقي للدفع عند الاستلام
  double remainingOnDelivery(double dealPrice, double unitDeposit) =>
      quantity * (dealPrice - unitDeposit);

  factory DealParticipantModel.fromJson(Map<String, dynamic> json, String docId) {
    return DealParticipantModel(
      id: docId,
      dealId: json['dealId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      paymentMethod: json['paymentMethod'] as String? ?? 'مندوب القرية',
      claimCode: json['claimCode'] as String? ?? '',
      isConfirmedByAdmin: json['isConfirmedByAdmin'] as bool? ?? false,
      confirmedAt: tsToDateTime(json['confirmedAt']),
      confirmedBy: json['confirmedBy'] as String? ?? '',
      isDelivered: json['isDelivered'] as bool? ?? false,
      deliveredAt: tsToDateTime(json['deliveredAt']),
      deliveredBy: json['deliveredBy'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: tsToDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dealId': dealId,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'quantity': quantity,
      'paymentMethod': paymentMethod,
      'claimCode': claimCode,
      'isConfirmedByAdmin': isConfirmedByAdmin,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'confirmedBy': confirmedBy,
      'isDelivered': isDelivered,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'deliveredBy': deliveredBy,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
