import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/lost_item_model.dart';
import 'package:qurity/services/lost_item_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LostItemService', () {
    test('create persists with isApproved=false and owner fields', () async {
      final fake = FakeFirebaseFirestore();
      final svc = LostItemService(fake);
      await svc.create(const LostItem(
        title: 'مفتاح منزل',
        location: 'شارع السوق',
        phone: '0100',
        userId: 'u1',
        userName: 'أحمد',
      ));
      final doc = (await fake.collection('lost_items').get()).docs.single;
      expect(doc.data()['isApproved'], false);
      expect(doc.data()['title'], 'مفتاح منزل');
      expect(doc.data()['userId'], 'u1');
      expect(doc.data()['type'], 'lost');
    });

    test('watchApproved returns only approved items', () async {
      final fake = FakeFirebaseFirestore();
      final svc = LostItemService(fake);
      await fake.collection('lost_items').add({
        'title': 'معتمد', 'isApproved': true, 'type': 'lost',
      });
      await fake.collection('lost_items').add({
        'title': 'معلق', 'isApproved': false, 'type': 'found',
      });
      final items = await svc.watchApproved().first;
      expect(items.length, 1);
      expect(items.single.title, 'معتمد');
    });

    test('setResolved toggles the flag', () async {
      final fake = FakeFirebaseFirestore();
      final svc = LostItemService(fake);
      final ref = await fake.collection('lost_items').add({
        'title': 'هاتف', 'isApproved': true, 'isResolved': false,
      });
      await svc.setResolved(ref.id, true);
      final data = (await ref.get()).data()!;
      expect(data['isResolved'], true);
    });

    test('fromJson defaults and type label', () {
      final item = LostItem.fromJson({'title': 'x'}, 'id1');
      expect(item.isLostType, true);
      expect(item.typeLabel, 'مفقود');
      expect(item.isResolved, false);
      final found = LostItem.fromJson({'title': 'y', 'type': 'found'}, 'id2');
      expect(found.isLostType, false);
      expect(found.typeLabel, 'موجود');
    });
  });
}
