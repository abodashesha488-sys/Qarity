import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/common_appbar_actions.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contacts = [
      {'name': 'شرطة القرية', 'phone': '0123456789', 'icon': Icons.security},
      {'name': 'إطفاء القرية', 'phone': '0123456780', 'icon': Icons.local_fire_department},
      {'name': 'مستشفى القرية', 'phone': '0123456781', 'icon': Icons.local_hospital},
      {'name': 'عربة الإسعاف', 'phone': '0123456782', 'icon': Icons.emergency},
    ];

    final community = [
      {'name': 'لجنة القرية', 'phone': '0123456783', 'icon': Icons.groups},
      {'name': 'الشرطة النسائية', 'phone': '0123456784', 'icon': Icons.person},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطوارئ'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.emergency_rounded, size: 40, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الطوارئ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onErrorContainer)),
                      Text('اتصل بنا فوراً في حالات الطوارئ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('جهات الطوارئ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...contacts.map((c) => _ContactCard(
            name: c['name'] as String,
            phone: c['phone'] as String,
            icon: c['icon'] as IconData,
            theme: theme,
            onCall: () => _makeCall(c['phone'] as String),
            onSms: () => _sendSms(c['phone'] as String),
          )),
          const SizedBox(height: 20),
          Text('خدمات مجتمعية', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...community.map((c) => _ContactCard(
            name: c['name'] as String,
            phone: c['phone'] as String,
            icon: c['icon'] as IconData,
            theme: theme,
            onCall: () => _makeCall(c['phone'] as String),
            onSms: () => _sendSms(c['phone'] as String),
          )),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final IconData icon;
  final ThemeData theme;
  final VoidCallback onCall;
  final VoidCallback onSms;

  const _ContactCard({
    required this.name,
    required this.phone,
    required this.icon,
    required this.theme,
    required this.onCall,
    required this.onSms,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Text(phone, style: theme.textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filled(
              onPressed: onSms,
              icon: const Icon(Icons.message_rounded, size: 18),
              style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onCall,
              icon: const Icon(Icons.call_rounded, size: 18),
              style: IconButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.15)),
            ),
          ],
        ),
      ),
    );
  }
}
