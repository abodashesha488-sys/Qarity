import 'package:flutter/material.dart';

import '../models/service_provider_model.dart';

/// علامة الصفة (مدرس / مدرسة) — صورة «mal/femal» بنفس مقاس الرموز التي تستبدلها.
class EduKindMark extends StatelessWidget {
  const EduKindMark({super.key, required this.kind, this.size = 15});

  final String kind;
  final double size;

  static String? imageOf(String kind) {
    if (kind == kEduKindSchool) return 'assets/images/femal.jpg';
    if (kind == kEduKindTeacher) return 'assets/images/mal.jpg';
    return null;
  }

  IconData get _fallbackIcon => kind == kEduKindSchool
      ? Icons.account_balance_rounded
      : Icons.person_rounded;

  @override
  Widget build(BuildContext context) {
    final path = imageOf(kind);
    if (path == null) return Icon(_fallbackIcon, size: size);
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 3.0;
    return ClipRRect(
      key: ValueKey('edu-kind-mark-$kind'),
      borderRadius: BorderRadius.circular(size / 3),
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * dpr).ceil(),
        errorBuilder: (_, __, ___) => Icon(_fallbackIcon, size: size),
      ),
    );
  }
}
