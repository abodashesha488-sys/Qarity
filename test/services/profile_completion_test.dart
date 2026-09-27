import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/data_models.dart';
import 'package:qurity/services/user_service.dart';
import 'package:qurity/widgets/gender_selector.dart';

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
}
