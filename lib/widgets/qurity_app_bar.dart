import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';
import 'common_appbar_actions.dart';
import 'header_action_buttons.dart';

/// هيدر موحّد لكل شاشات التطبيق (عدا الشاشة الرئيسية):
/// زر الرئيسية + اسم الصفحة + زر الإضافة (حيث للشاشة إجراء إضافة) + الجرس،
/// بخلفية زمردية داكنة في كل الصفحات (أعمق في الوضع الداكن حتى لا تلسع على
/// الأسود)، وكتابة وأيقونات بيضاء، وارتفاع ثابت.
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

  static Color get headerColor => AppColors.primary;

  /// خلفية الهيدر حسب الوضع: الزمردي نفسه في الفاتح، وأغمق منه في الداكن
  /// (`darkPrimary`) لأن `colorScheme.primary` في الداكن صار فاتحًا عمدًا —
  /// فهو يستعمل كتابةً وأيقونات في كل الشاشات، فلا يصلح أرضية للهيدر.
  static Color headerColorFor(Brightness brightness) =>
      brightness == Brightness.dark ? AppColors.darkPrimary : headerColor;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final add = onAdd;
    return AppBar(
      backgroundColor: headerColorFor(Theme.of(context).brightness),
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
