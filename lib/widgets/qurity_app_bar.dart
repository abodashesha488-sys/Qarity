import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'common_appbar_actions.dart';
import 'qurity_logo.dart';

/// هيدر موحّد وثابت لكل شاشات التطبيق (عدا الشاشة الرئيسية):
/// شعار التطبيق + اسم الصفحة + جرس الإشعارات، بخلفية بنية #6F4E37
/// وكتابة وأيقونات بيضاء، وارتفاع ثابت (kToolbarHeight) في كل الصفحات.
class QurityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QurityAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
    this.leading,
  });

  final String title;

  /// أزرار إضافية للشاشة — يُضاف جرس الإشعارات تلقائيًا بعدها.
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  static const Color headerColor = Color(0xFF6F4E37);

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
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
          const QurityLogo(size: 32),
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
        const NotificationBellButton(),
      ],
      bottom: bottom,
    );
  }
}
