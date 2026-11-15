import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firebase_ts.dart';

/// سوق من الأسواق المتاحة للتسوق (سوق الجمعة بأبودشيشة أو أسواق القرى المجاورة)
class EtsawaqliMarket {
  final String id;
  final String name; // مثال: سوق الجمعة (أبودشيشة)
  final String dayOfWeek; // الجمعة / الثلاثاء / الأحد
  final String village; // أبودشيشة / بلقاس / المعصرة
  final String cutoffTimeText; // مثال: الخميس حتى 10 مساءً
  final String deliveryTimeText; // مثال: الجمعة من 11 ص حتى 2 ظ
  final double serviceFee; // رسوم خدمة التسوق
  final double deliveryFee; // رسوم التوصيل
  final bool isActive;

  const EtsawaqliMarket({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.village,
    required this.cutoffTimeText,
    required this.deliveryTimeText,
    this.serviceFee = 25.0,
    this.deliveryFee = 15.0,
    this.isActive = true,
  });

  factory EtsawaqliMarket.fromJson(Map<String, dynamic> json, String docId) {
    return EtsawaqliMarket(
      id: docId,
      name: json['name'] as String? ?? 'سوق القرية',
      dayOfWeek: json['dayOfWeek'] as String? ?? 'الجمعة',
      village: json['village'] as String? ?? 'أبودشيشة',
      cutoffTimeText:
          json['cutoffTimeText'] as String? ?? 'قبل موعد السوق بـ 12 ساعة',
      deliveryTimeText:
          json['deliveryTimeText'] as String? ?? 'يوم السوق ظهراً',
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 25.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 15.0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dayOfWeek': dayOfWeek,
      'village': village,
      'cutoffTimeText': cutoffTimeText,
      'deliveryTimeText': deliveryTimeText,
      'serviceFee': serviceFee,
      'deliveryFee': deliveryFee,
      'isActive': isActive,
    };
  }

  EtsawaqliMarket copyWith({
    String? name,
    String? dayOfWeek,
    String? village,
    String? cutoffTimeText,
    String? deliveryTimeText,
    double? serviceFee,
    double? deliveryFee,
    bool? isActive,
  }) {
    return EtsawaqliMarket(
      id: id,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      village: village ?? this.village,
      cutoffTimeText: cutoffTimeText ?? this.cutoffTimeText,
      deliveryTimeText: deliveryTimeText ?? this.deliveryTimeText,
      serviceFee: serviceFee ?? this.serviceFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// صنف من أصناف السوق (خضار، فاكهة، لحوم، أسماك، طيور...)
class EtsawaqliProductItem {
  final String id;
  final String name; // مثال: طماطم بلدي طازة
  final String
      category; // خضروات / فواكه / لحوم / دواجن / أسماك / ألبان وجبن / عطارة
  final String unit; // كيلو / نصف كيلو / رابطة / قفص / حبة
  final double estimatedPrice; // السعر التقديري المحدد من الإدارة
  final bool isAvailable;
  final String imageUrl;

  const EtsawaqliProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.estimatedPrice,
    this.isAvailable = true,
    this.imageUrl = '',
  });

  factory EtsawaqliProductItem.fromJson(
      Map<String, dynamic> json, String docId) {
    return EtsawaqliProductItem(
      id: docId,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'خضروات',
      unit: json['unit'] as String? ?? 'كيلو',
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'unit': unit,
      'estimatedPrice': estimatedPrice,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
    };
  }

  EtsawaqliProductItem copyWith({
    String? name,
    String? category,
    String? unit,
    double? estimatedPrice,
    bool? isAvailable,
    String? imageUrl,
  }) {
    return EtsawaqliProductItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// عنصر مشتريات داخل سلة أو فاتورة التسوق
class EtsawaqliCartItem {
  final String productId;
  final String productName;
  final String category;
  final String unit;
  final double quantity; // e.g. 1.0 or 2.5
  final double unitPrice;
  final String userNotes; // مثال: طماطم جامدة للسلطة

  const EtsawaqliCartItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    this.userNotes = '',
  });

  double get totalPrice => quantity * unitPrice;

  factory EtsawaqliCartItem.fromJson(Map<String, dynamic> json) {
    return EtsawaqliCartItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      unit: json['unit'] as String? ?? 'كيلو',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      userNotes: json['userNotes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'category': category,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'userNotes': userNotes,
    };
  }
}

/// فاتورة اشتراك وتسوق «إتسوقلي» المنظمة على نسق كاشير السوبر ماركت
class EtsawaqliOrder {
  final String id;
  final String invoiceNumber; // رقم فاتورة مميز غير متكرر: TS-20261115-7821
  final String userId;
  final String userName;
  final String userPhone;
  final String marketId;
  final String marketName;
  final String marketDay;
  final List<EtsawaqliCartItem> items;
  final double itemsSubtotal; // مجموع ثمن السلع المقدر
  final double serviceFee; // رسوم خدمة التسوق
  final double deliveryFee; // رسوم التوصيل
  final double totalAmount; // الإجمالي النهائي
  final String claimCode; // كود الاستلام السري 4 أرقام
  final String
      status; // pending / shopping / delivering / completed / cancelled
  final String shopperName; // اسم مندوبة/مندوب التسوق
  final String shopperPhone;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String notes;

  const EtsawaqliOrder({
    required this.id,
    required this.invoiceNumber,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.marketId,
    required this.marketName,
    required this.marketDay,
    required this.items,
    required this.itemsSubtotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.totalAmount,
    required this.claimCode,
    this.status = 'pending',
    this.shopperName = '',
    this.shopperPhone = '',
    required this.deliveryAddress,
    required this.createdAt,
    this.deliveredAt,
    this.notes = '',
  });

  /// نص الملاحظة الإلزامية في نهاية فاتورة التسوق
  static const String marketNoticeText =
      'الأسعار قابلة للتحديث حسب أسعار السوق الفعلي عند الشراء، وقد تتأثر جودة بعض المنتجات بالمواسم. نلتزم دائماً بانتقاء أفضل جودة وأنسب سعر لكم. شكراً لتفهمكم';

  String get marketNotice => marketNoticeText;

  String get statusArabic {
    switch (status) {
      case 'shopping':
        return 'المندوبة تتسوق لك الآن 🧺';
      case 'delivering':
        return 'جاري التوصيل لباب بيتك 🛵';
      case 'completed':
        return 'تم التسليم بنجاح ✅';
      case 'cancelled':
        return 'ملغي ❌';
      default:
        return 'طلب مسجل — بانتظار يوم السوق ⏳';
    }
  }

  factory EtsawaqliOrder.fromJson(Map<String, dynamic> json, String docId) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((item) => EtsawaqliCartItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return EtsawaqliOrder(
      id: docId,
      invoiceNumber: json['invoiceNumber'] as String? ?? 'TS-$docId',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      marketId: json['marketId'] as String? ?? '',
      marketName: json['marketName'] as String? ?? '',
      marketDay: json['marketDay'] as String? ?? '',
      items: itemsList,
      itemsSubtotal: (json['itemsSubtotal'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      claimCode: json['claimCode'] as String? ?? '0000',
      status: json['status'] as String? ?? 'pending',
      shopperName: json['shopperName'] as String? ?? '',
      shopperPhone: json['shopperPhone'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      createdAt: tsToDateTime(json['createdAt']) ?? DateTime.now(),
      deliveredAt: tsToDateTime(json['deliveredAt']),
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceNumber': invoiceNumber,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'marketId': marketId,
      'marketName': marketName,
      'marketDay': marketDay,
      'items': items.map((i) => i.toJson()).toList(),
      'itemsSubtotal': itemsSubtotal,
      'serviceFee': serviceFee,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'claimCode': claimCode,
      'status': status,
      'shopperName': shopperName,
      'shopperPhone': shopperPhone,
      'deliveryAddress': deliveryAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'notes': notes,
    };
  }
}
