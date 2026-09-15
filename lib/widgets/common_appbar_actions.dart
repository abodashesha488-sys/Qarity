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
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    String uid = '';
    try {
      uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      uid = '';
    }
    if (uid.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<int>(
      stream: NotificationInboxService.instance.unreadCount(uid),
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
        // النسخة المضغوطة (هيدر الرئيسية) — دائرة زرقاء صريحة + شارة غير مقطوعة
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 4, top: 1, bottom: 1),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: open,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.6),
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
                  const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 21),
                  if (unread > 0)
                    PositionedDirectional(
                      top: 4,
                      end: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 15),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 1.2),
                        ),
                        child: Text(
                            unread > 99 ? '99+' : '$unread',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
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
