import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/admin_service.dart';

class AdminDetailScreen extends StatefulWidget {
  final String collection;
  final String docId;
  final Map<String, dynamic> item;

  const AdminDetailScreen({super.key, required this.collection, required this.docId, required this.item});

  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  final AdminService _adminService = AdminService();
  final Set<String> _busy = {};

  bool _isBusy(String action) => _busy.contains(action);

  Future<void> _run(String action, Future<void> Function() fn) async {
    if (_isBusy(action)) return;
    setState(() => _busy.add(action));
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy.remove(action));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final title = item['title'] ?? item['name'] ?? item['content'] ?? 'بدون عنوان';

    return Scaffold(
      appBar: AppBar(
        title: Text(title.length > 24 ? '${title.substring(0, 24)}...' : title),
        centerTitle: true,
        actions: [
          _busy.isEmpty
              ? TextButton(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRoutes.adminEdit,
                      arguments: {
                        'collection': widget.collection,
                        'docId': widget.docId,
                        'item': item,
                      },
                    );
                    if (result == true && mounted) setState(() {});
                  },
                  child: const Text('تعديل'),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...item.entries.expand((entry) {
                    final key = entry.key;
                    final value = entry.value;
                    if (key == 'id') return const <Widget>[];
                     return [
                       const Divider(height: 32),
                       _buildDetailRow(theme, key, value),
                     ];
                   }),
                 ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionFilled(theme, 'موافقة', Icons.check_rounded, Colors.green,
                  _isBusy('approve')
                      ? null
                      : () => _run('approve', () => _adminService.approveItem(widget.collection, widget.docId))),
              _buildActionFilled(theme, 'رفض', Icons.close_rounded, Colors.orange,
                  _isBusy('reject')
                      ? null
                      : () => _run('reject', () => _adminService.rejectItem(widget.collection, widget.docId))),
              _buildActionFilled(theme, 'حذف', Icons.delete_rounded, Colors.red,
                  _isBusy('delete')
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: const Text('هل أنت متأكد من حذف هذا العنصر؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _run('delete', () => _adminService.deleteItem(widget.collection, widget.docId));
                          }
                        }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String key, dynamic value) {
    final display =
        value == null ? 'لا يوجد' : value is List ? value.join('، ') : value.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(key, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontFamily: 'monospace')),
        const SizedBox(height: 4),
        Text(display, style: theme.textTheme.bodyMedium?.copyWith(height: 1.3)),
      ],
    );
  }

  Widget _buildActionFilled(ThemeData theme, String label, IconData icon, Color color, VoidCallback? onPressed) {
    final isLoading = onPressed == null;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: color.withValues(alpha: 0.2))),
      ),
      onPressed: isLoading ? null : onPressed,
      icon: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
