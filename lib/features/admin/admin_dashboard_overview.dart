part of 'admin_dashboard.dart';

/// صفحة النظرة العامة المحسّنة
class _OverviewPage extends StatefulWidget {
  const _OverviewPage({
    required this.stats,
    required this.pendingCounts,
    required this.isLoading,
    required this.totalPending,
    required this.onRefresh,
    required this.onOpenReview,
    required this.onOpenUsers,
    required this.onOpenReports,
    required this.onOpenAlerts,
    required this.onOpenBroadcast,
  });

  final Map<String, int> stats;
  final Map<String, int> pendingCounts;
  final bool isLoading;
  final int totalPending;
  final Future<void> Function() onRefresh;
  final void Function(String cat) onOpenReview;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenBroadcast;

  @override
  State<_OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<_OverviewPage> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة الترحيب
          _WelcomeHeader(
            isLoading: widget.isLoading,
            users: widget.stats['users'] ?? 0,
          ),
          const SizedBox(height: 20),

          // الإحصائيات السريعة
          _QuickStatsGrid(
            stats: widget.stats,
            pendingCounts: widget.pendingCounts,
            totalPending: widget.totalPending,
          ),
          const SizedBox(height: 20),

          const SizedBox(height: 20),

          // عناصر تحتاج مراجعة
          if (widget.totalPending > 0) ...[
            _PendingReviewSection(
              pendingCounts: widget.pendingCounts,
              onOpenReview: widget.onOpenReview,
            ),
            const SizedBox(height: 20),
          ],

          // روابط سريعة
          _QuickActionsGrid(
            onOpenUsers: widget.onOpenUsers,
            onOpenReports: widget.onOpenReports,
            onOpenAlerts: widget.onOpenAlerts,
            onOpenBroadcast: widget.onOpenBroadcast,
          ),
          const SizedBox(height: 20),

          // نشاط حديث
          _RecentActivitySection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// بطاقة الترحيب
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.isLoading, required this.users});
  final bool isLoading;
  final int users;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    String greeting = 'مساء الخير';
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 18) {
      greeting = 'مساء الخير';
    } else {
      greeting = 'مساء الخير';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              const Color(0xFF6F4E37).withValues(alpha: 0.05),
              const Color(0xFF6F4E37).withValues(alpha: 0.02),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF6F4E37),
                    Color(0xFF8B6347),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6F4E37).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.dashboard_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'لوحة تحكم قَرية',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$users مستخدم نشط',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
          ],
        ),
      ),
    );
  }
}

/// شبكة الإحصائيات السريعة
class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid({
    required this.stats,
    required this.pendingCounts,
    required this.totalPending,
  });

  final Map<String, int> stats;
  final Map<String, int> pendingCounts;
  final int totalPending;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCardOverview(
          title: 'المستخدمون',
          value: '${stats['users'] ?? 0}',
          icon: Icons.people_rounded,
          color: Colors.teal,
          trend: '+${stats['users_trend'] ?? 0}',
        ),
        _StatCardOverview(
          title: 'المحتوى',
          value:
              '${(stats['news'] ?? 0) + (stats['market_products'] ?? 0) + (stats['forum_posts'] ?? 0)}',
          icon: Icons.article_rounded,
          color: Colors.deepPurple,
          trend: '+${stats['content_trend'] ?? 0}',
        ),
        _StatCardOverview(
          title: 'بانتظار المراجعة',
          value: '$totalPending',
          icon: Icons.pending_actions_rounded,
          color: totalPending > 0 ? Colors.orange : Colors.green,
          highlight: totalPending > 0,
        ),
        _StatCardOverview(
          title: 'الخدمات الطبية',
          value:
              '${(stats['village_clinics'] ?? 0) + (stats['pharmacies'] ?? 0) + (stats['medical_labs'] ?? 0)}',
          icon: Icons.local_hospital_rounded,
          color: const Color(0xFF00897B),
        ),
      ],
    );
  }
}

/// بطاقة إحصائية (نسخة النظرة العامة)
class _StatCardOverview extends StatelessWidget {
  const _StatCardOverview({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.highlight = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: highlight
              ? color.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: highlight ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: highlight
              ? LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    color.withValues(alpha: 0.08),
                    color.withValues(alpha: 0.03),
                  ],
                )
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (trend != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trend!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// قسم العناصر المعلقة
class _PendingReviewSection extends StatelessWidget {
  const _PendingReviewSection({
    required this.pendingCounts,
    required this.onOpenReview,
  });

  final Map<String, int> pendingCounts;
  final void Function(String) onOpenReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = pendingCounts.entries
        .where((e) => e.value > 0)
        .map((e) => MapEntry(_getLabelForCollection(e.key), e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (pending.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.orange.withValues(alpha: 0.08),
              Colors.orange.withValues(alpha: 0.03),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pending_actions_rounded,
                      color: Colors.orange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عناصر تحتاج مراجعة',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${pending.length} فئة بها محتوى معلق',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...pending.take(5).map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    onTap: () => onOpenReview(_getCollectionForLabel(e.key)),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${e.value}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.key,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded,
                              size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                )),
            if (pending.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => onOpenReview('news'),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('عرض الكل'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLabelForCollection(String collection) {
    const map = {
      'news': 'الأخبار',
      'market_products': 'المنتجات',
      'shops': 'المحلات',
      'obituaries': 'العزاء',
      'occasions': 'المناسبات',
      'forum_posts': 'المنتدى',
      'seller_requests': 'طلبات المتاجر',
      'phone_directory': 'دليل الهاتف',
      'service_providers': 'دليل الخدمات',
      'lost_items': 'المفقودات',
      'medical_center_clinics': 'عيادات المركز',
      'village_clinics': 'عيادات القرية',
      'pharmacies': 'الصيدليات',
      'medical_labs': 'معامل التحاليل',
      'blood_requests': 'طلبات الدم',
      'blood_donors': 'المتبرعون بالدم',
    };
    return map[collection] ?? collection;
  }

  String _getCollectionForLabel(String label) {
    const map = {
      'الأخبار': 'news',
      'المنتجات': 'market_products',
      'المحلات': 'shops',
      'العزاء': 'obituaries',
      'المناسبات': 'occasions',
      'المنتدى': 'forum_posts',
      'طلبات المتاجر': 'seller_requests',
      'دليل الهاتف': 'phone_directory',
      'دليل الخدمات': 'service_providers',
      'المفقودات': 'lost_items',
      'عيادات المركز': 'medical_center_clinics',
      'عيادات القرية': 'village_clinics',
      'الصيدليات': 'pharmacies',
      'معامل التحاليل': 'medical_labs',
      'طلبات الدم': 'blood_requests',
      'المتبرعون بالدم': 'blood_donors',
    };
    return map[label] ?? 'news';
  }
}

/// شبكة الإجراءات السريعة
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onOpenUsers,
    required this.onOpenReports,
    required this.onOpenAlerts,
    required this.onOpenBroadcast,
  });

  final VoidCallback onOpenUsers;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenBroadcast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'إجراءات سريعة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _QuickActionCard(
              title: 'إدارة المستخدمين',
              icon: Icons.people_rounded,
              color: Colors.teal,
              onTap: onOpenUsers,
            ),
            _QuickActionCard(
              title: 'التقارير',
              icon: Icons.insights_rounded,
              color: Colors.deepPurple,
              onTap: onOpenReports,
            ),
            _QuickActionCard(
              title: 'التنبيهات',
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              onTap: onOpenAlerts,
            ),
            _QuickActionCard(
              title: 'الإرسال الجماعي',
              icon: Icons.send_rounded,
              color: Colors.blue,
              onTap: onOpenBroadcast,
            ),
          ],
        ),
      ],
    );
  }
}

/// بطاقة إجراء سريع
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_left_rounded,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// قسم النشاط الحديث
class _RecentActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.history_rounded,
                      color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'النشاط الأخير',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.timeline_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      'سيتم عرض النشاط الأخير هنا',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

