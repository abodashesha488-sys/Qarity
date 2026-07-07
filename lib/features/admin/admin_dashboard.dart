import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
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

  Future<void> _handleAction(int tabIndex, String docId, String action) async {
    final key = '${action}_${tabIndex}_$docId';
    if (_busyActions.contains(key)) return;
    setState(() => _busyActions.add(key));
    try {
      switch (tabIndex) {
        case 0:
          if (action == 'approve') {
            await _adminService.approveNews(docId);
          } else if (action == 'reject') {
            await _adminService.rejectNews(docId);
          } else if (action == 'delete') {
            await _adminService.deleteNews(docId);
          }
          break;
        case 1:
          if (action == 'approve') {
            await _adminService.approveProduct(docId);
          } else if (action == 'reject') {
            await _adminService.rejectProduct(docId);
          } else if (action == 'delete') {
            await _adminService.deleteProduct(docId);
          }
          break;
        case 2:
          if (action == 'approve') {
            await _adminService.approveObituary(docId);
          } else if (action == 'reject') {
            await _adminService.rejectObituary(docId);
          } else if (action == 'delete') {
            await _adminService.deleteObituary(docId);
          }
          break;
        case 3:
          if (action == 'approve') {
            await _adminService.approveOccasion(docId);
          } else if (action == 'reject') {
            await _adminService.rejectOccasion(docId);
          } else if (action == 'delete') {
            await _adminService.deleteOccasion(docId);
          }
          break;
        case 4:
          if (action == 'approve') {
            await _adminService.approveForumPost(docId);
          } else if (action == 'reject') {
            await _adminService.rejectForumPost(docId);
          } else if (action == 'delete') {
            await _adminService.deleteForumPost(docId);
          }
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('تم ${action == 'approve' ? 'الموافقة' : action == 'reject' ? 'الرفض' : action == 'delete' ? 'الحذف' : 'التعديل'} بنجاح'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busyActions.remove(key));
    }
  }

  String _collectionForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'news';
      case 1:
        return 'market_products';
      case 2:
        return 'obituaries';
      case 3:
        return 'occasions';
      case 4:
        return 'forum_posts';
      default:
        return '';
    }
  }

  String _getTitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'الأخبار';
      case 1:
        return 'المنتجات';
      case 2:
        return 'العزاء';
      case 3:
        return 'المناسبات';
      case 4:
        return 'المنتدى';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPending = _pendingCounts.values.fold<int>(0, (p, e) => p + e);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: theme.colorScheme.surface,
          bottom: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            isScrollable: true,
            tabs: [
              Tab(
                child: Row(
                  children: [
                    const Text('الأخبار'),
                    if (_pendingCounts['news'] != null && _pendingCounts['news']! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(8)),
                        child: Text('${_pendingCounts['news']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('المنتجات'),
                    if (_pendingCounts['market_products'] != null && _pendingCounts['market_products']! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(8)),
                        child: Text('${_pendingCounts['market_products']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('العزاء'),
                    if (_pendingCounts['obituaries'] != null && _pendingCounts['obituaries']! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(8)),
                        child: Text('${_pendingCounts['obituaries']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('المناسبات'),
                    if (_pendingCounts['occasions'] != null && _pendingCounts['occasions']! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(8)),
                        child: Text('${_pendingCounts['occasions']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('المنتدى'),
                    if (_pendingCounts['forum_posts'] != null && _pendingCounts['forum_posts']! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(8)),
                        child: Text('${_pendingCounts['forum_posts']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (totalPending > 0)
              Container(
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions_rounded, size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 6),
                    Text('$totalPending منتظر', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.error)),
                  ],
                ),
              ),
            IconButton(onPressed: _loadStats, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        body: Column(
          children: [
            _buildStatsGrid(theme),
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
                children: List.generate(5, (index) => _buildTabContent(theme, index)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildStatsGrid(ThemeData theme) {
    return _isLoadingStats
        ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(height: 72, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          )
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(child: _buildStatChip(theme, 'أخبار', '${_stats['news'] ?? 0}', Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatChip(theme, 'منتجات', '${_stats['market_products'] ?? 0}', Colors.deepPurple)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatChip(theme, 'عزاء', '${_stats['obituaries'] ?? 0}', Colors.indigo)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatChip(theme, 'مناسبات', '${_stats['occasions'] ?? 0}', Colors.teal)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatChip(theme, 'منتدى', '${_stats['forum_posts'] ?? 0}', Colors.brown)),
              ],
            ),
          );
  }

  Widget _buildStatChip(ThemeData theme, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: color)),
          Text(title, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'بحث...',
        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
        suffixIcon: _searchController.text.isNotEmpty ? IconButton(onPressed: () => _searchController.clear(), icon: const Icon(Icons.clear_rounded)) : null,
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
    final isSelected = _selectedFilter == (label == 'الكل' ? 'all' : 'pending');
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = label == 'الكل' ? 'all' : 'pending');
        }
      },
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      selectedColor: theme.colorScheme.primary,
    );
  }

  bool _matchesFilter(Map<String, dynamic> item) {
    if (_selectedFilter != 'pending') return true;
    return item['isApproved'] != true;
  }

  bool _matchesQuery(Map<String, dynamic> item, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    final searchable = [item['title'], item['content'], item['name'], item['providerName'], item['submittedBy'], item['authorName']].whereType<String>().join(' ');
    return searchable.toLowerCase().contains(q);
  }

  Widget _buildTabContent(ThemeData theme, int tabIndex) {
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildItemCard(theme, tabIndex, items[index]),
        );
      },
    );
  }

  Widget _buildItemCard(ThemeData theme, int tabIndex, Map<String, dynamic> item) {
    final isApproved = item['isApproved'] == true;
    final itemLabel = item['title'] ?? item['name'] ?? item['content'] ?? item['providerName'] ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final collection = _collectionForTab(tabIndex);
          await Navigator.pushNamed(
            context,
            AppRoutes.adminDetail,
            arguments: {'collection': collection, 'docId': item['id'] as String, 'item': item},
          );
          if (mounted) setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(itemLabel, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                  _buildStatusBadge(theme, isApproved),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionChip(theme, 'موافقة', Icons.check_rounded, Colors.green, () => _handleAction(tabIndex, item['id'] as String, 'approve'), isLoading: _busyActions.contains('approve_${tabIndex}_${item['id']}')),
                  _buildActionChip(theme, 'رفض', Icons.close_rounded, Colors.orange, () => _handleAction(tabIndex, item['id'] as String, 'reject'), isLoading: _busyActions.contains('reject_${tabIndex}_${item['id']}')),
                  _buildActionChip(theme, 'حذف', Icons.delete_rounded, Colors.red, () => _handleAction(tabIndex, item['id'] as String, 'delete'), isLoading: _busyActions.contains('delete_${tabIndex}_${item['id']}')),
                ],
              )
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildActionChip(ThemeData theme, String label, IconData icon, Color color, VoidCallback onPressed, {bool isLoading = false}) {
    return SizedBox(
      height: 36,
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            )
          : InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: color),
                    if (label.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
                    ],
                  ],
                ),
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
