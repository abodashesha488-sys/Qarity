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

/// جرس الإشعارات — عادي لـ AppBar، أو `compact` كبسولة لهيدر الرئيسية بنفس تنسيق متصل وعضو.
class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({super.key, this.compact = false});
  final bool compact;

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
        // النسخة المضغوطة (هيدر الرئيسية) — بنفس تنسيق كبسولات الهيدر المقابلة (متصل وعضو)
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: open,
            child: Container(
              height: 27,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  width: 0.9,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x38000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Badge(
                    isLabelVisible: unread > 0,
                    label: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: const Color(0xFFE53935),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 14.5,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(width: 4.5),
                  if (unread > 0) ...[
                    Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 3.5),
                  ],
                  Text(
                    'إشعارات',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
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
