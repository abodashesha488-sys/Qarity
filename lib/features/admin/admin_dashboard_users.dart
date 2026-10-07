part of 'admin_dashboard.dart';

// ═══════════════════════════ Users (إدارة الأدوار) ═══════════════════════════
class _UsersPage extends StatefulWidget {
  const _UsersPage({
    required this.adminService,
    required this.currentUid,
    required this.onUpdated,
  });
  final AdminService adminService;
  final String? currentUid;
  final VoidCallback onUpdated;

  @override
  State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage> {
  final TextEditingController _search = TextEditingController();
  String _filter = 'all';
  String _sortBy = 'newest'; // newest, oldest, name, email

  /// مرشّح النوع مستقل عن مرشّح الدور: كلٌّ منهما يضيّق القائمة على حدة، فتولّد
  /// «الرجال + البائعون» ضغطة من كل شريط بلا حالة مركّبة لكل احتمال.
  String _genderFilter = 'all'; // all, male, female

  /// دور المستخدم الحالي من نفس سترة المستخدمين (يُحدّث في build).
  /// يحدد ما إذا كان حساب المدير العام محمياً من إجراءاته: الأدمن المساعد
  /// لا يستطيع حذف أو تنحية المدير العام (انظر _isProtectedGeneralAdmin).
  String _actingRole = '';

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
    'assistant_admin': ('أدمن مساعد', Color(0xFF6A1B9A), Icons.shield_rounded),
    'admin': (
      'مدير عام',
      Color(0xFF1565C0),
      Icons.admin_panel_settings_rounded
    ),
  };

  static const _filters = <(String, String)>[
    ('all', 'الكل'),
    ('user', 'مستخدمون'),
    ('seller', 'بائعون'),
    ('moderator', 'مشرفون'),
    ('medical_admin', 'مدير طبي'),
    ('agricultural_admin', 'مدير زراعي'),
    ('assistant_admin', 'أدمن مساعد'),
    ('admin', 'مدراء'),
    ('disabled', 'معطّلون'),
  ];

  /// شرائط النوع الثلاثة — «الكل» يعني بلا تضييق، لا نوعًا رابعًا.
  static const _genderChips = <(String, String)>[
    ('all', 'الكل'),
    (kGenderGroupMale, 'رجل'),
    (kGenderGroupFemale, 'امرأة'),
  ];

  late final Stream<List<Map<String, dynamic>>> _usersStream =
      widget.adminService.getAllUsersStream();

  /// المستخدمون الظاهرون الآن (بعد البحث والفلترة والترتيب) — هم من يُصدَّر،
  /// فيكون مخرَج التصدير مطابقاً لما تراه العين.
  List<Map<String, dynamic>> _visible = const [];

  /// مقارنة ضمن نفس الرتبة حسب الترتيب المختار.
  int _compareWithinRank(Map<String, dynamic> a, Map<String, dynamic> b) {
    switch (_sortBy) {
      case 'name':
        return (a['name'] ?? '')
            .toString()
            .compareTo((b['name'] ?? '').toString());
      case 'email':
        return (a['email'] ?? '')
            .toString()
            .compareTo((b['email'] ?? '').toString());
      case 'oldest':
        return _compareJoin(a, b, newestFirst: false);
      default:
        return _compareJoin(a, b, newestFirst: true);
    }
  }

  /// تاريخ التسجيل الفعلي (`joinDate`) — `createdAt` غير موجود في مستندات
  /// المستخدمين، فكان الترتيب والتصدير والتواريخ كلها تعمل على null.
  static int _compareJoin(Map<String, dynamic> a, Map<String, dynamic> b,
      {required bool newestFirst}) {
    final da = signupAt(a);
    final db = signupAt(b);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return newestFirst ? db.compareTo(da) : da.compareTo(db);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('جاري تحميل المستخدمين...',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }
        final all = snapshot.data ?? [];

        // دور المستخدم الحالي لمعرفة الحسابات المحمية من إجراءاته
        // (الأدمن المساعد لا يمسّ حساب المدير العام).
        _actingRole = '';
        for (final u in all) {
          if (u['id'] == widget.currentUid) {
            _actingRole = (u['role'] ?? '').toString();
            break;
          }
        }

        // الرقم التسلسلي = ترتيب التسجيل الفعلي (الأقدم = 1)، ثابت مهما تغيّر
        // الترتيب المعروض.
        final sortedForIndex = List<Map<String, dynamic>>.from(all)
          ..sort((a, b) => _compareJoin(a, b, newestFirst: false));
        for (int i = 0; i < sortedForIndex.length; i++) {
          sortedForIndex[i]['_serial'] = i + 1;
        }
        final serialMap = {
          for (final u in sortedForIndex) u['id'] as String: u['_serial'] as int
        };
        for (final u in all) {
          u['_serial'] = serialMap[u['id'] as String] ?? 0;
        }

        final sellers = all.where((u) => (u['role'] ?? '') == 'seller').length;
        final managers = all
            .where((u) => [
                  'admin',
                  'assistant_admin',
                  'medical_admin',
                  'moderator'
                ].contains((u['role'] ?? '')))
            .length;
        final disabled = all.where((u) => u['isActive'] == false).length;

        // عدّادات النوع على القائمة كاملة لا على المرشّحة: المراجع يحتاج أن يرى
        // حجم كل مجموعة وهو يبدّل الشرائط، لا أن يراها تتساوى دائمًا مع الظاهر.
        final men =
            all.where((u) => genderGroupOf(u) == kGenderGroupMale).length;
        final women =
            all.where((u) => genderGroupOf(u) == kGenderGroupFemale).length;
        final noGender = all.length - men - women;

        final q = _search.text.trim().toLowerCase();
        final filtered = all.where((u) {
          final role = (u['role'] ?? 'user').toString();
          final off = u['isActive'] == false;
          if (!genderFilterMatches(_genderFilter, u)) return false;
          if (_filter == 'disabled' && !off) return false;
          if (_filter != 'all' && _filter != 'disabled' && role != _filter) {
            return false;
          }
          if (q.isEmpty) return true;
          return (u['name']?.toString().toLowerCase().contains(q) ?? false) ||
              (u['email']?.toString().toLowerCase().contains(q) ?? false) ||
              (u['phone']?.toString().toLowerCase().contains(q) ?? false);
        }).toList();

        // الترتيب: النوع أولًا (الرجال ⇒ النساء ⇒ بلا نوع)، ثم رتبة الدور داخل
        // النوع، ثم المفتاح المختار (الأحدث/الأقدم/الاسم/البريد).
        filtered.sort((a, b) => compareUsersForList(a, b, _compareWithinRank));
        _visible = filtered;
        final rows = _listRows(filtered);

        return Column(
          children: [
            // ── عنوان الصفحة الموحّد ─────────────────────────────
            _PageHeader(
              icon: Icons.people_rounded,
              title: 'إدارة المستخدمين',
              subtitle: '${all.length} مستخدم مسجل',
              color: Colors.teal,
              count: all.length,
            ),

            // ── إحصائيات سريعة ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      _miniStat(theme, 'الكل', '${all.length}', Colors.teal),
                      const SizedBox(width: 8),
                      _miniStat(
                          theme, 'البائعون', '$sellers', Colors.deepPurple),
                      const SizedBox(width: 8),
                      _miniStat(theme, 'المسؤولون', '$managers',
                          const Color(0xFF1565C0)),
                      const SizedBox(width: 8),
                      _miniStat(theme, 'معطّل', '$disabled',
                          disabled > 0 ? Colors.red : Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // عدّادات النوع مجمّعة على القائمة كاملة، ورابعة تقول كم صمد
                  // أمام المرشّحات الحالية — فلا يُحسب صفرٌ على أنه «لا نساء في
                  // القرية» بينما المرشّح هو الذي أخفاهن.
                  Row(
                    key: const Key('gender-counters'),
                    children: [
                      _miniStat(
                          theme, 'الرجال', '$men', const Color(0xFF1565C0)),
                      const SizedBox(width: 8),
                      _miniStat(
                          theme, 'النساء', '$women', const Color(0xFFAD1457)),
                      const SizedBox(width: 8),
                      _miniStat(theme, 'بلا نوع', '$noGender',
                          noGender > 0 ? Colors.orange : Colors.grey.shade400),
                      const SizedBox(width: 8),
                      _miniStat(
                          theme, 'الظاهر', '${filtered.length}', Colors.brown),
                    ],
                  ),
                ],
              ),
            ),

            // ── شريط الأدوات ────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.2)),
                  bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.2)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // البحث سطرٌ كامل العرض وحده: في صفٍّ واحد مع الرقائق الثلاث
                  // كان يتقلّص إلى 38dp (وإلى 8.6dp مع أطول تسمية دور «أدمن
                  // مساعد» فيفيض الصف) فلا يظهر منه إلا دائرة العدسة بلا التلميح.
                  TextField(
                    key: const Key('users-search-field'),
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم أو البريد أو الهاتف...',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: q.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => _search.clear())
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    key: const Key('users-tools-row'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // تصفية
                      Tooltip(
                        message: 'تصفية حسب الدور',
                        child: PopupMenuButton<String>(
                          initialValue: _filter,
                          onSelected: (v) => setState(() => _filter = v),
                          itemBuilder: (ctx) => _filters
                              .map((f) => PopupMenuItem(
                                    value: f.$1,
                                    child: Row(
                                      children: [
                                        if (_filter == f.$1)
                                          Icon(Icons.check_rounded,
                                              size: 18,
                                              color: theme.colorScheme.primary),
                                        if (_filter == f.$1)
                                          const SizedBox(width: 8),
                                        Text(f.$2),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: theme.colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.filter_list_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(_filterLabel,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down_rounded,
                                    size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // ترتيب
                      Tooltip(
                        message: 'ترتيب النتائج',
                        child: PopupMenuButton<String>(
                          initialValue: _sortBy,
                          onSelected: (v) => setState(() => _sortBy = v),
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(
                                value: 'newest',
                                child: Row(children: [
                                  Icon(Icons.new_releases_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('الأحدث أولاً')
                                ])),
                            PopupMenuItem(
                                value: 'oldest',
                                child: Row(children: [
                                  Icon(Icons.history_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('الأقدم أولاً')
                                ])),
                            PopupMenuItem(
                                value: 'name',
                                child: Row(children: [
                                  Icon(Icons.sort_by_alpha_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('الاسم أبجدياً')
                                ])),
                            PopupMenuItem(
                                value: 'email',
                                child: Row(children: [
                                  Icon(Icons.email_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('البريد أبجدياً')
                                ])),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: theme.colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sort_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(_sortByLabel,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down_rounded,
                                    size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // تصدير
                      PopupMenuButton<String>(
                        onSelected: _handleExport,
                        itemBuilder: (ctx) {
                          // الأيقونات رسومية بمقاس 18 فوق القائمة المنبثقة،
                          // فحدّها 3.0: الأخضر 2.8 والبرتقالي 2.15 لا يُقرأّن
                          // على البياض، فيُنزح سطوعهما وحده وتبقى دلالتهما.
                          final b = Theme.of(ctx).brightness;
                          return [
                            PopupMenuItem(
                              value: 'excel',
                              child: Row(
                                children: [
                                  Icon(Icons.table_chart_rounded,
                                      size: 18,
                                      color: AppColors.readableInk(
                                          Colors.green, b,
                                          minRatio: 3.0)),
                                  const SizedBox(width: 8),
                                  const Text('Excel — القائمة الظاهرة'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'csv',
                              child: Row(
                                children: [
                                  Icon(Icons.table_chart_rounded,
                                      size: 18,
                                      color: AppColors.readableInk(
                                          Colors.orange, b,
                                          minRatio: 3.0)),
                                  const SizedBox(width: 8),
                                  const Text('CSV — القائمة الظاهرة'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'json',
                              child: Row(
                                children: [
                                  Icon(Icons.code_rounded,
                                      size: 18,
                                      color: AppColors.readableInk(
                                          Colors.blue, b,
                                          minRatio: 3.0)),
                                  const SizedBox(width: 8),
                                  const Text('JSON — القائمة الظاهرة'),
                                ],
                              ),
                            ),
                          ];
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('تصدير',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // شريط النوع مستقل عن قائمة الأدوار: الضغطة هنا تضيّق داخل
                  // مجموعة الدور المختارة، وقائمة الدور تضيّق داخل النوع.
                  Wrap(
                    key: const Key('gender-filter-row'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in _genderChips)
                        ChoiceChip(
                          key: Key('gender-filter-${g.$1}'),
                          label: Text(g.$2),
                          selected: _genderFilter == g.$1,
                          avatar: Icon(
                            g.$1 == 'all'
                                ? Icons.filter_alt_rounded
                                : g.$1 == kGenderGroupMale
                                    ? Icons.male_rounded
                                    : Icons.female_rounded,
                            size: 18,
                            color: _genderFilter == g.$1
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          onSelected: (_) =>
                              setState(() => _genderFilter = g.$1),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── قائمة المستخدمين ────────────────────────────────
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('لا يوجد مستخدمون مطابقون',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          Text('جرب تغيير معايير البحث أو الفلترة',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        if (row.isHeader) {
                          return _genderHeader(theme, row.label!, row.count!);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _userCard(theme, row.user!, row.cardIndex),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// صفوف القائمة: رأس لكل نوع له مستخدمون ثم بطاقاتهم بالترتيب الجاري داخله.
  /// المجموعة الفارغة لا رأس لها — رأس بلا تحته شيء يوحي بأن القسم «مقصوم» لا
  /// أن القرية لا تملكه.
  List<_UserRow> _listRows(List<Map<String, dynamic>> sorted) {
    final rows = <_UserRow>[];
    var cardIndex = 0;
    for (final group in genderGroupsOf(sorted)) {
      rows.add(_UserRow.header(group.label, group.members.length));
      for (final m in group.members) {
        rows.add(_UserRow.card(m, cardIndex++));
      }
    }
    return rows;
  }

  Widget _genderHeader(ThemeData theme, String label, int count) {
    return Padding(
      key: Key('gender-header-$label'),
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  String get _filterLabel {
    // مجموعة الأدوار «الكل» تصبح جنسيةً حين يُختار نوع: نفس الضغطة تعني
    // «كل الرجال» أو «كل النساء»، والاسم يقول ذلك بدل أن يُفهم ضمناً.
    if (_filter == 'all') return genderAwareAllLabel(_genderFilter);
    for (final f in _filters) {
      if (f.$1 == _filter) return f.$2;
    }
    return 'الكل';
  }

  String get _sortByLabel {
    switch (_sortBy) {
      case 'oldest':
        return 'الأقدم';
      case 'name':
        return 'الاسم';
      case 'email':
        return 'البريد';
      default:
        return 'الأحدث';
    }
  }

  /// الصفوف المُصدَّرة = ما هو ظاهر على الشاشة بالضبط (نفس البحث والفلترة
  /// والترتيب)، فيفهم المستخدم ما الذي خرج من الزر.
  List<Map<String, dynamic>> _exportRows() {
    final rows = <Map<String, dynamic>>[];
    for (final u in _visible) {
      final role = (u['role'] ?? 'user').toString();
      final opt = _roleOptions[role] ?? _roleOptions['user']!;
      rows.add({
        'الرقم': u['_serial'] ?? '',
        'الاسم': u['name'] ?? '',
        'الدور': opt.$1,
        'نوع البائع': role == 'seller'
            ? _typeLabel((u['sellerType'] ?? '').toString())
            : '',
        'الحالة': u['isActive'] == false ? 'معطّل' : 'مفعّل',
        'تاريخ التسجيل': _formatDate(signupAt(u)) ?? '',
        'آخر تسجيل دخول': _formatDate(lastLoginAt(u)) ?? '',
        'البريد الإلكتروني': u['email'] ?? '',
        'الهاتف': u['phone'] ?? '',
        'المعرف': u['id'] ?? '',
      });
    }
    return rows;
  }

  String get _stamp {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }

  Future<void> _handleExport(String type) async {
    final rows = _exportRows();
    if (rows.isEmpty) {
      _snack('لا يوجد مستخدمون في القائمة الحالية للتصدير');
      return;
    }
    try {
      if (type == 'json') {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(rows);
        _report(
          await exportFile(
            fileName: 'qarity_users_$_stamp.json',
            mimeType: 'application/json',
            bytes: utf8.encode(jsonStr),
          ),
          rows.length,
          'JSON',
        );
      } else if (type == 'excel') {
        _report(
          await exportFile(
            fileName: 'qarity_users_$_stamp.xlsx',
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            bytes: buildTableXlsx(sheetName: 'المستخدمون', rows: rows),
          ),
          rows.length,
          'Excel',
        );
      } else if (type == 'csv') {
        _report(
          await exportFile(
            fileName: 'qarity_users_$_stamp.csv',
            mimeType: 'text/csv',
            bytes: utf8.encode(buildCsv(rows)),
          ),
          rows.length,
          'CSV',
        );
      }
    } on ExportException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('تعذّر التصدير: $e');
    }
  }

  /// `exportFile` يعيد `false` حين يلغي المستخدم نافذة الحفظ على الويب — فلا
  /// تُقرأ الرحلة كلها كنجاح وهو لم يحصل على ملف.
  void _report(bool saved, int count, String kind) {
    _snack(
        saved ? 'تم تصدير $count مستخدم ($kind)' : kExportCancelledMessageAr);
  }

  /// تاريخ + ساعة مقروء (`2026/09/26 · 14:05`)، أو null عند غياب التاريخ.
  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year}/${two(date.month)}/${two(date.day)} · '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Widget _miniStat(ThemeData theme, String label, String value, Color color) {
    // التظليل والحدّ والظلّ تبقى على درجة القسم، وأما الرقم (18 ووزن 900، وهو
    // دون سقف النص الكبير) فحبرٌ فوق الخلفية فيُنزل أو يُنار سطوعًا وحده.
    final ink = AppColors.readableInk(color, theme.brightness);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: ink, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  /// بطاقة مستخدم في **سطر واحد مدمج**: رقم القسم، الصورة، الاسم والبريد في
  /// عمود بسطر واحد لكلٍّ، شارة النوع والرتبة، ثم زر إدارة واحد مضغوط. التاريخ
  /// ونوع البائع وكل بيان يقرؤه المراجع بقي في `_showUserDetail` التي يفتحها
  /// النقر على البطاقة — فسطر ثانٍ تحتها كان يضاعف ارتفاع القائمة ويجعل عمود
  /// التاريخ يفيض على عرض الهاتف.
  Widget _userCard(ThemeData theme, Map<String, dynamic> u, int index) {
    final uid = u['id'] as String;
    final role = (u['role'] ?? 'user').toString();
    final disabled = u['isActive'] == false;
    final isSelf = uid == widget.currentUid;
    final opt = _roleOptions[role] ?? _roleOptions['user']!;
    final serial = u['_serial'] as int? ?? index + 1;
    final photoUrl = (u['photoUrl'] ?? '').toString();
    final protected = _isProtectedGeneralAdmin(role);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: disabled
                ? Colors.red.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: disabled ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: () => _showUserDetail(u),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // رقم القسم — أول الـRow تحت RTL فيظهر يمين البطاقة
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$serial',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 22,
                backgroundColor: opt.$2.withValues(alpha: 0.14),
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Icon(opt.$3,
                        color: AppColors.readableInk(
                            opt.$2, theme.brightness,
                            minRatio: 3.0),
                        size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${u['name']?.toString() ?? 'بدون اسم'}${isSelf ? ' (أنت)' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(u['email']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // النوع والرتبة في شارة واحدة. `Flexible` + ellipsis لأن أطول
              // تسمية دور («مدير الخدمات الزراعية») فوق أطول اسم لا يجوز أن
              // ترفعا البطاقة إلى فيضان في منتصف القائمة.
              Flexible(
                child: _badge(
                  '${userGenderBadgeLabel(u)} · ${opt.$1}',
                  opt.$2,
                ),
              ),
              if (disabled) ...[
                const SizedBox(width: 4),
                _badge('معطّل', theme.colorScheme.error),
              ],
              // زر الإدارة (معطّل لحساب المدير العام إذا لم يكن المستخدم
              // الحالي مديراً عاماً)
              IconButton(
                icon: Icon(Icons.shield_rounded,
                    color: theme.colorScheme.primary, size: 20),
                tooltip: protected ? 'محمي — للمدير العام فقط' : 'إدارة الحساب',
                onPressed: protected ? null : () => _manage(context, u),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36), padding: EdgeInsets.zero),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    // الشارة حبرٌ بمقاس 9.5 فوق تظليل الدرجة نفسها، فالدرجة وحدها لا تكفي
    // على البطاقة البضاء (البرتقالي 2.15) فتُنزح سطوعًا لا لونًا.
    final ink =
        AppColors.readableInk(color, Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w800, color: ink)),
    );
  }

  static String _typeLabel(String t) {
    for (final e in SellerType.values) {
      if (e.name == t) return e.label;
    }
    return t;
  }

  // ───────────────────── شاشة تفاصيل المستخدم ─────────────────────
  void _showUserDetail(Map<String, dynamic> u) {
    final theme = Theme.of(context);
    // حذف الحساب فعلٌ لا رجعة فيه، فيبقى على الأحمر الهادئ لا `Colors.red`
    // الخام؛ وفي الداكن تُنار درجته حتى تُقرأ الكتابة والحدّ معًا.
    final deleteInk = AppColors.readableInk(AppColors.error, theme.brightness);
    final role = (u['role'] ?? 'user').toString();
    final opt = _roleOptions[role] ?? _roleOptions['user']!;
    final photoUrl = (u['photoUrl'] ?? '').toString();
    final sellerType = (u['sellerType'] ?? '').toString();
    final disabled = u['isActive'] == false;
    final isSelf = u['id'] == widget.currentUid;
    final protected = _isProtectedGeneralAdmin(role);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس البطاقة
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: opt.$2.withValues(alpha: 0.45), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: opt.$2.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 78,
                        backgroundColor: opt.$2.withValues(alpha: 0.14),
                        backgroundImage:
                            photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? Icon(opt.$3,
                                color: AppColors.readableInk(
                                    opt.$2, theme.brightness,
                                    minRatio: 3.0),
                                size: 64)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      u['name']?.toString() ?? 'بدون اسم',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        _detailBadge(opt.$1, opt.$2),
                        if (role == 'seller' && sellerType.isNotEmpty)
                          _detailBadge(_typeLabel(sellerType), Colors.brown),
                        if (disabled)
                          _detailBadge('معطّل', theme.colorScheme.error),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              // بيانات تفصيلية
              _buildDetailRow(theme, 'الرقم التسلسلي',
                  u['_serial']?.toString() ?? '—', Icons.numbers_rounded),
              _buildDetailRow(
                  theme, 'المعرف', u['id'] ?? '—', Icons.fingerprint_rounded),
              _buildDetailRow(theme, 'البريد الإلكتروني', u['email'] ?? '—',
                  Icons.email_rounded),
              _buildDetailRow(
                  theme, 'رقم الهاتف', u['phone'] ?? '—', Icons.phone_rounded),
              _buildDetailRow(theme, 'الدور', opt.$1, opt.$3, color: opt.$2),
              if (role == 'seller' && sellerType.isNotEmpty)
                _buildDetailRow(theme, 'نوع البائع', _typeLabel(sellerType),
                    Icons.store_rounded,
                    color: Colors.brown),
              _buildDetailRow(theme, 'الحالة', disabled ? 'معطّل' : 'مفعّل',
                  disabled ? Icons.block_rounded : Icons.check_circle_rounded,
                  color: disabled ? theme.colorScheme.error : Colors.green),
              _buildDetailRow(
                  theme,
                  'تاريخ التسجيل',
                  _formatDate(signupAt(u)) ?? 'غير مسجّل',
                  Icons.calendar_today_rounded),
              _buildDetailRow(
                  theme,
                  'آخر تسجيل دخول',
                  _formatDate(lastLoginAt(u)) ?? 'لم يسجّل الدخول بعد',
                  Icons.login_rounded,
                  color: lastLoginAt(u) == null
                      ? theme.colorScheme.onSurfaceVariant
                      : null),
              if ((u['googleId'] ?? '').toString().isNotEmpty)
                _buildDetailRow(theme, 'معرف Google', u['googleId'],
                    Icons.g_mobiledata_rounded),
              const Divider(),
              // أزرار الإجراءات
              if (!isSelf && !protected) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.shield_rounded,
                            color: theme.colorScheme.primary),
                        label: Text('إدارة الحساب',
                            style: TextStyle(color: theme.colorScheme.primary)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _manage(context, u);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: deleteInk,
                            side: BorderSide(color: deleteInk)),
                        icon: Icon(Icons.delete_outline_rounded,
                            color: deleteInk),
                        label: Text('حذف نهائياً',
                            style: TextStyle(color: deleteInk)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _confirmDelete(context, u['id'] as String,
                              u['name']?.toString() ?? '',
                              role: (u['role'] ?? 'user').toString());
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (!isSelf && protected)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                        'هذا حساب المدير العام — لا يمكنك إدارته أو حذفه.',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      ThemeData theme, String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 20,
              color: AppColors.readableInk(color ?? theme.colorScheme.primary,
                  theme.brightness,
                  minRatio: 3.0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBadge(String text, Color color) {
    // مثل `_badge`: التظليل والحدّ بدرجة القسم، والكتابة بمقاس 11 حبرٌ يُنزح.
    final ink =
        AppColors.readableInk(color, Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: ink)),
    );
  }

  // ───────────────────── لوحة إدارة الحساب ─────────────────────
  Future<void> _manage(BuildContext context, Map<String, dynamic> u) async {
    final uid = u['id'] as String;
    final role = (u['role'] ?? 'user').toString();
    final name = u['name']?.toString() ?? '';
    final email = u['email']?.toString() ?? '';
    final sellerType = (u['sellerType'] ?? '').toString();
    final active = u['isActive'] != false;
    final isSelf = uid == widget.currentUid;
    final service = widget.adminService;
    // حساب المدير العام محمي: الأدمن المساعد لا يغيّر دوره ولا يحذفه.
    final protected = _isProtectedGeneralAdmin(role);
    // الحذف فعل لا رجعة فيه: الأحمر الهادئ لا `Colors.red` الخام، ويُزار
    // سطوعه في الداكن حتى تُقرأ الكتابة والحدّ معًا.
    final deleteInk =
        AppColors.readableInk(AppColors.error, Theme.of(context).brightness);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isEmpty ? 'مستخدم' : name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(email,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              if (isSelf)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                        'هذا حسابك — تغيير الدور معطّل لحمايتك من قفل الصلاحيات.',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              if (protected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                        'هذا حساب المدير العام — لا يمكنك تغيير دوره أو حذفه.',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text('الدور والصلاحيات',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.primary)),
              ),
              RadioGroup<String>(
                groupValue: role,
                onChanged: (v) async {
                  if (v == null || isSelf || protected) return;
                  await service.setUserRole(uid, v);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack('تم تعيين الدور: ${_roleOptions[v]!.$1}');
                  widget.onUpdated();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final e in _roleOptions.entries)
                      RadioListTile<String>(
                        value: e.key,
                        dense: true,
                        title: Text(e.value.$1,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(_roleHint(e.key),
                            style: const TextStyle(fontSize: 11)),
                        secondary:
                            Icon(e.value.$3, size: 18, color: e.value.$2),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text('نوع البائع (حدود رفع الصور)',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.secondary)),
              ),
              RadioGroup<String>(
                groupValue: sellerType.isEmpty ? null : sellerType,
                onChanged: (v) async {
                  if (v == null) return;
                  await service.updateUserAccess(uid, sellerType: v);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack('تم تحديث نوع البائع: ${_typeLabel(v)}');
                  widget.onUpdated();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in SellerType.values)
                      RadioListTile<String>(
                        value: t.name,
                        dense: true,
                        title: Text(t.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('حتى ${t.maxImages} صور',
                            style: const TextStyle(fontSize: 11)),
                        secondary: Icon(t.icon, size: 18),
                      ),
                  ],
                ),
              ),
              const Divider(),
              SwitchListTile(
                secondary: Icon(
                    active ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                    color: active ? AppColors.success : Colors.grey),
                title: const Text('الحساب مفعّل',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    active
                        ? 'يمكنه استخدام التطبيق'
                        : 'معطّل — لن يستطيع الوصول',
                    style: const TextStyle(fontSize: 11)),
                value: active && !isSelf,
                onChanged: isSelf || protected
                    ? null
                    : (v) async {
                        await service.setUserActive(uid, v);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack(v ? 'تم تفعيل الحساب' : 'تم تعطيل الحساب');
                        widget.onUpdated();
                      },
              ),
              const Divider(),
              if (!isSelf && !protected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: deleteInk,
                        side: BorderSide(color: deleteInk)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _confirmDelete(context, uid, name, role: role);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('حذف المستخدم نهائياً'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// حساب المدير العام محمي من المستخدم الحالي فقط إذا كان هذا المستخدم
  /// أدمن مساعد (ليس مديراً عاماً) — لا يستطيع حذفه أو تنحية دوره. القواعد
  /// في firestore.rules ترفض العملية من الخادم أيضاً كحماية مزدوجة.
  bool _isProtectedGeneralAdmin(String targetRole) {
    return targetRole == 'admin' && _actingRole == 'assistant_admin';
  }

  static String _roleHint(String role) {
    switch (role) {
      case 'user':
        return 'تصفح وإضافة محتوى (يُنشر بعد الموافقة)';
      case 'seller':
        return 'فتح متجر ورفع منتجات بعدد صور حسب نوعه';
      case 'moderator':
        return 'دور غير مفعّل حالياً — يحتفظ بالتسمية فقط';
      case 'assistant_admin':
        return 'نفس صلاحيات المدير العام، لكن لا يستطيع حذف (أو تنحية) المدير العام';
      case 'medical_admin':
        return 'إدارة المركز الطبي الخيري فقط — لا يراجع بقية محتوى الخدمات الطبية';
      case 'admin':
        return 'كل الصلاحيات + تعيين الأدوار';
      default:
        return '';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, String uid, String name,
      {required String role}) async {
    // حماية مزدوجة: القواعد ترفض ذلك أيضاً، لكن نمنع المحاولة هنا برسالة واضحة.
    // الفحص بدور الهدف الحقيقي: تمرير دور ثابت كان يمنع الأدمن المساعد من حذف
    // أي حساب برسالة مضلّلة عن المدير العام.
    if (_isProtectedGeneralAdmin(role)) {
      _snack('لا يمكنك حذف حساب المدير العام');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text('هل أنت متأكد من حذف "$name"؟ لا يمكن التراجع.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await widget.adminService.deleteItem('users', uid);
        widget.onUpdated();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      }
    }
  }
}

/// سطر في قائمة المستخدمين: إمّا رأس مجموعة نوع أو بطاقة مستخدم. القائمة صارت
/// مزيجا من الاثنين، فلا يصلح `itemCount` على عدد المستخدمين وحدهم.
class _UserRow {
  const _UserRow.header(this.label, this.count)
      : user = null,
        cardIndex = 0;
  const _UserRow.card(this.user, this.cardIndex)
      : label = null,
        count = null;

  final String? label;
  final int? count;
  final Map<String, dynamic>? user;

  /// موضع البطاقة بين البطاقات — تتسلّمه `_userCard` لاحتياط الرقم التسلسلي.
  final int cardIndex;

  bool get isHeader => user == null;
}
