import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart'
    show Excel, CellIndex, CellStyle, HorizontalAlign, TextCellValue;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/promo_placements.dart';
import '../../models/data_models.dart';
import '../../models/promo_model.dart';
import '../../models/village_alert.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../services/alert_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/promo_service.dart';
import '../../services/remote_push_service.dart';
import '../../widgets/promo_host.dart';
import '../../widgets/qurity_app_bar.dart';

part 'admin_dashboard_alerts.dart';
part 'admin_dashboard_broadcast.dart';
part 'admin_dashboard_models.dart';
part 'admin_dashboard_overview.dart';
part 'admin_dashboard_promos.dart';
part 'admin_dashboard_reports.dart';
part 'admin_dashboard_review.dart';
part 'admin_dashboard_users.dart';

/// لوحة تحكم احترافية محسّنة
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  int _reviewNav = 0;

  bool _isLoadingStats = true;
  Map<String, int> _stats = {};
  Map<String, int> _pendingCounts = {};
  final Set<String> _busyActions = {};
  String? _selectedCat;

  static const List<_Cat> _cats = [
    _Cat('news', 'الأخبار', Icons.newspaper_rounded, Colors.blue),
    _Cat('market_products', 'المنتجات', Icons.store_rounded, Colors.deepPurple),
    _Cat('shops', 'المحلات', Icons.storefront_rounded, Colors.amber),
    _Cat('obituaries', 'العزاء', Icons.volunteer_activism_rounded,
        Colors.indigo),
    _Cat('occasions', 'المناسبات', Icons.celebration_rounded, Colors.teal),
    _Cat('forum_posts', 'المنتدى', Icons.forum_rounded, Colors.brown),
    _Cat('seller_requests', 'طلبات المتاجر', Icons.storefront_rounded,
        Colors.orange),
    _Cat('phone_directory', 'دليل الهاتف', Icons.phone_rounded, Colors.cyan),
    _Cat('service_providers', 'دليل الخدمات', Icons.category_rounded,
        Color(0xFF6D4C41)),
    _Cat('lost_items', 'المفقودات', Icons.search_rounded, Color(0xFF5E35B1)),
    _Cat('medical_center_clinics', 'عيادات المركز الخيري',
        Icons.local_hospital_rounded, Color(0xFF00695C)),
    _Cat('village_clinics', 'عيادات القرية', Icons.add_business_rounded,
        Color(0xFF00897B)),
    _Cat('pharmacies', 'الصيدليات', Icons.local_pharmacy_rounded,
        Color(0xFF6F4E37)),
    _Cat('medical_labs', 'معامل التحاليل', Icons.science_rounded,
        Color(0xFF6A1B9A)),
    _Cat('blood_requests', 'طلبات التبرع بالدم', Icons.bloodtype_rounded,
        Colors.red),
    _Cat(
        'blood_donors', 'المتبرعون بالدم', Icons.favorite_rounded, Colors.pink),
  ];

  int get _totalPending => _pendingCounts.values.fold<int>(0, (p, e) => p + e);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadStats();
    _loadPendingCounts();
    unawaited(_adminService.backfillSellerTypes());
  }

  void _onTabChanged() {
    // تحديث عند التبديل بين التبويبات
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _adminService.getStatistics();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadPendingCounts() async {
    try {
      final counts = await _adminService.fetchPendingCounts();
      if (!mounted) return;
      setState(() => _pendingCounts = counts);
    } catch (_) {}
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadStats(), _loadPendingCounts()]);
  }

  Future<void> _refreshDashboard() async {
    await _refreshAll();
    if (!mounted) return;
    setState(() => _reviewNav++);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(
        title: 'لوحة التحكم الإدارية',
        actions: [
          // إشعار العناصر المعلقة
          if (_totalPending > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Badge.count(
                count: _totalPending,
                backgroundColor: Colors.orange,
                child: IconButton(
                  tooltip: '$_totalPending عنصر بانتظار المراجعة',
                  icon: const Icon(Icons.notifications_active_rounded),
                  onPressed: () => _tabController.animateTo(1),
                ),
              ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),
            ),
          // زر التحديث
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: _isLoadingStats
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isLoadingStats ? null : _refreshDashboard,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFF6F4E37),
              indicatorWeight: 3,
              labelColor: const Color(0xFF6F4E37),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: const [
                Tab(
                  icon: Icon(Icons.space_dashboard_rounded, size: 20),
                  text: 'نظرة عامة',
                  height: 50,
                ),
                Tab(
                  icon: Icon(Icons.rule_folder_rounded, size: 20),
                  text: 'المراجعة',
                  height: 50,
                ),
                Tab(
                  icon: Icon(Icons.group_rounded, size: 20),
                  text: 'المستخدمون',
                  height: 50,
                ),
                Tab(
                  icon: Icon(Icons.assessment_rounded, size: 20),
                  text: 'التقارير',
                  height: 50,
                ),
                Tab(
                  icon: Icon(Icons.campaign_rounded, size: 20),
                  text: 'الإعلانات',
                  height: 50,
                ),
                Tab(
                  icon: Icon(Icons.warning_amber_rounded, size: 20),
                  text: 'التنبيهات',
                  height: 50,
                ),
                Tab(
                  icon: Icon(Icons.send_rounded, size: 20),
                  text: 'الإرسال',
                  height: 50,
                ),
              ],
            ),
            ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // منع السحب الجانبي
        children: [
          _OverviewPage(
            stats: _stats,
            pendingCounts: _pendingCounts,
            isLoading: _isLoadingStats,
            totalPending: _totalPending,
            onRefresh: _refreshDashboard,
            onOpenReview: (cat) {
              _tabController.animateTo(1);
              setState(() => _selectedCat = cat);
              _reviewNav = 1 - _reviewNav;
            },
            onOpenUsers: () => _tabController.animateTo(2),
            onOpenReports: () => _tabController.animateTo(3),
            onOpenAlerts: () => _tabController.animateTo(5),
            onOpenBroadcast: () => _tabController.animateTo(6),
          ),
          _ReviewPage(
            key: ValueKey('review_$_reviewNav'),
            cats: _cats,
            selected: _selectedCat ?? _cats.first.collection,
            pendingCounts: _pendingCounts,
            onSelect: (c) => setState(() => _selectedCat = c),
            onAction: _handleAction,
            busyActions: _busyActions,
            onItemChanged: _refreshAll,
            notesProvider: _showAdminNotesDialog,
          ),
          _UsersPage(
            adminService: _adminService,
            currentUid: _auth.currentUser?.uid,
            onUpdated: _refreshAll,
          ),
          const _ReportsPage(),
          _PromosPage(currentUid: _auth.currentUser?.uid),
          const _AlertsControlPage(),
          _BroadcastPage(currentUid: _auth.currentUser?.uid),
        ],
      ),
    );
  }

  // ─────────────────────────── actions ───────────────────────────
  Future<void> _handleAction(
      String collection, String docId, String action) async {
    final key = '${action}_${collection}_$docId';
    if (_busyActions.contains(key)) return;
    setState(() => _busyActions.add(key));
    try {
      if (collection == 'seller_requests') {
        if (action == 'approve') {
          final notes = await _showAdminNotesDialog(context);
          if (notes == null) return;
          await _adminService.approveSellerRequest(docId, notes: notes);
        } else if (action == 'reject') {
          final notes = await _showAdminNotesDialog(context, isReject: true);
          if (notes == null) return;
          await _adminService.rejectSellerRequest(docId, notes: notes);
        } else if (action == 'delete') {
          await _adminService.deleteItem(collection, docId);
        }
      } else {
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
      }
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
              'تم ${action == 'approve' ? 'الموافقة' : action == 'reject' ? 'الرفض' : 'الحذف'} بنجاح'),
          backgroundColor: const Color(0xFF6F4E37),
        ),
      );
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busyActions.remove(key));
    }
  }

  Future<String?> _showAdminNotesDialog(BuildContext context,
      {bool isReject = false}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(isReject ? 'سبب الرفض' : 'ملاحظات (اختياري)'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: isReject ? 'أدخل سبب الرفض...' : 'أضف ملاحظات للمتقدم...',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(
                  context,
                  controller.text.trim().isEmpty
                      ? null
                      : controller.text.trim()),
              child: const Text('تأكيد')),
        ],
      ),
    );
  }
}
