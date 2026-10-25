part of 'admin_dashboard.dart';

// ═══════════════════════════ Review ═══════════════════════════
class _ReviewPage extends StatefulWidget {
  const _ReviewPage({
    super.key,
    required this.cats,
    required this.selected,
    required this.pendingCounts,
    required this.onSelect,
    required this.onAction,
    required this.busyActions,
    required this.onItemChanged,
    required this.notesProvider,
  });

  final List<_Cat> cats;
  final String selected;
  final Map<String, int> pendingCounts;
  final void Function(String) onSelect;
  final Future<void> Function(String collection, String docId, String action)
      onAction;
  final Set<String> busyActions;
  final VoidCallback onItemChanged;
  final Future<String?> Function(BuildContext, {bool isReject}) notesProvider;

  @override
  State<_ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<_ReviewPage> with _ReviewBulkMixin {
  bool _pendingOnly = true;
  final _search = TextEditingController();
  String _sortBy = 'newest'; // newest, oldest, title

  static const Map<String, String> _collectionPillars = {
    kAllPending: 'all',
    'upgrade_requests': 'all',

    'market_products': 'market',
    'tab_med_supplies': 'market',
    'shops': 'market',
    'buy_requests': 'market',
    'donations': 'market',

    'news': 'community',
    'obituaries': 'community',
    'occasions': 'community',
    'forum_posts': 'community',
    'lost_items': 'community',
    'village_ads': 'community',

    'medical_center_clinics': 'medical',
    'village_clinics': 'medical',
    'pharmacies': 'medical',
    'medical_labs': 'medical',
    'optical_shops': 'medical',
    'blood_requests': 'medical',
    'blood_donors': 'medical',

    'tab_svc_technicians': 'services',
    'tab_svc_agricultural': 'services',
    'tab_svc_educational': 'services',
    'lawyers': 'services',
    'legal_consultations': 'services',
    'agriculture_consultations': 'services',
    'phone_directory': 'services',
  };

  static final List<_PillarInfo> _pillars = [
    _PillarInfo(
      id: 'all',
      label: 'الرئيسية',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.primary,
    ),
    const _PillarInfo(
      id: 'market',
      label: 'السوق',
      icon: Icons.storefront_rounded,
      color: Colors.deepPurple,
    ),
    const _PillarInfo(
      id: 'community',
      label: 'المجتمع',
      icon: Icons.diversity_3_rounded,
      color: Colors.blue,
    ),
    const _PillarInfo(
      id: 'medical',
      label: 'الصحة',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF00897B),
    ),
    const _PillarInfo(
      id: 'services',
      label: 'الخدمات والدليل',
      icon: Icons.handyman_rounded,
      color: Color(0xFFEF6C00),
    ),
  ];

  late String _selectedPillar;

  @override
  void initState() {
    super.initState();
    _selectedPillar = _collectionPillars[widget.selected] ?? 'all';
  }

  @override
  void didUpdateWidget(covariant _ReviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      final p = _collectionPillars[widget.selected];
      if (p != null && _selectedPillar != 'all_list') {
        _selectedPillar = p;
      }
    }
  }

  int _pillarPending(String pillarId) {
    if (pillarId == 'all') {
      return (widget.pendingCounts[kAllPending] ?? _totalRealPending) +
          (widget.pendingCounts['upgrade_requests'] ?? 0);
    }
    if (pillarId == 'all_list') return _totalRealPending;
    var sum = 0;
    for (final c in widget.cats) {
      if (_collectionPillars[c.collection] == pillarId) {
        sum += widget.pendingCounts[c.collection] ?? 0;
      }
    }
    return sum;
  }

  List<_Cat> get _filteredCats {
    if (_selectedPillar == 'all_list') return widget.cats;
    final list = widget.cats.where((c) {
      return _collectionPillars[c.collection] == _selectedPillar;
    }).toList(growable: false);
    return list.isNotEmpty ? list : widget.cats;
  }

  void _showAllCategoriesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AllCategoriesSheet(
        cats: widget.cats,
        selected: widget.selected,
        pendingCounts: widget.pendingCounts,
        totalRealPending: _totalRealPending,
        pillars: _pillars,
        collectionPillars: _collectionPillars,
        onSelect: (catId) {
          Navigator.pop(ctx);
          final pillar = _collectionPillars[catId];
          setState(() {
            if (pillar != null) _selectedPillar = pillar;
          });
          widget.onSelect(catId);
        },
      ),
    );
  }

  // تثبيت الـStream لكل (مجموعة، وضع) — إعادة إنشائه مع كل ضغطة كتابة
  // كان يفكّ الاشتراك ويعيد تنزيل المجموعة كلها في كل حرف.
  Stream<List<Map<String, dynamic>>>? _itemsStream;
  String? _itemsStreamKey;

  /// المجموعات الحقيقية وحدها — تُشتق من `realCollection` وتُحصر بالتعيين
  /// (Set) لأن التبويبات المصفّاة تتشارك مصدرها مع تبويب حقيقي، فذكر المصدر
  /// مرتين في القائمة الموحّدة يضاعف كل عنصر فيه.
  List<String> get _realCollections => widget.cats
      .map((c) => c.realCollection)
      .where((c) => c != kAllPending)
      .toSet()
      .toList(growable: false);

  /// إجمالي المعلّقات الحقيقية: التبويب المصفّى يعدّ مستندات مجموعة قائمة،
  /// فجمعه مع مصدرها يُضاعف الرقم في ترويسة «كل المعلّقات» وفي الرقائق.
  int get _totalRealPending => widget.cats
      .where((c) => !c.isVirtual && !c.isAllPending)
      .fold<int>(0, (acc, c) => acc + (widget.pendingCounts[c.collection] ?? 0));

  /// قيم التصنيف التي أخذتها تبويبات أخرى من نفس المصدر — «الباقي» يتركها لها،
  /// وإلا ظهر السجل الزراعي في تبويب الحرفيين وتبويب الزراعة معًا.
  Set<String> _claimedElsewhere(_Cat cat) => {
        for (final other in widget.cats)
          if (other.isVirtual &&
              other.collection != cat.collection &&
              other.realCollection == cat.realCollection &&
              other.filterField == cat.filterField)
            ...?other.filterValues
      };

  Stream<List<Map<String, dynamic>>> _streamFor(_Cat cat, bool pendingOnly) {
    final key = '${cat.collection}_$pendingOnly';
    if (_itemsStreamKey != key || _itemsStream == null) {
      _itemsStreamKey = key;
      if (cat.isAllPending) {
        _itemsStream = AdminService().allPendingStream(_realCollections);
      } else {
        final source = AdminService()
            .itemsStream(cat.realCollection, pendingOnly: pendingOnly);
        // التبويب المصفّى يقرأ مستندات المصدر نفسه ويرفّصها هنا: لا مجموعة
        // جديدة ولا أدوار ولا قواعد — والقرار في البطاقة يذهب إلى المصدر.
        _itemsStream = cat.isVirtual
            ? source.map((docs) => docs
                .where((d) =>
                    cat.matches(d, claimedElsewhere: _claimedElsewhere(cat)))
                .toList(growable: false))
            : source;
      }
    }
    return _itemsStream!;
  }

  /// فئة العنصر للعرض: تبويب مُصفّى يطابقه أولًا (هو أدقّ من اسم المجموعة —
  /// «خدمات تعليمية» لا «دليل الخدمات»)، وإلا المجموعة الحقيقية نفسها.
  _Cat? _sourceCatFor(Map<String, dynamic> item) {
    final real = item['_collection'] as String?;
    if (real == null) return null;
    for (final c in widget.cats) {
      if (c.isVirtual &&
          c.realCollection == real &&
          c.matches(item, claimedElsewhere: _claimedElsewhere(c))) {
        return c;
      }
    }
    for (final c in widget.cats) {
      if (!c.isVirtual && c.collection == real) return c;
    }
    return null;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  _Cat get _cat =>
      widget.cats.firstWhere((c) => c.collection == widget.selected,
          orElse: () => widget.cats.first);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allPendingView = _cat.isAllPending;
    final totalPending = _totalRealPending;
    return Column(
      children: [
        // ── عنوان الصفحة الموحّد ─────────────────────────────────
        _PageHeader(
          icon: _cat.icon,
          title: allPendingView ? 'كل الإجراءات المعلقة' : 'مراجعة ${_cat.label}',
          subtitle: allPendingView
              ? 'قائمة واحدة من كل الأقسام مع ذكر مصدر كل إجراء'
              : (_pendingOnly ? 'عرض العناصر المعلقة فقط' : 'عرض جميع العناصر'),
          color: _cat.color,
          count: allPendingView
              ? totalPending
              : (_pendingOnly ? (widget.pendingCounts[_cat.collection] ?? 0) : null),
          countLabel: 'معلّق',
        ),

        // ── شريط المجموعات الكبرى والفئات ──────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: SizedBox(
            height: 38,
            child: Row(
              children: [
                // زر عرض كل الأقسام مع أيقونة شبكية
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAllCategoriesSheet,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grid_view_rounded, size: 15, color: theme.colorScheme.primary),
                          const SizedBox(width: 5),
                          Text(
                            'تصفح الكل (27)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 22,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                // ركائز المجموعات
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pillars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final p = _pillars[i];
                      final isSelected = _selectedPillar == p.id;
                      final pending = _pillarPending(p.id);
                      final ink = AppColors.readableInk(p.color, theme.brightness);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPillar = p.id;
                            final inPillar = widget.cats.where(
                                (c) => _collectionPillars[c.collection] == p.id);
                            if (!inPillar.any((c) => c.collection == widget.selected) &&
                                inPillar.isNotEmpty) {
                              widget.onSelect(inPillar.first.collection);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? p.color.withValues(alpha: 0.16)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? p.color
                                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(p.icon, size: 14, color: isSelected ? ink : theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 5),
                              Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? ink : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (pending > 0) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? p.color : AppColors.warning,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: isSelected ? Colors.white : AppColors.onWarning,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── شريط الفئات المحسّن (المصفى حسب الركيزة) ───────────────
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
                bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.2))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filteredCats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final c = _filteredCats[i];
              final sel = c.collection == widget.selected;
              final pending = c.isAllPending
                  ? _totalRealPending
                  : (widget.pendingCounts[c.collection] ?? 0);
              return _CategoryChip(
                cat: c,
                selected: sel,
                pending: pending,
                total: pending,
                onTap: () => widget.onSelect(c.collection),
              );
            },
          ),
        ),

        // ── شريط الأدوات المحسّن ─────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
                bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.2))),
          ),
          child: isSelectionMode
              ? buildSelectionToolbar(theme)
              : _buildMainToolbar(theme),
        ),

        // ── قائمة العناصر ───────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _streamFor(_cat, allPendingView ? true : _pendingOnly),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: _cat.color),
                      const SizedBox(height: 16),
                      Text('جاري تحميل ${_cat.label}...',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                );
              }
              if (snapshot.hasError) {
                return _ErrorReview(color: _cat.color);
              }
              var items = List<Map<String, dynamic>>.from(snapshot.data ?? []);
              final q = _search.text.trim().toLowerCase();
              if (q.isNotEmpty) {
                items = items.where((it) {
                  final source = _sourceCatFor(it)?.label ?? '';
                  final text = [
                    it['title'],
                    it['name'],
                    it['content'],
                    it['description'],
                    it['shopName'],
                    it['userName'],
                    it['authorName'],
                    it['phone'],
                    it['specialty'],
                    it['stage'],
                    it['providerKind'],
                    it['universityNote'],
                    it['category'],
                    if (it['offersPrivateTutoring'] == true) 'تدريس خاص',
                    source,
                  ].whereType<String>().join(' ').toLowerCase();
                  return text.contains(q);
                }).toList();
              }
              // ترتيب — `createdAt` يصل من Firestore كـ Timestamp، والتحويل
              // بـ as DateTime? كان يرمي TypeError فيسقط البناء ولا تظهر بيانات.
              int cmpCreatedAt(Map<String, dynamic> a, Map<String, dynamic> b,
                  {required bool newestFirst}) {
                final da = tsToDateTime(a['createdAt']);
                final db = tsToDateTime(b['createdAt']);
                if (da == null && db == null) return 0;
                if (da == null) return 1;
                if (db == null) return -1;
                return newestFirst ? db.compareTo(da) : da.compareTo(db);
              }

              items.sort((a, b) {
                switch (_sortBy) {
                  case 'oldest':
                    return cmpCreatedAt(a, b, newestFirst: false);
                  case 'title':
                    final t = (a['title'] ?? a['name'] ?? '')
                        .toString()
                        .compareTo((b['title'] ?? b['name'] ?? '').toString());
                    if (t != 0) return t;
                    return cmpCreatedAt(a, b, newestFirst: true);
                  default:
                    return cmpCreatedAt(a, b, newestFirst: true);
                }
              });

              if (items.isEmpty) {
                return _EmptyReview(
                  pending: _pendingOnly,
                  label: _cat.label,
                  icon: _cat.icon,
                  color: _cat.color,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final source = _sourceCatFor(item);
                  return _ReviewCard(
                    cat: _cat,
                    source: source,
                    item: item,
                    index: i,
                    onAction: widget.onAction,
                    busyActions: widget.busyActions,
                    onChanged: widget.onItemChanged,
                    isSelected: selectedIds.contains(selectionKey(item)),
                    onSelectionChanged: isSelectionMode
                        ? (v) => toggleSelection(item)
                        : null,
                    selectionMode: isSelectionMode,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainToolbar(ThemeData theme) {
    return Row(
      children: [
        // بحث
        Expanded(
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'بحث في ${_cat.label}...',
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _search.clear())
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // فلتر معلق/الكل — لا معنى له في القائمة الموحّدة (معلّقات فقط بطبيعتها)
        if (!_cat.isAllPending) ...[
          Tooltip(
            message: 'تصفية الحالة',
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: true,
                    label: Text('معلق'),
                    icon: Icon(Icons.hourglass_top_rounded, size: 16)),
                ButtonSegment(
                    value: false,
                    label: Text('الكل'),
                    icon: Icon(Icons.list_alt_rounded, size: 16)),
              ],
              selected: {_pendingOnly},
              onSelectionChanged: (s) => setState(() => _pendingOnly = s.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                minimumSize: WidgetStateProperty.all(const Size(80, 36)),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
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
                  value: 'title',
                  child: Row(children: [
                    Icon(Icons.sort_by_alpha_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('أبجدياً')
                  ])),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(_sortByLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // تحديد متعدد
        Tooltip(
          message: 'تحديد متعدد',
          child: IconButton(
            icon:
                Icon(Icons.checklist_rounded, color: theme.colorScheme.primary),
            onPressed: () => setState(() => isSelectionMode = true),
          ),
        ),
        const SizedBox(width: 4),
        // تحديث
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            setState(() {
              _itemsStream = null;
              _itemsStreamKey = null;
            });
            widget.onItemChanged();
          },
        ),
      ],
    );
  }

  String get _sortByLabel {
    switch (_sortBy) {
      case 'oldest':
        return 'الأقدم';
      case 'title':
        return 'أبجدي';
      default:
        return 'الأحدث';
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.cat,
    required this.selected,
    required this.pending,
    required this.total,
    required this.onTap,
  });
  final _Cat cat;
  final bool selected;
  final int pending;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // التحديد صمغٌ بلون القسم كان يُنتج بياضًا 12px فوق العنبري 1.63 والبرتقالي
    // 2.16 والسماوي 2.30 والوردي 4.35 — لا تجتاز 4.5 بحال، ولا يُصلحها الحبر لأن
    // الأرضية مصمتة. فتبقى درجة القسم كما طلب صاحبها وتُنتقل الدلالة إلى تظليل
    // + إطار غليظ، ويكتب القسمُ نفسُه حبرَه المجرَّب.
    final ink = AppColors.readableInk(cat.color, theme.brightness);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? cat.color.withValues(alpha: 0.18)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? cat.color
                : cat.color.withValues(alpha: 0.2),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: cat.color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2)),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat.icon, size: 16, color: ink),
            const SizedBox(width: 6),
            Text(
              cat.label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                color: selected ? ink : theme.colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
            if (pending > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  // عدّاد المعلّقات حالة وسيطة لا خطأ، فيأخذ العنبري (كما في
                  // شارة اللوحة)، وأما حبره فبرونزي مجرَّب لأن #FF9800 كتابةً
                  // 2.16 فوق البياض.
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.readableInk(
                        AppColors.warningInk, theme.brightness),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({
    required this.pending,
    required this.label,
    required this.icon,
    required this.color,
  });
  final bool pending;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                pending ? Icons.check_circle_outline_rounded : icon,
                size: 64,
                color: color.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pending ? 'رائع! لا توجد عناصر معلقة' : 'لا توجد عناصر',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pending
                  ? 'جميع عناصر $label تمت مراجعتها'
                  : 'لم يتم إضافة أي عناصر في $label بعد',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة خطأ المراجعة — كانت تعيد Container فارغ فتبدو القائمة مكسورة بلا سبب.
class _ErrorReview extends StatelessWidget {
  const _ErrorReview({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56,
                color: AppColors.readableInk(color, theme.brightness,
                    minRatio: 3.0)),
            const SizedBox(height: 16),
            Text(
              'تعذّر تحميل العناصر',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'تحقق من الاتصال بالإنترنت ثم أعد المحاولة',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.cat,
    required this.item,
    required this.index,
    required this.onAction,
    required this.busyActions,
    required this.onChanged,
    this.source,
    this.isSelected = false,
    this.onSelectionChanged,
    this.selectionMode = false,
  });
  final _Cat cat;

  /// فئة القسم المصدري — تظهر فقط في القائمة الموحّدة (بلا قيمة في التبويبات
  /// الفردية حيث يكون `cat` هو المصدر نفسه).
  final _Cat? source;
  final Map<String, dynamic> item;
  final int index;
  final Future<void> Function(String, String, String) onAction;
  final Set<String> busyActions;
  final VoidCallback onChanged;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool selectionMode;

  /// المجموعة الفعلية للعنصر: `_collection` المدموجة في القائمة الموحّدة،
  /// وإلا **مصدر** التبويب الحالي — فالتبويب المصفّى معرّفه وهمي (`tab_*`)
  /// والعنوان الحقيقي للوثيقة في Firestore هو مصدره. كل إجراء (موافقة/رفض/
  /// حذف/تفاصيل/تعديل) يجب أن يوجَّه إليها لا إلى المعرّف الوهمي.
  String get collection => (item['_collection'] as String?) ?? cat.realCollection;
  String get sourceLabel => source?.label ?? cat.label;
  Color get sourceColor => source?.color ?? cat.color;
  IconData get sourceIcon => source?.icon ?? cat.icon;

  /// وصف طبيعة الإجراء ومصدره (سوق/أخبار/طبي…) — يُعرض في القائمة الموحّدة
  /// حتى يعرف المدير ما الذي يوافق عليه دون فتح التفاصيل.
  String get _kindLabel => switch (collection) {
        'news' => 'خبر بانتظار النشر',
        // «المستلزمات الطبية» ليست مجموعة: هي مستند `market_products` بتصنيف
        // واحد، فالبطاقة تسمّي حقيقيتها كي لا يظن المراجع أنه يوافق على منتج
        // سوق عام وهو يوافق على مستلزم يظهر في صفحة الخدمات الطبية.
        'market_products' => item['category'] == kMedicalSuppliesCategory
            ? 'مستلزم طبي من السوق'
            : 'منتج من السوق',
        'shops' => 'محل في السوق',
        // تبويبا «مطلوب/تبرعات» في سوق القرية: مجموعتان حقيقيتان، والموافقة
        // هنا هي البوابة الوحيدة لظهورهما للعامة.
        'buy_requests' => 'طلب شراء (مطلوب) في السوق',
        'donations' => 'تبرع بسلعة في السوق',
        'obituaries' => 'نعوة بانتظار النشر',
        'occasions' => 'مناسبة بانتظار النشر',
        'forum_posts' => 'منشور في المندرة',
        'upgrade_requests' => 'طلب ترقية الحساب',
        'seller_requests' => 'طلب تحوّل إلى بائع',
        'phone_directory' => item['isDispute'] == true
            ? 'طلب مراجعة ملكية رقم هاتف'
            : 'رقم في دليل الهاتف',
        'service_providers' => switch ('${item['category'] ?? ''}') {
            ServiceCategory.agricultural => 'سجل في صفحة خدمات زراعية',
            ServiceCategory.educational => 'سجل في صفحة خدمات تعليمية',
            _ => 'سجل في صفحة دليل الحرفيين',
          },
        'lost_items' => 'إعلان مفقودات',
        'village_ads' => 'إعلان تجاري/خدمي في القرية',
        'lawyers' => 'تسجيل في سجل المحامين',
        'legal_consultations' => 'سؤال استشارة قانونية',
        'agriculture_consultations' => 'سؤال استشارة زراعية',
        'medical_center_clinics' => 'عيادة المركز الطبي الخيري',
        'village_clinics' => 'عيادة من الخدمات الطبية',
        'pharmacies' => 'صيدلية من الخدمات الطبية',
        'medical_labs' => 'معمل تحاليل',
        'optical_shops' => 'محل نظارات',
        'blood_requests' => 'طلب تبرع بالدم',
        'blood_donors' => 'متبرع بالدم',
        _ => 'إجراء بانتظار المراجعة',
      };

  String get _title {
    if (collection == 'phone_directory' && item['isDispute'] == true) {
      return 'مراجعة رقم: ${item['phone'] ?? ''} (الاسم المقترح: ${item['name'] ?? ''})';
    }
    if (collection == 'upgrade_requests') {
      final t = item['targetTitle'] ?? 'ترقية';
      final u = item['userName'] ?? 'مستخدم';
      return 'طلب ترقية: $t ($u)';
    }
    final t = item['title'] ??
        item['name'] ??
        item['shopName'] ??
        item['patientName'] ??
        item['requesterName'] ??
        item['content'] ??
        item['question'] ??
        item['providerName'] ??
        'بدون عنوان';
    return t.toString();
  }

  String get _subtitle {
    if (collection == 'phone_directory' && item['isDispute'] == true) {
      final oldN = item['oldEntryName'] ?? '';
      final newN = item['name'] ?? '';
      final reason = item['disputeReason'] ?? '';
      return 'المسجل حالياً: «$oldN» ← المطلوب: «$newN»\nتوضيح المستخدم: $reason';
    }
    if (collection == 'upgrade_requests') {
      final cRole = (item['currentRole'] ?? 'user').toString();
      final current = cRole == 'seller'
          ? 'بائع (${item['currentSellerType'] ?? 'عادي'})'
          : (cRole == 'admin' ? 'مدير عام' : cRole);
      final notes = (item['notes'] ?? item['reason'] ?? '').toString();
      final noteStr = notes.isNotEmpty ? '\nملاحظات: $notes' : '';
      return 'الحالي: $current ← المطلوب: ${item['targetTitle'] ?? ''}$noteStr';
    }
    return item['description'] ??
        item['content'] ??
        item['question'] ??
        item['userName'] ??
        item['authorName'] ??
        item['shopName'] ??
        item['specialty'] ??
        item['stage'] ??
        item['category'] ??
        '';
  }

  String get _authorName {
    return item['userName'] ??
        item['authorName'] ??
        item['providerName'] ??
        item['requesterName'] ??
        item['patientName'] ??
        item['ownerName'] ??
        'مجهول';
  }

  DateTime? get _createdAt => tsToDateTime(item['createdAt']);

  bool get _isApproved {
    if (collection == 'seller_requests' || collection == 'upgrade_requests') {
      return item['status'] == 'approved';
    }
    if (collection == 'seller_profiles') {
      return true;
    }
    if (collection == 'product_reviews') {
      return item['status'] == 'approved';
    }
    return item['isApproved'] == true;
  }

  String? get _image {
    if (item['imageUrls'] is List && (item['imageUrls'] as List).isNotEmpty) {
      final f = (item['imageUrls'] as List).first;
      if (f is String && f.isNotEmpty) {
        return f;
      }
    }
    for (final k in ['imageUrl', 'userPhotoUrl', 'logoUrl', 'photoUrl']) {
      if (item[k] is String && (item[k] as String).isNotEmpty) {
        return item[k] as String;
      }
    }
    return null;
  }

  bool get _isFeatured =>
      collection == 'service_providers' && item['isFeatured'] == true;

  bool get _offersPrivateTutoring =>
      collection == 'service_providers' &&
      item['offersPrivateTutoring'] == true;

  /// صفة السجل التعليمي كما تظهر في بطاقته العامة؛ السجل القديم الذي بلا
  /// `providerKind` يُعامل كمدرّس، وهو ما يقرأه النموذج نفسه.
  String get _eduKind {
    if (collection != 'service_providers' ||
        item['category'] != ServiceCategory.educational) {
      return '';
    }
    final kind = (item['providerKind'] as String? ?? '').trim();
    return kind.isEmpty ? kEduKindTeacher : kind;
  }

  Color get _eduKindColor =>
      ServiceCategory.color(ServiceCategory.educational);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = item['id'] as String;
    final statusColor = _isApproved ? AppColors.success : Colors.orange;
    // الشريتان ترسمان لونهما **حبرًا** فوق تظليل 0.12 من نفس اللون. البرتقالي
    // 2.16 فوق البياض لا يُقرأ عند 10px، ودرجات الأقسام الفاتحة (العنبري
    // والسماوي والبرتقالي) كذلك — فيُزحزح السطوع وحده حتى تجتاز 4.5 مع بقاء
    // اللون والتشبّع، لأن التظليل خفيف فلا يُغني عن قياس الحبر.
    final sourceInk = AppColors.readableInk(sourceColor, theme.brightness);
    final statusInk = AppColors.readableInk(statusColor, theme.brightness);
    final isBusy =
        busyActions.any((k) => k.endsWith('${collection}_$id'));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectionMode && isSelected
              ? theme.colorScheme.primary
              : (_isFeatured
                  ? const Color(0xFFB8860B)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
          width: selectionMode && isSelected ? 2 : (_isFeatured ? 1.4 : 1),
        ),
        color: selectionMode && isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : (_isFeatured
                ? const Color(0xFFFEF3C7)
                : theme.colorScheme.surface),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: selectionMode
              ? () => onSelectionChanged?.call(!isSelected)
              : () async {
                  await Navigator.pushNamed(context, AppRoutes.adminDetail,
                      arguments: {
                        'collection': collection,
                        'docId': id,
                        'item': item
                      });
                  onChanged();
                },
          onLongPress: () => onSelectionChanged?.call(true),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectionMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (v) => onSelectionChanged?.call(v ?? false),
                        fillColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? theme.colorScheme.primary
                                : null),
                      ),
                      const SizedBox(width: 4),
                    ],
                    _thumb(theme),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // القائمة الموحّدة: من أي قسم جاء هذا الإجراء؟
                          if (source != null) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: sourceColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                        color:
                                            sourceColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(sourceIcon,
                                          size: 11, color: sourceInk),
                                      const SizedBox(width: 4),
                                      Text('القسم: $sourceLabel',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: sourceInk)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(_kindLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: theme
                                              .colorScheme.onSurfaceVariant)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Text(_title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800)),
                              ),
                              if (_isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFFF1C40F),
                                      Color(0xFFB8860B)
                                    ]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded,
                                          size: 10, color: Colors.white),
                                      Text('مميز',
                                          style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),
                              if (_eduKind.isNotEmpty)
                                Container(
                                  key: ValueKey('review-edu-kind-$id'),
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _eduKindColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color:
                                            _eduKindColor.withValues(alpha: .45)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      EduKindMark(kind: _eduKind, size: 12),
                                      const SizedBox(width: 3),
                                      Text(_eduKind,
                                          style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: _eduKindColor)),
                                    ],
                                  ),
                                ),
                              if (_offersPrivateTutoring)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00695C)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFF00695C)
                                            .withValues(alpha: 0.45)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cast_for_education_rounded,
                                          size: 10, color: Color(0xFF00695C)),
                                      SizedBox(width: 3),
                                      Text('تدريس خاص',
                                          style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF00695C))),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_subtitle.isNotEmpty)
                            Text(_subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: statusColor.withValues(
                                            alpha: 0.3))),
                                child: Text(
                                    _isApproved
                                        ? 'موافق عليه'
                                        : 'بانتظار المراجعة',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: statusInk)),
                              ),
                              const SizedBox(width: 8),
                              if (_createdAt != null)
                                Text(_formatDate(_createdAt!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                              const Spacer(),
                              if (_authorName != 'مجهول')
                                Row(
                                  children: [
                                    Icon(Icons.person_outline_rounded,
                                        size: 10,
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 2),
                                    Text(_authorName,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 10)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!selectionMode) ...[
                  const SizedBox(height: 12),
                  _buildActionButtons(context, id, statusColor, isBusy),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildActionButtons(
      BuildContext context, String id, Color statusColor, bool isBusy) {
    return Row(
      children: [
        Expanded(
          child: _btn(
              context,
              'موافقة',
              Icons.check_rounded,
              AppColors.primary,
              () => onAction(collection, id, 'approve'),
              isBusy),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _btn(context, 'رفض', Icons.close_rounded, AppColors.warning,
              () => onAction(collection, id, 'reject'), isBusy),
        ),
        const SizedBox(width: 6),
        _icon(context, Icons.edit_rounded, Colors.blueGrey, () async {
          await Navigator.pushNamed(context, AppRoutes.adminEdit, arguments: {
            'collection': collection,
            'docId': id,
            'item': item
          });
          onChanged();
        }),
        const SizedBox(width: 6),
        _icon(context, Icons.delete_rounded, AppColors.error,
            () => onAction(collection, id, 'delete'),
            busy: isBusy),
      ],
    );
  }

  Widget _thumb(ThemeData theme) {
    final url = _image;
    // الأيقونة رسمٌ لا نصّ فوق تظليل القسم (0.12)، فحدّها 3.0 وحده المجرَّب.
    final ink =
        AppColors.readableInk(cat.color, theme.brightness, minRatio: 3.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: url == null
            ? Container(
                color: cat.color.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: Icon(cat.icon, color: ink, size: 22),
              )
            : Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: cat.color.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Icon(cat.icon, color: ink))),
      ),
    );
  }

  Widget _btn(BuildContext context, String label, IconData icon, Color color,
      VoidCallback onTap, bool busy) {
    final theme = Theme.of(context);
    // الأرضية تظليل خفيف (0.1) للتمييز نفسه، أما الحبر فيُشتق من التمييز
    // بحدّ النص العادي: العنبري كتابةً 2.16 فوق البياض، و`inkOn` لا يحرّك
    // شيئًا في الفاتح، فيبقى الزر غير مقروء في السمَتين.
    final ink = AppColors.readableInk(color, theme.brightness);
    return SizedBox(
      height: 36,
      child: busy
          ? Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: ink)))
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ink.withValues(alpha: 0.25))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 14, color: ink),
                    const SizedBox(width: 4),
                    Text(label,
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800, color: ink)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _icon(
      BuildContext context, IconData icon, Color color, VoidCallback onTap,
      {bool busy = false}) {
    // نفس فصل الحبر عن التظليل في `_btn`: الأرضية باهتة عمدًا، والحبر أيقونةٌ
    // رسومية وحدّها 3.0، فيُزحزح سطوعها وحدها في السمَتين إن قصرت.
    final ink = AppColors.readableInk(color, Theme.of(context).brightness,
        minRatio: 3.0);
    return SizedBox(
      width: 36,
      height: 36,
      child: busy
          ? Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: ink)))
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ink.withValues(alpha: 0.25))),
                child: Icon(icon, size: 16, color: ink),
              ),
            ),
    );
  }
}

/// نافذة سفلية تتيح تصفح والبحث في كل الأقسام الـ 27 دفعة واحدة مصنفة حسب القطاعات
class _AllCategoriesSheet extends StatefulWidget {
  const _AllCategoriesSheet({
    required this.cats,
    required this.selected,
    required this.pendingCounts,
    required this.totalRealPending,
    required this.pillars,
    required this.collectionPillars,
    required this.onSelect,
  });

  final List<_Cat> cats;
  final String selected;
  final Map<String, int> pendingCounts;
  final int totalRealPending;
  final List<_PillarInfo> pillars;
  final Map<String, String> collectionPillars;
  final ValueChanged<String> onSelect;

  @override
  State<_AllCategoriesSheet> createState() => _AllCategoriesSheetState();
}

class _AllCategoriesSheetState extends State<_AllCategoriesSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.85),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض السحب
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // الترويسة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.grid_view_rounded,
                      color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'دليل أقسام المراجعة (27 قسماً)',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'اختر القسم المطلوب للانتقال إليه مباشرة',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // حقل البحث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'ابحث عن قسم (مثل: صيدليات، محامين، عزاء...)',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // قائمة الأقسام مصنفة حسب الركائز
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: widget.pillars.map((pillar) {
                final inPillar = widget.cats.where((c) {
                  if (widget.collectionPillars[c.collection] != pillar.id) return false;
                  if (_query.isEmpty) return true;
                  return c.label.toLowerCase().contains(_query);
                }).toList(growable: false);

                if (inPillar.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان الركيزة
                      Row(
                        children: [
                          Icon(pillar.icon, size: 16, color: pillar.color),
                          const SizedBox(width: 8),
                          Text(
                            pillar.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: pillar.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${inPillar.length})',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // شبكة أقسام هذه الركيزة
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: inPillar.map((cat) {
                          final isSelected = cat.collection == widget.selected;
                          final pending = cat.isAllPending
                              ? widget.totalRealPending
                              : (widget.pendingCounts[cat.collection] ?? 0);
                          final ink = AppColors.readableInk(cat.color, theme.brightness);

                          return InkWell(
                            onTap: () => widget.onSelect(cat.collection),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cat.color.withValues(alpha: 0.18)
                                    : theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? cat.color
                                      : cat.color.withValues(alpha: 0.25),
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cat.icon, size: 14, color: ink),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                      color: isSelected
                                          ? ink
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (pending > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$pending',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.onWarning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

