import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/product_categories.dart';
import 'package:qurity/features/medical/medical_home_screen.dart';
import 'package:qurity/services/market_service.dart';
import 'package:qurity/services/medical_service.dart';
import 'package:qurity/widgets/ad_photo_frame.dart';
import 'package:qurity/widgets/med_grid_tile.dart';

/// البطاقة تُضخّ دائمًا بعرض عمود الشبكة على هاتف (٣٩٠ − حشو ٣٢ − فاصل ١٤ ⇒ ÷٢).
const double _kCardWidth = 172;

Widget _tile(Widget child) => MaterialApp(
      locale: const Locale('ar', 'EG'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
              child: SizedBox(width: _kCardWidth, height: 252, child: child)),
        ),
      ),
    );

const _longTitle = 'عيادة الأسنان التخصصية لأطفال القرية وأهالي أبوديشيشة';
const _longTag = 'تحليل هرمونات وغدة درقية وسكر صائم';
const _longSubtitle =
    'من ٩ ص إلى ٢ م — شارع المدرسة الابتدائية بجوار المسجد الكبير بالقرية';

Future<void> _pumpCard(WidgetTester tester, Widget tile) async {
  await tester.pumpWidget(_tile(tile));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  group('بطاقة الشبكة الطبية: كرتان في السطر بمساحة صورة معلومة', () {
    test('المُرتِّب: عمودان بارتفاع مطلق لا نسبة', () {
      expect(kMedGridDelegate.crossAxisCount, 2);
      expect(kMedGridDelegate.mainAxisExtent, 252);
      expect(kMedGridDelegate.mainAxisSpacing, 14);
      expect(kMedGridDelegate.crossAxisSpacing, 14);
    });

    testWidgets('عنوان ووسمان ووصف طويلان: لا فيضان ولا استثناء',
        (tester) async {
      await _pumpCard(
          tester,
          MedGridTile(
            title: _longTitle,
            imageUrl: '',
            icon: Icons.add_business_rounded,
            accent: const Color(0xFF00897B),
            onTap: () {},
            tags: const [
              Text(_longTag),
              Text('د. محمد عبدالباسط الشهاوي'),
            ],
            subtitle: _longSubtitle,
          ));
      expect(tester.takeException(), isNull);
      expect(find.byType(Wrap), findsOneWidget);
      // العنوان سطر واحد مقصوص، والوصف سطران مقصوصان — لا كتلة تفيض.
      expect(
          tester.widget<Text>(find.text(_longTitle)).maxLines, 1);
      expect(
          tester.widget<Text>(find.text(_longSubtitle)).maxLines, 2);
    });

    testWidgets('بلا صورة: أيقونة بلون القسم داخل مساحة الصورة ولا طلب شبكة',
        (tester) async {
      await _pumpCard(
          tester,
          MedGridTile(
            title: 'عيادة القرية',
            imageUrl: '',
            icon: Icons.local_pharmacy_rounded,
            accent: const Color(0xFF6F4E37),
            onTap: () {},
          ));
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.local_pharmacy_rounded), findsOneWidget);
      expect(tester.getSize(find.byType(Stack).first),
          const Size(_kCardWidth, MedGridTile.imageHeight));
    });

    testWidgets('بصورة: تملأ المساحة بـcover وتُفكّ بعرض البطاقة لا أكثر',
        (tester) async {
      await _pumpCard(
          tester,
          MedGridTile(
            title: 'محل النظارات',
            imageUrl: 'https://cdn.test/eye.jpg',
            icon: Icons.remove_red_eye_rounded,
            accent: const Color(0xFF3949AB),
            onTap: () {},
          ));
      final image =
          tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.fit, BoxFit.cover);
      expect(image.memCacheWidth, 520);
      expect(tester.getSize(find.byType(CachedNetworkImage)).height,
          MedGridTile.imageHeight);
      expect(tester.getSize(find.byType(CachedNetworkImage)).width, _kCardWidth);
    });

    testWidgets('الشارة ترسم بجوار العنوان والنقر ينادى مرة واحدة',
        (tester) async {
      var taps = 0;
      await _pumpCard(
          tester,
          MedGridTile(
            title: 'معمل التحاليل',
            imageUrl: '',
            icon: Icons.science_rounded,
            accent: const Color(0xFF6A1B9A),
            onTap: () => taps++,
            badge: const Text('سحب منزلي'),
          ));
      expect(find.text('سحب منزلي'), findsOneWidget);
      await tester.tap(find.text('معمل التحاليل'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('المحل المميّز يُحدّد بذهبي لا بلون القسم', (tester) async {
      await _pumpCard(
          tester,
          MedGridTile(
            title: 'نظارات أبوديشيشة',
            imageUrl: '',
            icon: Icons.remove_red_eye_rounded,
            accent: const Color(0xFF3949AB),
            onTap: () {},
            goldBorder: true,
          ));
      final card = tester.widget<Card>(find.byType(Card));
      final side = (card.shape as RoundedRectangleBorder).side;
      expect(side.color, const Color(0xFFB8860B));
      expect(side.width, 1.6);
    });
  });

  group('إطار صورة الإعلان: مساحة ثابتة تملؤها الصورة', () {
    testWidgets('بلا صورة: المساحة معلومة الارتفاع وبلا أي طلب شبكة',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
                width: 358,
                child: AdPhotoFrame(
                    imageUrl: '',
                    height: 230,
                    accent: Color(0xFF311B92))),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.campaign_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AdPhotoFrame)).height, 230);
    });

    testWidgets('بصورة: cover على العرض الكامل بمقاس فكّ محسوب', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
                width: 358,
                child: AdPhotoFrame(
                    imageUrl: 'https://cdn.test/ad.jpg',
                    height: 260,
                    accent: Color(0xFF311B92))),
          ),
        ),
      ));
      await tester.pump();
      final image =
          tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.fit, BoxFit.cover);
      expect(image.memCacheWidth, (358 * 3).round());
      expect(tester.getSize(find.byType(AdPhotoFrame)).height, 260);
    });
  });

  group('الأقسام الحقيقية: عيادات/صيدليات/معامل/نظارات بعمودين', () {
    String src(String p) => File(p).readAsStringSync();

    /// عنوان ووصف أطول مما تحتمله بلاطة بعرض ١٧٢dp — إن فاضت البطاقة أو
    /// انقطعت الشبكة سقط الاختبار هنا لا في اللقطة فقط.
    const longName = 'عيادة الأسنان التخصصية لأطفال القرية وأهالي أبوديشيشة';

    Map<String, dynamic> base() => {
          'name': longName,
          'specialty': 'تحليل هرمونات وغدة درقية وسكر صائم',
          'category': 'تحاليل طبية دقيقة ومتخصصة جدًا',
          'ownerName': 'د. محمد عبدالباسط الشهاوي',
          'phone': '01000000000',
          'address': 'شارع المدرسة الابتدائية بجوار المسجد الكبير بالقرية',
          'workingHours': 'من ٩ ص إلى ٢ م طوال أيام الأسبوع عدا الجمعة',
          'description': 'نبذة طويلة جدًا عن السجل حتى تُختبر حدود البطاقة.',
          'imageUrls': <String>[],
          'isApproved': true,
          'is24Hours': true,
          'homeCollection': true,
          'adType': 'normal',
          'submittedBy': 'u1',
          'submittedByName': 'مضيف',
        };

    Future<void> pumpSection(WidgetTester tester, int index,
        FirebaseFirestore fs) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar', 'EG'),
        home: switch (index) {
          2 => MedicalSectionScreen(
              index: 2, clinicService: VillageClinicService(fs)),
          3 => MedicalSectionScreen(
              index: 3, pharmacyService: PharmacyService(fs)),
          4 => MedicalSectionScreen(
              index: 4, labService: MedicalLabService(fs)),
          5 => MedicalSectionScreen(
              index: 5, opticalService: OpticalShopService(fs)),
          6 => MedicalSectionScreen(
              index: 6, marketService: MarketService(firestore: fs)),
          _ => throw StateError('فهرس قسم غير مُهيّأ في pumpSection: $index'),
        },
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
    }

    Future<void> seed(FirebaseFirestore fs, String col,
        {int count = 3}) async {
      for (var i = 0; i < count; i++) {
        await fs.collection(col).add({...base(), 'name': '$longName $i'});
      }
    }

    Future<void> expectTwoUp(WidgetTester tester) async {
      expect(tester.takeException(), isNull);
      final byType = find.byType(MedGridTile);
      expect(byType, findsWidgets);
      final first = tester.getRect(byType.at(0));
      final second = tester.getRect(byType.at(1));
      // السطح ٣٩٠ − حشو ٣٢ − فاصل ١٤ ⇒ عمودان بعرض ~١٧٢ وارتفاع مطلق ٢٥٢.
      expect(first.height, 252);
      expect(second.height, 252);
      expect(first.width, lessThan(200));
      expect(first.top, second.top, reason: 'كرتان في السطر نفسه');
      expect(first.left, isNot(second.left));
    }

    testWidgets('عيادات القرية', (tester) async {
      final fs = FakeFirebaseFirestore();
      await seed(fs, 'village_clinics');
      await pumpSection(tester, 2, fs);
      await expectTwoUp(tester);
    });

    testWidgets('الوسوم لا تلتفّ: تخصص طويل يبقى سطرًا واحدًا مقصوصًا',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      await seed(fs, 'village_clinics');
      await pumpSection(tester, 2, fs);
      // الأوسمة داخل `Wrap` بعرض البطاقة (~١٥٢dp)، فأي وسم يلتفّ سطرين يضيف
      // سطرًا كاملًا إلى جسم مقصوص الارتفاع أصلًا — وهو فيضان قِيس على بناء
      // حقيقي بخط Tajawal في المتصفح ولم تره اختبارات الواجهة (خط الاختبار
      // أضيق). الدليل هنا سلوكي: الوسم نفسه مقصوص عند سطر واحد.
      final chips =
          find.text('تحليل هرمونات وغدة درقية وسكر صائم');
      expect(chips, findsWidgets);
      for (final el in chips.evaluate()) {
        final chip = el.widget as Text;
        expect(chip.maxLines, 1);
        expect(chip.overflow, TextOverflow.ellipsis);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('صيدليات القرية — وشارة «٢٤ ساعة» تبقى فوق العنوان',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      await seed(fs, 'pharmacies');
      await pumpSection(tester, 3, fs);
      await expectTwoUp(tester);
      expect(find.textContaining('٢٤'), findsWidgets);
    });

    testWidgets('معامل التحاليل — وشارة «سحب منزلي»', (tester) async {
      final fs = FakeFirebaseFirestore();
      await seed(fs, 'medical_labs');
      await pumpSection(tester, 4, fs);
      await expectTwoUp(tester);
      expect(find.textContaining('سحب منزلي'), findsWidgets);
    });

    testWidgets('نظارات طبية — كرتان في السطر', (tester) async {
      final fs = FakeFirebaseFirestore();
      await seed(fs, 'optical_shops');
      await pumpSection(tester, 5, fs);
      await expectTwoUp(tester);
    });

    /// القسم السابع لا يملك مجموعة خاصة: بضاعته منتجات `market_products`
    /// بتصنيف واحد، فتُseed بصورها الحقيقية لا بشكل السجلات الطبية.
    testWidgets('مستلزمات طبية — كرتان في السطر من منتجات السوق',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      for (var i = 0; i < 3; i++) {
        await fs.collection('market_products').add({
          'name': '$longName $i',
          'description': 'مستلزم تعقيم يُصرف داخل القرية',
          'price': 45.0,
          'category': kMedicalSuppliesCategory,
          'isApproved': true,
          'imageUrls': <String>[],
          'sellerName': 'د. محمد عبدالباسط الشهاوي',
          'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1 + i)),
        });
      }
      await pumpSection(tester, 6, fs);
      await expectTwoUp(tester);
    });

    test('الملفات المطلوبة كلها لا تذكر شبكة الثلاثة أعمدة', () {
      for (final f in [
        'lib/features/medical/medical_home_screen.dart',
        'lib/features/market/market_tab_shops.dart',
      ]) {
        expect(File(f).readAsStringSync(), isNot(contains('crossAxisCount: 3')),
            reason: f);
      }
      // القسم السابع بلا مسار خاص: بوابة الخدمات الطبية تدخل أقسامها بفهرس
      // داخل `/medical/section`، فمسارات التطبيق لا تُسمّي الأقسام الطبية أصلًا.
      final routes = src('lib/routes/app_routes.dart');
      expect(routes, isNot(contains('/medical/supplies')));
      expect(routes, isNot(contains('نظارات طبية')));
    });
  });

  group('عقد المصدر: كرتان في السطر في كل ما طُلب', () {
    String src(String p) => File(p).readAsStringSync();

    test('العيادات والصيدليات والمعامل والنظارات والمستلزمات: خمس شبكات بعمودين',
        () {
      final s = src('lib/features/medical/medical_home_screen.dart');
      expect(RegExp('gridDelegate: kMedGridDelegate').allMatches(s).length, 5,
          reason: 'عيادات + صيدليات + معامل + نظارات + مستلزمات طبية');
      expect(RegExp('return MedGridTile\\(').allMatches(s).length, 5);
      expect(s, isNot(contains('crossAxisCount: 3')),
          reason: 'لاعودة لشبكة العمود الثلاثة');
      // بطاقة المركز الخيري ومنسّقها بقيا كما هما (لم يُطلب تغييرهما).
      expect(s, contains('ClinicPhotoTile('));
      expect(s, contains('_Pill('));
      // أزرار المالك وبوابة مدير المركز لم تمسّها الشبكة.
      expect(s, contains('OwnerActions('));
      expect(s, contains('if (widget.index != 0 || !_isMedicalAdmin) return null;'));
    });

    test('البوابة الطبية: بلاطتان في السطر وصور مفكوكة بمقاسها', () {
      final s = src('lib/features/medical/medical_home_screen.dart');
      expect(s, contains('crossAxisCount: 2'));
      expect(s, contains('cacheWidth: 520'));
      expect(
          RegExp(r"\('([^']+)', 'assets/images/[^']+'\)", multiLine: true)
              .allMatches(s)
              .length,
          7);
    });

    test('تبويب المحلات في سوق القرية: كرتان في السطر', () {
      final s = src('lib/features/market/market_tab_shops.dart');
      expect(s, contains('crossAxisCount: 2'));
      expect(s, contains('mainAxisExtent: 212'));
      expect(s, contains('return _ShopGridCard('));
    });

    test('إعلانات القرية: الإطار الثابت في القائمة والتفاصيل', () {
      final list = src('lib/features/ads/village_ads_screen.dart');
      final detail = src('lib/features/ads/village_ad_detail_screen.dart');
      final model = src('lib/models/village_ad_model.dart');
      expect(list, contains('AdPhotoFrame('));
      expect(list, contains('height: kVillageAdCardImageHeight'));
      expect(detail, contains('AdPhotoFrame('));
      expect(detail, contains('height: kVillageAdDetailImageHeight'));
      expect(model, contains('const double kVillageAdCardImageHeight = 230;'));
      expect(model, contains('const double kVillageAdDetailImageHeight = 260;'));
      // القائمة بقيت ListView عمودية لأن اختبار السحب يعتمد عليها.
      expect(list, contains('ListView'));
    });

    test('هيدر الشاشة الرئيسية مُكبّر مع الجرس', () {
      final home = src('lib/features/home/home.dart');
      final bell = src('lib/widgets/common_appbar_actions.dart');
      expect(home, contains('compact: true, compactSize: 59'));
      expect(home, contains('bottomRight: Radius.circular(45)'));
      expect(home, contains('EdgeInsets.fromLTRB(22, 11, 22, 20)'));
      expect(bell, contains('this.compactSize'));
      // مقياس التوسيع: نصف قطر الزاوية القديم 31 ⇒ 45، فصار الهيدر أكبر
      // من مقداره بلا أن يمسّ أي محتوى فيه.
      expect(home, contains('bottomLeft: Radius.circular(45)'));
    });
  });
}
