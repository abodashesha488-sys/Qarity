import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/cache_service.dart';
import 'package:qurity/services/user_service.dart';
import 'package:qurity/widgets/gender_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserModel _user(
        {String name = 'أحمد',
        String? phone = '01000000000',
        String gender = 'ذكر'}) =>
    UserModel(
      id: 'u1',
      name: name,
      email: 'a@b.com',
      phone: phone,
      gender: gender,
      joinDate: DateTime(2026),
    );

Future<void> _pumpSelector(WidgetTester tester,
    {String? value, String? errorText, required ValueChanged<String> onChanged}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: GenderSelector(
          value: value, errorText: errorText, onChanged: onChanged),
    ),
  ));
}

void main() {
  group('بوابة إكمال الملف الشخصي: النوع إلزامي', () {
    test('بيانات كاملة (اسم + هاتف + نوع) ⇒ مسموح بالدخول', () {
      expect(UserService.isProfileComplete(_user()), isTrue);
    });

    test('بلا نوع ⇒ غير مكتمل (يوجَّه إلى شاشة الإكمال)', () {
      expect(UserService.isProfileComplete(_user(gender: '')), isFalse);
      expect(UserService.isProfileComplete(_user(gender: '   ')), isFalse);
    });

    test('بلا اسم أو بلا هاتف يبقى غير مكتمل ولو وُجد النوع', () {
      expect(UserService.isProfileComplete(_user(name: '')), isFalse);
      expect(UserService.isProfileComplete(_user(phone: null)), isFalse);
    });

    test('لا مستخدم ⇒ غير مكتمل', () {
      expect(UserService.isProfileComplete(null), isFalse);
    });
  });

  group('منتقي النوع (يُستخدم في الإكمال وفي تعديل الملف)', () {
    testWidgets('يعرض ذكر/أنثى ويستدعي onChanged بالقيمة المختارة',
        (tester) async {
      String? captured;
      await _pumpSelector(tester, onChanged: (v) => captured = v);
      expect(find.text('ذكر'), findsOneWidget);
      expect(find.text('أنثى'), findsOneWidget);

      await tester.tap(find.text('أنثى'));
      expect(captured, 'أنثى');
    });

    testWidgets('القيمة المختارة تُبرز الرسالة عند وجودها', (tester) async {
      await _pumpSelector(tester,
          value: 'ذكر',
          errorText: 'يجب اختيار النوع',
          onChanged: (_) {});
      expect(find.text('النوع *'), findsOneWidget);
      expect(find.text('يجب اختيار النوع'), findsOneWidget);
    });
  });

  group('قراءة السلطات من الخادم (تجاوز النسخة المحفوظة على الجهاز)', () {
    late FakeFirebaseFirestore fs;

    Future<void> seedServer({bool active = false}) =>
        fs.collection('users').doc('u1').set({
              'name': 'أحمد',
              'email': 'a@b.com',
              'role': 'user',
              'gender': 'ذكر',
              'isActive': active,
            });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fs = FakeFirebaseFirestore();
      // نسخة الجهاز القديمة تقول «مفعّل» — وهي أصل المشكلة.
      await CacheService.saveUser('u1',
          _user().copyWith().toJson()); // isActive: true افتراضيًا
    });

    test('getUser العادي يظل يرجع النسخة المحفوظة (سلوك معروف)', () async {
      await seedServer();
      final u = await UserService(fs).getUser('u1');
      expect(u?.isActive, isTrue,
          reason: 'الكاش أولاً — لهذا لا يلاحظ جهاز المخالف التعطيل');
    });

    test('getAuthority يرجع قرار الخادم ويحدّث الكاش', () async {
      await seedServer();
      final u = await UserService(fs).getAuthority('u1');
      expect(u?.isActive, isFalse);
      final refreshed = await CacheService.getUser('u1');
      expect(refreshed?['isActive'], isFalse,
          reason: 'القرار الأمني يُكتب للكاش فلا يتعارض مع كل فتح لاحق');
    });

    test('ملف محذوف ⇒ null وإسقاط النسخة المحفوظة (لا عودة بالكاش)',
        () async {
      await fs.collection('users').doc('u1').set({'name': 'أحمد'});
      await fs.collection('users').doc('u1').delete();
      final u = await UserService(fs).getAuthority('u1');
      expect(u, isNull);
      expect(await CacheService.getUser('u1'), isNull);
    });

    test('حساب قديم بلا حقل التفعيل يُعتبر مفعّلاً', () async {
      await fs.collection('users').doc('u1').set({'name': 'أحمد'});
      final u = await UserService(fs).getAuthority('u1');
      expect(u?.isActive, isTrue);
    });
  });
}
