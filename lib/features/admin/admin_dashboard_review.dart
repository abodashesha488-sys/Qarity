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

class _ReviewPageState extends State<_ReviewPage> {
  bool _pendingOnly = true;
  final _search = TextEditingController();

  // تثبيت الـStream لكل (مجموعة، وضع) — إعادة إنشائه مع كل ضغطة كتابة
  // كانت تعيد الاشتراك وتومض القائمة.
  Stream<List<Map<String, dynamic>>>? _itemsStream;
  String? _itemsStreamKey;

  Stream<List<Map<String, dynamic>>> _streamFor(String collection, bool pendingOnly) {
    final key = '${collection}_$pendingOnly';
    if (_itemsStreamKey != key || _itemsStream == null) {
      _itemsStreamKey = key;
      _itemsStream =
          AdminService().itemsStream(collection, pendingOnly: pendingOnly);
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
    return Column(
      children: [
        SizedBox(
          height: 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: widget.cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final c = widget.cats[i];
              final sel = c.collection == widget.selected;
              final pending = widget.pendingCounts[c.collection] ?? 0;
              return ChoiceChip(
                selected: sel,
                onSelected: (_) => widget.onSelect(c.collection),
                avatar: pending > 0
                    ? Icon(Icons.error_rounded,
                        size: 16, color: sel ? Colors.white : Colors.red)
                    : Icon(c.icon,
                        size: 16, color: sel ? Colors.white : c.color),
                label: Text(c.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: sel ? Colors.white : null)),
                selectedColor: c.color,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'بحث...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('معلق')),
                  ButtonSegment(value: false, label: Text('الكل')),
                ],
                selected: {_pendingOnly},
                onSelectionChanged: (s) =>
                    setState(() => _pendingOnly = s.first),
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _streamFor(_cat.collection, _pendingOnly),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var items = snapshot.data ?? [];
              final q = _search.text.trim().toLowerCase();
              if (q.isNotEmpty) {
                items = items.where((it) {
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
                    it['category'],
                  ].whereType<String>().join(' ').toLowerCase();
                  return text.contains(q);
                }).toList();
              }
              if (items.isEmpty) {
                return _EmptyReview(pending: _pendingOnly, label: _cat.label);
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ReviewCard(
                  cat: _cat,
                  item: items[i],
                  onAction: widget.onAction,
                  busyActions: widget.busyActions,
                  onChanged: widget.onItemChanged,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.pending, required this.label});
  final bool pending;
  final String label;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(pending ? Icons.task_alt_rounded : Icons.inbox_rounded,
                size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
                pending
                    ? 'لا توجد عناصر معلقة في $label'
                    : 'لا توجد عناصر في $label',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
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
    required this.onAction,
    required this.busyActions,
    required this.onChanged,
  });
  final _Cat cat;
  final Map<String, dynamic> item;
  final Future<void> Function(String, String, String) onAction;
  final Set<String> busyActions;
  final VoidCallback onChanged;

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

  bool get _isApproved {
    if (cat.collection == 'seller_requests') {
      return item['status'] == 'approved';
    }
    if (cat.collection == 'seller_profiles') {
      return true;
    }
    if (cat.collection == 'product_reviews') {
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
      cat.collection == 'service_providers' && item['isFeatured'] == true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = item['id'] as String;
    final statusColor = _isApproved ? const Color(0xFF6F4E37) : Colors.orange;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: _isFeatured
                ? const Color(0xFFB8860B)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: _isFeatured ? 1.4 : 1),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(context, AppRoutes.adminDetail, arguments: {
            'collection': cat.collection,
            'docId': id,
            'item': item
          });
          onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _thumb(theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: statusColor.withValues(alpha: 0.3))),
                              child: Text(
                                  _isApproved ? 'موافق عليه' : 'بانتظار المراجعة',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor)),
                            ),
                            if (_isFeatured) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFF1C40F),
                                    Color(0xFFB8860B)
                                  ]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded,
                                        size: 12, color: Colors.white),
                                    Text('مميز',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                            if (cat.collection == 'service_providers') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: ServiceCategory.color(
                                            '${item['category'] ?? ''}')
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                    'تبويب: ${ServiceCategory.label('${item['category'] ?? ''}')}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: ServiceCategory.color(
                                            '${item['category'] ?? ''}'))),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _btn(
                        context,
                        'موافقة',
                        Icons.check_rounded,
                        const Color(0xFF6F4E37),
                        () => onAction(cat.collection, id, 'approve'),
                        _busy('approve', id)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _btn(
                        context,
                        'رفض',
                        Icons.close_rounded,
                        Colors.orange,
                        () => onAction(cat.collection, id, 'reject'),
                        _busy('reject', id)),
                  ),
                  const SizedBox(width: 6),
                  _icon(context, Icons.edit_rounded, Colors.blueGrey, () async {
                    await Navigator.pushNamed(context, AppRoutes.adminEdit,
                        arguments: {
                          'collection': cat.collection,
                          'docId': id,
                          'item': item
                        });
                    onChanged();
                  }),
                  const SizedBox(width: 6),
                  _icon(context, Icons.delete_rounded, Colors.red,
                      () => onAction(cat.collection, id, 'delete'),
                      busy: _busy('delete', id)),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  bool _busy(String action, String id) =>
      busyActions.contains('${action}_${cat.collection}_$id');

  Widget _thumb(ThemeData theme) {
    final url = _image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: url == null
            ? Container(
                color: cat.color.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: Icon(cat.icon, color: cat.color),
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
      height: 38,
      child: busy
          ? Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: color)))
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.25))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 15, color: color),
                    const SizedBox(width: 5),
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
      width: 38,
      height: 38,
      child: busy
          ? Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: color)))
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.25))),
                child: Icon(icon, size: 16, color: color),
              ),
            ),
    );
  }
}
