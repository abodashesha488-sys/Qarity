import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'common_appbar_actions.dart';
import 'header_action_buttons.dart';

/// هيدر موحّد لكل شاشات التطبيق (عدا الشاشة الرئيسية):
/// زر الرئيسية + اسم الصفحة + زر الإضافة (حيث للشاشة إجراء إضافة) + الجرس،
/// بخلفية بنية #6F4E37 في كل الصفحات، وكتابة وأيقونات بيضاء، وارتفاع ثابت.
class QurityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QurityAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
    this.leading,
    this.onAdd,
    this.addTooltip = 'إضافة',
  });

  final String title;

  /// أزرار إضافية للشاشة — يُضاف زر «+» ثم الجرس تلقائيًا بعده.
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  /// إجراء إضافة الشاشة؛ عند تمريره يظهر زر «+» الأخضر بجوار الجرس بديلًا عن
  /// الزر العائم. يُترك null في الشاشات التي لا إضافة فيها.
  final VoidCallback? onAdd;
  final String addTooltip;

  static const Color headerColor = Color(0xFF6F4E37);

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final add = onAdd;
    return AppBar(
      backgroundColor: headerColor,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 10,
      leading: leading,
      title: Row(
        children: [
          const HeaderHomeButton(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      actions: [
        ...actions,
        if (add != null) HeaderAddButton(onPressed: add, tooltip: addTooltip),
        const NotificationBellButton(),
      ],
      bottom: bottom,
    );
  }
}
