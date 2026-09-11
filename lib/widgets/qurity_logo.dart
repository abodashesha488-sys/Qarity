import 'package:flutter/material.dart';

/// شعار قرية أبوديشيشة (assets/images/Qurity.png) داخل دائرة بيضاء —
/// يُستخدم بدل أيقونة القرية الافتراضية في الهيدر والدرج والشبكة وشريط التنقل.
class QurityLogo extends StatelessWidget {
  const QurityLogo({
    super.key,
    this.size = 48,
    this.withBorder = true,
    this.withShadow = true,
  });

  final double size;
  final bool withBorder;
  final bool withShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: withBorder
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: size > 30 ? 2 : 1.2)
            : null,
        boxShadow: withShadow
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: size > 30 ? 10 : 6,
                    offset: Offset(0, size > 30 ? 3 : 2))
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset('assets/images/Qurity.png', fit: BoxFit.cover),
      ),
    );
  }
}
