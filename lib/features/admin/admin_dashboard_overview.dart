part of 'admin_dashboard.dart';

// ═══════════════════════════ Overview ═══════════════════════════
class _OverviewPage extends StatelessWidget {
  const _OverviewPage({
    required this.stats,
    required this.pendingCounts,
    required this.isLoading,
    required this.totalPending,
    required this.onOpenReview,
    required this.onOpenUsers,
    required this.onOpenReports,
  });

  final Map<String, int> stats;
  final Map<String, int> pendingCounts;
  final bool isLoading;
  final int totalPending;
  final void Function(String cat) onOpenReview;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomeHeader(isLoading: isLoading, users: stats['users'] ?? 0),
          const SizedBox(height: 16),
          if (totalPending > 0)
            _PendingAlert(
                    count: totalPending, onTap: () => onOpenReview('news'))
                .animate()
                .fadeIn()
                .slideY(begin: 0.1),
          const SizedBox(height: 16),
          Text('الإحصائيات',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    _StatCard(
                        label: 'المستخدمون',
                        value: stats['users'] ?? 0,
                        icon: Icons.people_rounded,
                        color: Colors.teal,
                        onTap: onOpenUsers),
                    _StatCard(
                        label: 'الأخبار',
                        value: stats['news'] ?? 0,
                        icon: Icons.newspaper_rounded,
                        color: Colors.blue,
                        onTap: () => onOpenReview('news')),
                    _StatCard(
                        label: 'المنتجات',
                        value: stats['market_products'] ?? 0,
                        icon: Icons.store_rounded,
                        color: Colors.deepPurple,
                        onTap: () => onOpenReview('market_products')),
                    _StatCard(
                        label: 'المنشورات',
                        value: stats['forum_posts'] ?? 0,
                        icon: Icons.forum_rounded,
                        color: Colors.brown,
                        onTap: () => onOpenReview('forum_posts')),
                    _StatCard(
                        label: 'العزاء',
                        value: stats['obituaries'] ?? 0,
                        icon: Icons.volunteer_activism_rounded,
                        color: Colors.indigo,
                        onTap: () => onOpenReview('obituaries')),
                    _StatCard(
                        label: 'المناسبات',
                        value: stats['occasions'] ?? 0,
                        icon: Icons.celebration_rounded,
                        color: Colors.teal,
                        onTap: () => onOpenReview('occasions')),
                  ],
                ),
          const SizedBox(height: 16),
          Text('المراجعة السريعة',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _AdminDashboardScreenState._cats)
                ActionChip(
                  avatar: Icon(c.icon,
                      size: 16,
                      color: (pendingCounts[c.collection] ?? 0) > 0
                          ? Colors.red
                          : c.color),
                  label: Text(c.label),
                  backgroundColor: (pendingCounts[c.collection] ?? 0) > 0
                      ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  onPressed: () => onOpenReview(c.collection),
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenReports,
            icon: const Icon(Icons.insights_rounded),
            label: const Text('عرض التقارير والإحصائيات'),
          ),
          const SizedBox(height: 24),
          _ActivityPreview(),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.isLoading, required this.users});
  final bool isLoading;
  final int users;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مرحباً بك 👋',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('إدارة كاملة لمحتوى القرية في مكان واحد',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingAlert extends StatelessWidget {
  const _PendingAlert({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.pending_actions_rounded,
                  color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text('لديك $count عنصر بانتظار المراجعة والموافقة',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onErrorContainer)),
              ),
              Icon(Icons.chevron_left_rounded, color: theme.colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              Text('$value',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900, color: color)),
              Text(label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('آخر النشاطات',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: AdminService().getActivityLogStream(limit: 6),
          builder: (context, snapshot) {
            final log = snapshot.data ?? [];
            if (log.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا يوجد نشاط بعد',
                    style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: log
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.3))),
                          leading: Icon(_actionIcon(e['action']),
                              color: _actionColor(e['action'], theme)),
                          title: Text(
                              '${_actionLabel(e['action'])}: ${e['targetTitle'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  static IconData _actionIcon(dynamic action) {
    switch (action) {
      case 'approve':
        return Icons.check_circle_rounded;
      case 'reject':
        return Icons.cancel_rounded;
      case 'delete':
        return Icons.delete_rounded;
      case 'publish':
        return Icons.publish_rounded;
      case 'set_role':
      case 'remove_admin':
        return Icons.shield_rounded;
      case 'enable_user':
        return Icons.toggle_on_rounded;
      case 'disable_user':
        return Icons.toggle_off_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  static Color _actionColor(dynamic action, ThemeData theme) {
    switch (action) {
      case 'approve':
      case 'publish':
        return Colors.green;
      case 'reject':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  static String _actionLabel(dynamic action) {
    switch (action) {
      case 'approve':
        return 'موافقة';
      case 'reject':
        return 'رفض';
      case 'delete':
        return 'حذف';
      case 'publish':
        return 'نشر';
      case 'set_role':
        return 'تغيير دور';
      case 'remove_admin':
        return 'إزالة إدارة';
      case 'enable_user':
        return 'تفعيل حساب';
      case 'disable_user':
        return 'تعطيل حساب';
      default:
        return '$action';
    }
  }
}
