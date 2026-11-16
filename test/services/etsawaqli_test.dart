import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/etsawaqli_model.dart';
import 'package:qurity/services/etsawaqli_service.dart';
import 'package:qurity/widgets/etsawaqli_market_sheet.dart';

void main() {
  group('Etsawaqli Models Tests', () {
    test('EtsawaqliCartItem computes item totalPrice accurately', () {
      const item1 = EtsawaqliCartItem(
        productId: 'veg_tomato',
        productName: 'طماطم بلدي',
        category: 'خضروات',
        unit: 'كيلو',
        quantity: 3,
        unitPrice: 15.0,
      );
      expect(item1.totalPrice, 45.0); // 3 * 15 = 45

      const item2 = EtsawaqliCartItem(
        productId: 'poultry_white',
        productName: 'فراخ بيضاء',
        category: 'دواجن',
        unit: 'كيلو',
        quantity: 2,
        unitPrice: 90.0,
        userNotes: 'تقطيع 4 قطع',
      );
      expect(item2.totalPrice, 180.0); // 2 * 90 = 180
    });

    test('EtsawaqliOrder cashier invoice totals and notice text validation', () {
      const items = [
        EtsawaqliCartItem(
          productId: 'veg_tomato',
          productName: 'طماطم بلدي',
          category: 'خضروات',
          unit: 'كيلو',
          quantity: 2,
          unitPrice: 15.0,
        ),
        EtsawaqliCartItem(
          productId: 'veg_potato',
          productName: 'بطاطس تحمير',
          category: 'خضروات',
          unit: 'كيلو',
          quantity: 3,
          unitPrice: 20.0,
        ),
      ];

      final subtotal = items.fold<double>(0.0, (sum, i) => sum + i.totalPrice);
      expect(subtotal, 90.0); // (2*15) + (3*20) = 30 + 60 = 90

      final order = EtsawaqliOrder(
        id: 'ord_123',
        invoiceNumber: 'TS-20261115-4567',
        userId: 'u_client',
        userName: 'أم محمد',
        userPhone: '01055554444',
        marketId: 'market_friday_abudshisha',
        marketName: 'سوق الجمعة (أبودشيشة)',
        marketDay: 'الجمعة',
        items: items,
        itemsSubtotal: subtotal,
        serviceFee: 25.0,
        deliveryFee: 15.0,
        totalAmount: subtotal + 25.0 + 15.0,
        claimCode: '8392',
        deliveryAddress: 'شارع داير الناحية',
        createdAt: DateTime.now(),
      );

      expect(order.invoiceNumber, startsWith('TS-'));
      expect(order.totalAmount, 130.0); // 90 + 25 + 15 = 130
      expect(order.claimCode.length, 4);
      expect(order.marketNotice, contains('الأسعار قابلة للتحديث حسب أسعار السوق الفعلي عند الشراء'));
      expect(order.marketNotice, contains('نلتزم دائماً بانتقاء أفضل جودة وأنسب سعر لكم. شكراً لتفهمكم'));
    });

    test('EtsawaqliMarket and ProductItem serialization and copyWith', () {
      const market = EtsawaqliMarket(
        id: 'm_1',
        name: 'سوق الجمعة',
        dayOfWeek: 'الجمعة',
        village: 'أبودشيشة',
        cutoffTimeText: 'الخميس 10 م',
        deliveryTimeText: 'الجمعة 1 ظ',
        serviceFee: 20.0,
        deliveryFee: 10.0,
      );

      final jsonMarket = market.toJson();
      final restoredMarket = EtsawaqliMarket.fromJson(jsonMarket, 'm_1');
      expect(restoredMarket.name, 'سوق الجمعة');
      expect(restoredMarket.serviceFee, 20.0);

      final updatedMarket = market.copyWith(serviceFee: 30.0);
      expect(updatedMarket.serviceFee, 30.0);
      expect(updatedMarket.name, 'سوق الجمعة');

      const product = EtsawaqliProductItem(
        id: 'p_1',
        name: 'لحم بقري',
        category: 'لحوم',
        unit: 'كيلو',
        estimatedPrice: 380.0,
      );

      final jsonProd = product.toJson();
      final restoredProd = EtsawaqliProductItem.fromJson(jsonProd, 'p_1');
      expect(restoredProd.name, 'لحم بقري');
      expect(restoredProd.estimatedPrice, 380.0);

      final updatedProd = product.copyWith(estimatedPrice: 400.0);
      expect(updatedProd.estimatedPrice, 400.0);
    });
  });

  group('EtsawaqliService Generator Tests', () {
    test('generateInvoiceNumber matches TS-YYYYMMDD-XXXX format', () {
      for (int i = 0; i < 20; i++) {
        final invNum = EtsawaqliService.generateInvoiceNumber();
        expect(invNum, matches(r'^TS-\d{8}-\d{4}$'));
      }
    });

    test('generateClaimCode produces 4-digit numeric code', () {
      for (int i = 0; i < 20; i++) {
        final code = EtsawaqliService.generateClaimCode();
        expect(code.length, 4);
        final numVal = int.tryParse(code);
        expect(numVal, isNotNull);
        expect(numVal! >= 1000 && numVal <= 9999, isTrue);
      }
    });
  });

  group('EtsawaqliMarketSheet UI & Workflow Tests', () {
    testWidgets('renders landing view with intro hero card and two main buttons', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final etsawaqliService = EtsawaqliService(firestore: fakeFirestore);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EtsawaqliMarketSheet(
              service: etsawaqliService,
              currentUserId: 'user_test_123',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('خدمة إتسوقلي (تسوق أسواق القرية) 🧺'), findsOneWidget);
      expect(find.text('تسوق سوق الجمعة والأسواق المجاورة حتى باب منزلك'), findsOneWidget);
      expect(find.text('قائمة المشتريات 🧺'), findsOneWidget);
      expect(find.text('سجل العمليات 📜'), findsOneWidget);
    });

    testWidgets('navigates to shopping list view, adds custom item and displays it as standard item with controls', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final etsawaqliService = EtsawaqliService(firestore: fakeFirestore);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EtsawaqliMarketSheet(
              service: etsawaqliService,
              currentUserId: 'user_test_123',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // النقر على زر قائمة المشتريات 🧺
      await tester.ensureVisible(find.text('قائمة المشتريات 🧺'));
      await tester.tap(find.text('قائمة المشتريات 🧺'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('إضافة صنف خاص ليس بالقوائم (يُعامل كبنود التطبيق):'), findsOneWidget);

      // إدخال بيانات الصنف الخاص
      await tester.enterText(
        find.widgetWithText(TextField, 'اسم الصنف (مثال: نعناع، ملوخية، ليمون...)'),
        'جبنة قريش فلاحي',
      );

      // النقر على زر الإضافة للقائمة
      await tester.ensureVisible(find.text('إضافة للقائمة ➕'));
      await tester.tap(find.text('إضافة للقائمة ➕'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // التأكد من ظهور الصنف الخاص في القائمة ومعاملته مثل باقي بنود التطبيق
      expect(find.text('جبنة قريش فلاحي'), findsOneWidget);
      expect(find.text('صنف خاص • 1.0 كيلو (سعر السوق الفعلي)'), findsOneWidget);
    });

    testWidgets('navigates to order history view and renders summary card, detail sheet opens without claim code', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final etsawaqliService = EtsawaqliService(firestore: fakeFirestore);

      await fakeFirestore.collection('etsawaqli_orders').doc('ord_test_1').set({
        'invoiceNumber': 'TS-20261117-9999',
        'userId': 'user_test_123',
        'userName': 'أم محمد',
        'userPhone': '01055554444',
        'marketId': 'market_friday_abudshisha',
        'marketName': 'سوق الجمعة (أبودشيشة)',
        'marketDay': 'الجمعة',
        'items': [
          {
            'productId': 'veg_tomato',
            'productName': 'طماطم بلدي',
            'category': 'خضروات',
            'unit': 'كيلو',
            'quantity': 2,
            'unitPrice': 15.0,
            'isCustom': false,
          }
        ],
        'itemsSubtotal': 30.0,
        'serviceFee': 20.0,
        'deliveryFee': 10.0,
        'totalAmount': 60.0,
        'claimCode': '8392',
        'deliveryAddress': 'شارع داير الناحية',
        'status': 'shopping',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EtsawaqliMarketSheet(
              initialView: 2,
              service: etsawaqliService,
              currentUserId: 'user_test_123',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('سجل العمليات 📜'), findsOneWidget);
      expect(find.text('TS-20261117-9999'), findsOneWidget);
      expect(find.text('جاري التسوق بالسوق 🧺'), findsOneWidget);
      expect(find.text('60 ج'), findsOneWidget);

      // النقر على الكارت لفتح تفاصيل العملية
      await tester.tap(find.text('TS-20261117-9999'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('تفاصيل العملية (TS-20261117-9999)'), findsOneWidget);
      expect(find.text('الأصناف والسلع المطلوبة:'), findsOneWidget);
      // التأكد من عدم عرض كود التسليم في الفاتورة والتفاصيل
      expect(find.text('كود الاستلام السري'), findsNothing);
      expect(find.text('8392'), findsNothing);
    });
  });
}
