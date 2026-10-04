import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/features/market/market_tabs_screen.dart';
import 'package:qurity/services/shop_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تبويب المحلات: كرتان في كل سطر على مقاس الهاتف (٣٩٠ − حشو ٣٢ − فاصل ١٤ ⇒ ~١٧٢).
const longShopName = 'بقالة ومخبز القرية الحديثة لأهالي أبوديشيشة الكرام';
const longShopDesc =
    'يوميًا خبز بلدي طازج وأرزاق التموين ومواد غذائية بأسعار الجملة، '
    'مع توصيل مجاني داخل القرية للطلبات فوق مائتي جنيه';

Map<String, dynamic> _shopDoc(String name) => <String, dynamic>{
      'ownerUid': 'u1',
      'ownerName': 'محمد عبدالباسط',
      'name': name,
      'category': 'مواد غذائية',
      'description': longShopDesc,
      'imageUrls': <String>[],
      'whatsapp': '01000000000',
      'ownerRole': 'seller',
      'ownerSellerType': 'gold',
      'isActive': true,
      'isApproved': true,
      'createdAt': Timestamp.fromDate(DateTime(2026, 9, 20)),
    };

Future<void> _pumpShops(WidgetTester tester, FirebaseFirestore fs) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar', 'EG'),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: ShopsTab(service: ShopService(fs))),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('تبويب المحلات: كرتان في السطر بلا فيضان', () {
    testWidgets('ثلاثة محلات بأسماء طويلة: عمودان وارتفاع مطلق',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      for (var i = 0; i < 3; i++) {
        await fs.collection('shops').add({..._shopDoc('$longShopName $i')});
      }
      await _pumpShops(tester, fs);

      expect(tester.takeException(), isNull);

      final grid = tester.widget<GridView>(find.byType(GridView).first);
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      expect(delegate.mainAxisExtent, 212);

      final cards = find.byType(Card);
      expect(cards, findsWidgets);
      final first = tester.getRect(cards.at(0));
      final second = tester.getRect(cards.at(1));
      expect(first.top, second.top, reason: 'كرتان في السطر نفسه');
      expect(first.left, isNot(second.left));
      expect(first.width, lessThan(200));
      expect(first.height, 212,
          reason: 'ثيم التطبيق يلغي هامش الكرت فتملأ خانة الشبكة كاملة');
      expect(find.textContaining('لا توجد محلات بعد'), findsNothing);
    });

    testWidgets('غير المعتمد لا يظهر للعامة (بلا جلسة ⇒ uid=null)',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('shops')
          .add({..._shopDoc(longShopName), 'isApproved': false});
      await _pumpShops(tester, fs);
      expect(tester.takeException(), isNull);
      expect(find.byType(Card), findsNothing);
      expect(find.textContaining('لا توجد محلات بعد'), findsOneWidget);
    });

    test('المصدر: التبويب عام وقابل للحقن', () {
      final shops =
          File('lib/features/market/market_tab_shops.dart').readAsStringSync();
      expect(shops, contains('class ShopsTab extends StatelessWidget'));
      expect(shops, contains('final ShopService? service;'));
      expect(shops, contains('this.service ?? ShopService()'));
      expect(shops, contains('mainAxisExtent: 212'));
      final screen =
          File('lib/features/market/market_tabs_screen.dart').readAsStringSync();
      expect(screen, contains('ShopsTab(),'),
          reason: 'موضع الاستعمال نُقل إلى الصنف العام');
      expect(screen, isNot(contains('_ShopsTab')));
    });
  });
}
