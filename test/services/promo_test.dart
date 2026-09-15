import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/promo_placements.dart';
import 'package:qurity/models/promo_model.dart';
import 'package:qurity/routes/app_routes.dart';
import 'package:qurity/services/promo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Promo _p({
  DateTime? start,
  DateTime? end,
  bool active = true,
  String image = 'https://x/i.png',
}) =>
    Promo(
      id: 'a1',
      title: 'ت',
      imageUrl: image,
      placement: 'home',
      startsAt: start ?? DateTime(2026),
      endsAt: end ?? DateTime(2026, 12, 31),
      isActive: active,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Promo.isVisibleAt', () {
    test('true inside window when active with image', () {
      final now = DateTime(2026, 6);
      expect(
          _p(start: now.subtract(const Duration(days: 1)),
                  end: now.add(const Duration(days: 1)))
              .isVisibleAt(now),
          true);
    });
    test('false before start / after end / paused / no image', () {
      final now = DateTime(2026, 6);
      expect(_p(start: now.add(const Duration(days: 1)), end: now.add(const Duration(days: 5)))
          .isVisibleAt(now), false);
      expect(_p(start: now.subtract(const Duration(days: 5)), end: now.subtract(const Duration(days: 1)))
          .isVisibleAt(now), false);
      expect(_p(active: false).isVisibleAt(now), false);
      expect(_p(image: '').isVisibleAt(now), false);
    });
    test('seenKey changes with version', () {
      expect(_p().seenKey, isNot(_p().copyWith(version: 2).seenKey));
    });
  });

  group('promoKeyForRoute', () {
    test('maps main screens', () {
      expect(promoKeyForRoute(AppRoutes.home, null), 'home');
      expect(promoKeyForRoute(AppRoutes.newsList, null), 'news');
      expect(promoKeyForRoute(AppRoutes.marketProducts, null), 'market');
    });
    test('maps category sub-screens via arguments', () {
      expect(promoKeyForRoute(AppRoutes.serviceCategory, 'technicians'), 'svc_technicians');
      expect(promoKeyForRoute(AppRoutes.serviceCategory, 'educational'), 'svc_educational');
      expect(promoKeyForRoute(AppRoutes.serviceCategory, null), 'services');
    });
    test('maps medical sections via int index', () {
      expect(promoKeyForRoute(AppRoutes.medicalSection, 1), 'med_blood');
      expect(promoKeyForRoute(AppRoutes.medicalSection, 4), 'med_labs');
    });
    test('unknown routes return empty', () {
      expect(promoKeyForRoute('/somewhere-new', null), '');
    });
  });

  group('buildExternalUrl', () {
    test('full urls pass through', () {
      expect(buildExternalUrl('whatsapp', 'https://wa.me/20100'), 'https://wa.me/20100');
    });
    test('whatsapp local number gains country code', () {
      expect(buildExternalUrl('whatsapp', '01001234567'), 'https://wa.me/201001234567');
      expect(buildExternalUrl('whatsapp', '+201001234567'), 'https://wa.me/201001234567');
    });
    test('social handles build platform urls', () {
      expect(buildExternalUrl('facebook', 'abudshisha'), 'https://www.facebook.com/abudshisha');
      expect(buildExternalUrl('instagram', '@qarity'), 'https://www.instagram.com/qarity');
      expect(buildExternalUrl('telegram', 'qarity'), 'https://t.me/qarity');
      expect(buildExternalUrl('tiktok', 'qarity'), 'https://www.tiktok.com/@qarity');
    });
    test('whatsapp without digits is null', () {
      expect(buildExternalUrl('whatsapp', 'لا رقم'), isNull);
    });
  });

  group('PromoService', () {
    test('create persists then watchAll returns it', () async {
      final fake = FakeFirebaseFirestore();
      final svc = PromoService(fake);
      final id = await svc.create(_p(image: 'u'));
      final all = await svc.watchAll().first;
      expect(all, hasLength(1));
      expect(all.single.id, id);
      expect(all.single.placement, 'home');
    });
    test('update bumps version', () async {
      final fake = FakeFirebaseFirestore();
      final svc = PromoService(fake);
      final id = await svc.create(_p());
      final created = (await svc.watchAll().first).single;
      await svc.update(created.copyWith(title: 'جديد'));
      final updated = fake.collection('promos').doc(id);
      final data = (await updated.get()).data()!;
      expect(data['version'], 2);
      expect(data['title'], 'جديد');
    });
    test('setActive toggles flag only', () async {
      final fake = FakeFirebaseFirestore();
      final svc = PromoService(fake);
      final id = await svc.create(_p());
      final created = (await svc.watchAll().first).single;
      await svc.setActive(created, false);
      final data = (await fake.collection('promos').doc(id).get()).data()!;
      expect(data['isActive'], false);
      expect(data['title'], 'ت');
    });
  });

  group('PromoInternalLink', () {
    test('encode/decode with args', () {
      const l = PromoInternalLink('ف', AppRoutes.serviceCategory, 'technicians');
      final (route, args) = PromoInternalLink.decode(l.encoded);
      expect(route, AppRoutes.serviceCategory);
      expect(args, 'technicians');
    });
    test('medical section decodes to int', () {
      final (route, args) = PromoInternalLink.decode('${AppRoutes.medicalSection}|2');
      expect(route, AppRoutes.medicalSection);
      expect(args, 2);
    });
  });
}
