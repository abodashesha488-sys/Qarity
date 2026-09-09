part of 'admin_dashboard.dart';

// ═══════════════════════════ Reports ═══════════════════════════
class _ReportsPage extends StatelessWidget {
  const _ReportsPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = AdminService();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<int>(
          future: service.getActiveUsersCount(),
          builder: (context, s) => _reportRow(theme, 'المستخدمون',
              '${s.data ?? 0}', Icons.people_rounded, Colors.green),
        ),
        const SizedBox(height: 12),
        const _SectionTitle(
            'أحدث المنتجات', Icons.shopping_bag_rounded, Colors.deepPurple),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: service.getTopProducts(limit: 6),
          builder: (context, s) {
            final list = s.data ?? [];
            if (list.isEmpty) return const _Muted('لا توجد بيانات بعد');
            return Column(
              children: list
                  .map((p) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.store_rounded, size: 20),
                        title: Text(p['name']?.toString() ?? 'بدون اسم',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text('${p['price'] ?? 0} ج.م'),
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        const _SectionTitle('أحدث المناسبات', Icons.event_rounded, Colors.teal),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: service.getOccasionsStats(),
          builder: (context, s) {
            final list = s.data ?? [];
            if (list.isEmpty) return const _Muted('لا توجد بيانات بعد');
            return Column(
              children: list
                  .take(6)
                  .map((o) => ListTile(
                        dense: true,
                        leading:
                            const Icon(Icons.celebration_rounded, size: 20),
                        title: Text(o['title']?.toString() ?? 'بدون عنوان',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(o['date']?.toString() ?? ''),
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        const _SectionTitle(
            'طلبات الخدمات', Icons.request_page_rounded, Colors.orange),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: service.getServiceRequestsStats(),
          builder: (context, s) {
            final list = s.data ?? [];
            if (list.isEmpty) return const _Muted('لا توجد طلبات');
            return Column(
              children: list
                  .take(6)
                  .map((r) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.assignment_rounded, size: 20),
                        title: Text(r['type']?.toString() ?? 'طلب',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(r['status']?.toString() ?? ''),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _reportRow(
      ThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800))),
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      );
}
