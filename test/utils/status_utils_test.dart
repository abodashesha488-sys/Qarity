import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/status_utils.dart';

void main() {
  const labels = <String, String>{
    'pending': 'قيد الانتظار',
    'done': 'مكتمل',
  };
  const colors = <String, Color>{
    'pending': Color(0xFFFF9800),
    'done': Color(0xFF43A047),
  };

  group('resolveStatusLabel', () {
    test('returns mapped label', () {
      expect(resolveStatusLabel(labels, 'pending'), 'قيد الانتظار');
      expect(resolveStatusLabel(labels, 'done'), 'مكتمل');
    });
    test('falls back to unknown', () {
      expect(resolveStatusLabel(labels, 'missing'), 'غير معروف');
      expect(resolveStatusLabel(const {}, 'x'), 'غير معروف');
    });
  });

  group('resolveStatusColor', () {
    test('returns mapped color', () {
      expect(resolveStatusColor(colors, 'pending'), const Color(0xFFFF9800));
      expect(resolveStatusColor(colors, 'done'), const Color(0xFF43A047));
    });
    test('falls back to grey', () {
      expect(resolveStatusColor(colors, 'missing'), const Color(0xFF757575));
      expect(resolveStatusColor(const {}, 'x'), const Color(0xFF757575));
    });
  });
}
