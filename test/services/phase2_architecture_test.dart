import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/theme/app_theme.dart';
import 'package:qurity/core/utils/debouncer.dart';
import 'package:qurity/widgets/qarity_state_views.dart';

void main() {
  test('Debouncer collapses rapid calls and executes only the latest action',
      () async {
    final debouncer = Debouncer(duration: const Duration(milliseconds: 40));
    var calls = 0;
    var lastValue = '';

    debouncer.run(() {
      calls++;
      lastValue = 'a';
    });
    debouncer.run(() {
      calls++;
      lastValue = 'b';
    });
    debouncer.run(() {
      calls++;
      lastValue = 'c';
    });

    expect(calls, 0);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(calls, 1);
    expect(lastValue, 'c');

    debouncer.run(() => calls++);
    debouncer.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(calls, 1);
    debouncer.dispose();
  });

  testWidgets('QarityEmptyState and QarityErrorState render and handle actions',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: QarityErrorState(
            message: 'تعذر الاتصال بالخادم',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('حدث خطأ غير متوقع'), findsOneWidget);
    expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    expect(retried, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: QarityEmptyState(
            icon: Icons.inbox_rounded,
            title: 'لا توجد عناصر',
            subtitle: 'سيظهر المحتوى هنا فور إضافته',
          ),
        ),
      ),
    );
    expect(find.text('لا توجد عناصر'), findsOneWidget);
    expect(find.text('سيظهر المحتوى هنا فور إضافته'), findsOneWidget);
  });
}
