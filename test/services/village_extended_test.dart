import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/village_content_models.dart';
import 'package:qurity/services/village_extended_service.dart';

void main() {
  group('VillageExtendedService contributions', () {
    test('public pinned stream returns approved and pinned only', () async {
      final fake = FakeFirebaseFirestore();
      final service = VillageExtendedService(fake);
      final col = fake.collection('village_contributions');
      await col.add(const VillageContribution(
        userId: 'u1',
        userName: 'أحمد',
        type: 'photo',
        title: 'معتمدة ومثبتة',
        approvalStatus: 'approved',
        pinOnHome: true,
      ).toJson());
      await col.add(const VillageContribution(
        userId: 'u2',
        userName: 'محمود',
        type: 'info',
        title: 'معتمدة غير مثبتة',
        approvalStatus: 'approved',
      ).toJson());
      await col.add(const VillageContribution(
        userId: 'u3',
        userName: 'سعيد',
        type: 'info',
        title: 'قيد المراجعة',
        pinOnHome: true,
      ).toJson());

      final items = await service.watchPinnedContributions().first;
      expect(items.map((e) => e.title), ['معتمدة ومثبتة']);
    });

    test('admin review transitions and pin state persist', () async {
      final fake = FakeFirebaseFirestore();
      final service = VillageExtendedService(fake);
      final ref = fake.collection('village_contributions').doc('c1');
      await ref.set(const VillageContribution(
        userId: 'u1',
        userName: 'أحمد',
        type: 'document',
        title: 'وثيقة قديمة',
      ).toJson());

      await service.approveContribution('c1', 'admin');
      await service.pinContribution('c1', true);
      var item = VillageContribution.fromJson((await ref.get()).data()!, 'c1');
      expect(item.approvalStatus, 'approved');
      expect(item.pinOnHome, isTrue);

      await service.rejectContribution('c1', 'admin');
      item = VillageContribution.fromJson((await ref.get()).data()!, 'c1');
      expect(item.approvalStatus, 'rejected');
    });
  });

  test('archive and heritage category registries are complete', () {
    expect(ArchiveItemCategory.all.length, 7);
    expect(HeritageCategory.all.length, 8);
    for (final key in ArchiveItemCategory.all) {
      expect(ArchiveItemCategory.label(key), isNotEmpty);
      expect(ArchiveItemCategory.icon(key), isNotNull);
    }
    for (final key in HeritageCategory.all) {
      expect(HeritageCategory.label(key), isNotEmpty);
      expect(HeritageCategory.color(key), isNotNull);
    }
  });
}
