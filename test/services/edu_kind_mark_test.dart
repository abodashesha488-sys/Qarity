import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/widgets/edu_kind_mark.dart';

void main() {
  test('صور الصفة مسجّلة في حزمة الأصول', () async {
    for (final k in ['مدرس', 'مدرسة']) {
      final path = EduKindMark.imageOf(k)!;
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(1000), reason: path);
    }
  });

  testWidgets('EduKindMark يرسم الصورة بالمقاس المطلوب بلا ارتداد للأيقونة',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: EduKindMark(kind: 'مدرس', size: 40),
      ),
    ));
    await tester.runAsync(() async {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    });
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(EduKindMark)), const Size(40, 40));
    // لم يسقط إلى الأيقونة البديلة ⇒ مسار الصورة يُحمَّل فعلًا.
    expect(find.byIcon(Icons.person_rounded), findsNothing);
  });
}
