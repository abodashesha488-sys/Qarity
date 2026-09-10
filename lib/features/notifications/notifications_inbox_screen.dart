import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/notification_inbox_service.dart';
import '../../widgets/common_appbar_actions.dart';

/// صندوق الإشعارات الشخصي للمستخدم.
class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() =>
      _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  final _service = NotificationInboxService.instance;
  String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_uid.isNotEmpty) _service.markAllRead(_uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إشعاراتي'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: _uid.isEmpty
          ? const Center(
              child: Text('سجّل الدخول لعرض إشعاراتك',
                  style: TextStyle(color: Colors.grey)))
          : StreamBuilder<List<UserNotification>>(
              stream: _service.streamFor(_uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const _EmptyInbox();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final color = switch (n.kind) {
                      'approve' => Colors.green,
                      'reject' => Colors.orange,
                      _ => theme.colorScheme.primary,
                    };
                    final icon = switch (n.kind) {
                      'approve' => Icons.check_circle_rounded,
                      'reject' => Icons.warning_amber_rounded,
                      _ => Icons.notifications_rounded,
                    };
                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.4)),
                      ),
                      child: ListTile(
                        onTap: () async {
                          await _service.markRead(n.id);
                          if (!context.mounted) return;
                          if (n.route != null && n.route!.isNotEmpty) {
                            Navigator.pushNamed(context, n.route!);
                          }
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(n.title,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        subtitle: Text(n.body,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        trailing: Text(_ago(n.createdAt),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: Colors.grey)),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'الآن';
    if (d.inMinutes < 60) return '${d.inMinutes}د';
    if (d.inHours < 24) return '${d.inHours}س';
    return '${d.inDays}ي';
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 60, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('لا توجد إشعارات بعد',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('ستصلك إشعارات هنا عند الموافقة على ما ترسله أو مراجعته',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
