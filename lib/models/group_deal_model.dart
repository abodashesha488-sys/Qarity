import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firebase_ts.dart';

/// نموذج بيانات صفقة الشراء الجماعي بسعر الجملة
class GroupDealModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> imageUrls; // دعم صور متعددة للمنتج
  final double marketPrice; // السعر في السوق
  final double dealPrice; // سعر الصفقة الجماعية (سعر الجملة)
  final double depositAmount; // قيمة عربون جدية الحجز للوحدة
  final int targetCount; // العدد المطلوب لاكتمال الصفقة
  final int currentCount; // إجمالي الحصص المحجوزة حتى الآن
  final int confirmedCount; // الحصص المؤكدة باستلام العربون
  final DateTime endTime; // وقت انتهاء العرض
  final bool isActive; // هل الصفقة معروضة ونشطة
  final bool isCompleted; // هل اكتمل العدد أو أغلقت
  final String category; // تصنيف السلعة (أغذية، تموين، أعلاف، إلخ)
  final String unitName; // اسم الوحدة (كرتونة، شيكارة، كيلو، إلخ)
  final int reopenRequestsCount; // عدد طلبات إعادة فتح الصفقة
  final String createdBy; // معرف الأدمن المنشئ
  final DateTime? createdAt;

  const GroupDealModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl = '',
    this.imageUrls = const [],
    required this.marketPrice,
    required this.dealPrice,
    required this.depositAmount,
    required this.targetCount,
    this.currentCount = 0,
    this.confirmedCount = 0,
    required this.endTime,
    this.isActive = true,
    this.isCompleted = false,
    this.reopenRequestsCount = 0,
    this.category = 'تموين ومواد غذائية',
    this.unitName = 'حصة',
    this.createdBy = '',
    this.createdAt,
  });

  /// الصورة الرئيسية الأولى
  String get primaryImage {
    if (imageUrls.isNotEmpty && imageUrls.first.trim().isNotEmpty) {
      return imageUrls.first.trim();
    }
    return imageUrl.trim();
  }

  /// قائمة كل الصور المتاحة بدون فراغات
  List<String> get allImages {
    final list = <String>[];
    for (final img in imageUrls) {
      final t = img.trim();
      if (t.isNotEmpty && !list.contains(t)) list.add(t);
    }
    final single = imageUrl.trim();
    if (single.isNotEmpty && !list.contains(single)) list.add(single);
    return list;
  }

  /// الحصص قيد انتظار تأكيد العربون
  int get pendingCount => (currentCount - confirmedCount).clamp(0, currentCount);

  /// الوفر للوحدة الواحدة (جنيه)
  double get savingsPerUnit => (marketPrice - dealPrice).clamp(0, double.infinity);
  double get savingPerUnit => savingsPerUnit;

  /// نسبة الخصم المئوية
  int get discountPercentage {
    if (marketPrice <= 0) return 0;
    final pct = ((marketPrice - dealPrice) / marketPrice) * 100;
    return pct.clamp(0, 100).round();
  }

  /// إجمالي الوفر المالي لأهالي القرية المحجوز حتى الآن من هذه الصفقة
  double get totalVillageSavings => currentCount * savingsPerUnit;

  /// الوفر المالي المؤكد فعلياً
  double get confirmedVillageSavings => confirmedCount * savingsPerUnit;

  /// إجمالي قيمة المبيعات المحجوزة
  double get totalDealValue => currentCount * dealPrice;

  /// إجمالي قيمة المبيعات المؤكدة
  double get confirmedDealValue => confirmedCount * dealPrice;

  /// إجمالي العربون المؤكد استلامه
  double get totalDepositsCollected => confirmedCount * depositAmount;

  /// العربون قيد الانتظار
  double get pendingDeposits => pendingCount * depositAmount;

  /// إجمالي المتبقي للتحصيل عند التسليم
  double get totalRemainingToCollect => currentCount * (dealPrice - depositAmount);

  /// نسبة اكتمال الصفقة (من 0.0 إلى 1.0)
  double get progressRatio {
    if (targetCount <= 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// عدد الحصص المتبقية لاكتمال الصفقة
  int get remainingCount => (targetCount - currentCount).clamp(0, targetCount);

  /// هل انتهى وقت الصفقة
  bool get isExpired => DateTime.now().isAfter(endTime);

  /// هل الصفقة متاحة للحجز حالياً
  bool get isAvailableForBooking => isActive && !isCompleted && !isExpired && remainingCount > 0;

  static const List<String> supportedCategories = [
    'تموين ومواد غذائية',
    'لحوم ودواجن وأسماك',
    'خضروات وفواكه جملة',
    'أعلاف وثروة حيوانية',
    'أسمدة ومستلزمات زراعية',
    'أجهزة كهربائية ومنزلية',
    'ملابس ومفروشات',
    'مستلزمات مدرسية ومكتبية',
    'أخرى',
  ];

  static const List<String> supportedUnits = [
    'كرتونة',
    'شيكارة',
    'كيلو',
    'قفص / عداية',
    'طرد / باكت',
    'لتر / جركن',
    'رأس',
    'قطعة / جهاز',
    'طن',
    'حصة',
  ];

  factory GroupDealModel.fromJson(Map<String, dynamic> json, String docId) {
    final imgs = (json['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const [];
    final singleImg = (json['imageUrl'] as String? ?? '').trim();
    final resolvedList = imgs.isNotEmpty
        ? imgs
        : (singleImg.isNotEmpty ? [singleImg] : const <String>[]);

    return GroupDealModel(
      id: docId,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: singleImg.isNotEmpty ? singleImg : (resolvedList.isNotEmpty ? resolvedList.first : ''),
      imageUrls: resolvedList,
      marketPrice: (json['marketPrice'] as num?)?.toDouble() ?? 0.0,
      dealPrice: (json['dealPrice'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      targetCount: (json['targetCount'] as num?)?.toInt() ?? 1,
      currentCount: (json['currentCount'] as num?)?.toInt() ?? 0,
      confirmedCount: (json['confirmedCount'] as num?)?.toInt() ?? 0,
      endTime: tsToDateTime(json['endTime']) ?? DateTime.now().add(const Duration(days: 3)),
      isActive: json['isActive'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
      category: json['category'] as String? ?? 'تموين ومواد غذائية',
      unitName: json['unitName'] as String? ?? 'حصة',
      reopenRequestsCount: (json['reopenRequestsCount'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: tsToDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': primaryImage,
      'imageUrls': allImages,
      'marketPrice': marketPrice,
      'dealPrice': dealPrice,
      'depositAmount': depositAmount,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'confirmedCount': confirmedCount,
      'endTime': Timestamp.fromDate(endTime),
      'isActive': isActive,
      'isCompleted': isCompleted,
      'category': category,
      'unitName': unitName,
      'reopenRequestsCount': reopenRequestsCount,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  GroupDealModel copyWith({
    String? title,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    double? marketPrice,
    double? dealPrice,
    double? depositAmount,
    int? targetCount,
    int? currentCount,
    int? confirmedCount,
    DateTime? endTime,
    bool? isActive,
    bool? isCompleted,
    String? category,
    String? unitName,
    int? reopenRequestsCount,
  }) {
    return GroupDealModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      marketPrice: marketPrice ?? this.marketPrice,
      dealPrice: dealPrice ?? this.dealPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      unitName: unitName ?? this.unitName,
      reopenRequestsCount: reopenRequestsCount ?? this.reopenRequestsCount,
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
  final String deliveryOption; // 'hub' (مقر التوزيع - مجاناً) أو 'home' (توصيل للبيت)
  final String deliveryAddress; // عنوان التوصيل إذا كان توصيل منزلي
  final double deliveryFee; // رسوم التوصيل المنزلي إن وجدت
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
    this.deliveryOption = 'hub',
    this.deliveryAddress = '',
    this.deliveryFee = 0.0,
    this.notes = '',
    this.createdAt,
  });

  /// حساب إجمالي العربون المستحق لهذا المشترك
  double depositRequired(double unitDeposit) => quantity * unitDeposit;

  /// حساب إجمالي المبلغ الكلي للحصة مع رسوم التوصيل إن وجدت
  double totalAmount(double dealPrice) => (quantity * dealPrice) + deliveryFee;

  /// المبلغ المتبقي للدفع عند الاستلام مع رسوم التوصيل
  double remainingOnDelivery(double dealPrice, double unitDeposit) =>
      (quantity * (dealPrice - unitDeposit)) + deliveryFee;

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
      deliveryOption: json['deliveryOption'] as String? ?? 'hub',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
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
      'deliveryOption': deliveryOption,
      'deliveryAddress': deliveryAddress,
      'deliveryFee': deliveryFee,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  DealParticipantModel copyWith({
    int? quantity,
    String? paymentMethod,
    bool? isConfirmedByAdmin,
    DateTime? confirmedAt,
    String? confirmedBy,
    bool? isDelivered,
    DateTime? deliveredAt,
    String? deliveredBy,
    String? notes,
  }) {
    return DealParticipantModel(
      id: id,
      dealId: dealId,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      quantity: quantity ?? this.quantity,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      claimCode: claimCode,
      isConfirmedByAdmin: isConfirmedByAdmin ?? this.isConfirmedByAdmin,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      isDelivered: isDelivered ?? this.isDelivered,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      deliveredBy: deliveredBy ?? this.deliveredBy,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}

/// طلب إعادة فتح صفقة منتهية من قبل مستخدم لم يلحق التسجيل بها
class GroupDealReopenRequest {
  final String id;
  final String dealId;
  final String dealTitle;
  final String userId;
  final String userName;
  final String userPhone;
  final int requestedQuantity;
  final DateTime createdAt;
  final bool isHandled;

  const GroupDealReopenRequest({
    required this.id,
    required this.dealId,
    required this.dealTitle,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.requestedQuantity = 1,
    required this.createdAt,
    this.isHandled = false,
  });

  factory GroupDealReopenRequest.fromJson(Map<String, dynamic> json, String docId) {
    return GroupDealReopenRequest(
      id: docId,
      dealId: json['dealId'] as String? ?? '',
      dealTitle: json['dealTitle'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      requestedQuantity: (json['requestedQuantity'] as num?)?.toInt() ?? 1,
      createdAt: tsToDateTime(json['createdAt']) ?? DateTime.now(),
      isHandled: json['isHandled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dealId': dealId,
      'dealTitle': dealTitle,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'requestedQuantity': requestedQuantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'isHandled': isHandled,
    };
  }
}
