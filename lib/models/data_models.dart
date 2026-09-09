import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/utils/status_utils.dart';

part 'data_models_content.dart';
part 'data_models_community.dart';

// ═══════════════════════════════════════════════════════════════
// BASE MODEL
// ═══════════════════════════════════════════════════════════════
abstract class BaseModel {
  String get id;
  Map<String, dynamic> toJson();
  DateTime? get createdAt;
}

// ═══════════════════════════════════════════════════════════════
// UTILITY FUNCTIONS
// ═══════════════════════════════════════════════════════════════
DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
