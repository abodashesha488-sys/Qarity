import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/widgets/order_progress_stepper.dart';

void main() {
  testWidgets('OrderProgressStepper renders all steps and completion icons',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrderProgressStepper(
            steps: [
              OrderProgressStep(label: 'استلام الطلب', isDone: true),
              OrderProgressStep(label: 'جاري التنفيذ', isDone: true),
              OrderProgressStep(label: 'تم التسليم', isDone: false),
            ],
          ),
        ),
      ),
    );

    expect(find.text('استلام الطلب'), findsOneWidget);
    expect(find.text('جاري التنفيذ'), findsOneWidget);
    expect(find.text('تم التسليم'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });
}
