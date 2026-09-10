import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/notification_service.dart';
import '../../widgets/common_appbar_actions.dart';

/// إعدادات الإشعارات — كل الخدمات مفعّلة افتراضياً، والتبديل محفوظ محلياً
/// ويرتبط فعلياً بالاشتراك/الإلغاء في موضوع FCM الخاص بالخدمة.
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _Service {
  final String topic;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _Service(this.topic, this.title, this.subtitle, this.icon, this.color);
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  static const _services = <_Service>[
    _Service('village_news', 'إشعارات الأخبار', 'أحدث أخبار ومستجدات القرية',
        Icons.newspaper_rounded, Colors.indigo),
    _Service('village_obituaries', 'إشعارات العزاء', 'النعياء والتعازي الجديدة',
        Icons.volunteer_activism_rounded, Colors.blueGrey),
    _Service('village_occasions', 'إشعارات المناسبات',
        'المناسبات القادمة في القرية', Icons.celebration_rounded, Colors.purple),
    _Service('village_market', 'إشعارات السوق', 'المنتجات والمحلات الجديدة',
        Icons.shopping_bag_rounded, Colors.deepOrange),
    _Service('village_forum', 'إشعارات المنتدى', 'المنشورات والنقاشات الجديدة',
        Icons.forum_rounded, Colors.brown),
    _Service('village_services', 'إشعارات الخدمات', 'طلبات وتحديثات الخدمات',
        Icons.support_agent_rounded, Colors.teal),
    _Service('village_medical', 'الإشعارات الطبية',
        'المركز الطبي وعياداته والصيدليات وبنك الدم',
        Icons.medical_services_rounded, Color(0xFF00897B)),
  ];

  final Map<String, bool> _states = {};
  bool _loading = true;

  static String _key(String topic) => 'notif_pref_$topic';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final s in _services) {
        // افتراضي: مفعّل
        _states[s.topic] = prefs.getBool(_key(s.topic)) ?? true;
      }
      _loading = false;
    });
  }

  Future<void> _toggle(_Service s, bool value) async {
    setState(() => _states[s.topic] = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(s.topic), value);
    try {
      if (value) {
        await NotificationService.subscribeToTopic(s.topic);
      } else {
        await NotificationService.unsubscribeFromTopic(s.topic);
      }
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(value ? 'تم تفعيل ${s.title}' : 'تم إيقاف ${s.title}'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'جميع الإشعارات مفعّلة افتراضياً — يمكنك إيقاف أي خدمة منها في أي وقت وستبقى اختيارك محفوظاً.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._services.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.4)),
                        ),
                        child: SwitchListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          value: _states[s.topic] ?? true,
                          onChanged: (v) => _toggle(s, v),
                          secondary: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                                color: s.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12)),
                            child:
                                Icon(s.icon, color: s.color, size: 20),
                          ),
                          title: Text(s.title,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          subtitle: Text(s.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
