import 'dart:async';
import 'package:flutter/foundation.dart';

/// مؤخّر زمني خفيف (Debouncer) لتقليل استدعاءات البحث أو التصفية المتكررة
/// أثناء الكتابة السريعة، مع تنظيف آمن للمؤقت عند الإغلاق.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 220)});

  final Duration duration;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
