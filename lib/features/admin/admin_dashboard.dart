import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/promo_placements.dart';
import '../../models/data_models.dart';
import '../../models/promo_model.dart';
import '../../models/service_provider_model.dart';
import '../../models/village_alert.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../services/alert_service.dart';
import '../../services/app_update_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/promo_service.dart';
import '../../widgets/promo_host.dart';
import '../../widgets/qurity_app_bar.dart';

part 'admin_dashboard_alerts.dart';
part 'admin_dashboard_models.dart';
part 'admin_dashboard_overview.dart';
part 'admin_dashboard_promos.dart';
part 'admin_dashboard_reports.dart';
part 'admin_dashboard_review.dart';
part 'admin_dashboard_users.dart';
part 'admin_dashboard_version.dart';

/// لوحة تحكم عصرية — أربع وجهات: نظرة عامة، المراجعة، المستخدمون، التقارير.
/// الملف مقسّم إلى `part` files حسب الصفحة لتسهيل الصيانة.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _navIndex = 0;
  int _reviewNav = 0; // used to force rebuild of review page

  bool _isLoadingStats = true;
  Map<String, int> _stats = {};
  Map<String, int> _pendingCounts = {};
  final Set<String> _busyActions = {};

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
    _Cat('lost_items', 'المفقودات', Icons.search_rounded,
        Color(0xFF5E35B1)),
    _Cat('medical_center_clinics', 'عيادات المركز الخيري',
        Icons.local_hospital_rounded, Color(0xFF00695C)),
    _Cat('village_clinics', 'عيادات القرية', Icons.add_business_rounded,
        Color(0xFF00897B)),
    _Cat('pharmacies', 'الصيدليات', Icons.local_pharmacy_rounded, Color(0xFF6F4E37)),
    _Cat('medical_labs', 'معامل التحاليل', Icons.science_rounded,
        Color(0xFF6A1B9A)),
    _Cat('blood_requests', 'طلبات التبرع بالدم', Icons.bloodtype_rounded,
        Colors.red),
    _Cat('blood_donors', 'المتبرعون بالدم', Icons.favorite_rounded,
        Colors.pink),
  ];

  int get _totalPending => _pendingCounts.values.fold<int>(0, (p, e) => p + e);

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadPendingCounts();
    // إصلاح تأسيسي للمنتجات القديمة غير المصنّفة بنوع بائع.
    unawaited(_adminService.backfillSellerTypes());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QurityAppBar(
        title: 'لوحة التحكم • ${_navTitles[_navIndex]}',
        actions: [
          if (_totalPending > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Badge.count(
                count: _totalPending,
                backgroundColor: Theme.of(context).colorScheme.error,
                child: IconButton(
                  tooltip: 'عناصر بانتظار المراجعة',
                  icon: const Icon(Icons.notifications_active_rounded),
                  onPressed: () => setState(() {
                    _navIndex = 1;
                    _reviewNav = 1;
                  }),
                ),
              ),
            ),
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _refreshAll();
              setState(() => _reviewNav = 1 - _reviewNav);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _OverviewPage(
            stats: _stats,
            pendingCounts: _pendingCounts,
            isLoading: _isLoadingStats,
            totalPending: _totalPending,
            onOpenReview: (cat) => setState(() {
              _navIndex = 1;
              _selectedCat = cat;
              _reviewNav = 1 - _reviewNav;
            }),
            onOpenUsers: () => setState(() => _navIndex = 2),
            onOpenReports: () => setState(() => _navIndex = 3),
            onOpenAlerts: () => setState(() => _navIndex = 5),
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
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'نظرة عامة'),
          NavigationDestination(
              icon: Icon(Icons.rule_folder_outlined),
              selectedIcon: Icon(Icons.rule_folder_rounded),
              label: 'المراجعة'),
          NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group_rounded),
              label: 'المستخدمون'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'التقارير'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'الإعلانات'),
          NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined),
              selectedIcon: Icon(Icons.warning_amber_rounded),
              label: 'التنبيهات'),
        ],
      ),
    );
  }

  static const List<String> _navTitles = [
    'نظرة عامة على المنصة',
    'مراجعة المحتوى والطلبات',
    'إدارة المستخدمين والأدوار',
    'تقارير وإحصائيات',
    'الإعلانات الدعائية المنبثقة',
    'التنبيهات العاجلة',
  ];

  String? _selectedCat;

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
