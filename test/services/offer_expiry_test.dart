import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/firebase_ts.dart';
import 'package:qurity/features/admin/admin_edit.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/market_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «عروض لا تنتهي أبدًا»: العلم وحده كان يكفي لخصم سرمدي. النافذة صارت تُكتب
/// وقت التفعيل، وكل بوابة في النموذج والخدمة والتعديل تمرّ من `hasActiveOfferAt`.
MarketProduct _p({
  double price = 100,
  double? offerPrice = 80,
  bool isOnOffer = true,
  DateTime? offerStartsAt,
  DateTime? offerEndsAt,
}) =>
    MarketProduct(
      id: 'p1',
      name: 'لبن',
      description: 'وصف',
      price: price,
      imageUrl: '',
      category: 'ألبان',
      sellerName: 'بائع',
      sellerPhone: '0100',
      isOnOffer: isOnOffer,
      offerPrice: offerPrice,
      offerStartsAt: offerStartsAt,
      offerEndsAt: offerEndsAt,
    );

Map<String, dynamic> _doc({
  String name = 'لبن',
  double price = 100,
  double? offerPrice,
  bool isOnOffer = false,
  DateTime? offerEndsAt,
  bool isApproved = true,
}) =>
    {
      'name': name,
      'description': 'وصف',
      'price': price,
      'imageUrl': '',
      'category': 'ألبان',
      'sellerName': 'بائع',
      'sellerPhone': '0100',
      'sellerId': 's1',
      'isApproved': isApproved,
      'isOnOffer': isOnOffer,
      'offerPrice': offerPrice,
      'offerEndsAt': offerEndsAt == null ? null : Timestamp.fromDate(offerEndsAt),
      'stock': 5,
      'createdAt': Timestamp.fromDate(DateTime(2026, 9)),
    };

void main() {
  final now = DateTime(2026, 10, 3, 12);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('عقد النموذج الزمني', () {
    test('hasActiveOffer هو hasActiveOfferAt(now) في كل حالة', () {
      final cases = [
        _p(),
        _p(offerEndsAt: now.add(const Duration(days: 1))),
        _p(offerEndsAt: now.subtract(const Duration(days: 1))),
        _p(offerPrice: 120),
        _p(offerPrice: 100),
        _p(offerPrice: null),
        _p(offerPrice: 0),
        _p(price: 0),
        _p(isOnOffer: false),
      ];
      for (final p in cases) {
        expect(p.hasActiveOffer, p.hasActiveOfferAt(now), reason: p.toString());
      }
    });

    test('نافذة سارية تحسم الخصم، ومنتهية تُرجع السعر لأصله', () {
      final live = _p(offerEndsAt: now.add(const Duration(hours: 6)));
      expect(live.hasActiveOfferAt(now), isTrue);
      expect(live.effectivePriceAt(now), 80);
      expect(live.discountPercentAt(now), 20);
      expect(live.sortWeightAt(now), 1);
      expect(live.isExpiredOfferAt(now), isFalse);

      final dead = _p(offerEndsAt: now.subtract(const Duration(minutes: 1)));
      expect(dead.hasActiveOfferAt(now), isFalse);
      expect(dead.effectivePriceAt(now), 100);
      expect(dead.discountPercentAt(now), 0);
      expect(dead.sortWeightAt(now), 0);
      expect(dead.isExpiredOfferAt(now), isTrue);
      // بالضبط على الحد: لم يمضِ شيء ⇒ العرض ما زال ساريًا
      expect(_p(offerEndsAt: now).hasActiveOfferAt(now), isTrue);
      expect(_p(offerEndsAt: now).isExpiredOfferAt(now), isFalse);
    });

    test('المستند القديم بلا نافذة يبقى ساريًا كما كان', () {
      final legacy = _p();
      expect(legacy.hasActiveOfferAt(now), isTrue);
      expect(legacy.isExpiredOfferAt(now), isFalse);
    });

    test('علم عرض بلا سعر عرض لا يُنتج «0 ج.م» ولا خصم ١٠٠٪', () {
      final json = _doc(isOnOffer: true); // offerPrice غائب تمامًا
      final p = MarketProduct.fromJson(json, 'doc');
      expect(p.offerPrice, isNull);
      expect(p.hasActiveOfferAt(now), isFalse);
      expect(p.effectivePriceAt(now), 100);
      expect(p.discountPercentAt(now), 0);
      // صفرًا مكتوبًا يدوريًا مرفوض likewise
      expect(_p(offerPrice: 0).hasActiveOfferAt(now), isFalse);
    });

    test('المدة الافتراضية ٣٠ يومًا وقابلة للتجاوز، وتدور مع toJson/fromJson',
        () {
      final window = MarketProduct.offerWindow(now);
      expect(window['offerStartsAt'], isA<Timestamp>());
      expect((window['offerEndsAt'] as Timestamp).toDate(),
          now.add(const Duration(days: 30)));
      expect(kDefaultOfferDuration, const Duration(days: 30));
      final custom = MarketProduct.offerWindow(now,
          window: const Duration(days: 7));
      expect((custom['offerEndsAt'] as Timestamp).toDate(),
          now.add(const Duration(days: 7)));

      final round = MarketProduct.fromJson(
          _p(offerStartsAt: now, offerEndsAt: now.add(const Duration(days: 3)))
              .toJson(),
          'doc');
      expect(round.offerStartsAt, now);
      expect(round.offerEndsAt, now.add(const Duration(days: 3)));
      // غياب النافذة لا يكتب حقلًا ولا يُفسد القراءة
      expect(_p().toJson().containsKey('offerEndsAt'), isFalse);
    });
  });

  group('الخدمة: القائمة والفرز على الساري لا على المرفوع', () {
    test('toggleOffer يكتب النافذة عند التفعيل ولا يُمطّط ما هو سارٍ', () async {
      final fake = FakeFirebaseFirestore();
      final svc = MarketService(firestore: fake);
      final doc = await fake.collection('market_products').add(_doc(name: 'جبنة'));
      final id = doc.id;

      await svc.toggleOffer(id, true, 70);
      var data = (await doc.get()).data()!;
      expect(data['isOnOffer'], isTrue);
      expect(data['offerPrice'], 70);
      expect(tsToDateTime(data['offerEndsAt'])!.isAfter(DateTime.now()), isTrue);

      // التفعيل بلا مدة مخصّصة يعطي ٣٠ يومًا
      await svc.toggleOffer(id, true, 60, window: const Duration(days: 3));
      data = (await doc.get()).data()!;
      final ends = tsToDateTime(data['offerEndsAt'])!;
      expect(ends.difference(DateTime.now()).inDays, lessThanOrEqualTo(3));

      await svc.toggleOffer(id, false, null);
      data = (await doc.get()).data()!;
      expect(data['isOnOffer'], isFalse);
    });

    test('getProductsOnOffer يُخفي المنتهي ويُبقي الحي والقديم', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('market_products').add(_doc(
          name: 'حي', isOnOffer: true, offerPrice: 80,
          offerEndsAt: DateTime.now().add(const Duration(days: 2))));
      await fake.collection('market_products').add(_doc(
          name: 'منتهٍ', isOnOffer: true, offerPrice: 80,
          offerEndsAt: DateTime.now().subtract(const Duration(days: 1))));
      await fake.collection('market_products')
          .add(_doc(name: 'قديم', isOnOffer: true, offerPrice: 80));
      await fake.collection('market_products')
          .add(_doc(name: 'بلا علم', offerPrice: 80));

      final on = await MarketService(firestore: fake).getProductsOnOffer();
      expect(on.map((p) => p.name).toSet(), {'حي', 'قديم'});
    });

    test('فلتر «العروض» في getProductsList يعني الساري الآن', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('market_products').add(_doc(
          name: 'حي', isOnOffer: true, offerPrice: 80,
          offerEndsAt: DateTime.now().add(const Duration(days: 2))));
      await fake.collection('market_products').add(_doc(
          name: 'منتهٍ', isOnOffer: true, offerPrice: 80,
          offerEndsAt: DateTime.now().subtract(const Duration(days: 1))));

      final svc = MarketService(firestore: fake);
      final offers =
          await svc.getProductsList(forceRefresh: true, isOnOffer: true);
      expect(offers.map((p) => p.name).toList(), ['حي']);
      final rest = await svc.getProductsList(
          forceRefresh: true, isOnOffer: false, category: 'الكل');
      expect(rest.map((p) => p.name).toSet(), {'منتهٍ'});
    });

    test('«أقل سعر» يقارن السعر الفعلي فالمنتهي لا يسبق الحي', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('market_products').add(_doc(
          name: 'عرض_سارٍ', isOnOffer: true, offerPrice: 90,
          offerEndsAt: DateTime.now().add(const Duration(days: 1))));
      await fake.collection('market_products').add(_doc(
          name: 'عرض_منتهٍ', price: 95, isOnOffer: true, offerPrice: 10,
          offerEndsAt: DateTime.now().subtract(const Duration(days: 1))));

      final sorted = await MarketService(firestore: fake)
          .getProductsList(forceRefresh: true, sortBy: 'أقل سعر');
      expect(sorted.map((p) => p.name).toList(), ['عرض_سارٍ', 'عرض_منتهٍ']);

      final offers = await MarketService(firestore: fake)
          .getProductsList(forceRefresh: true, sortBy: 'العروض أولاً');
      expect(offers.first.name, 'عرض_سارٍ');
    });
  });

  group('ختم النافذة في تعديل الأدمن', () {
    test('تفعيل جديد يحصل على نافذة، ونافذة سارية لا تُمسّ', () {
      final moment = DateTime(2026, 10, 3, 12);
      final fresh = <String, dynamic>{'isOnOffer': true};
      stampOfferWindow({}, fresh, now: moment);
      expect(tsToDateTime(fresh['offerEndsAt']), moment.add(const Duration(days: 30)));
      expect(tsToDateTime(fresh['offerStartsAt']), moment);

      final live = <String, dynamic>{'isOnOffer': true};
      stampOfferWindow(
          {'offerEndsAt': Timestamp.fromDate(moment.add(const Duration(days: 5)))},
          live,
          now: moment);
      expect(live.containsKey('offerEndsAt'), isFalse,
          reason: 'الحفظ العرضي لا يُجدّد المدة');

      final reActivated = <String, dynamic>{'isOnOffer': true};
      stampOfferWindow(
          {'offerEndsAt': Timestamp.fromDate(moment.subtract(const Duration(days: 1)))},
          reActivated,
          now: moment);
      expect(tsToDateTime(reActivated['offerEndsAt']),
          moment.add(const Duration(days: 30)));
    });

    test('إيقاف العرض يمسح نافذته ولا يكتب شيئًا إن لم تكن له واحدة', () {
      final off = <String, dynamic>{'isOnOffer': false};
      stampOfferWindow(
          {'offerEndsAt': Timestamp.fromDate(DateTime(2026, 11))}, off);
      expect(off['offerEndsAt'], isNull);
      expect(off['offerStartsAt'], isNull);

      final untouched = <String, dynamic>{'isOnOffer': false};
      stampOfferWindow({}, untouched);
      expect(untouched.keys, ['isOnOffer']);

      // بلا علم عرض في الكتابة لاختم ولا مسح
      final noFlag = <String, dynamic>{'name': 'لبن'};
      stampOfferWindow({}, noFlag);
      expect(noFlag.length, 1);
    });
  });

  group('عقد المصدر', () {
    final marketTab =
        File('lib/features/market/market_tab_market.dart').readAsStringSync();
    final home = File('lib/features/home/home.dart').readAsStringSync();

    test('السوق والرئيسية: تدفّق ثابت + نبض يُخفي المنتهي بلا إعادة قراءة', () {
      expect(marketTab.contains('late final Stream<List<MarketProduct>> _stream'),
          isTrue);
      expect(home.contains('late final Stream<List<MarketProduct>> _productsStream'),
          isTrue);
      for (final text in [marketTab, home]) {
        expect(text.contains('Timer.periodic(const Duration(minutes: 1)'), isTrue);
        expect(text.contains('_offerTicker?.cancel()'), isTrue);
      }
    });

    test('الشارة والسعر بوابةَهما hasActiveOffer لا العلم الخام', () {
      const spots = [
        'lib/features/market/market_tab_market.dart',
        'lib/features/home/home.dart',
        'lib/features/market/product_detail.dart',
        'lib/features/market/seller_profile.dart',
        'lib/features/medical/optical_shop_detail_screen.dart',
      ];
      for (final path in spots) {
        expect(File(path).readAsStringSync().contains('hasActiveOffer'), isTrue,
            reason: path);
      }
      // تفاصيل المنتج تقول صراحةً لماذا رجع السعر لأصله
      expect(File('lib/features/market/product_detail.dart')
          .readAsStringSync()
          .contains('isExpiredOffer'), isTrue);
    });
  });
}
