import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/etsawaqli_model.dart';
import 'group_deal_service.dart';
import 'remote_push_service.dart';

/// خدمة إدارة أسواق ومشتريات وفواتير «إتسوقلي»
class EtsawaqliService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _marketsCol =>
      _firestore.collection('etsawaqli_markets');

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _firestore.collection('etsawaqli_products');

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('etsawaqli_orders');

  /// توليد كود استلام سري عشوائي من 4 أرقام
  static String generateClaimCode() => GroupDealService.generateClaimCode();

  /// توليد رقم فاتورة كاشير فريد غير متكرر: TS-YYYYMMDD-XXXX
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final rand = (1000 + Random.secure().nextInt(9000)).toString();
    return 'TS-$y$m$d-$rand';
  }

  // ───────────────────────── الأسواق ─────────────────────────

  /// قائمة الأسواق الافتراضية
  static const List<EtsawaqliMarket> defaultMarkets = [
    EtsawaqliMarket(
      id: 'market_friday_abudshisha',
      name: 'سوق الجمعة (أبودشيشة)',
      dayOfWeek: 'الجمعة',
      village: 'أبودشيشة',
      cutoffTimeText: 'الخميس حتى 10:00 مساءً',
      deliveryTimeText: 'الجمعة من 11:30 ص حتى 2:30 ظهراً',
    ),
    EtsawaqliMarket(
      id: 'market_tuesday_belqas',
      name: 'سوق الثلاثاء (بلقاس)',
      dayOfWeek: 'الثلاثاء',
      village: 'بلقاس',
      cutoffTimeText: 'الإثنين حتى 10:00 مساءً',
      deliveryTimeText: 'الثلاثاء من 12:00 ظهراً حتى 3:00 عصراً',
      serviceFee: 30.0,
      deliveryFee: 20.0,
    ),
    EtsawaqliMarket(
      id: 'market_sunday_maasara',
      name: 'سوق الأحد (المعصرة)',
      dayOfWeek: 'الأحد',
      village: 'المعصرة',
      cutoffTimeText: 'السبت حتى 10:00 مساءً',
      deliveryTimeText: 'الأحد من 12:00 ظهراً حتى 3:00 عصراً',
      serviceFee: 30.0,
      deliveryFee: 20.0,
    ),
    EtsawaqliMarket(
      id: 'market_wednesday_stamoni',
      name: 'سوق الأربعاء (الستاموني)',
      dayOfWeek: 'الأربعاء',
      village: 'الستاموني',
      cutoffTimeText: 'الثلاثاء حتى 10:00 مساءً',
      deliveryTimeText: 'الأربعاء من 12:00 ظهراً حتى 3:00 عصراً',
      serviceFee: 30.0,
      deliveryFee: 20.0,
    ),
  ];

  /// بث الأسواق النشطة مع التغذية الافتراضية
  Stream<List<EtsawaqliMarket>> watchActiveMarkets() {
    return _marketsCol.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return defaultMarkets;
      }
      return snap.docs
          .map((d) => EtsawaqliMarket.fromJson(d.data(), d.id))
          .where((m) => m.isActive)
          .toList();
    });
  }

  /// إضافة أو تعديل سوق
  Future<void> upsertMarket(EtsawaqliMarket market) async {
    final docId = market.id.isEmpty ? _marketsCol.doc().id : market.id;
    await _marketsCol.doc(docId).set(market.toJson(), SetOptions(merge: true));
  }

  // ───────────────────────── قائمة السلع وأسعار السوق ─────────────────────────

  /// السلع الشائعة الافتراضية للأسواق الريفية المصرية
  static const List<EtsawaqliProductItem> defaultProducts = [
    // خضروات
    EtsawaqliProductItem(
        id: 'veg_tomato',
        name: 'طماطم بلدي طازة',
        category: 'خضروات',
        unit: 'كيلو',
        estimatedPrice: 15.0),
    EtsawaqliProductItem(
        id: 'veg_potato',
        name: 'بطاطس تحمير',
        category: 'خضروات',
        unit: 'كيلو',
        estimatedPrice: 20.0),
    EtsawaqliProductItem(
        id: 'veg_onion',
        name: 'بصل أحمر بلدي',
        category: 'خضروات',
        unit: 'كيلو',
        estimatedPrice: 18.0),
    EtsawaqliProductItem(
        id: 'veg_cucumber',
        name: 'خيار بلدي صابح',
        category: 'خضروات',
        unit: 'كيلو',
        estimatedPrice: 16.0),
    EtsawaqliProductItem(
        id: 'veg_pepper',
        name: 'فلفل رومي وشطة',
        category: 'خضروات',
        unit: 'كيلو',
        estimatedPrice: 22.0),
    EtsawaqliProductItem(
        id: 'veg_eggplant',
        name: 'باذنجان رومي وعروس',
        category: 'خضروات',
        unit: 'كيلو',
        estimatedPrice: 12.0),
    EtsawaqliProductItem(
        id: 'veg_zucchini',
        name: 'كوسة فلاحي',
        category: 'خضروات',
        unit: 'كيلو',
        estimatedPrice: 18.0),
    EtsawaqliProductItem(
        id: 'veg_lemon',
        name: 'ليمون بلدي بنزهير',
        category: 'خضروات',
        unit: 'كيلو',
        estimatedPrice: 30.0),
    EtsawaqliProductItem(
        id: 'veg_greens',
        name: 'خضرة مشكلة (شبت وبقدونس وكزبرة)',
        category: 'خضروات',
        unit: 'رابطة',
        estimatedPrice: 5.0),

    // فواكه
    EtsawaqliProductItem(
        id: 'fruit_banana',
        name: 'موز بلدي فاخر',
        category: 'فواكه',
        unit: 'كيلو',
        estimatedPrice: 25.0),
    EtsawaqliProductItem(
        id: 'fruit_orange',
        name: 'برتقال ويوسفي بلدي',
        category: 'فواكه',
        unit: 'كيلو',
        estimatedPrice: 20.0),
    EtsawaqliProductItem(
        id: 'fruit_apple',
        name: 'تفاح مصري سكري',
        category: 'فواكه',
        unit: 'كيلو',
        estimatedPrice: 45.0),
    EtsawaqliProductItem(
        id: 'fruit_strawberry',
        name: 'فراولة بلدي سكري',
        category: 'فواكه',
        unit: 'كيلو',
        estimatedPrice: 35.0),
    EtsawaqliProductItem(
        id: 'fruit_guava',
        name: 'جوافة بناتي',
        category: 'فواكه',
        unit: 'كيلو',
        estimatedPrice: 30.0),

    // لحوم ودواجن
    EtsawaqliProductItem(
        id: 'poultry_white',
        name: 'فراخ بيضاء مذبوحة طازة ومغسولة',
        category: 'دواجن',
        unit: 'كيلو',
        estimatedPrice: 90.0),
    EtsawaqliProductItem(
        id: 'poultry_baladi',
        name: 'فراخ بلدي حشو',
        category: 'دواجن',
        unit: 'كيلو',
        estimatedPrice: 125.0),
    EtsawaqliProductItem(
        id: 'poultry_pane',
        name: 'صدور بانيه بلدي صافي',
        category: 'دواجن',
        unit: 'كيلو',
        estimatedPrice: 210.0),
    EtsawaqliProductItem(
        id: 'meat_beef',
        name: 'لحم بقري بلدي مشكل',
        category: 'لحوم',
        unit: 'كيلو',
        estimatedPrice: 380.0),
    EtsawaqliProductItem(
        id: 'meat_minced',
        name: 'لحم مفروم بلدي',
        category: 'لحوم',
        unit: 'كيلو',
        estimatedPrice: 360.0),

    // أسماك
    EtsawaqliProductItem(
        id: 'fish_tilapia',
        name: 'سمك بلطي نيلي طازة',
        category: 'أسماك',
        unit: 'كيلو',
        estimatedPrice: 85.0),
    EtsawaqliProductItem(
        id: 'fish_mullet',
        name: 'سمك بوري نمرة واحد',
        category: 'أسماك',
        unit: 'كيلو',
        estimatedPrice: 140.0),

    // ألبان وجبن فلاحي
    EtsawaqliProductItem(
        id: 'dairy_cottage',
        name: 'جبن قريش فلاحي أصلي',
        category: 'ألبان وجبن',
        unit: 'كيلو',
        estimatedPrice: 80.0),
    EtsawaqliProductItem(
        id: 'dairy_butter',
        name: 'زبدة بلدي جاموسي فلاحي',
        category: 'ألبان وجبن',
        unit: 'كيلو',
        estimatedPrice: 240.0),
    EtsawaqliProductItem(
        id: 'dairy_eggs',
        name: 'بيض بلدي طازج',
        category: 'ألبان وجبن',
        unit: 'كرتونة',
        estimatedPrice: 165.0),
  ];

  /// بث السلع المتاحة مصنفة
  Stream<List<EtsawaqliProductItem>> watchProducts({String? category}) {
    return _productsCol.snapshots().map((snap) {
      List<EtsawaqliProductItem> items;
      if (snap.docs.isEmpty) {
        items = defaultProducts;
      } else {
        items = snap.docs
            .map((d) => EtsawaqliProductItem.fromJson(d.data(), d.id))
            .where((p) => p.isAvailable)
            .toList();
      }
      if (category != null && category.isNotEmpty && category != 'الكل') {
        return items.where((p) => p.category == category).toList();
      }
      return items;
    });
  }

  /// تحديث سعر سلعة أو إضافتها (للأدمن)
  Future<void> upsertProduct(EtsawaqliProductItem item) async {
    final docId = item.id.isEmpty ? _productsCol.doc().id : item.id;
    await _productsCol.doc(docId).set(item.toJson(), SetOptions(merge: true));
  }

  /// حذف سلعة
  Future<void> deleteProduct(String productId) async {
    await _productsCol.doc(productId).delete();
  }

  // ───────────────────────── طلبات وفواتير التسوق ─────────────────────────

  /// إنشاء فاتورة اشتراك وتسوق جديدة
  Future<String> createOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required String marketId,
    required String marketName,
    required String marketDay,
    required List<EtsawaqliCartItem> items,
    required double itemsSubtotal,
    required double serviceFee,
    required double deliveryFee,
    required String deliveryAddress,
    bool isRecurringWeekly = false,
    String notes = '',
  }) async {
    final docRef = _ordersCol.doc();
    final invoiceNumber = generateInvoiceNumber();
    final claimCode = generateClaimCode();

    final order = EtsawaqliOrder(
      id: docRef.id,
      invoiceNumber: invoiceNumber,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      marketId: marketId,
      marketName: marketName,
      marketDay: marketDay,
      items: items,
      itemsSubtotal: itemsSubtotal,
      serviceFee: serviceFee,
      deliveryFee: deliveryFee,
      totalAmount: itemsSubtotal + serviceFee + deliveryFee,
      claimCode: claimCode,
      deliveryAddress: deliveryAddress.trim(),
      isRecurringWeekly: isRecurringWeekly,
      notes: notes.trim(),
      createdAt: DateTime.now(),
    );

    await docRef.set(order.toJson());
    unawaited(RemotePushService.notifyAdmins('etsawaqli_orders'));
    return docRef.id;
  }

  /// تحديث حالة الطلب (قيد التجهيز / جاري التوصيل / مكتمل / ملغي)
  Future<void> updateOrderStatus(String orderId, String newStatus, {String shopperName = '', String shopperPhone = ''}) async {
    final updateData = <String, dynamic>{'status': newStatus};
    if (shopperName.isNotEmpty) updateData['shopperName'] = shopperName;
    if (shopperPhone.isNotEmpty) updateData['shopperPhone'] = shopperPhone;
    await _ordersCol.doc(orderId).update(updateData);
  }

  /// تأكيد تسليم فاتورة المشتريات للعميل بمطابقة كود الاستلام
  Future<bool> verifyAndDeliverOrder({
    required String orderId,
    required String inputCode,
    required String shopperUid,
  }) async {
    final docRef = _ordersCol.doc(orderId);
    final snap = await docRef.get();
    if (!snap.exists) return false;

    final data = snap.data();
    final realCode = (data?['claimCode'] as String?) ?? '';

    if (realCode.trim() != inputCode.trim()) {
      return false;
    }

    await docRef.update({
      'status': 'completed',
      'deliveredAt': FieldValue.serverTimestamp(),
      'deliveredBy': shopperUid,
    });
    return true;
  }

  /// إلغاء الطلب
  Future<void> cancelOrder(String orderId) async {
    await _ordersCol.doc(orderId).update({'status': 'cancelled'});
  }

  /// متابعة فواتير وتاريخ اشتراكات المستخدم الحالي
  Stream<List<EtsawaqliOrder>> watchMyOrders(String userId) {
    return _ordersCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => EtsawaqliOrder.fromJson(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// متابعة كل فواتير التسوق للوحة الإدارة والمندوبات
  Stream<List<EtsawaqliOrder>> watchAllOrders() {
    return _ordersCol.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => EtsawaqliOrder.fromJson(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
