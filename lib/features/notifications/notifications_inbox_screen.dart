import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/notification_deeplink.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_inbox_service.dart';
import '../../widgets/qurity_app_bar.dart';

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

  Future<void> _confirmDeleteAll() async {
    if (_uid.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف كافة الإشعارات'),
        content: const Text(
            'هل أنت متأكد من حذف جميع الإشعارات المسجلة؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _service.deleteAll(_uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف كافة الإشعارات بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(
        title: 'إشعاراتي',
        actions: [
          IconButton(
            key: const Key('inbox-delete-all'),
            tooltip: 'حذف كافة الإشعارات',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _confirmDeleteAll,
          ),
        ],
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
                      'approve' => AppColors.success,
                      'reject' => Colors.orange,
                      'alert' => AppColors.error,
                      'broadcast' => const Color(0xFF1565C0),
                      _ => theme.colorScheme.primary,
                    };
                    final icon = switch (n.kind) {
                      'approve' => Icons.check_circle_rounded,
                      'reject' => Icons.warning_amber_rounded,
                      'alert' => Icons.crisis_alert_rounded,
                      'broadcast' => Icons.campaign_rounded,
                      _ => Icons.notifications_rounded,
                    };
                    final iconInk =
                        AppColors.readableInk(color, theme.brightness,
                            minRatio: 3.0);
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
                          await _service.markRead(n.id, userId: _uid);
                          if (!context.mounted) return;
                          final target = n.route;
                          if (target == null || target.isEmpty) return;
                          final deep = NotificationDeepLink.decode(target);
                          if (deep != null) {
                            Navigator.pushNamed(
                                context, AppRoutes.notificationOpen,
                                arguments: deep.toArgs());
                          } else {
                            Navigator.pushNamed(context, target);
                          }
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, color: iconInk),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(n.title,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                            ),
                            if (n.isBroadcast)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: const Color(0xFF1565C0)
                                          .withValues(alpha: 0.3)),
                                ),
                                child: const Text('إذاعي عام',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1565C0))),
                              ),
                          ],
                        ),
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
