
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qurity/main.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const QarityApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}