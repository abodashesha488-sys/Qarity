part of 'admin_dashboard.dart';

/// صفحة النظرة العامة المحسّنة
class _OverviewPage extends StatefulWidget {
  const _OverviewPage({
    required this.stats,
    required this.pendingCounts,
    required this.reviewTabs,
    required this.reviewLabels,
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

  /// عدّادات بطاقات المراجعة بمفاتيح **تبويبات اللوحة** (لا أسماء المجموعات)
  /// مع تسمياتها، حتى تفتح النقرة التبويب الذي يحمل الرقم نفسه.
  final Map<String, int> reviewTabs;
  final Map<String, String> reviewLabels;
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
          // ترويسة الصفحة الموحّدة (شارة المعلّقات تجذب الانتباه للمراجعة)
          _PageHeader(
            icon: Icons.space_dashboard_rounded,
            title: 'نظرة عامة',
            subtitle: '${widget.stats['users'] ?? 0} مستخدم نشط',
            color: AppColors.primary,
            count: widget.totalPending > 0 ? widget.totalPending : null,
            countLabel: 'معلّق',
          ),
          const SizedBox(height: 20),

          // الإحصائيات السريعة
          _QuickStatsGrid(
            stats: widget.stats,
            pendingCounts: widget.pendingCounts,
            totalPending: widget.totalPending,
          ),
          const SizedBox(height: 16),

          // عناصر تحتاج مراجعة
          if (widget.totalPending > 0) ...[
            _PendingReviewSection(
              pendingCounts: widget.reviewTabs,
              labels: widget.reviewLabels,
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

/// شبكة الإحصائيات السريعة — أربع خلايا مدمجة أفقية بدل بطاقات 2×2 كبيرة،
/// فتأخذ النظرة العامة ثلث المساحة التي كانت تستهلكها.
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
    final content = (stats['news'] ?? 0) +
        (stats['market_products'] ?? 0) +
        (stats['forum_posts'] ?? 0) +
        (stats['village_ads'] ?? 0);
    final medical = (stats['village_clinics'] ?? 0) +
        (stats['pharmacies'] ?? 0) +
        (stats['medical_labs'] ?? 0) +
        (stats['optical_shops'] ?? 0) +
        (stats['medical_center_clinics'] ?? 0);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      mainAxisExtent: 88,
      children: [
        _StatCellOverview(
            label: 'مستخدمون',
            value: '${stats['users'] ?? 0}',
            icon: Icons.people_rounded,
            color: Colors.teal),
        _StatCellOverview(
            label: 'محتوى',
            value: '$content',
            icon: Icons.article_rounded,
            color: Colors.deepPurple),
        _StatCellOverview(
            label: 'معلّق',
            value: '$totalPending',
            icon: Icons.pending_actions_rounded,
            color: totalPending > 0 ? AppColors.warning : AppColors.success,
            highlight: totalPending > 0),
        _StatCellOverview(
            label: 'طبي',
            value: '$medical',
            icon: Icons.local_hospital_rounded,
            color: const Color(0xFF00897B)),
      ],
    );
  }
}

/// خلية إحصائية مدمجة: أيقونة صغيرة + رقم بارز + اسم قصير.
class _StatCellOverview extends StatelessWidget {
  const _StatCellOverview({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    // التظليل والحدّ يبقيان على درجة القسم، وأما الرقم والأيقونة فحبرٌ على
    // البطاقة: الرقم بمقاس 19 ووزن 900 فهو «نص كبير» وسقفه 3.0، فدرجة البنفسجي
    // (1.81 على البطاقة الداكنة) تُنار والتركوازي 4.32 يبقى كما هو.
    final ink = AppColors.readableInk(
        color, Theme.of(context).brightness, minRatio: 3.0);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlight ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: color.withValues(alpha: highlight ? 0.45 : 0.22),
            width: highlight ? 1.6 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ink, size: 16),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: ink, fontSize: 19),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// قسم العناصر المعلقة — شرائط مضغوطة بدل صفوف طويلة: كل شريط يحمل
/// اسم **تبويب المراجعة** وعدد معلّقاته، واللمسة تفتح مراجعته مباشرة.
///
/// المفاتيح هنا معرّفات تبويبات (`tab_*` للتصفية) لا أسماء مجموعات، والتسميات
/// مرافقة لها من `_reviewTabLabels` — فلا يظهر رقم تحت اسم لا يفتحه النقر.
class _PendingReviewSection extends StatelessWidget {
  const _PendingReviewSection({
    required this.pendingCounts,
    required this.labels,
    required this.onOpenReview,
  });

  final Map<String, int> pendingCounts;
  final Map<String, String> labels;
  final void Function(String) onOpenReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = pendingCounts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (pending.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.warning.withValues(alpha: 0.3),
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
              AppColors.warning.withValues(alpha: 0.08),
              AppColors.warning.withValues(alpha: 0.03),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // العنبري حبرًا فوق تظليله: درجته الخام 2.16 فلا تُقرأ،
                  // فيُنزلها المحرّك سطوعًا وحده إلى سقف النص العادي.
                  child: Icon(Icons.pending_actions_rounded,
                      color: AppColors.readableInk(
                          AppColors.warning, theme.brightness),
                      size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'عناصر تحتاج مراجعة (${pending.length} قسم)',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onOpenReview(kAllPending),
                  icon: const Icon(Icons.layers_rounded, size: 16),
                  label: const Text('كل المعلّقات'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pending.map((e) {
                final label = labels[e.key] ?? e.key;
                return InkWell(
                  onTap: () => onOpenReview(e.key),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      // أرضية الشريحة تُقرأ من الثيم لا من البياض الخام: البياض
                      // عند 0.6 يجعلها صفراء فاتحة في الداكن فيختفي اسم القسم.
                      color: theme.colorScheme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${e.value}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.onWarning)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// شبكة الإجراءات السريعة — صف واحد من أربع أزرار مدمجة بدل بطاقات 2×2.
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
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'إجراءات سريعة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 74,
          children: [
            // الأسماء هنا حبرٌ بمقاس 11، والدرجات تبقى دلالات أقسامها الخام
            // لأن `_QuickActionCard` ينزاح بها سطوعًا إلى سقف النص العادي وحده.
            _QuickActionCard(
                title: 'مستخدمون',
                icon: Icons.people_rounded,
                color: Colors.teal,
                onTap: onOpenUsers),
            _QuickActionCard(
                title: 'تقارير',
                icon: Icons.insights_rounded,
                color: Colors.deepPurple,
                onTap: onOpenReports),
            _QuickActionCard(
                title: 'تنبيهات',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                onTap: onOpenAlerts),
            _QuickActionCard(
                title: 'إرسال',
                icon: Icons.send_rounded,
                color: Colors.blue,
                onTap: onOpenBroadcast),
          ],
        ),
      ],
    );
  }
}

/// زر إجراء سريع مدمج (أيقونة فوق الاسم).
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
    // التظليل والحدّ يبقيان على درجة القسم، وأما الأيقونة والاسم فحبرٌ بمقاس
    // 11 ووزن 800 فهو نص عادي وسقفه 4.5؛ تُظلم الدرجة في الفاتح وتُنار في
    // الداكن حتى تبلغ النسبة، فيبقى معنى القسم (لونه وتشبّعه) كما هو.
    final ink = AppColors.readableInk(color, Theme.of(context).brightness);
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: ink, size: 20),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// قسم النشاط الحديث
class _RecentActivitySection extends StatefulWidget {
  @override
  State<_RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<_RecentActivitySection> {
  final AdminService _service = AdminService();

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
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getActivityLogStream(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'لا يوجد نشاط بعد',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: items.map((e) => _ActivityTile(entry: e)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = (entry['action'] ?? '').toString();
    final spec = _activitySpec(action);
    final title = (entry['targetTitle'] ?? entry['targetCollection'] ?? '—').toString();
    final collection = (entry['targetCollection'] ?? '').toString();
    final when = _formatWhen(entry['createdAt']);
    // التظليل يبقى على درجة الإجراء، وأما الأيقونة (16px رسومية) فحبرٌ فوق
    // البطاقة وسقفها 3.0، فالدرجات التي دونها في الداكن تُنار وحدها.
    final ink =
        AppColors.readableInk(spec.color, theme.brightness, minRatio: 3.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(spec.icon, color: ink, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${spec.label} • $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  [if (collection.isNotEmpty) collection, if (when.isNotEmpty) when]
                      .join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static ({IconData icon, String label, Color color}) _activitySpec(
      String action) {
    switch (action) {
      case 'approve':
        return (icon: Icons.check_circle_rounded, label: 'موافقة', color: const Color(0xFF2E7D32));
      case 'reject':
        return (icon: Icons.cancel_rounded, label: 'رفض', color: const Color(0xFFE65100));
      case 'delete':
        return (icon: Icons.delete_rounded, label: 'حذف', color: const Color(0xFFC62828));
      case 'publish':
        return (icon: Icons.publish_rounded, label: 'نشر', color: const Color(0xFF1565C0));
      case 'set_role':
        return (icon: Icons.shield_rounded, label: 'تعيين دور', color: const Color(0xFF6A1B9A));
      case 'remove_admin':
        return (icon: Icons.remove_circle_rounded, label: 'إزالة صلاحية', color: const Color(0xFFEF6C00));
      case 'enable_user':
        return (icon: Icons.person_add_rounded, label: 'تفعيل حساب', color: const Color(0xFF00838F));
      case 'disable_user':
        return (icon: Icons.person_remove_rounded, label: 'تعطيل حساب', color: const Color(0xFF616161));
      default:
        return (icon: Icons.history_rounded, label: action.isEmpty ? 'نشاط' : action, color: AppColors.primary);
    }
  }

  static String _formatWhen(dynamic value) {
    final dt = value is Timestamp
        ? value.toDate()
        : (value is DateTime ? value : null);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

