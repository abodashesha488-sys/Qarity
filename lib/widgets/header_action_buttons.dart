import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// زر «الرئيسية» في الهيدر الموحّد — يحل محل شعار التطبيق.
/// يُغلق كل الصفحات المفتوحة فوق الرئيسية فينقل المستخدم إليها من أي عمق.
class HeaderHomeButton extends StatelessWidget {
  const HeaderHomeButton({super.key});

  static const double side = 38;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'العودة إلى الرئيسية',
      child: InkWell(
        key: const Key('header-home'),
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}

/// زر «+» الأخضر في الهيدر — بديل زر الإضافة العائم، يستدعي إجراء الشاشة نفسها.
class HeaderAddButton extends StatelessWidget {
  const HeaderAddButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'إضافة',
  });

  final VoidCallback onPressed;
  final String tooltip;

  static const double side = 38;
  static const Color circleColor = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 6),
        child: InkWell(
          key: const Key('header-add'),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ],
            ),
            // Icons.add لا add_rounded: الضلع أسمك، وهو المطلوب مع «+ كبيرة».
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
