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
        // النسخة المضغوطة (هيدر الرئيسية) — رمز نقي بلا دائرة ولا لون
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Badge(
                isLabelVisible: unread > 0,
                label: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFFE53935),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 24,
                  color: Color(0xFFFFD700),
                  shadows: [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                    Shadow(
                      color: Color(0x66FFD700),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
