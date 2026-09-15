import 'package:cloud_firestore/cloud_firestore.dart';

/// تحويل قيم Firestore (Timestamp/int/String/DateTime) إلى DateTime أو null.
DateTime? tsToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// النسخة غير القابلة لـ null — ترجع الوقت الحالي عند الفقد/التعذر.
DateTime tsOrNow(dynamic value) => tsToDateTime(value) ?? DateTime.now();
