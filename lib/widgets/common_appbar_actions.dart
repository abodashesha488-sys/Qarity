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
        return Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: CircleBorder(
              side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.28))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: open,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(child: badge),
            ),
          ),
        );
      },
    );
  }
}
