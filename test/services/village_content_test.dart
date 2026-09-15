import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/village_content_models.dart';
import 'package:qurity/services/village_content_service.dart';

void main() {
  group('VillageContentService CRUD', () {
    test('saveEra add then watch ordered by sortOrder', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageContentService(fake);
      await svc.saveEra(const HistoryEra(
          title: 'الحقبة الثانية', narrative: 'ب', sortOrder: 2));
      await svc.saveEra(const HistoryEra(
          title: 'الحقبة الأولى', narrative: 'ا', sortOrder: 1));
      final eras = await svc.watchEras().first;
      expect(eras.map((e) => e.title), ['الحقبة الأولى', 'الحقبة الثانية']);
    });

    test('saveFigure updates in place when id set', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageContentService(fake);
      final id = (await fake.collection('village_figures').add(const VillageFigure(
              name: 'العمدة الأول', category: FigureCategory.mayor)
              .toJson()))
          .id;
      final figures = await svc.watchFigures().first;
      final orig = figures.single;
      await svc.saveFigure(VillageFigure(
          id: id,
          name: 'العمدة الثاني',
          category: orig.category,
          title: orig.title,
          era: orig.era,
          bio: orig.bio,
          photoUrl: orig.photoUrl,
          sortOrder: orig.sortOrder,
          createdAt: orig.createdAt));
      final after = await svc.watchFigures().first;
      expect(after, hasLength(1));
      expect(after.single.name, 'العمدة الثاني');
    });

    test('institution by type + delete', () async {
      final fake = FakeFirebaseFirestore();
      final svc = VillageContentService(fake);
      await svc.saveInstitution(const VillageInstitution(
          name: 'مسجد القرية الكبير', type: InstitutionType.mosque));
      final id =
          (await fake.collection('village_institutions').get()).docs.single.id;
      var list = await svc.watchInstitutions().first;
      expect(list.single.type, InstitutionType.mosque);
      await svc.deleteDoc('village_institutions', id);
      list = await svc.watchInstitutions().first;
      expect(list, isEmpty);
    });
  });

  group('migrateLegacyIfNeeded', () {
    test('moves legacy lists once and stamps the flag', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('village_info').doc('main').set({
        'name': 'قرية أبوديشيشة',
        'history': [
          {'year': '1920', 'event': 'ذكر التأسيس'},
          {'year': '1960', 'event': 'بناء المدرسة'},
        ],
        'institutions': [
          {'name': 'مدرسة أبوديشيشة الابتدائية', 'location': 'شارع البلد'},
          {'name': 'مسجد الرحمن', 'location': ''},
        ],
        'archive': ['صورة السوق القديم'],
      });
      final svc = VillageContentService(fake);
      final moved = await svc.migrateLegacyIfNeeded();
      expect(moved, 5);
      expect((await svc.watchEras().first).length, 2);
      final insts = await svc.watchInstitutions().first;
      expect(insts.map((i) => i.type).toSet(),
          {InstitutionType.schools, InstitutionType.mosque});
      expect((await svc.watchArchivePhotos().first).length, 1);
      final main = await fake.collection('village_info').doc('main').get();
      expect(main.data()!['contentMigrated'], true);
      expect(await svc.migrateLegacyIfNeeded(), 0);
    });

    test('no-op when doc missing', () async {
      final fake = FakeFirebaseFirestore();
      expect(await VillageContentService(fake).migrateLegacyIfNeeded(), 0);
    });
  });

  group('category helpers', () {
    test('figure labels and colors are unique per category', () {
      final labels = FigureCategory.all.map(FigureCategory.label).toSet();
      final colors =
          FigureCategory.all.map(FigureCategory.color).toSet();
      expect(labels, hasLength(FigureCategory.all.length));
      expect(colors, hasLength(FigureCategory.all.length));
    });
    test('institution type guess from name', () {
      expect(InstitutionType.guessFromName('معهد أبو ديشيشة الأزهري'),
          InstitutionType.azhar);
      expect(InstitutionType.guessFromName('الجمعية الزراعية'),
          InstitutionType.agri);
      expect(InstitutionType.guessFromName('مكتب البريد'),
          InstitutionType.post);
      expect(InstitutionType.guessFromName('لا شيء'), InstitutionType.other);
    });
  });
}
