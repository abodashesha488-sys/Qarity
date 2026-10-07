import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart'
    show
        Excel,
        CellIndex,
        CellStyle,
        ExcelColor,
        HorizontalAlign,
        TextCellValue;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/product_categories.dart';
import '../../core/constants/promo_placements.dart';
import '../../core/utils/file_export.dart';
import '../../core/utils/firebase_ts.dart';
import '../../core/utils/user_gender_groups.dart';
import '../../core/utils/xlsx_export.dart';
import '../../models/data_models.dart';
import '../../models/promo_model.dart';
import '../../models/service_provider_model.dart';
import '../../models/village_alert.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../services/alert_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/promo_service.dart';
import '../../services/remote_push_service.dart';
import '../../widgets/edu_kind_mark.dart';
import '../../widgets/promo_host.dart';
import '../../widgets/qurity_app_bar.dart';

part 'admin_dashboard_alerts.dart';
part 'admin_dashboard_broadcast.dart';
part 'admin_dashboard_models.dart';
part 'admin_dashboard_overview.dart';
part 'admin_dashboard_promos.dart';
part 'admin_dashboard_reports.dart';
part 'admin_dashboard_review.dart';
part 'admin_dashboard_review_bulk.dart';
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

  /// عدّادات المعلّقات بمفاتيح **التبويبات**: المجموعات الحقيقية بأسمائها،
  /// والتبويبات المصفّاة بمعرفاتها الوهمية. `_pendingCounts` هي الوجه الحقيقي
  /// وحده الذي تقرأه الشريط العلوي والنظرة العامة والتقارير.
  Map<String, int> _counts = {};

  /// المجموعات الحقيقية التي تُراجع في اللوحة (بلا القائمة الموحّدة الوهمية).
  static List<String> get _realCollections => _cats
      .map((c) => c.realCollection)
      .where((c) => c != kAllPending)
      .toSet()
      .toList(growable: false);

  /// التبويبات المصفّاة تعتمد على مستندات مجموعة قائمة، فجمعها معها يُضاعف
  /// الإجمالي؛ لذلك تُصفّى هنا عند كل جمع أو عرض للمجموعات.
  Map<String, int> get _pendingCounts => {
        for (final key in _realCollections)
          if (_counts[key] != null) key: _counts[key]!
      };

  /// عدّادات أعادت الإذاعة قراءتها بعد قرار واحد. تُدمج فوق نتيجة
  /// `fetchPendingCounts` الكاملة لأن تلك القراءة قد تكون انطلقت قبل القرار
  /// فترجع بعدَه برقم قدمه.
  final Map<String, int> _recounted = {};
  StreamSubscription<String>? _pendingSub;
  final Set<String> _recountInFlight = {};
  final Set<String> _recountAgain = {};
  bool _statsInFlight = false;
  bool _statsAgain = false;
  final Set<String> _busyActions = {};
  String? _selectedCat;

  static final List<_Cat> _cats = [
    _Cat(kAllPending, 'كل المعلّقات', Icons.layers_rounded, AppColors.primary),
    const _Cat('news', 'الأخبار', Icons.newspaper_rounded, Colors.blue),
    const _Cat('market_products', 'المنتجات', Icons.store_rounded, Colors.deepPurple),
    // «المستلزمات الطبية» صفحة في الخدمات الطبية لا مجموعة: مستندات
    // `market_products` بتصنيف واحد، فالتبويب هنا عرض مُصفّى من المنتجات.
    const _Cat('tab_med_supplies', 'المستلزمات الطبية',
        Icons.medical_services_rounded, Color(0xFF0097A7),
        source: 'market_products',
        filterField: 'category',
        filterValues: {kMedicalSuppliesCategory}),
    const _Cat('shops', 'المحلات', Icons.storefront_rounded, Colors.amber),
    // «مطلوب» و«تبرعات» تبويبا سوق القرية: مجموعتان حقيقيتان (`buy_requests`
    // و`donations`) تملكان `isApproved` مثل بقية المحتوى، فمراجعهما هنا هي
    // البوابة الوحيدة لظهورهما للعامة.
    const _Cat('buy_requests', 'المطلوب', Icons.request_quote_rounded,
        Color(0xFF0288D1)),
    const _Cat('donations', 'التبرعات', Icons.redeem_rounded, Color(0xFFE64A19)),
    const _Cat('obituaries', 'العزاء', Icons.volunteer_activism_rounded,
        Colors.indigo),
    const _Cat('occasions', 'المناسبات', Icons.celebration_rounded, Colors.teal),
    const _Cat('forum_posts', 'المنتدى', Icons.forum_rounded, Colors.brown),
    const _Cat('seller_requests', 'طلبات المتاجر', Icons.storefront_rounded,
        Colors.orange),
    const _Cat('phone_directory', 'دليل الهاتف', Icons.phone_rounded, Colors.cyan),
    // دليل الخدمات صفحةٌ لكل فئة؛ والتبويب هنا صفحةٌ كذلك، لا سجل واحد يخلط
    // الحرفيين بالزراعة بالتعليم. كلها `service_providers` بتصفية `category`.
    const _Cat('tab_svc_technicians', 'دليل الحرفيين', Icons.engineering_rounded,
        Color(0xFFEF6C00),
        source: 'service_providers',
        filterField: 'category',
        filterValues: {ServiceCategory.technicians},
        takesRest: true),
    const _Cat('tab_svc_agricultural', 'خدمات زراعية', Icons.agriculture_rounded,
        Color(0xFFAD1457),
        source: 'service_providers',
        filterField: 'category',
        filterValues: {ServiceCategory.agricultural}),
    const _Cat('tab_svc_educational', 'خدمات تعليمية', Icons.school_rounded,
        Color(0xFF1565C0),
        source: 'service_providers',
        filterField: 'category',
        filterValues: {ServiceCategory.educational}),
    const _Cat('lost_items', 'المفقودات', Icons.search_rounded, Color(0xFF5E35B1)),
    const _Cat('village_ads', 'إعلانات القرية', Icons.campaign_rounded,
        Color(0xFF311B92)),
    const _Cat('lawyers', 'سجل المحامين', Icons.gavel_rounded, Color(0xFF006064)),
    const _Cat('legal_consultations', 'الاستشارات القانونية',
        Icons.help_center_rounded, Color(0xFF00838F)),
    const _Cat('medical_center_clinics', 'عيادات المركز الخيري',
        Icons.local_hospital_rounded, Color(0xFF00695C)),
    const _Cat('village_clinics', 'عيادات القرية', Icons.add_business_rounded,
        Color(0xFF00897B)),
    _Cat('pharmacies', 'الصيدليات', Icons.local_pharmacy_rounded,
        AppColors.primary),
    const _Cat('medical_labs', 'معامل التحاليل', Icons.science_rounded,
        Color(0xFF6A1B9A)),
    const _Cat('optical_shops', 'نظارات طبية', Icons.remove_red_eye_rounded,
        Color(0xFF3949AB)),
    const _Cat('blood_requests', 'طلبات التبرع بالدم', Icons.bloodtype_rounded,
        Colors.red),
    const _Cat(
        'blood_donors', 'المتبرعون بالدم', Icons.favorite_rounded, Colors.pink),
  ];

  int get _totalPending => _pendingCounts.values.fold<int>(0, (p, e) => p + e);

  /// بطاقات المراجعة في النظرة العامة تُسمّى **بتبويبات المراجعة** لا بأسماء
  /// المجموعات، حتى تطابق النقرة ما يفتحه التبويب عددًا وقسمًا. مجموعة يقسّمها
  /// تبويباتها تقسيمًا كاملًا (أحدها يحمل «الباقي») تُترك لتبويباتها فلا يتكرّر
  /// مجموعها تحت اسم المجموعة؛ ومجموعة جزئية التصفية (المنتجات ومنها
  /// المستلزمات الطبية) تبقى لأن رقمها أوسع من رقم تبويبه المصفّى.
  Map<String, int> get _reviewTabCounts {
    final partitioned = <String>{
      for (final c in _cats)
        if (c.isVirtual && c.takesRest) c.realCollection
    };
    final out = <String, int>{};
    for (final c in _cats) {
      if (c.isAllPending) continue;
      if (!c.isVirtual && partitioned.contains(c.collection)) continue;
      final count = _counts[c.collection] ?? 0;
      if (count > 0) out[c.collection] = count;
    }
    return out;
  }

  static Map<String, String> get _reviewTabLabels => {
        for (final c in _cats)
          if (!c.isAllPending) c.collection: c.label
      };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadStats();
    _loadPendingCounts();
    // كل قرار إداري — هنا أو في شاشة التفاصيل/التعديل — ينشر مجموعته على هذه
    // الإذاعة، فتُعاد قراءة عدّها وحدها بدل `fetchPendingCounts` العشرين.
    _pendingSub = AdminService.pendingCountEvents.listen(_applyPendingCount);
    unawaited(_backfillSellerTypesOnce());
  }

  /// الترحيل التأسيسي لسellerType يعمل مرة واحدة ناجحة لكل جهاز —
  /// كان يمسح market_products + shops + seller_profiles كاملة عند كل فتح.
  Future<void> _backfillSellerTypesOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('seller_type_backfill_v1') == true) return;
      final ok = await _adminService.backfillSellerTypes();
      if (ok) await prefs.setBool('seller_type_backfill_v1', true);
    } catch (_) {}
  }

  void _onTabChanged() {
    // تحديث عند التبديل بين التبويبات
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
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
      final groups = await _loadGroupCounts();
      if (!mounted) return;
      counts.addAll(groups);
      counts.addAll(_recounted);
      setState(() => _counts = counts);
    } catch (_) {}
  }

  /// عدّادات التبويبات المصفّاة — تُقرأ مع مصدرها في رحلة واحدة لكل مجموعة
  /// (مجموعتان هنا: المنتجات ودليل الخدمات)، وتفشل بالاستثناء لا بالصفر لأن
  /// «صفر» في شارة حيّة تعني «لا معلّقات». `onlySource` يحصر القراءة في
  /// المجموعة التي تغيّرت فعليًا فلا تُعاد قراءة كل المصادر مع كل قرار.
  Future<Map<String, int>> _loadGroupCounts({String? onlySource}) async {
    final bySource = <String, List<_Cat>>{};
    for (final c in _cats) {
      if (!c.isVirtual) continue;
      if (onlySource != null && c.realCollection != onlySource) continue;
      (bySource[c.realCollection] ??= <_Cat>[]).add(c);
    }
    final out = <String, int>{};
    for (final entry in bySource.entries) {
      final cats = entry.value;
      final known = <String>{for (final c in cats) ...?c.filterValues};
      final counts = await _adminService.fetchGroupPendingCounts(
          entry.key, cats.first.filterField!, known.toList(growable: false));
      for (final c in cats) {
        out[c.collection] = c.takesRest
            ? (counts[_kRestGroup] ?? 0)
            : c.filterValues!
                .fold<int>(0, (acc, v) => acc + (counts[v] ?? 0));
      }
    }
    return out;
  }

  /// قرار واحد ⇒ عدّ مجموعة واحدة وكل تبويباتها المصفّاة: الشريط العلوي
  /// ورقائق التبويب وبطاقات النظرة العامة كلها تقرأ `_counts` نفسها فتنعّم
  /// جميعها بـ`setState` واحد. تُعاد القراءة مرة أخرة إن وصل قرار أثناء الجري
  /// (إجراء جماعي على عناصر من نفس المجموعة) وإلا بقي الرقم الذي قرأ قبل آخر
  /// قرار.
  Future<void> _applyPendingCount(String collection) async {
    if (!_cats.any((c) => c.realCollection == collection)) return;
    if (!_recountInFlight.add(collection)) {
      _recountAgain.add(collection);
      return;
    }
    do {
      _recountAgain.remove(collection);
      final Map<String, int> counted;
      try {
        counted = {
          collection: await _adminService.recountPending(collection),
          ...await _loadGroupCounts(onlySource: collection),
        };
      } catch (_) {
        // لا صفر زائف في شارة حيّة — «صفر» تعني «لا معلّقات» فيمضي المراجع دون
        // أن ينظر. يبقى آخر رقم معروف، و«تحديث» السحب أو زر التحديث في المراجعة
        // هو ممرّ الاستعادة لأنه يعيد العدّادات كاملة.
        if (!mounted) return;
        _recountInFlight.remove(collection);
        return;
      }
      if (!mounted) return;
      _recounted.addAll(counted);
      var changed = false;
      for (final entry in counted.entries) {
        if (_counts[entry.key] != entry.value) changed = true;
      }
      if (changed) setState(() => _counts = {..._counts, ...counted});
    } while (_recountAgain.contains(collection));
    _recountInFlight.remove(collection);
  }

  /// الإحصاءات وحدها بعد قرار: عدد المعلّقات تجلبه إذاعة `pendingCountEvents`،
  /// فاستدعاء `fetchPendingCounts` الكامل هنا كان يكلّف عشرين عدًّا لكل ضغطة.
  ///
  /// الدمج ضروري في الإجراء الجماعي: الحلقة تنادي هذه الدالة لكل عنصر، فبدون
  /// الحارس تدفع ثلاثاً وعشرين عدّة لكل عنصر بدل واحدة للدفعة كلها.
  Future<void> _refreshStats() async {
    if (_statsInFlight) {
      _statsAgain = true;
      return;
    }
    _statsInFlight = true;
    try {
      do {
        _statsAgain = false;
        await _loadStats();
      } while (_statsAgain);
    } finally {
      _statsInFlight = false;
    }
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([_loadStats(), _loadPendingCounts()]);
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
                // العنبري رمز الحالة الوسيطة وهو مقصود هنا، أما الحبر فكان
                // البياض الافتراضي (`onError`) فلا يُقرأ فوقه (2.16)؛ الحبر
                // يُثبَّت على الزمردي الداكن الذي يجتاز 5.99 على العنبري.
                backgroundColor: AppColors.warning,
                textColor: AppColors.onWarning,
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
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
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
            reviewTabs: _reviewTabCounts,
            reviewLabels: _reviewTabLabels,
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
            pendingCounts: _counts,
            onSelect: (c) => setState(() => _selectedCat = c),
            onAction: _handleAction,
            busyActions: _busyActions,
            onItemChanged: _refreshStats,
            notesProvider: _showAdminNotesDialog,
          ),
          _UsersPage(
            adminService: _adminService,
            currentUid: _auth.currentUser?.uid,
            onUpdated: _refreshStats,
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
              'تم ${action == 'approve' ? 'الموافقة' : action == 'reject' ? 'الرفض' : 'الحذف'} بنجاح',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
        ),
      );
      _refreshStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          // أرضية الشريط لون ثابت في السمتين بينما حبره الافتراضي في الداكن
          // داكن ⇒ البياض يُثبَّت، والأحمر هو الهادئ لا `Colors.red` الساطع.
          SnackBar(
              content: Text('خطأ: $e',
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: AppColors.error));
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
