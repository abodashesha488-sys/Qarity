import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/news_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('إعجاب الأخبار: مسار واحد يزامن likes مع likedBy', () {
    test('إضافة ثم إلغاء ثم مستخدم ثانٍ يبقي العدّاد مطابقًا للقائمة',
        () async {
      final fake = FakeFirebaseFirestore();
      final id = (await fake
              .collection('news')
              .add({'title': 'خبر', 'likes': 0, 'likedBy': <String>[]}))
          .id;
      final svc = NewsService(fake);

      expect(await svc.toggleNewsLike(id, 'u1'), isTrue);
      var data = (await fake.collection('news').doc(id).get()).data()!;
      expect(data['likes'], 1);
      expect(data['likedBy'], ['u1']);

      expect(await svc.toggleNewsLike(id, 'u1'), isFalse);
      data = (await fake.collection('news').doc(id).get()).data()!;
      expect(data['likes'], 0);
      expect(data['likedBy'], isEmpty);

      await svc.toggleNewsLike(id, 'u1');
      await svc.toggleNewsLike(id, 'u2');
      data = (await fake.collection('news').doc(id).get()).data()!;
      expect((data['likedBy'] as List).toSet(), {'u1', 'u2'});
      expect(data['likes'], (data['likedBy'] as List).length);
    });

    test('إعادة إعجاب نفس المستخدم لا تضاعف العدّاد', () async {
      final fake = FakeFirebaseFirestore();
      final id = (await fake
              .collection('news')
              .add({'title': 'خبر', 'likes': 0, 'likedBy': <String>['u1']}))
          .id;
      final svc = NewsService(fake);

      // «u1» معجب مسبقًا ⇒ الضغط الأول يزيل، والثاني يضيف مرة واحدة فقط
      await svc.toggleNewsLike(id, 'u1');
      await svc.toggleNewsLike(id, 'u1');
      final data = (await fake.collection('news').doc(id).get()).data()!;
      expect(data['likedBy'], ['u1']);
      expect(data['likes'], 1);
    });
  });
}
