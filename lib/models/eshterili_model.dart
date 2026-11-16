import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firebase_ts.dart';

/// حالة طلب خدمة «إشتريلي»
enum EshteriliStatus {
  pendingPricing, // بانتظار تسعير الإدارة أو المندوب
  pricedWaitingApproval, // تم التسعير وبانتظار موافقة العميل
  inProgress, // جاري الشراء والتوصيل
  completed, // تم التسليم بنجاح
  cancelled; // ملغي

  static EshteriliStatus fromCode(String? code) => EshteriliStatusX.fromCode(code);
}

extension EshteriliStatusX on EshteriliStatus {
  String get code {
    switch (this) {
      case EshteriliStatus.pendingPricing:
        return 'pending_pricing';
      case EshteriliStatus.pricedWaitingApproval:
        return 'priced_waiting_approval';
      case EshteriliStatus.inProgress:
        return 'in_progress';
      case EshteriliStatus.completed:
        return 'completed';
      case EshteriliStatus.cancelled:
        return 'cancelled';
    }
  }

  String get labelArabic {
    switch (this) {
      case EshteriliStatus.pendingPricing:
        return 'قيد التسعير ⏳';
      case EshteriliStatus.pricedWaitingApproval:
        return 'بانتظار موافقتك على السعر 💬';
      case EshteriliStatus.inProgress:
        return 'جاري الشراء والتوصيل 🛵';
      case EshteriliStatus.completed:
        return 'تم التسليم بنجاح ✅';
      case EshteriliStatus.cancelled:
        return 'ملغي ❌';
    }
  }

  static EshteriliStatus fromCode(String? code) {
    switch (code) {
      case 'priced_waiting_approval':
        return EshteriliStatus.pricedWaitingApproval;
      case 'in_progress':
        return EshteriliStatus.inProgress;
      case 'completed':
        return EshteriliStatus.completed;
      case 'cancelled':
        return EshteriliStatus.cancelled;
      default:
        return EshteriliStatus.pendingPricing;
    }
  }
}

/// نموذج طلب خدمة «إشتريلي»
class EshteriliOrder {
  final String id;
  final String orderNumber; // رقم فاتورة مميز غير متكرر مثل: ESH-20261115-4891
  final String userId;
  final String userName;
  final String userPhone;
  final String itemsDescription; // تفاصيل المشتريات والطلبات
  final double estimatedBudget; // الميزانية المتوقعة من العميل
  final String storeOrArea; // المكان المفضل للشراء (محل معين أو منطقة)
  final String deliveryAddress; // عنوان التوصيل بالقرية
  final EshteriliStatus status;
  final double itemCost; // تكلفة البضاعة الفعلية المحددة من المندوب/الأدمن
  final double serviceFee; // رسوم خدمة التطبيق (عمولة الشراء)
  final double deliveryFee; // أجرة التوصيل
  final String claimCode; // كود الاستلام السري المكون من 4 أرقام
  final String assignedAgentId;
  final String assignedAgentName;
  final String assignedAgentPhone;
  final String imageUrl; // صورة ملحقة بالطلب (روشتة، قائمة مكتوبة بخط اليد، صورة المنتج)
  final List<String> imageUrls;
  final String receiptImageUrl; // صورة فاتورة المحل الورقية المرفوعة من المندوب
  final String notes;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  const EshteriliOrder({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.itemsDescription,
    required this.estimatedBudget,
    required this.storeOrArea,
    required this.deliveryAddress,
    this.status = EshteriliStatus.inProgress,
    this.itemCost = 0.0,
    this.serviceFee = 0.0,
    this.deliveryFee = 0.0,
    required this.claimCode,
    this.assignedAgentId = '',
    this.assignedAgentName = '',
    this.assignedAgentPhone = '',
    this.imageUrl = '',
    this.imageUrls = const [],
    this.receiptImageUrl = '',
    this.notes = '',
    required this.createdAt,
    this.deliveredAt,
  });

  /// الإجمالي الحسابي النهائي المطلوب من العميل
  double get totalAmount => itemCost + serviceFee + deliveryFee;

  /// هل تم تسعير الطلب من الإدارة
  bool get isPriced => itemCost > 0 || serviceFee > 0 || deliveryFee > 0;

  factory EshteriliOrder.fromJson(Map<String, dynamic> json, String docId) {
    return EshteriliOrder(
      id: docId,
      orderNumber: json['orderNumber'] as String? ?? 'ESH-$docId',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      itemsDescription: json['itemsDescription'] as String? ?? '',
      estimatedBudget: (json['estimatedBudget'] as num?)?.toDouble() ?? 0.0,
      storeOrArea: json['storeOrArea'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      status: EshteriliStatusX.fromCode(json['status'] as String?),
      itemCost: (json['itemCost'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      claimCode: json['claimCode'] as String? ?? '0000',
      assignedAgentId: json['assignedAgentId'] as String? ?? '',
      assignedAgentName: json['assignedAgentName'] as String? ?? '',
      assignedAgentPhone: json['assignedAgentPhone'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      receiptImageUrl: json['receiptImageUrl'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: tsToDateTime(json['createdAt']) ?? DateTime.now(),
      deliveredAt: tsToDateTime(json['deliveredAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderNumber': orderNumber,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'itemsDescription': itemsDescription,
      'estimatedBudget': estimatedBudget,
      'storeOrArea': storeOrArea,
      'deliveryAddress': deliveryAddress,
      'status': status.code,
      'itemCost': itemCost,
      'serviceFee': serviceFee,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'claimCode': claimCode,
      'assignedAgentId': assignedAgentId,
      'assignedAgentName': assignedAgentName,
      'assignedAgentPhone': assignedAgentPhone,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'receiptImageUrl': receiptImageUrl,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }

  EshteriliOrder copyWith({
    EshteriliStatus? status,
    double? itemCost,
    double? serviceFee,
    double? deliveryFee,
    String? assignedAgentId,
    String? assignedAgentName,
    String? assignedAgentPhone,
    String? imageUrl,
    List<String>? imageUrls,
    String? receiptImageUrl,
    String? notes,
    DateTime? deliveredAt,
  }) {
    return EshteriliOrder(
      id: id,
      orderNumber: orderNumber,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      itemsDescription: itemsDescription,
      estimatedBudget: estimatedBudget,
      storeOrArea: storeOrArea,
      deliveryAddress: deliveryAddress,
      status: status ?? this.status,
      itemCost: itemCost ?? this.itemCost,
      serviceFee: serviceFee ?? this.serviceFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      claimCode: claimCode,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
      assignedAgentName: assignedAgentName ?? this.assignedAgentName,
      assignedAgentPhone: assignedAgentPhone ?? this.assignedAgentPhone,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
