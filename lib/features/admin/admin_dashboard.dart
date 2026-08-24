import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/network/network_info.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  bool _isLoadingStats = true;
  Map<String, int> _stats = {};
  Map<String, int> _pendingCounts = {};
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  final AdminService _adminService = AdminService();
  final Set<String> _busyActions = {};

  static const List<_TabMeta> _tabs = [
    _TabMeta(index: 0, label: 'الأخبار', collection: 'news', icon: Icons.newspaper_rounded, color: Colors.blue),
    _TabMeta(index: 1, label: 'المنتجات', collection: 'market_products', icon: Icons.store_rounded, color: Colors.deepPurple),
    _TabMeta(index: 2, label: 'العزاء', collection: 'obituaries', icon: Icons.volunteer_activism_rounded, color: Colors.indigo),
    _TabMeta(index: 3, label: 'المناسبات', collection: 'occasions', icon: Icons.celebration_rounded, color: Colors.teal),
    _TabMeta(index: 4, label: 'المنتدى', collection: 'forum_posts', icon: Icons.forum_rounded, color: Colors.brown),
    _TabMeta(index: 5, label: 'التقارير', collection: '', icon: Icons.bar_chart_rounded, color: Colors.cyan),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
    _loadStats();
    _loadPendingCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _adminService.getStatistics();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadPendingCounts() async {
    try {
      final counts = await _adminService.fetchPendingCounts();
      if (!mounted) return;
      setState(() => _pendingCounts = counts);
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> _getStreamForTab(int index) {
    switch (index) {
      case 0:
        return _selectedFilter == 'pending' ? _adminService.getPendingNewsStream() : _adminService.getAllNewsStream();
      case 1:
        return _selectedFilter == 'pending' ? _adminService.getPendingProductsStream() : _adminService.getAllProductsStream();
      case 2:
        return _adminService.getPendingObituariesStream();
      case 3:
        return _adminService.getPendingOccasionsStream();
      case 4:
        return _adminService.getPendingForumPostsStream();
      default:
        return const Stream.empty();
    }
  }

  String _getTitle(int tabIndex) {
    for (final t in _tabs) {
      if (t.index == tabIndex) return t.label;
    }
    return '';
  }

  _TabMeta _tabMeta(int index) => _tabs.firstWhere((t) => t.index == index, orElse: () => _tabs.first);

  Widget _buildReportsTab(ThemeData theme) {
    return FutureBuilder<bool>(
      future: NetworkInfo().isConnected,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.data == false) {
          return const Center(child: Text('لا يوجد اتصال بالإنترنت'));
        }
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _adminService.getTopProducts(),
          builder: (context, productsSnapshot) {
            if (productsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            final topProducts = productsSnapshot.data ?? [];

            return FutureBuilder<int>(
              future: _adminService.getActiveUsersCount(),
              builder: (context, usersSnapshot) {
                final activeUsers = usersSnapshot.data ?? 0;

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _adminService.getServiceRequestsStats(),
                  builder: (context, requestsSnapshot) {
                    final requests = requestsSnapshot.data ?? [];

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _adminService.getOccasionsStats(),
                      builder: (context, occasionsSnapshot) {
                        final occasions = occasionsSnapshot.data ?? [];

                        if (topProducts.isEmpty && requests.isEmpty && occasions.isEmpty) {
                          return _buildEmptyState(theme, 'لا توجد إحصائيات كافية بعد');
                        }

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildReportSection(theme, 'المستخدمون النشطون', Icons.people_rounded, '$activeUsers مستخدم', Colors.green),
                            const SizedBox(height: 16),
                            _buildReportSection(theme, 'أكثر المنتجات مشاهدة', Icons.shopping_bag_rounded, '${topProducts.length} منتج', Colors.deepPurple),
                            const SizedBox(height: 8),
                            ...topProducts.map((p) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.store_rounded, size: 20),
                                  title: Text(p['name']?.toString() ?? 'بدون اسم', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: Text('${p['price'] ?? 0} ج.م', style: theme.textTheme.labelSmall),
                                )),
                            const SizedBox(height: 16),
                            _buildReportSection(theme, 'أحدث الطلبات', Icons.request_page_rounded, '${requests.length} طلب', Colors.orange),
                            const SizedBox(height: 8),
                            ...requests.take(5).map((r) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.assignment_rounded, size: 20),
                                  title: Text(r['type']?.toString() ?? 'طلب', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: Text(r['status']?.toString() ?? '', style: theme.textTheme.labelSmall),
                                )),
                            const SizedBox(height: 16),
                            _buildReportSection(theme, 'أحدث المناسبات', Icons.event_rounded, '${occasions.length} مناسبة', Colors.teal),
                            const SizedBox(height: 8),
                            ...occasions.take(5).map((o) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.celebration_rounded, size: 20),
                                  title: Text(o['title']?.toString() ?? 'بدون عنوان', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: Text(o['date']?.toString() ?? '', style: theme.textTheme.labelSmall),
                                )),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReportSection(ThemeData theme, String title, IconData icon, String summary, Color color) {
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
          Expanded(child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
          Text(summary, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _handleAction(int tabIndex, String docId, String action) async {
    final key = '${action}_${tabIndex}_$docId';
    if (_busyActions.contains(key)) return;
    setState(() => _busyActions.add(key));
    try {
      final collection = _tabMeta(tabIndex).collection;
      switch (action) {
        case 'approve':
          await _adminService.approveItem(collection, docId);
          break;
        case 'reject':
          await _adminService.rejectItem(collection, docId);
          break;
        case 'delete':
          await _adminService.deleteItem(collection, docId);
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('تم ${action == 'approve' ? 'الموافقة' : action == 'reject' ? 'الرفض' : 'الحذف'} بنجاح'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busyActions.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPending = _pendingCounts.values.fold<int>(0, (p, e) => p + e);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('لوحة التحكم', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            Text('إدارة المحتوى', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          if (totalPending > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.pending_actions_rounded, size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Text('$totalPending منتظر', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.error)),
                ],
              ),
            ),
          IconButton(
            onPressed: () {
              _loadStats();
              _loadPendingCounts();
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            isScrollable: true,
            tabs: _tabs
                .map((t) => Tab(
                      child: Row(
                        children: [
                          Icon(t.icon, size: 18),
                          const SizedBox(width: 6),
                          Text(t.label),
                          if (t.index != 5 &&
                              _pendingCounts[t.collection] != null &&
                              _pendingCounts[t.collection]! > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(8)),
                              child: Text('${_pendingCounts[t.collection]}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStatsGrid(theme),
          if (_tabController.index != 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(child: _buildSearchField(theme)),
                  const SizedBox(width: 8),
                  _buildFilterChip(theme, 'الكل'),
                  const SizedBox(width: 8),
                  _buildFilterChip(theme, 'معلق'),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (index) => _buildTabContent(theme, index)),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildStatsGrid(ThemeData theme) {
    return _isLoadingStats
        ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(height: 84, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          )
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs
                    .where((t) => t.index != 5)
                    .map((t) {
                      final value = _stats[t.collection] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildStatChip(theme, t.label, '$value', t.color, t.icon),
                      );
                    })
                    .toList(),
              ),
            ),
          );
  }

  Widget _buildStatChip(ThemeData theme, String title, String value, Color color, IconData icon) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: color)),
          Text(title, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'بحث في المحتوى...',
        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(onPressed: () => _searchController.clear(), icon: const Icon(Icons.clear_rounded))
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1.5)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label) {
    final value = label == 'الكل' ? 'all' : 'pending';
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = value);
      },
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
      checkmarkColor: theme.colorScheme.onPrimary,
    );
  }

  bool _matchesFilter(Map<String, dynamic> item) {
    if (_selectedFilter != 'pending') return true;
    return item['isApproved'] != true;
  }

  bool _matchesQuery(Map<String, dynamic> item, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    final searchable = [
      item['title'],
      item['content'],
      item['name'],
      item['providerName'],
      item['submittedBy'],
      item['authorName'],
    ].whereType<String>().join(' ');
    return searchable.toLowerCase().contains(q);
  }

  Widget _buildTabContent(ThemeData theme, int tabIndex) {
    if (tabIndex == 5) return _buildReportsTab(theme);
    return FutureBuilder<bool>(
      future: NetworkInfo().isConnected,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.data == false) {
          return const Center(child: Text('لا يوجد اتصال بالإنترنت'));
        }
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getStreamForTab(tabIndex),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            final query = _searchController.text.trim().toLowerCase();
            List<Map<String, dynamic>> items = snapshot.data ?? [];
            items = items.where((item) => _matchesFilter(item) && _matchesQuery(item, query)).toList();

            if (items.isEmpty) return _buildEmptyState(theme, _getTitle(tabIndex));
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildItemCard(theme, tabIndex, items[index]),
            );
          },
        );
      },
    );
  }

  String? _itemImage(Map<String, dynamic> item) {
    if (item['imageUrls'] is List && (item['imageUrls'] as List).isNotEmpty) {
      final first = (item['imageUrls'] as List).first;
      if (first is String && first.isNotEmpty) return first;
    }
    if (item['imageUrl'] is String && (item['imageUrl'] as String).isNotEmpty) return item['imageUrl'] as String;
    return null;
  }

  Widget _buildItemCard(ThemeData theme, int tabIndex, Map<String, dynamic> item) {
    final isApproved = item['isApproved'] == true;
    final itemLabel = item['title'] ?? item['name'] ?? item['content'] ?? item['providerName'] ?? '';
    final accent = _tabMeta(tabIndex).color;
    final image = _itemImage(item);
    final collection = _tabMeta(tabIndex).collection;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(
            context,
            AppRoutes.adminDetail,
            arguments: {'collection': collection, 'docId': item['id'] as String, 'item': item},
          );
          if (mounted) setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        image,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(accent),
                      ),
                    )
                  else
                    _placeholder(accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemLabel.toString(),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildStatusBadge(theme, isApproved),
                            const Spacer(),
                            _buildActionIcon(theme, Icons.edit_rounded, Colors.blueGrey, () async {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.adminEdit,
                                arguments: {'collection': collection, 'docId': item['id'] as String, 'item': item},
                              );
                              if (mounted) setState(() {});
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      theme,
                      'موافقة',
                      Icons.check_rounded,
                      Colors.green,
                      () => _handleAction(tabIndex, item['id'] as String, 'approve'),
                      isLoading: _busyActions.contains('approve_${tabIndex}_${item['id']}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      theme,
                      'رفض',
                      Icons.close_rounded,
                      Colors.orange,
                      () => _handleAction(tabIndex, item['id'] as String, 'reject'),
                      isLoading: _busyActions.contains('reject_${tabIndex}_${item['id']}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionIcon(
                    theme,
                    Icons.delete_rounded,
                    Colors.red,
                    () => _handleAction(tabIndex, item['id'] as String, 'delete'),
                    isLoading: _busyActions.contains('delete_${tabIndex}_${item['id']}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 220.ms).slideY(begin: 0.05);
  }

  Widget _placeholder(Color accent) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.article_rounded, color: accent),
      );

  Widget _buildActionButton(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 40,
      child: isLoading
          ? Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color)))
          : InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionIcon(ThemeData theme, IconData icon, Color color, VoidCallback onPressed, {bool isLoading = false}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: isLoading
          ? Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color)))
          : InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, bool isApproved) {
    final text = isApproved ? 'موافق عليه' : 'معلق';
    final color = isApproved ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _TabMeta {
  final int index;
  final String label;
  final String collection;
  final IconData icon;
  final Color color;

  const _TabMeta({
    required this.index,
    required this.label,
    required this.collection,
    required this.icon,
    required this.color,
  });
}
