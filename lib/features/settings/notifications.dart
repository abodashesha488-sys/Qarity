import 'package:flutter/material.dart';

import '../../widgets/common_appbar_actions.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _newsNotifications = true;
  bool _occasionsNotifications = true;
  bool _marketNotifications = false;
  bool _emergencyNotifications = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الإشعارات'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.notifications_active_rounded, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('الإشعارات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationTile(
                    theme,
                    icon: Icons.newspaper_rounded,
                    title: 'إشعارات الأخبار',
                    subtitle: 'تلقي إشعارات عند نشر أخبار جديدة',
                    value: _newsNotifications,
                    onChanged: (v) => setState(() => _newsNotifications = v),
                    color: Colors.indigo,
                  ),
                  const Divider(height: 24),
                  _buildNotificationTile(
                    theme,
                    icon: Icons.celebration_rounded,
                    title: 'إشعارات المناسبات',
                    subtitle: 'تلقي إشعارات عن المناسبات القادمة',
                    value: _occasionsNotifications,
                    onChanged: (v) => setState(() => _occasionsNotifications = v),
                    color: Colors.purple,
                  ),
                  const Divider(height: 24),
                  _buildNotificationTile(
                    theme,
                    icon: Icons.shopping_bag_rounded,
                    title: 'إشعارات السوق',
                    subtitle: 'تلقي إشعارات عن المنتجات الجديدة',
                    value: _marketNotifications,
                    onChanged: (v) => setState(() => _marketNotifications = v),
                    color: Colors.deepOrange,
                  ),
                  const Divider(height: 24),
                  _buildNotificationTile(
                    theme,
                    icon: Icons.emergency_rounded,
                    title: 'إشعارات الطوارئ',
                    subtitle: 'تلقي إشعارات الطوارئ المهمة',
                    value: _emergencyNotifications,
                    onChanged: (v) => setState(() => _emergencyNotifications = v),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: theme.colorScheme.primary,
        ),
      ],
    );
  }
}
