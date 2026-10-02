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
                // عنوان الصفحة الموحّد
                const _PageHeader(
                  icon: Icons.assessment_rounded,
                  title: 'التقارير والإحصائيات',
                  subtitle: 'عرض شامل لأداء التطبيق',
                  color: Color(0xFF6F4E37),
                ),
                const SizedBox(height: 20),

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
          // extent ثابت بدل نسبة عرض/ارتفاع: البطاقة تأخذ طولها الفعلي فلا
          // يخرج نص التفصيل خارج إطارها.
          mainAxisExtent: 152,
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
                  '${(stats['village_clinics'] ?? 0) + (stats['pharmacies'] ?? 0) + (stats['medical_labs'] ?? 0) + (stats['optical_shops'] ?? 0) + (stats['medical_center_clinics'] ?? 0)}',
              subtitle: 'عيادات + صيدليات + معامل + نظارات + مركز طبي',
              icon: Icons.local_hospital_rounded,
              color: const Color(0xFF00897B),
            ),
            _SummaryCard(
              title: 'إعلانات القرية',
              value: '${stats['village_ads'] ?? 0}',
              subtitle: 'تجارية + خدمية + إنشائية',
              icon: Icons.campaign_rounded,
              color: const Color(0xFF311B92),
            ),
            _SummaryCard(
              title: 'مستشار القرية',
              value:
                  '${(stats['lawyers'] ?? 0) + (stats['legal_consultations'] ?? 0)}',
              subtitle: 'سجل المحامين + الاستشارات',
              icon: Icons.gavel_rounded,
              color: const Color(0xFF006064),
            ),
          ],
        ),
      ],
    );
  }

  String _buildPendingBreakdown(Map<String, int> pending) {
    final items = pending.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (items.isEmpty) return 'لا يوجد معلّقات';
    // الأسماء العربية فقط — مفتاح المجموعة (market_products) غير مفهوم للمشرف.
    return items.take(3).map((e) => '${_statLabel(e.key)} ${e.value}').join(' • ');
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
      _StatItem('إعلانات القرية', '${stats['village_ads'] ?? 0}',
          Icons.campaign_rounded, const Color(0xFF311B92)),
      _StatItem('سجل المحامين', '${stats['lawyers'] ?? 0}',
          Icons.gavel_rounded, const Color(0xFF006064)),
      _StatItem('الاستشارات', '${stats['legal_consultations'] ?? 0}',
          Icons.help_center_rounded, const Color(0xFF00838F)),
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
        mainAxisExtent: 96,
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
            mainAxisExtent: 96,
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
      _StatItem('نظارات طبية', '${stats['optical_shops'] ?? 0}',
          Icons.remove_red_eye_rounded, const Color(0xFF3949AB)),
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
        mainAxisExtent: 96,
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
            child: Text('أحدث المنتجات الموافَق عليها',
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
                    'السعر: ${p['price'] ?? 0} ج.م • ${p['sellerName'] ?? p['uploadedByName'] ?? 'بائع غير معروف'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${p['likes'] ?? 0} إعجاب',
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
                      Text('ملف فيه كل إحصائيات المحتوى والمعلّقات وأحدث المنتجات',
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

  String get _stamp {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }

  Map<String, dynamic> get _reportPayload => {
        'تاريخ التصدير': DateTime.now().toIso8601String(),
        'الإحصائيات': {
          for (final e in (_reportData['stats'] as Map? ?? {}).cast<String, dynamic>().entries)
            _statLabel(e.key.toString()): e.value
        },
        'بانتظار المراجعة': {
          for (final e in (_reportData['pendingCounts'] as Map? ?? {}).cast<String, dynamic>().entries)
            _statLabel(e.key.toString()): e.value
        },
        'المستخدمون النشطون': _reportData['activeUsers'] ?? 0,
        'أحدث المنتجات': _reportData['topProducts'] ?? [],
        'المناسبات': _reportData['recentOccasions'] ?? [],
        'طلبات الخدمة': _reportData['serviceRequests'] ?? [],
      };

  Future<void> _exportToJson() async {
    if (_reportData.isEmpty) {
      _snack('لا توجد بيانات للتصدير');
      return;
    }
    try {
      final jsonStr = const JsonEncoder.withIndent('  ')
          .convert(_reportPayload);
      await exportFile(
        fileName: 'qarity_report_$_stamp.json',
        mimeType: 'application/json',
        bytes: utf8.encode(jsonStr),
      );
      _snack('تم تصدير التقرير (JSON)');
    } catch (e) {
      _snack('تعذّر التصدير: $e');
    }
  }

  Future<void> _exportToExcel() async {
    if (_reportData.isEmpty) {
      _snack('لا توجد بيانات للتصدير');
      return;
    }
    try {
      final excel = Excel.createExcel();

      // شيت الملخص — مؤشر/قيمة بالأسماء العربية
      final summary = excel['الملخص'];
      _writeRow(summary, 0, ['المؤشر', 'القيمة'], bold: true);
      final stats = (_reportData['stats'] as Map? ?? {}).cast<String, dynamic>();
      final pending =
          (_reportData['pendingCounts'] as Map? ?? {}).cast<String, dynamic>();
      int sum(Map<String, dynamic> m) =>
          m.values.fold<int>(0, (acc, e) => acc + ((e as num?)?.toInt() ?? 0));
      final rows = <List<String>>[
        ['المستخدمون', '${stats['users'] ?? 0}'],
        ['المستخدمون النشطون', '${_reportData['activeUsers'] ?? 0}'],
        ['إجمالي المحتوى', '${sum(stats)}'],
        ['بانتظار المراجعة', '${sum(pending)}'],
        ...stats.entries
            .where((e) => e.key != 'users')
            .map((e) => [_statLabel(e.key), '${e.value}']),
        ...pending.entries
            .where((e) => (e.value as num?)?.toInt() != 0)
            .map((e) => ['بانتظار: ${_statLabel(e.key)}', '${e.value}']),
      ];
      for (int i = 0; i < rows.length; i++) {
        _writeRow(summary, i + 1, rows[i]);
      }
      summary.setColumnWidth(0, 32.0);
      summary.setColumnWidth(1, 16.0);

      // شيت أحدث المنتجات — الإعجابات لا المشاهدات (views حقل الأخبار)
      final products = excel['المنتجات'];
      _writeRow(products, 0, ['المنتج', 'السعر', 'البائع', 'الإعجابات'],
          bold: true);
      final top = (_reportData['topProducts'] as List?)?.cast<Map>();
      if (top != null && top.isNotEmpty) {
        for (int i = 0; i < top.length; i++) {
          final p = top[i];
          _writeRow(products, i + 1, [
            '${p['name'] ?? 'بدون اسم'}',
            '${p['price'] ?? 0}',
            '${p['sellerName'] ?? p['uploadedByName'] ?? ''}',
            '${p['likes'] ?? 0}',
          ]);
        }
        for (int c = 0; c < 4; c++) {
          products.setColumnWidth(c, 24.0);
        }
      } else {
        _writeRow(products, 1, ['لا توجد منتجات', '', '', '']);
      }

      excel.delete('Sheet1');

      final fileBytes = excel.encode();
      if (fileBytes == null) throw Exception('فشل إنشاء ملف Excel');
      await exportFile(
        fileName: 'qarity_report_$_stamp.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        bytes: Uint8List.fromList(fileBytes),
      );
      _snack('تم تصدير التقرير (Excel)');
    } catch (e) {
      _snack('تعذّر التصدير: $e');
    }
  }

  /// ألوان الخلية يجب أن تكون `ExcelColor` — تمرير نص `'#6F4E37'` كان يرمي
  /// TypeError داخل المحاولة فيظهر «خطأ في التصدير» ولا يُنتج ملف.
  void _writeRow(dynamic sheet, int rowIndex, List<String> values,
      {bool bold = false}) {
    for (int c = 0; c < values.length; c++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex));
      cell.value = TextCellValue(values[c]);
      cell.cellStyle = CellStyle(
        bold: bold,
        horizontalAlign: HorizontalAlign.Center,
        fontColorHex: bold ? ExcelColor.white : ExcelColor.black,
        backgroundColorHex:
            bold ? ExcelColor.fromInt(0xFF6F4E37) : ExcelColor.none,
      );
    }
  }

  String _statLabel(String key) {
    const labels = {
      'users': 'المستخدمون',
      'news': 'الأخبار',
      'market_products': 'المنتجات',
      'obituaries': 'التعازي',
      'occasions': 'المناسبات',
      'forum_posts': 'منشورات المنتدى',
      'shops': 'المحلات',
      'service_providers': 'دليل الخدمات',
      'phone_directory': 'دليل الهاتف',
      'lost_items': 'المفقودات',
      'village_ads': 'إعلانات القرية',
      'lawyers': 'سجل المحامين',
      'legal_consultations': 'الاستشارات القانونية',
      'village_clinics': 'عيادات القرية',
      'pharmacies': 'الصيدليات',
      'medical_labs': 'معامل التحاليل',
      'optical_shops': 'نظارات طبية',
      'blood_donors': 'المتبرعون بالدم',
      'blood_requests': 'طلبات الدم',
      'medical_center_clinics': 'عيادات المركز',
      'seller_requests': 'طلبات البائعية',
      'service_requests': 'طلبات الخدمة',
      'buy_requests': 'الطلبات الشرائية',
      'donations': 'التبرعات',
    };
    return labels[key] ?? key;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), backgroundColor: const Color(0xFF6F4E37)),
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
