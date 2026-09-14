import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/models/market_extra_models.dart';
import 'package:qurity/services/phone_directory_service.dart';
import 'package:qurity/services/shop_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PhoneDirectoryService', () {
    test('addPhoneDirectoryEntry writes an entry', () async {
      final fake = FakeFirebaseFirestore();
      final svc = PhoneDirectoryService(fake);
      await svc.addPhoneDirectoryEntry(const PhoneDirectoryEntry(
        id: '',
        name: 'محمد',
        title: 'فلاح',
        phone: '0100',
      ));
      final snap = await fake.collection('phone_directory').get();
      expect(snap.docs.single.data()['name'], 'محمد');
    });

    test('getEntriesList returns all entries', () async {
      final fake = FakeFirebaseFirestore();
      final svc = PhoneDirectoryService(fake);
      await svc.addPhoneDirectoryEntry(const PhoneDirectoryEntry(id: '', name: 'أ', title: '', phone: '1'));
      await svc.addPhoneDirectoryEntry(const PhoneDirectoryEntry(id: '', name: 'ب', title: '', phone: '2'));
      final all = await svc.getEntriesList();
      expect(all.length, 2);
    });

    test('getApprovedEntriesStream filters only approved', () async {
      final fake = FakeFirebaseFirestore();
      final svc = PhoneDirectoryService(fake);
      final id1 = await fake.collection('phone_directory').add({'name': 'موافق', 'phone': '1', 'isApproved': true}).then((r) => r.id);
      expect(id1, isNotEmpty);
      await fake.collection('phone_directory').add({'name': 'معلق', 'phone': '2', 'isApproved': false});
      final list = await svc.getApprovedEntriesStream().first;
      expect(list.length, 1);
      expect(list.first.name, 'موافق');
    });

    test('getVisibleEntriesList shows approved + own pending only', () async {
      final fake = FakeFirebaseFirestore();
      final svc = PhoneDirectoryService(fake);
      await fake.collection('phone_directory').add({'name': 'معتمد', 'phone': '1', 'isApproved': true});
      await fake.collection('phone_directory').add({'name': 'معلق لي', 'phone': '2', 'isApproved': false, 'submittedBy': 'u1'});
      await fake.collection('phone_directory').add({'name': 'معلق لغيري', 'phone': '3', 'isApproved': false, 'submittedBy': 'u2'});
      final mine = await svc.getVisibleEntriesList('u1');
      expect(mine.map((e) => e.name).toSet(), {'معتمد', 'معلق لي'});
      final anon = await svc.getVisibleEntriesList(null);
      expect(anon.length, 1);
    });
  });

  group('ShopService', () {
    test('createShop persists with ownerUid and defaults', () async {
      final fake = FakeFirebaseFirestore();
      final svc = ShopService(fake);
      await svc.createShop(const Shop(
        id: '',
        ownerUid: 'u1',
        ownerName: 'علي',
        name: 'متجر علي',
        category: 'بقالة',
      ));
      final snap = await fake.collection('shops').get();
      expect(snap.docs.single.data()['ownerUid'], 'u1');
      expect(snap.docs.single.data()['isActive'], true);
      expect(snap.docs.single.data()['isApproved'], false);
    });

    test('getShopsStream filters approved + active only', () async {
      final fake = FakeFirebaseFirestore();
      final svc = ShopService(fake);
      await fake.collection('shops').add({
        'ownerUid': 'u1', 'name': 'نشط معتمد', 'isActive': true, 'isApproved': true,
      });
      await fake.collection('shops').add({
        'ownerUid': 'u2', 'name': 'معلق', 'isActive': true, 'isApproved': false,
      });
      await fake.collection('shops').add({
        'ownerUid': 'u3', 'name': 'معطل', 'isActive': false, 'isApproved': true,
      });
      final list = await svc.getShopsStream().first;
      expect(list.length, 1);
      expect(list.single.name, 'نشط معتمد');
    });

    test('hasShop returns true after creating one', () async {
      final fake = FakeFirebaseFirestore();
      final svc = ShopService(fake);
      expect(await svc.hasShop('u1'), isFalse);
      await svc.createShop(const Shop(id: '', ownerUid: 'u1', ownerName: 'x', name: 'y'));
      expect(await svc.hasShop('u1'), isTrue);
    });

    test('getVisibleShopsStream shows approved for all + owner pending', () async {
      final fake = FakeFirebaseFirestore();
      final svc = ShopService(fake);
      await fake.collection('shops').add({
        'ownerUid': 'u2', 'name': 'معتمد', 'isApproved': true, 'isActive': true,
      });
      await fake.collection('shops').add({
        'ownerUid': 'u1', 'name': 'معلق لي', 'isApproved': false, 'isActive': true,
      });
      await fake.collection('shops').add({
        'ownerUid': 'u3', 'name': 'معلق لغيري', 'isApproved': false, 'isActive': true,
      });
      final forOwner = await svc.getVisibleShopsStream('u1').first;
      expect(forOwner.map((s) => s.name).toSet(), {'معتمد', 'معلق لي'});
      expect(forOwner.first.name, 'معتمد');
      final anon = await svc.getVisibleShopsStream(null).first;
      expect(anon.length, 1);
    });
  });
}
