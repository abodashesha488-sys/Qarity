part of 'admin_dashboard.dart';

// ═══════════════════════════ Reports ═══════════════════════════
class _ReportsPage extends StatefulWidget {
  const _ReportsPage();

  @override
  State<_ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<_ReportsPage> {
  final AdminService _service = AdminService();
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _service.getStatistics();
      final pendingCounts = await _service.fetchPendingCounts();
      final activeUsers = await _service.getActiveUsersCount();
      final topProducts = await _service.getTopProducts(limit: 10);
      final recentOccasions = await _service.getOccasionsStats();
      final serviceRequests = await _service.getServiceRequestsStats();

      if (!mounted) return;
      setState(() {
        _reportData = {
          'stats': stats,
          'pendingCounts': pendingCounts,
          'activeUsers': activeUsers,
          'topProducts': topProducts,
          'recentOccasions': recentOccasions,
          'serviceRequests': serviceRequests,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // عنوان الصفحة
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6F4E37), Color(0xFF8B6347)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.assessment_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'التقارير والإحصائيات',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'عرض شامل لأداء التطبيق',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ملخص عام
                _buildSummaryCards(theme),
                const SizedBox(height: 20),

                // إحصائيات المحتوى
                _buildContentStatsSection(theme),
                const SizedBox(height: 20),

                // إحصائيات السوق
                _buildMarketStatsSection(theme),
                const SizedBox(height: 20),

                // إحصائيات الخدمات الطبية
                _buildMedicalStatsSection(theme),
                const SizedBox(height: 20),

                // أزرار التصدير
                _buildExportButtons(theme),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    final stats = _reportData['stats'] as Map<String, int>? ?? {};
    final pendingCounts =
        _reportData['pendingCounts'] as Map<String, int>? ?? {};
    final activeUsers = _reportData['activeUsers'] as int? ?? 0;
    final totalPending = pendingCounts.values.fold<int>(0, (p, e) => p + e);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ملخص عام',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _SummaryCard(
              title: 'إجمالي المستخدمين',
              value: '${stats['users'] ?? 0}',
              subtitle: 'نشطين: $activeUsers',
              icon: Icons.people_rounded,
              color: Colors.teal,
            ),
            _SummaryCard(
              title: 'بانتظار المراجعة',
              value: '$totalPending',
              subtitle: _buildPendingBreakdown(pendingCounts),
              icon: Icons.pending_actions_rounded,
              color: Colors.orange,
            ),
            _SummaryCard(
              title: 'إجمالي المحتوى',
              value:
                  '${(stats['news'] ?? 0) + (stats['market_products'] ?? 0) + (stats['forum_posts'] ?? 0) + (stats['obituaries'] ?? 0) + (stats['occasions'] ?? 0)}',
              subtitle: 'أخبار + منتجات + مناقشات + عزاء + مناسبات',
              icon: Icons.content_paste_rounded,
              color: Colors.deepPurple,
            ),
            _SummaryCard(
              title: 'الخدمات الطبية',
              value:
                  '${(stats['village_clinics'] ?? 0) + (stats['pharmacies'] ?? 0) + (stats['medical_labs'] ?? 0) + (stats['medical_center_clinics'] ?? 0)}',
              subtitle: 'عيادات + صيدليات + معامل + مركز طبي',
              icon: Icons.local_hospital_rounded,
              color: const Color(0xFF00897B),
            ),
          ],
        ),
      ],
    );
  }

  String _buildPendingBreakdown(Map<String, int> pending) {
    final items = <String>[];
    pending.forEach((key, value) {
      if (value > 0) items.add('$key: $value');
    });
    return items.isEmpty ? 'لا يوجد' : items.take(3).join(' • ');
  }

  Widget _buildContentStatsSection(ThemeData theme) {
    final stats = _reportData['stats'] as Map<String, int>? ?? {};
    final items = <_StatItem>[
      _StatItem('الأخبار', '${stats['news'] ?? 0}', Icons.newspaper_rounded,
          Colors.blue),
      _StatItem('المناسبات', '${stats['occasions'] ?? 0}',
          Icons.celebration_rounded, Colors.teal),
      _StatItem('العزاء', '${stats['obituaries'] ?? 0}',
          Icons.volunteer_activism_rounded, Colors.indigo),
      _StatItem('المنشورات', '${stats['forum_posts'] ?? 0}',
          Icons.forum_rounded, Colors.brown),
      _StatItem('دليل الهاتف', '${stats['phone_directory'] ?? 0}',
          Icons.phone_rounded, Colors.cyan),
      _StatItem('المفقودات', '${stats['lost_items'] ?? 0}',
          Icons.search_rounded, const Color(0xFF5E35B1)),
    ];

    return _buildSection(
      theme,
      'إحصائيات المحتوى',
      Icons.content_paste_rounded,
      Colors.deepPurple,
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: items.map((e) => _StatCard(item: e)).toList(),
      ),
    );
  }

  Widget _buildMarketStatsSection(ThemeData theme) {
    final stats = _reportData['stats'] as Map<String, int>? ?? {};
    final topProducts =
        _reportData['topProducts'] as List<Map<String, dynamic>>? ?? [];
    final items = <_StatItem>[
      _StatItem('المنتجات', '${stats['products'] ?? 0}', Icons.store_rounded,
          Colors.deepPurple),
      _StatItem('المحلات', '${stats['shops'] ?? 0}', Icons.storefront_rounded,
          Colors.amber),
      _StatItem('طلبات الشراء', '${stats['buy_requests'] ?? 0}',
          Icons.shopping_cart_rounded, Colors.green),
      _StatItem('التبرعات', '${stats['donations'] ?? 0}',
          Icons.favorite_rounded, Colors.pink),
      _StatItem('طلبات المتاجر', '${stats['seller_requests'] ?? 0}',
          Icons.storefront_rounded, Colors.orange),
    ];

    return _buildSection(
      theme,
      'إحصائيات السوق',
      Icons.shopping_bag_rounded,
      Colors.deepPurple,
      Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: items.map((e) => _StatCard(item: e)).toList(),
          ),
          if (topProducts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTopProductsList(theme, topProducts),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalStatsSection(ThemeData theme) {
    final stats = _reportData['stats'] as Map<String, int>? ?? {};
    final items = <_StatItem>[
      _StatItem('عيادات القرية', '${stats['village_clinics'] ?? 0}',
          Icons.add_business_rounded, const Color(0xFF00897B)),
      _StatItem('الصيدليات', '${stats['pharmacies'] ?? 0}',
          Icons.local_pharmacy_rounded, const Color(0xFF6F4E37)),
      _StatItem('معامل التحاليل', '${stats['medical_labs'] ?? 0}',
          Icons.science_rounded, const Color(0xFF6A1B9A)),
      _StatItem('عيادات المركز', '${stats['medical_center_clinics'] ?? 0}',
          Icons.local_hospital_rounded, const Color(0xFF00695C)),
      _StatItem('طلبات الدم', '${stats['blood_requests'] ?? 0}',
          Icons.bloodtype_rounded, Colors.red),
      _StatItem('متبرعو الدم', '${stats['blood_donors'] ?? 0}',
          Icons.favorite_rounded, Colors.pink),
    ];

    return _buildSection(
      theme,
      'إحصائيات الخدمات الطبية',
      Icons.local_hospital_rounded,
      const Color(0xFF00897B),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: items.map((e) => _StatCard(item: e)).toList(),
      ),
    );
  }

  Widget _buildTopProductsList(
      ThemeData theme, List<Map<String, dynamic>> products) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('أكثر المنتجات مشاهدة',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          ...products.take(5).map((p) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.store_rounded,
                      size: 18, color: theme.colorScheme.primary),
                ),
                title: Text(p['name']?.toString() ?? 'بدون اسم',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    'السعر: ${p['price'] ?? 0} ج.م • البائع: ${p['sellerName'] ?? ''}'),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${p['views'] ?? 0} مشاهدة',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildExportButtons(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.primary.withValues(alpha: 0.02),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
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
                  child: Icon(Icons.download_rounded,
                      color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تصدير التقارير',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900)),
                      Text('احفظ البيانات بصيغ متعددة',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.table_chart_rounded, size: 18),
                    label: const Text('Excel'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportToJson,
                    icon: const Icon(Icons.code_rounded, size: 18),
                    label: const Text('JSON'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('جاري تطوير ميزة تصدير Excel...'),
          backgroundColor: Color(0xFF6F4E37)),
    );
  }

  Future<void> _exportToJson() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('جاري تطوير ميزة تصدير JSON...'),
          backgroundColor: Color(0xFF6F4E37)),
    );
  }

  Widget _buildSection(
      ThemeData theme, String title, IconData icon, Color color, Widget child) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900, color: color)),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: color, fontSize: 24)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(title,
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: item.color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 24),
            const SizedBox(height: 6),
            Text(
              item.value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: item.color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
