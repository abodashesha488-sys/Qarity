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

  // تثبيت الـStream لكل (مجموعة، وضع) — إعادة إنشائه مع كل ضغطة كتابة
  // كان يفكّ الاشتراك ويعيد تنزيل المجموعة كلها في كل حرف.
  Stream<List<Map<String, dynamic>>>? _itemsStream;
  String? _itemsStreamKey;

  /// المجموعات الحقيقية (بلا القائمة الموحّدة الوهمية).
  List<String> get _realCollections => widget.cats
      .map((c) => c.collection)
      .where((c) => c != kAllPending)
      .toList(growable: false);

  /// اسم القسم المصدري لكل مجموعة — يُعرض على بطاقة القائمة الموحّدة.
  Map<String, _Cat> get _catsByCollection =>
      {for (final c in widget.cats) if (c.collection != kAllPending) c.collection: c};

  Stream<List<Map<String, dynamic>>> _streamFor(
      String collection, bool pendingOnly) {
    final key = '${collection}_$pendingOnly';
    if (_itemsStreamKey != key || _itemsStream == null) {
      _itemsStreamKey = key;
      _itemsStream = collection == kAllPending
          ? AdminService().allPendingStream(_realCollections)
          : AdminService().itemsStream(collection, pendingOnly: pendingOnly);
    }
    return _itemsStream!;
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
    final totalPending = widget.pendingCounts.values
        .fold<int>(0, (acc, value) => acc + value);
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

        // ── شريط الفئات المحسّن ─────────────────────────────────
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            itemCount: widget.cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final c = widget.cats[i];
              final sel = c.collection == widget.selected;
              final pending = c.isAllPending
                  ? widget.pendingCounts.values
                      .fold<int>(0, (acc, value) => acc + value)
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
            stream: _streamFor(
                _cat.collection, allPendingView ? true : _pendingOnly),
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
                  final source = _catsByCollection[it['_collection']]?.label ?? '';
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
                  final source =
                      _catsByCollection[item['_collection'] as String?];
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? cat.color
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
            Icon(cat.icon,
                size: 16, color: selected ? Colors.white : cat.color),
            const SizedBox(width: 6),
            Text(
              cat.label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
            if (pending > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : Colors.red,
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
            Icon(Icons.cloud_off_rounded, size: 56, color: color),
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
  /// وإلا مجموعة التبويب الحالي. كل إجراء (موافقة/رفض/حذف/تفاصيل/تعديل)
  /// يجب أن يوجَّه إليها لا إلى `_Cat` الوهمي.
  String get collection => (item['_collection'] as String?) ?? cat.collection;
  String get sourceLabel => source?.label ?? cat.label;
  Color get sourceColor => source?.color ?? cat.color;
  IconData get sourceIcon => source?.icon ?? cat.icon;

  /// وصف طبيعة الإجراء ومصدره (سوق/أخبار/طبي…) — يُعرض في القائمة الموحّدة
  /// حتى يعرف المدير ما الذي يوافق عليه دون فتح التفاصيل.
  String get _kindLabel => switch (collection) {
        'news' => 'خبر بانتظار النشر',
        'market_products' => 'منتج من السوق',
        'shops' => 'محل في السوق',
        'obituaries' => 'نعوة بانتظار النشر',
        'occasions' => 'مناسبة بانتظار النشر',
        'forum_posts' => 'منشور في المندرة',
        'seller_requests' => 'طلب تحوّل إلى بائع',
        'phone_directory' => 'رقم في دليل الهاتف',
        'service_providers' => switch ('${item['category'] ?? ''}') {
            'agricultural' => 'سجل في صفحة خدمات زراعية',
            'educational' => 'سجل في صفحة خدمات تعليمية',
            _ => 'سجل في صفحة دليل الحرفيين',
          },
        'lost_items' => 'إعلان مفقودات',
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
    final t = item['title'] ??
        item['name'] ??
        item['shopName'] ??
        item['patientName'] ??
        item['requesterName'] ??
        item['content'] ??
        item['providerName'] ??
        'بدون عنوان';
    return t.toString();
  }

  String get _subtitle {
    return item['description'] ??
        item['content'] ??
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
    if (collection == 'seller_requests') {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = item['id'] as String;
    final statusColor = _isApproved ? const Color(0xFF6F4E37) : Colors.orange;
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
                                          size: 11, color: sourceColor),
                                      const SizedBox(width: 4),
                                      Text('القسم: $sourceLabel',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: sourceColor)),
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
                                        color: statusColor)),
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
              const Color(0xFF6F4E37),
              () => onAction(collection, id, 'approve'),
              isBusy),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _btn(context, 'رفض', Icons.close_rounded, Colors.orange,
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
        _icon(context, Icons.delete_rounded, Colors.red,
            () => onAction(collection, id, 'delete'),
            busy: isBusy),
      ],
    );
  }

  Widget _thumb(ThemeData theme) {
    final url = _image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: url == null
            ? Container(
                color: cat.color.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: Icon(cat.icon, color: cat.color, size: 22),
              )
            : Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: cat.color.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Icon(cat.icon, color: cat.color))),
      ),
    );
  }

  Widget _btn(BuildContext context, String label, IconData icon, Color color,
      VoidCallback onTap, bool busy) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: busy
          ? Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: color)))
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.25))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(label,
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _icon(
      BuildContext context, IconData icon, Color color, VoidCallback onTap,
      {bool busy = false}) {
    return SizedBox(
      width: 36,
      height: 36,
      child: busy
          ? Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: color)))
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.25))),
                child: Icon(icon, size: 16, color: color),
              ),
            ),
    );
  }
}
