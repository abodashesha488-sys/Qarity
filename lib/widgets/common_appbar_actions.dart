import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/notification_inbox_service.dart';

/// أزرار مشتركة تظهر في أعلى كل الشاشات: جرس الإشعارات (مع عدّاد غير المقروء).
class CommonAppBarActions {
  static List<Widget> actions(BuildContext context) => const [
        NotificationBellButton(),
      ];
  }

/// جرس الإشعارات — عادي لـ AppBar، أو `compact` دائري زجاجي لهيدر الرئيسية.
/// `compactSize` يضبط قطر الدائرة (افتراضيًا 42)، فتبقى الشارة والأيقونة
/// متناسبة مع أي حجم يطلبه الهيدر.
class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton(
      {super.key, this.compact = false, this.compactSize});
  final bool compact;
  final double? compactSize;

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  late final String _uid;
  // stream مثبت لكل زر: كان يُنشأ داخل build فيعيد الاشتراك (وقراءة العدّاد)
  // عند كل rebuild لأي AppBar في التطبيق.
  late final Stream<int> _unread = _uid.isEmpty
      ? Stream.value(0)
      : NotificationInboxService.instance.unreadCount(_uid);

  @override
  void initState() {
    super.initState();
    String uid = '';
    try {
      uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      uid = '';
    }
    _uid = uid;
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    if (_uid.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<int>(
      stream: _unread,
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        final badge = Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          backgroundColor: Theme.of(context).colorScheme.error,
          child: Icon(
            Icons.notifications_none_rounded,
            color: compact ? Colors.white : null,
            size: compact ? 19 : 24,
          ),
        );
        void open() =>
            Navigator.pushNamed(context, AppRoutes.notificationsInbox);
        if (!compact) {
          return IconButton(
            tooltip: 'إشعاراتي',
            icon: badge,
            onPressed: open,
          );
        }
        // النسخة المضغوطة (هيدر الرئيسية) — دائرة بلون الثيم + شارة غير مقطوعة
        final side = widget.compactSize ?? 42.0;
        final scale = side / 42.0;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 4, top: 1, bottom: 1),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: open,
            child: Container(
              width: side,
              height: side,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primaryContainer,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.6 * scale),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 21 * scale),
                  if (unread > 0)
                    PositionedDirectional(
                      top: 4 * scale,
                      end: 3 * scale,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.5 * scale, vertical: 1 * scale),
                        constraints: BoxConstraints(minWidth: 15 * scale),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 1.2 * scale),
                        ),
                        child: Text(
                            unread > 99 ? '99+' : '$unread',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5 * scale,
                                height: 1.25,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
