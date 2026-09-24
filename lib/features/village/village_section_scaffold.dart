import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import 'village_content_admin.dart';

/// هيكل موحّد لشاشات أقسام «تعرف على القرية»:
/// ترويسة مزخرفة + بحث (اختياري) + قائمة بطاقات + شريط إدارة للأدمن.
/// يحلّ حالة الأدمن بنفسه عبر [canManageVillageContent]، فلا تكرّر الشاشات
/// منطق الصلاحيات.
class VillageSectionScaffold<T> extends StatefulWidget {
  const VillageSectionScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.stream,
    required this.cardBuilder,
    required this.formBuilder,
    required this.nameOf,
    required this.remove,
    this.subtitleOf,
    this.searchText,
    this.emptyText = 'لا يوجد محتوى منشور بعد',
    this.searchHint = 'ابحث…',
    this.topBuilder,
    this.manageTitle,
    this.headerHeight = 150,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;

  /// تدفّق العناصر المعروضة (قراءة عامة).
  final Stream<List<T>> stream;

  /// بطاقة العنصر (تُبنى لكل عنصر بترتيبه).
  final Widget Function(BuildContext ctx, T item, int index) cardBuilder;

  /// نموذج الإضافة/التعديل — يُمرّر `null` عند الإضافة.
  final Widget Function(BuildContext ctx, T? editing) formBuilder;

  /// اسم العنصر داخل قائمة الإدارة.
  final String Function(T item) nameOf;

  /// وصف مختصر للعنصر داخل قائمة الإدارة.
  final String Function(T item)? subtitleOf;

  /// حذف عنصر (تعمل من لوحة الإدارة).
  final Future<void> Function(String id) remove;

  /// نص بحث داخل العنصر. إن كانت `null` لا يظهر حقل البحث.
  final String Function(T item)? searchText;

  final String emptyText;
  final String searchHint;

  /// محتوى إضافي أعلى القائمة (شرائح فلترة مثلاً).
  final Widget Function(BuildContext ctx)? topBuilder;

  /// عنوان لوحة الإدارة (افتراضياً عنوان الشاشة).
  final String? manageTitle;

  final double headerHeight;

  @override
  State<VillageSectionScaffold<T>> createState() =>
      _VillageSectionScaffoldState<T>();
}

class _VillageSectionScaffoldState<T> extends State<VillageSectionScaffold<T>> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    canManageVillageContent().then((v) {
      if (mounted && v) setState(() => _isAdmin = true);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<T> _filter(List<T> items) {
    final searchText = widget.searchText;
    if (searchText == null || _query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items
        .where((i) => searchText(i).toLowerCase().contains(q))
        .toList(growable: false);
  }

  Future<void> _manage() async {
    await manageVillageContent<T>(
      context,
      title: widget.manageTitle ?? widget.title,
      accent: widget.accent,
      stream: widget.stream,
      nameOf: widget.nameOf,
      subtitleOf: widget.subtitleOf,
      remove: widget.remove,
      formBuilder: widget.formBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(title: widget.title, color: widget.accent),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'village_manage_${widget.title}',
              backgroundColor: widget.accent,
              foregroundColor: Colors.white,
              onPressed: _manage,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('إدارة',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      body: Column(
        children: [
          VillageSectionHeader(
            accent: widget.accent,
            title: widget.title,
            subtitle: widget.subtitle,
            icon: widget.icon,
            height: widget.headerHeight,
          ),
          if (widget.topBuilder != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: widget.topBuilder!(context),
            ),
          if (widget.searchText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  isDense: true,
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<T>>(
              stream: widget.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _message(theme,
                      'تعذّر تحميل المحتوى — تحقق من الاتصال', widget.accent);
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                }
                final items = _filter(snapshot.data ?? const []);
                if (items.isEmpty) {
                  return _message(
                      theme,
                      _query.isEmpty ? widget.emptyText : 'لا نتائج مطابقة',
                      widget.accent);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      widget.cardBuilder(context, items[i], i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(ThemeData theme, String text, Color accent) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                size: 52, color: accent.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      );
}

/// بطاقة نصية بسيطة لأقسام المرجع (عنوان + سطر وصفي + أسطر محتوى).
class VillageInfoCard extends StatelessWidget {
  const VillageInfoCard({
    super.key,
    required this.accent,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.body = const [],
    this.footer,
    this.index = 0,
  });

  final Color accent;
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<String> body;
  final Widget? footer;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shadowColor: accent.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: accent)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                for (final line in body)
                  if (line.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(line,
                          style: const TextStyle(fontSize: 12, height: 1.8)),
                    ),
                if (footer != null) ...[
                  const SizedBox(height: 10),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (40 * index).ms);
  }
}
