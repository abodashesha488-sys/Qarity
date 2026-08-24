import 'package:flutter/material.dart';

String resolveStatusLabel(Map<String, String> labels, String status) =>
    labels[status] ?? 'غير معروف';

Color resolveStatusColor(Map<String, Color> colors, String status) =>
    colors[status] ?? const Color(0xFF757575);
