import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/data_models.dart';
import '../../services/cache_service.dart';
import '../../services/emergency_contacts_service.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/qurity_app_bar.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final EmergencyContactsService _service = EmergencyContactsService();

  @override
  void initState() {
    super.initState();
    _service.seedIfEmpty().catchError((_) {});
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendSms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(title: 'الطوارئ'),
      body: OfflineStreamBuilder<List<EmergencyContact>>(
        stream: _service.getContactsStream(),
        onlineBuilder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          final contacts = snapshot.data ?? [];
          final emergency = contacts.where((c) => c.type == 'emergency' && c.isActive).toList();
          final community = contacts.where((c) => c.type == 'community' && c.isActive).toList();

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contact_phone_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('لا توجد جهات اتصال', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }

          return ListView(
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
              if (emergency.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('جهات الطوارئ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ...emergency.map((c) => _ContactCard(
                      contact: c,
                      theme: theme,
                      onCall: () => _makeCall(c.phone),
                      onSms: () => _sendSms(c.phone),
                      icon: Icons.emergency_rounded,
                    )),
              ],
              if (community.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('خدمات مجتمعية', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ...community.map((c) => _ContactCard(
                      contact: c,
                      theme: theme,
                      onCall: () => _makeCall(c.phone),
                      onSms: () => _sendSms(c.phone),
                      icon: Icons.groups_rounded,
                    )),
              ],
            ],
          );
        },
        cacheBuilder: (context) => FutureBuilder(
          future: CacheService.getEmergencyContacts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            final contacts = (snapshot.data ?? []).map((j) => EmergencyContact.fromJson(j, 'cache')).toList();
            final emergency = contacts.where((c) => c.type == 'emergency' && c.isActive).toList();
            final community = contacts.where((c) => c.type == 'community' && c.isActive).toList();
            if (contacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.contact_phone_rounded, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('لا توجد جهات اتصال', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('وضع غير متصل', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                if (emergency.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('جهات الطوارئ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ...emergency.map((c) => _ContactCard(
                        contact: c,
                        theme: theme,
                        onCall: () => _makeCall(c.phone),
                        onSms: () => _sendSms(c.phone),
                        icon: Icons.emergency_rounded,
                      )),
                ],
                if (community.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('خدمات مجتمعية', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ...community.map((c) => _ContactCard(
                        contact: c,
                        theme: theme,
                        onCall: () => _makeCall(c.phone),
                        onSms: () => _sendSms(c.phone),
                        icon: Icons.groups_rounded,
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final ThemeData theme;
  final VoidCallback onCall;
  final VoidCallback onSms;
  final IconData icon;

  const _ContactCard({
    required this.contact,
    required this.theme,
    required this.onCall,
    required this.onSms,
    required this.icon,
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
        title: Text(contact.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phone, style: theme.textTheme.bodySmall),
            if (contact.description != null && contact.description!.isNotEmpty)
              Text(contact.description!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
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
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF6F4E37).withValues(alpha: 0.15)),
            ),
          ],
        ),
      ),
    );
  }
}
