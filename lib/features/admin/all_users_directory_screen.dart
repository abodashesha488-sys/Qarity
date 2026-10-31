import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/file_export.dart';
import '../../core/utils/firebase_ts.dart';
import '../../core/utils/launch_link.dart';
import '../../core/utils/user_gender_groups.dart';
import '../../core/utils/xlsx_export.dart';
import '../../services/admin_service.dart';
import '../../widgets/qurity_app_bar.dart';

/// شاشة السجل الشامل لكامل المستخدمين:
/// تتيح فرزاً حراً مباشراً لكافة أعضاء القرية حسب تاريخ التسجيل، الاسم، أو التصنيف،
/// مع تصفية متعددة، وبحث فوري، وإمكانية تعديل الأدوار وإدارة الحسابات وتصدير البيانات.
class AllUsersDirectoryScreen extends StatefulWidget {
  const AllUsersDirectoryScreen({
    super.key,
    this.adminService,
    this.currentUid,
    this.onUpdated,
  });

  final AdminService? adminService;
  final String? currentUid;
  final VoidCallback? onUpdated;

  @override
  State<AllUsersDirectoryScreen> createState() =>
      _AllUsersDirectoryScreenState();
}

class _AllUsersDirectoryScreenState extends State<AllUsersDirectoryScreen> {
  late final AdminService _adminService =
      widget.adminService ?? AdminService();
  late final String _currentUid = widget.currentUid ??
      FirebaseAuth.instance.currentUser?.uid ??
      '';

  final TextEditingController _searchController = TextEditingController();

  // أنواع الترتيب:
  // join_newest: الأحدث تسجيلاً
  // join_oldest: الأقدم تسجيلاً
  // name_asc: الاسم (أ - ي)
  // name_desc: الاسم (ي - أ)
  // role: التصنيف والرتبة
  // login_newest: آخر تسجيل دخول
  String _sortBy = 'join_newest';

  // فلتر الدور
  String _roleFilter = 'all';

  // فلتر النوع
  String _genderFilter = 'all';

  // وضع العرض: detailed (بطاقات مفصلة بتواريخ التسجيل) أو compact (مدمجة)
  bool _isCompactView = false;
  List<Map<String, dynamic>> _visibleUsers = [];

  late final Stream<List<Map<String, dynamic>>> _usersStream =
      _adminService.getAllUsersStream();

  static const _roleOptions = <String, (String, Color, IconData)>{
    'user': ('مستخدم', Colors.teal, Icons.person_rounded),
    'seller': ('بائع', Colors.deepPurple, Icons.store_rounded),
    'moderator': ('مشرف', Colors.orange, Icons.verified_user_rounded),
    'medical_admin': (
      'مدير المركز الطبي',
      Color(0xFF00897B),
      Icons.medical_services_rounded
    ),
    'agricultural_admin': (
      'مدير الخدمات الزراعية',
      Color(0xFF558B2F),
      Icons.agriculture_rounded
    ),
    'legal_admin': (
      'أدمن الاستشارات القانونية',
      Color(0xFF2E7D32),
      Icons.gavel_rounded
    ),
    'heritage_admin': (
      'أدمن التراث',
      Color(0xFF8D6E63),
      Icons.auto_stories_rounded
    ),
    'assistant_admin': ('أدمن مساعد', Color(0xFF6A1B9A), Icons.shield_rounded),
    'admin': (
      'مدير عام',
      Color(0xFF1565C0),
      Icons.admin_panel_settings_rounded
    ),
  };

  static const _roleFilters = <(String, String)>[
    ('all', 'الكل'),
    ('admin_group', 'المسؤولون والمدراء'),
    ('seller', 'البائعون'),
    ('user', 'مستخدمون عاديون'),
    ('disabled', 'المعطلون'),
  ];

  static const _genderFilters = <(String, String)>[
    ('all', 'الكل'),
    (kGenderGroupMale, 'رجال'),
    (kGenderGroupFemale, 'نساء'),
    (kGenderGroupNone, 'بلا نوع'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _compareUsers(Map<String, dynamic> a, Map<String, dynamic> b) {
    switch (_sortBy) {
      case 'join_newest':
        final da = signupAt(a);
        final db = signupAt(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      case 'join_oldest':
        final da = signupAt(a);
        final db = signupAt(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      case 'name_asc':
        return (a['name'] ?? '')
            .toString()
            .compareTo((b['name'] ?? '').toString());
      case 'name_desc':
        return (b['name'] ?? '')
            .toString()
            .compareTo((a['name'] ?? '').toString());
      case 'role':
        final rankCompare = userRoleRank((a['role'] ?? 'user').toString())
            .compareTo(userRoleRank((b['role'] ?? 'user').toString()));
        if (rankCompare != 0) return rankCompare;
        final da = signupAt(a);
        final db = signupAt(b);
        if (da != null && db != null) return db.compareTo(da);
        return 0;
      case 'login_newest':
        final la = lastLoginAt(a);
        final lb = lastLoginAt(b);
        if (la == null && lb == null) return 0;
        if (la == null) return 1;
        if (lb == null) return -1;
        return lb.compareTo(la);
      default:
        final da = signupAt(a);
        final db = signupAt(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'غير محدد';
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d · $h:$min';
  }

  String get _sortTitle {
    switch (_sortBy) {
      case 'join_newest':
        return 'تاريخ التسجيل (الأحدث أولاً)';
      case 'join_oldest':
        return 'تاريخ التسجيل (الأقدم أولاً)';
      case 'name_asc':
        return 'الاسم أبجدياً (أ - ي)';
      case 'name_desc':
        return 'الاسم أبجدياً (ي - أ)';
      case 'role':
        return 'التصنيف / الرتبة (المسؤولون أولاً)';
      case 'login_newest':
        return 'آخر تسجيل دخول';
      default:
        return 'تاريخ التسجيل';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: QurityAppBar(
        title: 'سجل المستخدمين الشامل',
        actions: [
          IconButton(
            icon: Icon(
              _isCompactView
                  ? Icons.view_agenda_rounded
                  : Icons.view_headline_rounded,
            ),
            tooltip: _isCompactView ? 'عرض تفصيلي' : 'عرض مدمج',
            onPressed: () =>
                setState(() => _isCompactView = !_isCompactView),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'تصدير القائمة الحالية',
            onSelected: (kind) => _exportVisible(kind),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_rounded, color: Colors.green),
                    SizedBox(width: 8),
                    Text('تصدير Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.description_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('تصدير CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code_rounded, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('تصدير JSON'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];

          // حساب الأرقام التسلسلية الثابتة حسب تاريخ الانضمام
          final sortedForSerial = List<Map<String, dynamic>>.from(all)
            ..sort((a, b) {
              final da = signupAt(a);
              final db = signupAt(b);
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });
          final serialMap = <String, int>{};
          for (int i = 0; i < sortedForSerial.length; i++) {
            serialMap[sortedForSerial[i]['id'] as String] = i + 1;
          }
          for (final u in all) {
            u['_serial'] = serialMap[u['id'] as String] ?? 0;
          }

          final q = _searchController.text.trim().toLowerCase();
          final filtered = all.where((u) {
            final role = (u['role'] ?? 'user').toString();
            final off = u['isActive'] == false;

            // فلتر الدور
            if (_roleFilter == 'disabled' && !off) return false;
            if (_roleFilter == 'admin_group') {
              const adminRoles = [
                'admin',
                'assistant_admin',
                'medical_admin',
                'agricultural_admin',
                'legal_admin',
                'heritage_admin',
                'moderator',
              ];
              if (!adminRoles.contains(role)) return false;
            } else if (_roleFilter == 'seller' && role != 'seller') {
              return false;
            } else if (_roleFilter == 'user' && role != 'user') {
              return false;
            }

            // فلتر النوع
            if (!genderFilterMatches(_genderFilter, u)) return false;

            // فلتر البحث
            if (q.isNotEmpty) {
              final name = (u['name'] ?? '').toString().toLowerCase();
              final email = (u['email'] ?? '').toString().toLowerCase();
              final phone = (u['phone'] ?? '').toString().toLowerCase();
              final serial = (u['_serial'] ?? '').toString();
              return name.contains(q) ||
                  email.contains(q) ||
                  phone.contains(q) ||
                  serial == q;
            }
            return true;
          }).toList();

          // الترتيب الحر المباشر
          filtered.sort(_compareUsers);
          _visibleUsers = filtered;

          return Column(
            children: [
              _buildControlPanel(theme, all.length, filtered.length),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyView(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final u = filtered[i];
                          return _isCompactView
                              ? _buildCompactUserCard(theme, u, i + 1)
                              : _buildDetailedUserCard(theme, u, i + 1);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlPanel(
      ThemeData theme, int totalCount, int visibleCount) {
    final hasActiveFilter = _searchController.text.isNotEmpty ||
        _roleFilter != 'all' ||
        _genderFilter != 'all';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط البحث المباشر
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم، البريد، الهاتف، أو الرقم...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchController.clear()),
                    )
                  : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // شريط الترتيب والتصفية السريعة
          Row(
            children: [
              // زر اختيار الترتيب
              Expanded(
                child: PopupMenuButton<String>(
                  initialValue: _sortBy,
                  onSelected: (v) => setState(() => _sortBy = v),
                  itemBuilder: (ctx) => [
                    _buildSortItem('join_newest', 'تاريخ التسجيل (الأحدث أولاً)',
                        Icons.schedule_rounded),
                    _buildSortItem('join_oldest', 'تاريخ التسجيل (الأقدم أولاً)',
                        Icons.history_rounded),
                    _buildSortItem('name_asc', 'الاسم أبجدياً (أ - ي)',
                        Icons.sort_by_alpha_rounded),
                    _buildSortItem('name_desc', 'الاسم أبجدياً (ي - أ)',
                        Icons.sort_by_alpha_rounded),
                    _buildSortItem('role', 'التصنيف / الرتبة (المسؤولون أولاً)',
                        Icons.workspace_premium_rounded),
                    _buildSortItem('login_newest', 'آخر تسجيل دخول',
                        Icons.login_rounded),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _sortTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // زر تصفية النوع
              PopupMenuButton<String>(
                initialValue: _genderFilter,
                onSelected: (v) => setState(() => _genderFilter = v),
                itemBuilder: (ctx) => _genderFilters
                    .map((g) => PopupMenuItem(
                          value: g.$1,
                          child: Text(g.$2),
                        ))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: _genderFilter != 'all'
                        ? theme.colorScheme.secondary.withValues(alpha: 0.12)
                        : null,
                    border: Border.all(
                      color: _genderFilter != 'all'
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wc_rounded,
                        size: 17,
                        color: _genderFilter != 'all'
                            ? theme.colorScheme.secondary
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _genderFilter == 'all'
                            ? 'النوع'
                            : (_genderFilter == kGenderGroupMale
                                ? 'رجال'
                                : 'نساء'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _genderFilter != 'all'
                              ? theme.colorScheme.secondary
                              : null,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18),
                    ],
                  ),
                ),
              ),

              if (hasActiveFilter) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_alt_off_rounded,
                      color: AppColors.error),
                  tooltip: 'مسح الفلاتر والبحث',
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _roleFilter = 'all';
                      _genderFilter = 'all';
                    });
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // شرائط تصنيف الرتب
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final rf in _roleFilters)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(rf.$2),
                      selected: _roleFilter == rf.$1,
                      onSelected: (_) => setState(() => _roleFilter = rf.$1),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _roleFilter == rf.$1
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // سطر الملخص والإحصاء
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'المعروض: $visibleCount من أصل $totalCount مستخدم',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'الترتيب: $_sortTitle',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(
      String value, String title, IconData icon) {
    final isSelected = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }

  // ── بطاقة المستخدم المفصلة (Detailed View) ─────────────────────────
  Widget _buildDetailedUserCard(
      ThemeData theme, Map<String, dynamic> u, int displayIndex) {
    final uid = (u['id'] ?? '').toString();
    final role = (u['role'] ?? 'user').toString();
    final opt = _roleOptions[role] ?? _roleOptions['user']!;
    final name = (u['name'] ?? 'بدون اسم').toString();
    final email = (u['email'] ?? '').toString();
    final phone = (u['phone'] ?? '').toString();
    final photoUrl = (u['photoUrl'] ?? '').toString();
    final disabled = u['isActive'] == false;
    final isSelf = uid == _currentUid;
    final serial = u['_serial'] ?? displayIndex;
    final joinDate = signupAt(u);
    final lastLogin = lastLoginAt(u);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: disabled
              ? Colors.red.withValues(alpha: 0.45)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: disabled ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showUserDetailsSheet(u),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الرأس: الرقم، الصورة، الاسم، والرتبة
              Row(
                
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: opt.$2.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: opt.$2.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '#$serial',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        color: opt.$2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: opt.$2.withValues(alpha: 0.14),
                    backgroundImage: photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? Icon(opt.$3, color: opt.$2, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$name${isSelf ? ' (أنت)' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (role == 'admin') ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.stars_rounded,
                                  color: Colors.amber, size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _statusChip(opt.$1, opt.$2),
                            _statusChip(
                              userGenderBadgeLabel(u),
                              Colors.blueGrey,
                            ),
                            if (disabled)
                              _statusChip('معطّل', AppColors.error),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.manage_accounts_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'إدارة وتعديل الصلاحيات',
                    onPressed: () => _manageUser(u),
                  ),
                ],
              ),
              const Divider(height: 18),

              // بيانات الاتصال: البريد والهاتف
              if (email.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 15, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: email));
                          _snack('تم نسخ البريد الإلكتروني');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.copy_rounded,
                              size: 14,
                              color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),

              if (phone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 15, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => launchPhoneCall(phone),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text('اتصال',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // شريط التواريخ الحقيقي: تاريخ التسجيل وتاريخ آخر تسجيل دخول
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded,
                        size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      'سجل: ${_formatDate(joinDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (lastLogin != null) ...[
                      Icon(Icons.access_time_rounded,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'دخول: ${_formatDate(lastLogin)}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── بطاقة المستخدم المدمجة (Compact View) ───────────────────────────
  Widget _buildCompactUserCard(
      ThemeData theme, Map<String, dynamic> u, int displayIndex) {
    final uid = (u['id'] ?? '').toString();
    final role = (u['role'] ?? 'user').toString();
    final opt = _roleOptions[role] ?? _roleOptions['user']!;
    final name = (u['name'] ?? 'بدون اسم').toString();
    final email = (u['email'] ?? '').toString();
    final photoUrl = (u['photoUrl'] ?? '').toString();
    final disabled = u['isActive'] == false;
    final isSelf = uid == _currentUid;
    final serial = u['_serial'] ?? displayIndex;
    final joinDate = signupAt(u);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: disabled
              ? Colors.red.withValues(alpha: 0.45)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: opt.$2.withValues(alpha: 0.15),
              backgroundImage: photoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Icon(opt.$3, color: opt.$2, size: 18)
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$serial',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: opt.$2,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          '$name${isSelf ? ' (أنت)' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
        subtitle: Text(
          email.isNotEmpty
              ? '$email · ${_formatDate(joinDate)}'
              : _formatDate(joinDate),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusChip(opt.$1, opt.$2),
            if (disabled) ...[
              const SizedBox(width: 4),
              _statusChip('معطّل', AppColors.error),
            ],
            IconButton(
              icon: Icon(Icons.more_vert_rounded,
                  size: 18, color: theme.colorScheme.primary),
              onPressed: () => _manageUser(u),
            ),
          ],
        ),
        onTap: () => _showUserDetailsSheet(u),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد مستخدمون مطابقون لمعايير البحث',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تغيير كلمة البحث أو إعادة تعيين الفلاتر',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ── تفاصيل المستخدم وإدارته ────────────────────────────────────────
  void _showUserDetailsSheet(Map<String, dynamic> u) {
    final role = (u['role'] ?? 'user').toString();
    final opt = _roleOptions[role] ?? _roleOptions['user']!;
    final name = (u['name'] ?? 'بدون اسم').toString();
    final email = (u['email'] ?? '').toString();
    final phone = (u['phone'] ?? '').toString();
    final photoUrl = (u['photoUrl'] ?? '').toString();
    final joinDate = signupAt(u);
    final lastLogin = lastLoginAt(u);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: opt.$2.withValues(alpha: 0.15),
                backgroundImage: photoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? Icon(opt.$3, color: opt.$2, size: 36)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              _statusChip(opt.$1, opt.$2),
              const SizedBox(height: 16),
              const Divider(),
              _detailRow('المعرف (UID)', (u['id'] ?? '').toString(),
                  copyable: true),
              _detailRow('البريد الإلكتروني', email.isEmpty ? '—' : email,
                  copyable: email.isNotEmpty),
              _detailRow('رقم الهاتف', phone.isEmpty ? '—' : phone,
                  copyable: phone.isNotEmpty),
              _detailRow('النوع / الجنس', userGenderBadgeLabel(u)),
              _detailRow('تاريخ التسجيل بالقرية', _formatDate(joinDate)),
              _detailRow('آخر تسجيل دخول', _formatDate(lastLogin)),
              _detailRow('الحالة', u['isActive'] == false ? 'معطّل' : 'مفعّل'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.manage_accounts_rounded),
                label: const Text('إدارة الصلاحيات ورتبة الحساب'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _manageUser(u);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                _snack('تم نسخ: $label');
              },
              child: const Icon(Icons.copy_rounded, size: 16),
            ),
        ],
      ),
    );
  }

  void _manageUser(Map<String, dynamic> u) {
    final uid = (u['id'] ?? '').toString();
    String currentRole = (u['role'] ?? 'user').toString();
    String currentSellerType = (u['sellerType'] ?? '').toString();
    bool isActive = u['isActive'] != false;
    final isSelf = uid == _currentUid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'إدارة حساب: ${u['name'] ?? 'مستخدم'}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (isSelf)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'هذا حسابك الشخصي — تعديل الرتبة معطّل لحمايتك من فقدان صلاحيات الإدارة.',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),

                // اختيار الدور
                const Text('رتبة ودور المستخدم:',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: currentRole,
                  items: _roleOptions.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(
                              children: [
                                Icon(e.value.$3, color: e.value.$2, size: 18),
                                const SizedBox(width: 8),
                                Text(e.value.$1),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: isSelf
                      ? null
                      : (v) {
                          if (v != null) {
                            setModalState(() => currentRole = v);
                          }
                        },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // إذا كان بائعاً: نوع البائع
                if (currentRole == 'seller') ...[
                  const Text('تصنيف البائع وحد الصور:',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: currentSellerType.isEmpty
                        ? 'regular'
                        : currentSellerType,
                    items: const [
                      DropdownMenuItem(
                          value: 'regular',
                          child: Text('بائع عادي (صورة واحدة)')),
                      DropdownMenuItem(
                          value: 'super_seller',
                          child: Text('بائع سوبر (3 صور)')),
                      DropdownMenuItem(
                          value: 'premium',
                          child: Text('بائع بريميوم (5 صور)')),
                      DropdownMenuItem(
                          value: 'vip', child: Text('بائع VIP (10 صور)')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => currentSellerType = v);
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // تفعيل / تعطيل الحساب
                SwitchListTile(
                  title: const Text('تفعيل الحساب والوصول للتطبيق',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    isActive
                        ? 'الحساب نشط ويمكنه التفاعل'
                        : 'الحساب معطّل وممنوع من تسجيل الدخول',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: isActive,
                  onChanged: isSelf
                      ? null
                      : (v) => setModalState(() => isActive = v),
                ),
                const SizedBox(height: 20),

                // زر الحفظ
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _saveUserAccess(
                      uid: uid,
                      role: currentRole,
                      sellerType: currentRole == 'seller'
                          ? currentSellerType
                          : null,
                      isActive: isActive,
                    );
                  },
                  child: const Text('حفظ التعديلات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveUserAccess({
    required String uid,
    required String role,
    String? sellerType,
    required bool isActive,
  }) async {
    try {
      await _adminService.updateUserAccess(
        uid,
        role: role,
        sellerType: sellerType,
      );
      await _adminService.setUserActive(uid, isActive);
      widget.onUpdated?.call();
      _snack('تم تحديث بيانات المستخدم بنجاح');
    } catch (e) {
      _snack('تعذّر التحديث: $e');
    }
  }

  Future<void> _exportVisible(String type) async {
    if (_visibleUsers.isEmpty) {
      _snack('لا يوجد مستخدمون في القائمة الحالية للتصدير');
      return;
    }
    final rows = <Map<String, dynamic>>[];
    for (final u in _visibleUsers) {
      final role = (u['role'] ?? 'user').toString();
      final opt = _roleOptions[role] ?? _roleOptions['user']!;
      final photo = (u['photoUrl'] ?? u['profileImage'] ?? u['avatarUrl'] ?? '').toString();
      rows.add({
        'الرقم': u['_serial'] ?? '',
        'الاسم': u['name'] ?? '',
        'رابط الصورة الشخصية': photo,
        'الدور': opt.$1,
        'نوع البائع': role == 'seller' ? (u['sellerType'] ?? '').toString() : '',
        'النوع / الجنس': userGenderBadgeLabel(u),
        'الحالة': u['isActive'] == false ? 'معطّل' : 'مفعّل',
        'البريد الإلكتروني': u['email'] ?? '',
        'الهاتف': u['phone'] ?? '',
        'تاريخ التسجيل': _formatDate(signupAt(u)),
        'آخر تسجيل دخول': _formatDate(lastLoginAt(u)),
        'المعرف (UID)': u['id'] ?? '',
      });
    }

    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';

    try {
      if (type == 'json') {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(rows);
        final saved = await exportFile(
          fileName: 'qarity_users_$stamp.json',
          mimeType: 'application/json',
          bytes: utf8.encode(jsonStr),
        );
        _snack(saved ? 'تم تصدير ${rows.length} مستخدم (JSON)' : kExportCancelledMessageAr);
      } else if (type == 'excel') {
        final saved = await exportFile(
          fileName: 'qarity_users_$stamp.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          bytes: buildTableXlsx(sheetName: 'المستخدمون', rows: rows),
        );
        _snack(saved ? 'تم تصدير ${rows.length} مستخدم (Excel)' : kExportCancelledMessageAr);
      } else if (type == 'csv') {
        final saved = await exportFile(
          fileName: 'qarity_users_$stamp.csv',
          mimeType: 'text/csv',
          bytes: utf8.encode(buildCsv(rows)),
        );
        _snack(saved ? 'تم تصدير ${rows.length} مستخدم (CSV)' : kExportCancelledMessageAr);
      }
    } catch (e) {
      _snack('تعذّر التصدير: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
