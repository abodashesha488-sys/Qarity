import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/utils/helpers.dart';
import '../../core/utils/launch_link.dart';
import '../../models/service_provider_model.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/service_provider_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/edu_kind_mark.dart';
import '../../widgets/full_fit_image.dart';
import '../../widgets/qurity_app_bar.dart';

/// شاشة فئة في دليل الخدمات — صفحة **مستقلة** لكل فئة (مسارها الخاص في
/// `AppRoutes`: technicians / agricultural / educational)، تُفتح مباشرة من
/// الشبكة في الشاشة الرئيسية مثل بقية الصفحات. كانت تُفتح قديمًا عبر بوّابة
/// «دليل الخدمات» الجامعة، وقد أُلغيت.
/// المحتوى: مرشّحات الفئة + مربّع بحث + أقسام المميز/الأكثر تقييماً/الكل.
class ProviderCategoryScreen extends StatefulWidget {
  const ProviderCategoryScreen(
      {super.key, required this.category, this.service});
  final String category;

  /// حقن اختياري للاختبارات (بلا Firebase).
  final ServiceProviderService? service;

  @override
  State<ProviderCategoryScreen> createState() => _ProviderCategoryScreenState();
}

class _ProviderCategoryScreenState extends State<ProviderCategoryScreen> {
  late final Stream<List<ServiceProvider>> _stream =
      (widget.service ?? ServiceProviderService())
          .getApprovedByCategory(widget.category);
  final TextEditingController _search = TextEditingController();
  String _group = '';
  String _query = '';

  // ── مرشّحات الخدمات التعليمية ──
  String _kindFilter = '';
  String _stageFilter = '';
  String _eduTypeFilter = '';
  String _subjectFilter = '';
  bool _privateOnly = false;

  /// منطقة البحث والمرشّحات مطوية افتراضيًا: الصفحة تُظهر سجلاتها من أولها،
  /// والفلاتر المفعّلة تُلوَّخ في الرأس فلا يُخفى شيء على المستخدم.
  bool _filtersOpen = false;

  bool get _isEdu => widget.category == ServiceCategory.educational;

  /// عدد المرشّحات المفعّلة (بلا البحث) — يظهر كشارة على رأس الكارت.
  int get _activeFilterCount => (_isEdu
          ? [
              _kindFilter,
              _stageFilter,
              _eduTypeFilter,
              _subjectFilter,
            ]
          : [_group])
      .where((v) => v.isNotEmpty)
      .length +
      (_isEdu && _privateOnly ? 1 : 0);

  /// ما يلصق الكارت مطويًا: الفلاتر المفعّلة + كلمة البحث الحالية.
  List<String> get _filterSummaryParts => [
        if (_isEdu && _eduFilterSummary.isNotEmpty) _eduFilterSummary,
        if (!_isEdu && _group.isNotEmpty) _group,
        if (_query.isNotEmpty) 'بحث: ${_search.text.trim()}',
      ];

  void _clearAllFilters() {
    setState(() {
      _group = '';
      _kindFilter = '';
      _stageFilter = '';
      _eduTypeFilter = '';
      _subjectFilter = '';
      _privateOnly = false;
      _search.clear();
    });
  }

  List<String> get _groupOptions => kSubcategoriesFor(widget.category);

  String _groupOf(ServiceProvider p) => p.specialty;

  Color get _color => ServiceCategory.color(widget.category);

  /// وصف المرشّحات التعليمية المفعّلة (يظهر تحت عنوان «جميع السجلات»).
  String get _eduFilterSummary => [
        if (_kindFilter.isNotEmpty) _kindFilter,
        if (_stageFilter.isNotEmpty) _stageFilter,
        if (_eduTypeFilter.isNotEmpty) _eduTypeFilter,
        if (_subjectFilter.isNotEmpty) _subjectFilter,
        if (_privateOnly) 'تدريس خاص',
      ].join(' · ');

  @override
  void initState() {
    super.initState();
    _search.addListener(
        () => setState(() => _query = _search.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(ServiceProvider p) {
    if (_isEdu) {
      if (_kindFilter.isNotEmpty && p.providerKindLabel != _kindFilter) {
        return false;
      }
      if (_stageFilter.isNotEmpty) {
        // «مراحل أخرى» = السجلات القديمة التي لا مرحلة لها ضمن الخمس.
        final hit = _stageFilter == kEduStageOther
            ? p.stages.isEmpty
            : p.stages.contains(_stageFilter);
        if (!hit) return false;
      }
      if (_eduTypeFilter.isNotEmpty && !p.eduTypes.contains(_eduTypeFilter)) {
        return false;
      }
      if (_subjectFilter.isNotEmpty &&
          !p.subjects.contains(_subjectFilter) &&
          !p.specialty.contains(_subjectFilter)) {
        return false;
      }
      if (_privateOnly && !p.offersPrivateTutoring) return false;
    } else if (_group.isNotEmpty && _groupOf(p) != _group) {
      return false;
    }
    if (_query.isEmpty) return true;
    return [
      p.name,
      p.specialty,
      p.stage,
      p.address,
      p.description,
      if (_isEdu) ...[
        p.providerKindLabel,
        p.subjectsLine,
        p.stagesLine,
        p.eduTypesLine,
        p.universityNote,
      ] else
        _groupOf(p),
      ServiceCategory.label(widget.category),
    ].join(' ').toLowerCase().contains(_query);
  }

  Future<void> _openForm({ServiceProvider? existing}) async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    if (user == null) {
      _snack('سجّل الدخول أولاً', error: true);
      return;
    }
    final uid = user.uid;
    final identity = await UserService().resolveAuthor();
    if (!mounted) return;
    final res = await showModalBottomSheet<ServiceProvider>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ProviderFormSheet(
        category: widget.category,
        userId: uid,
        userName: identity.name,
        existing: existing,
      ),
    );
    if (res == null) return;
    final editing = existing != null;
    try {
      if (editing) {
        await ServiceProviderService().update(res);
        _snack('تم حفظ التعديلات — عاد السجل للمراجعة');
      } else {
        await ServiceProviderService().create(res);
        _snack('تم إرسال الإضافة — تظهر في الدليل بعد موافقة الإدارة');
      }
    } catch (e) {
      _snack('خطأ: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : const Color(0xFF6F4E37),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  /// رأس كارت «بحث وتصفية» + جسمه القابل للطي.
  Widget _filterCard(ThemeData theme) {
    final summary = _filterSummaryParts;
    return Material(
      color: _color.withValues(alpha: 0.06),
      child: Column(
        children: [
          InkWell(
            key: const Key('filters-toggle'),
            onTap: () => setState(() => _filtersOpen = !_filtersOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Icon(_filtersOpen ? Icons.tune_rounded : Icons.search_rounded,
                      size: 17, color: _color),
                  const SizedBox(width: 7),
                  Text('بحث وتصفية',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _color)),
                  if (_activeFilterCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      key: const Key('filters-count'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$_activeFilterCount',
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _filtersOpen || summary.isEmpty
                            ? ''
                            : summary.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4B4038)),
                      ),
                    ),
                  ),
                  if (_activeFilterCount > 0 || _query.isNotEmpty)
                    IconButton(
                      key: const Key('filters-clear'),
                      tooltip: 'مسح الكل',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.layers_clear_rounded,
                          size: 18, color: Color(0xFFB71C1C)),
                      onPressed: _clearAllFilters,
                    ),
                  AnimatedRotation(
                    turns: _filtersOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child:
                        Icon(Icons.expand_more_rounded, size: 18, color: _color),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _filtersOpen
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Column(
                      children: [
                        _searchField(theme),
                        const SizedBox(height: 10),
                        if (_isEdu)
                          ..._eduFilters(theme)
                        else
                          _groupPill(theme),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _searchField(ThemeData theme) {
    return TextField(
      key: const Key('provider-search'),
      controller: _search,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: switch (widget.category) {
          ServiceCategory.technicians => 'ابحث في السجلات: اسم أو حرفة…',
          ServiceCategory.agricultural => 'ابحث في السجلات: اسم أو خدمة…',
          _ => 'ابحث: اسم، مادة، مرحلة، تخصص جامعي…',
        },
        prefixIcon: Icon(Icons.search_rounded, color: _color, size: 19),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                tooltip: 'مسح',
                icon: const Icon(Icons.clear_rounded, size: 17),
                onPressed: _search.clear,
              )
            : null,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _color.withValues(alpha: 0.35))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _color.withValues(alpha: 0.35))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _color, width: 1.4)),
      ),
    );
  }

  /// زر مرشّح مضغوط يفتح قائمة اختيار أسفل الشاشة، بدل حقل منسدل بارتفاع حقل كامل.
  Widget _filterPill({
    required Key key,
    required String label,
    required IconData icon,
    required String value,
    required String allLabel,
    required List<String> options,
    required String group,
    bool searchable = false,
  }) {
    final active = value.isNotEmpty;
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(11),
      onTap: () => _openFilterSheet(
        title: label,
        value: value,
        allLabel: allLabel,
        options: options,
        searchable: searchable,
        group: group,
      ),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: active ? _color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border:
              Border.all(color: active ? _color : _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: _color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(active ? value : '$label: $allLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                      color: active
                          ? _color
                          : const Color(0xFF5B4E45))),
            ),
            const Icon(Icons.expand_more_rounded,
                size: 15, color: Color(0xFF5B4E45)),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet({
    required String title,
    required String value,
    required String allLabel,
    required List<String> options,
    required bool searchable,
    required String group,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (_) => _FilterOptionSheet(
        title: title,
        value: value,
        allLabel: allLabel,
        options: options,
        searchable: searchable,
        accent: _color,
      ),
    );
    if (picked == null) return;
    setState(() {
      switch (group) {
        case 'group':
          _group = picked;
        case 'stage':
          _stageFilter = picked;
        case 'eduType':
          _eduTypeFilter = picked;
        case 'subject':
          _subjectFilter = picked;
      }
    });
  }

  /// مرشّح الفئة في صفحتي الحرفيين والزراعية.
  Widget _groupPill(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: _filterPill(
        key: const Key('filter-group'),
        label: 'الفئة',
        icon: Icons.filter_alt_rounded,
        value: _group,
        allLabel: 'كل الفئات',
        options: [..._groupOptions, 'غير مصنّف'],
        searchable: _groupOptions.length > 10,
        group: 'group',
      ),
    );
  }

  /// مرشّحات الخدمات التعليمية: رقائق الصفة والتدريس الخاص في سطر،
  /// والمرشّحات الثلاثة في سطر واحد كأزرار مضغوطة.
  List<Widget> _eduFilters(ThemeData theme) {
    return [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final k in ['', ...kEduKinds])
            ChoiceChip(
              key: ValueKey('filter-kind-${k.isEmpty ? 'all' : k}'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              label: Text(k.isEmpty ? 'الكل' : k,
                  style: const TextStyle(fontSize: 11.5)),
              selected: _kindFilter == k,
              showCheckmark: false,
              avatar: k.isEmpty ? null : EduKindMark(kind: k, size: 13),
              selectedColor: _color.withValues(alpha: 0.16),
              side: BorderSide(
                  color: _kindFilter == k
                      ? _color
                      : theme.colorScheme.outlineVariant),
              labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight:
                      _kindFilter == k ? FontWeight.w900 : FontWeight.w600,
                  color: _kindFilter == k
                      ? _color
                      : theme.colorScheme.onSurfaceVariant),
              onSelected: (_) => setState(() => _kindFilter = k),
            ),
          ChoiceChip(
            key: const Key('filter-private-only'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            label: const Text('تدريس خاص', style: TextStyle(fontSize: 11.5)),
            selected: _privateOnly,
            showCheckmark: false,
            avatar: Icon(Icons.cast_for_education_rounded,
                size: 14,
                color: _privateOnly
                    ? kEduPrivateTagColor
                    : theme.colorScheme.onSurfaceVariant),
            selectedColor: kEduPrivateTagColor.withValues(alpha: 0.16),
            side: BorderSide(
                color: _privateOnly
                    ? kEduPrivateTagColor
                    : theme.colorScheme.outlineVariant),
            labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: _privateOnly ? FontWeight.w900 : FontWeight.w600,
                color: _privateOnly
                    ? kEduPrivateTagColor
                    : theme.colorScheme.onSurfaceVariant),
            onSelected: (v) => setState(() => _privateOnly = v),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _filterPill(
              key: const Key('filter-stage'),
              label: 'المرحلة',
              icon: Icons.school_rounded,
              value: _stageFilter,
              allLabel: 'الكل',
              options: [...kEduStages, kEduStageOther],
              group: 'stage',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _filterPill(
              key: const Key('filter-edu-type'),
              label: 'التعليم',
              icon: Icons.category_rounded,
              value: _eduTypeFilter,
              allLabel: 'الكل',
              options: kEduTypes,
              group: 'eduType',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _filterPill(
              key: const Key('filter-subject'),
              label: 'المادة',
              icon: Icons.menu_book_rounded,
              value: _subjectFilter,
              allLabel: 'الكل',
              options: kEgyptSubjects,
              searchable: true,
              group: 'subject',
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(
        title: ServiceCategory.label(widget.category),
        onAdd: _openForm,
        addTooltip: switch (widget.category) {
          ServiceCategory.technicians => 'أضف حرفياً',
          ServiceCategory.agricultural => 'أضف خدمة',
          _ => 'أضف مدرّساً أو مدرسة',
        },
      ),
      body: Column(
        children: [
          // كارت واحد قابل للطي: البحث + مرشّحات الفئة.
          _filterCard(theme),
          Expanded(
            child: StreamBuilder<List<ServiceProvider>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? [];
                if (all.isEmpty) {
                  return _EmptyCategory(category: widget.category);
                }
                final visible = all.where(_matches).toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 52, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text('لا نتائج مطابقة',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('جرّب فئة أخرى أو كلمة أبسط',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                final featured = visible.where((p) => p.isFeatured).toList();
                final topRated = (visible
                    .where((p) => !p.isFeatured && p.ratingCount > 0)
                    .toList())
                  ..sort((a, b) => b.rating.compareTo(a.rating));
                final top5 = topRated.take(5).toList();
                final topIds = top5.map((p) => p.id).toSet();
                final rest = visible
                    .where((p) => !p.isFeatured && !topIds.contains(p.id))
                    .toList();
                final filterLabel = _isEdu ? _eduFilterSummary : _group;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
                  children: [
                    if (featured.isNotEmpty) ...[
                      _MiniHead(
                          title: 'المميز',
                          subtitle: 'اختيار إدارة القرية',
                          icon: Icons.workspace_premium_rounded,
                          color: const Color(0xFFB8860B),
                          count: featured.length),
                      for (final p in featured)
                        _ProviderCard(provider: p, accent: _color),
                      const SizedBox(height: 8),
                    ],
                    if (top5.isNotEmpty) ...[
                      _MiniHead(
                          title: 'الأكثر تقييماً',
                          subtitle: 'الأعلى بتقييم المستخدمين',
                          icon: Icons.star_rounded,
                          color: Colors.amber.shade700,
                          count: top5.length),
                      for (final p in top5)
                        _ProviderCard(provider: p, accent: _color),
                      const SizedBox(height: 8),
                    ],
                    if (rest.isNotEmpty) ...[
                      _MiniHead(
                          title: 'جميع السجلات',
                          subtitle: filterLabel.isNotEmpty
                              ? filterLabel
                              : 'المقدّمة من المستخدمين والإدارة',
                          icon: Icons.list_alt_rounded,
                          color: _color,
                          count: rest.length),
                      for (final p in rest)
                        _ProviderCard(provider: p, accent: _color),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// قائمة اختيار لمرشّح واحد: تُغلق الشاشة بالقيمة المختارة (نص فارغ = الكل).
/// القوائم الطويلة (المواد، والحرف عند كثرتها) لها بحث داخلي حتى لا يُطلب
/// من المستخدم تمرير قائمة من أربعين عنصرًا.
class _FilterOptionSheet extends StatefulWidget {
  const _FilterOptionSheet({
    required this.title,
    required this.value,
    required this.allLabel,
    required this.options,
    required this.searchable,
    required this.accent,
  });
  final String title;
  final String value;
  final String allLabel;
  final List<String> options;
  final bool searchable;
  final Color accent;

  @override
  State<_FilterOptionSheet> createState() => _FilterOptionSheetState();
}

class _FilterOptionSheetState extends State<_FilterOptionSheet> {
  final TextEditingController _q = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _q.addListener(() => setState(() => _query = _q.text.trim()));
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = _query.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.contains(_query))
            .toList(growable: false);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Row(
              children: [
                Icon(Icons.filter_alt_rounded, size: 18, color: widget.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('مرشّح ${widget.title}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900)),
                ),
                IconButton(
                  tooltip: 'إغلاق',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                key: const Key('filter-sheet-search'),
                controller: _q,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ابحث في ${widget.title}…',
                  prefixIcon:
                      const Icon(Icons.search_rounded, size: 19),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide(
                          color: widget.accent.withValues(alpha: 0.35))),
                ),
              ),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                _optionTile(theme, '', widget.allLabel),
                if (matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('لا خيار مطابق لـ «$_query»',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B5F57))),
                  ),
                for (final o in matches) _optionTile(theme, o, o),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile(ThemeData theme, String value, String label) {
    final selected = widget.value == value;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: selected
          ? Icon(Icons.check_circle_rounded, size: 19, color: widget.accent)
          : const Icon(Icons.circle_outlined,
              size: 19, color: Color(0xFFB9AEA6)),
      title: Text(label,
          style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              color: selected ? widget.accent : const Color(0xFF2B2118))),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}

/// عنوان قسم مصغّر (داخل شاشة الفئة).
class _MiniHead extends StatelessWidget {
  const _MiniHead({
    required this.title,
    required this.icon,
    required this.color,
    this.subtitle,
    this.count,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900, color: color)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900, color: color)),
            ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.accent});
  final ServiceProvider provider;
  final Color accent;

  /// ضلع صورة البطاقة: نحو ثلث عرض البطاقة على شاشة الهاتف.
  static const double _kImageSide = 104;

  Color get _color => provider.isFeatured ? const Color(0xFFB8860B) : accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: color.withValues(alpha: provider.isFeatured ? 0.6 : 0.22)),
      ),
      color: provider.isFeatured
          ? const Color(0xFFB8860B).withValues(alpha: 0.06)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
            context, AppRoutes.serviceProviderDetail,
            arguments: provider),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FullFitImage(
                key: ValueKey('card-image-${provider.id}'),
                imageUrl: provider.photoUrl ?? '',
                width: _kImageSide,
                fallback: _avatar(theme, color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headline(),
                    if (provider.ratingCount > 0) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                              '${provider.rating.toStringAsFixed(1)} (${provider.ratingCount})',
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber)),
                        ],
                      ),
                    ],
                    if (provider.isEducational && _eduTags.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Wrap(spacing: 4, runSpacing: 4, children: _eduTags),
                    ],
                    if (provider.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(provider.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              height: 1.35,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 8),
                    _actions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// الاسم + شارة الصفة + شارة «مميز».
  Widget _headline() {
    final color = _color;
    final kind = provider.isSchool ? kEduKindSchool : kEduKindTeacher;
    return Row(
      children: [
        Flexible(
          child: Text(provider.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ),
        if (provider.isEducational) ...[
          const SizedBox(width: 5),
          _tag(kind, color, mark: kind),
        ],
        if (provider.isFeatured) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF1C40F), Color(0xFFB8860B)]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 10, color: Colors.white),
                Text('مميز',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// زرا الاتصال (أخضر) ومشاركة (أزرق) بحجم محتواهما — لا يملأان عرض البطاقة.
  Widget _actions() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (provider.hasContact)
          _miniAction(
            key: ValueKey('card-call-${provider.id}'),
            label: 'اتصال',
            icon: Icons.call_rounded,
            color: kCallButtonColor,
            onTap: () async {
              // بلا بوّابة `canLaunchUrl`: الفحص القبلي كان يصمت حين لا تُرى حزمة
              // الطلب على أندرويد 11+، والتجربة المباشرة هي الدليل.
              final error = await launchPhoneCall(provider.phone);
              if (error != null) AppHelpers.showToast(error, isError: true);
            },
          ),
        _miniAction(
          key: ValueKey('card-share-${provider.id}'),
          label: 'مشاركة',
          icon: Icons.share_rounded,
          color: kShareButtonColor,
          onTap: _share,
        ),
      ],
    );
  }

  Widget _miniAction({
    required Key key,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 32,
      child: FilledButton.icon(
        key: key,
        onPressed: onTap,
        style: FilledButton.styleFrom(
            backgroundColor: color,
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 11)),
        icon: Icon(icon, size: 14),
        label: Text(label,
            style:
                const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _share() {
    ShareService.shareText(
        title: provider.isEducational
            ? '\u{1F393} ${provider.name}'
            : '\u{1F6E0}\u{FE0F} ${provider.name}',
        body: [
          if (provider.isEducational && provider.providerKindLabel.isNotEmpty)
            'الصفة: ${provider.providerKindLabel}',
          if (provider.displaySpecialty.isNotEmpty)
            provider.isEducational
                ? 'المواد: ${provider.displaySpecialty}'
                : 'التخصص: ${provider.displaySpecialty}',
          if (provider.isEducational && provider.stagesLine.isNotEmpty)
            'المراحل: ${provider.stagesLine}',
          if (provider.isEducational && provider.eduTypesLine.isNotEmpty)
            'نوع التعليم: ${provider.eduTypesLine}',
          if (provider.isEducational &&
              provider.universityNote.trim().isNotEmpty)
            'التخصص الجامعي: ${provider.universityNote.trim()}',
          if (provider.isEducational && provider.offersPrivateTutoring)
            'امكانية تدريس خاص \u2713',
          if (provider.description.isNotEmpty) provider.description,
          if (provider.address.isNotEmpty) 'العنوان: ${provider.address}',
          if (provider.phone.isNotEmpty) 'هاتف: ${provider.phone}',
        ].join('\n'));
  }

  /// محتوى العمود التعليمي: سطر المواد + رقائق المراحل/الأنواع/التدريس الخاص.
  List<Widget> get _eduTags {
    final color = _color;
    return [
      if (provider.displaySpecialty.isNotEmpty)
        Text(provider.displaySpecialty,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      for (final s in provider.stageChips)
        _tag(s, color, icon: Icons.school_rounded),
      for (final t in provider.eduTypes)
        _tag(t, const Color(0xFF6A1B9A), icon: Icons.category_rounded),
      if (provider.offersPrivateTutoring)
        _tag('تدريس خاص', kEduPrivateTagColor,
            icon: Icons.cast_for_education_rounded, filled: true),
    ];
  }

  Widget _tag(String text, Color color,
      {IconData? icon, String? mark, bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: filled ? 1 : 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark != null)
            EduKindMark(kind: mark, size: 12)
          else if (icon != null)
            Icon(icon, size: 9, color: filled ? Colors.white : color),
          if (mark != null || icon != null) const SizedBox(width: 3),
          Text(text,
              style: TextStyle(
                  fontSize: 9,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: filled ? Colors.white : color)),
        ],
      ),
    );
  }

  Widget _avatar(ThemeData theme, Color accent) {
    final path = provider.isEducational
        ? EduKindMark.imageOf(provider.providerKind)
        : null;
    if (path == null) return _letterAvatar(theme, accent);
    return Image.asset(
      path,
      width: _kImageSide,
      height: _kImageSide,
      fit: BoxFit.cover,
      cacheWidth: (_kImageSide * 3).round(),
      errorBuilder: (_, __, ___) => _letterAvatar(theme, accent),
    );
  }

  Widget _letterAvatar(ThemeData theme, Color accent) => Container(
        color: accent.withValues(alpha: 0.1),
        alignment: Alignment.center,
        child: Text(
          provider.name.isNotEmpty ? provider.name.substring(0, 1) : '\u061F',
          style: TextStyle(
              color: accent, fontWeight: FontWeight.w900, fontSize: 34),
        ),
      );
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ServiceCategory.color(category);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ServiceCategory.icon(category),
                size: 64, color: color.withValues(alpha: 0.35)),
            const SizedBox(height: 14),
            Text(
              'لا توجد ${ServiceCategory.label(category)} معتمدة بعد',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'كن أول من يضيف خدمة — استخدم زر الإضافة أسفل الصفحة',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ نموذج الإضافة ═══════════════════════════
/// نموذج إضافة بيان إلى دليل الخدمات (عام لثلاث فئات، وبحقول تعليمية
/// متعددة الاختيار للفئة التعليمية).
class ProviderFormSheet extends StatefulWidget {
  const ProviderFormSheet(
      {super.key,
      required this.category,
      required this.userId,
      required this.userName,
      this.existing,
      this.uploader,
      this.bytesSource});
  final String category;
  final String userId;
  final String userName;

  /// بيان يملكه المستخدم الحالي — النموذج نفسه للتعديل (البند ٨): تُملأ
  /// الحقول من السجل، ويُعاد بنفس `id`/`createdAt`/النسبة فيحفظها Caller
  /// عبر `ServiceProviderService.update` الذي يفرض العودة إلى المراجعة.
  final ServiceProvider? existing;

  /// اختياري لاختبار المحرّر المشترك بلا شبكة ولا معرض جهاز.
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;

  @override
  State<ProviderFormSheet> createState() => _ProviderFormSheetState();
}

class _ProviderFormSheetState extends State<ProviderFormSheet> {
  late final TextEditingController _nameC =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _phoneC =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final TextEditingController _addressC =
      TextEditingController(text: widget.existing?.address ?? '');
  late final TextEditingController _descC =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _universityC =
      TextEditingController(text: widget.existing?.universityNote ?? '');
  final _subjectSearchC = TextEditingController();
  final _customSubjectC = TextEditingController();
  late String _specialty = _initialSpecialty;

  /// خيارات الحرفة/الخدمة: تُضاف قيمة السجل المحفوظة أولًا إن لم تكن في
  /// القائمة الحالية، فإبدالها ببداية القائمة كان يغيّر حرفة حرفيٍّ قديم
  /// لمجرد أن تسميتها أُزيلت من `kTechnicianCrafts`.
  List<String> get _specialtyOptions {
    final options = kSubcategoriesFor(widget.category);
    final saved = widget.existing?.specialty.trim() ?? '';
    if (saved.isEmpty || options.contains(saved)) return options;
    return [saved, ...options];
  }

  String get _initialSpecialty {
    final options = _specialtyOptions;
    final saved = widget.existing?.specialty.trim() ?? '';
    return options.contains(saved) ? saved : options.first;
  }

  // ── الخدمات التعليمية: صفة + اختيار متعدد ──
  String _kind = kEduKindTeacher;
  final Set<String> _eduTypes = {};
  final Set<String> _stages = {};
  final Set<String> _subjects = {};
  bool _privateTutoring = false;
  String _subjectQuery = '';

  bool _saving = false;

  /// انشغال الرفع كما يُبلّغه المحرّر المشترك — لا يملك النموذج الرفع ليُنبَّأ
  /// بدونه، والحفظ أثناءه كان يُضيع الصورة.
  bool _uploading = false;
  String? _photoUrl;

  bool get _isEdit => widget.existing != null;

  bool get _isEdu => widget.category == ServiceCategory.educational;

  /// تخصصات كتبها صاحب السجل بنفسه (تُقبل عدة قيم مفصولة بفواصل).
  List<String> get _customSubjects => _customSubjectC.text
      .split(RegExp(r'[،,]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  Color get _accent => ServiceCategory.color(widget.category);

  @override
  void initState() {
    super.initState();
    final editing = widget.existing;
    if (editing == null) return;
    _kind = editing.providerKind;
    _eduTypes.addAll(editing.eduTypes);
    _stages.addAll(editing.stages);
    _subjects.addAll(editing.subjects.where(kEgyptSubjects.contains));
    _privateTutoring = editing.offersPrivateTutoring;
    _photoUrl = (editing.photoUrl?.trim().isNotEmpty ?? false)
        ? editing.photoUrl!.trim()
        : null;
    // مادة قديمة لم تعد في `kEgyptSubjects` تُستعاد في الخانة الحرة، وإلا
    // ضاعت من السجل بمجرد فتح التعديل.
    final free =
        editing.subjects.where((s) => !kEgyptSubjects.contains(s)).join('، ');
    if (free.isNotEmpty) _customSubjectC.text = free;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _descC.dispose();
    _universityC.dispose();
    _subjectSearchC.dispose();
    _customSubjectC.dispose();
    super.dispose();
  }

  /// الصورة الافتراضية داخل دائرة الصورة حين لا يرفع المستخدم شيئًا:
  /// «mal» للمدرّس و«femal» للمدرسة، مملوءة كامل الدائرة كما ستُعرض لاحقًا.
  Widget _defaultPhotoMark() {
    final path = _isEdu ? EduKindMark.imageOf(_kind) : null;
    if (path == null) {
      return Icon(Icons.person_rounded, size: 36, color: _accent);
    }
    return ClipOval(
      child: Image.asset(
        path,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        cacheWidth: 240,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.person_rounded, size: 36, color: _accent),
      ),
    );
  }

  void _warn(String msg) {
    // أزل التنبيه السابق فوراً حتى لا يصطف خلفه ويختفي سبب المنع الأحدث.
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating));
  }

  void _submit() {
    if (_uploading) {
      _warn('الصورة ما زالت تُرفع… انتظر ثوانٍ ثم اضغط حفظ');
      return;
    }
    final name = _nameC.text.trim();
    final phone = _phoneC.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _warn('الاسم ورقم الهاتف مطلوبان');
      return;
    }
    if (_isEdu) {
      if (_eduTypes.isEmpty) {
        _warn('اختر نوع التعليم (عام / أزهري / خاص)');
        return;
      }
      if (_stages.isEmpty) {
        _warn('اختر مرحلة تعليمية واحدة على الأقل');
        return;
      }
      if (_subjects.isEmpty && _customSubjects.isEmpty) {
        _warn('اختر مادة واحدة على الأقل أو اكتب تخصصك في الخانة المخصصة');
        return;
      }
    }
    final wantsUniversity = _stages.contains(kEduStageUniversity);
    final subjects = <String>[
      ...kEgyptSubjects.where(_subjects.contains),
      ..._customSubjects.where((c) => !_subjects.contains(c)),
    ];
    setState(() => _saving = true);
    final editing = widget.existing;
    Navigator.pop(
      context,
      ServiceProvider(
        // التعديل يعيد نفس السجل: المعرّف والتاريخ والنسبة وحالة الإدارة
        // تُقرأ من السول كما هي، و`update` هو من يفرض العودة إلى المراجعة.
        id: editing?.id ?? '',
        category: widget.category,
        specialty: _isEdu ? '' : _specialty,
        name: name,
        phone: phone,
        address: _addressC.text.trim(),
        description: _descC.text.trim(),
        photoUrl: _photoUrl,
        isApproved: editing?.isApproved ?? false,
        isFeatured: editing?.isFeatured ?? false,
        rating: editing?.rating ?? 0,
        ratingCount: editing?.ratingCount ?? 0,
        submittedBy: editing?.submittedBy ?? widget.userId,
        submittedByName: editing?.submittedByName ?? widget.userName,
        createdAt: editing?.createdAt,
        providerKind: _kind,
        eduTypes:
            _isEdu ? kEduTypes.where(_eduTypes.contains).toList() : const [],
        stages: _isEdu ? kEduStages.where(_stages.contains).toList() : const [],
        subjects: _isEdu ? subjects : const [],
        universityNote: wantsUniversity ? _universityC.text.trim() : '',
        offersPrivateTutoring:
            _isEdu && _kind == kEduKindTeacher && _privateTutoring,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdu = widget.category == ServiceCategory.educational;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(ServiceCategory.icon(widget.category),
                    color: _accent, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      _isEdit
                          ? 'تعديل ${ServiceCategory.label(widget.category)}'
                          : 'إضافة إلى ${ServiceCategory.label(widget.category)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 17)),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: _accent.withValues(alpha: 0.1),
                foregroundImage: (_photoUrl?.isNotEmpty ?? false)
                    ? CachedNetworkImageProvider(_photoUrl!)
                    : null,
                child: (_photoUrl?.isNotEmpty ?? false)
                    ? null
                    : _defaultPhotoMark(),
              ),
            ),
            const SizedBox(height: 6),
            ImageListEditor(
              label: 'صورة السجل',
              fieldKey: 'photoUrl',
              single: true,
              urls: (_photoUrl?.isNotEmpty ?? false)
                  ? [_photoUrl!]
                  : const <String>[],
              uploader: widget.uploader,
              bytesSource: widget.bytesSource,
              maxSide: 600,
              onBusyChanged: (busy) => _uploading = busy,
              onChanged: (urls) => setState(() => _photoUrl =
                  urls.isEmpty ? null : urls.first),
            ),
            const SizedBox(height: 10),
            if (isEdu) ...[
              _kindSelector(theme),
              const SizedBox(height: 12),
            ],
            _field(
                theme,
                _nameC,
                isEdu
                    ? (_kind == kEduKindSchool ? 'اسم المدرسة' : 'اسم المدرّس')
                    : 'الاسم / اسم الورشة',
                isEdu && _kind == kEduKindSchool
                    ? Icons.account_balance_rounded
                    : Icons.person_rounded),
            const SizedBox(height: 12),
            if (isEdu) ...[
              _multiSection(
                theme,
                title: 'نوع التعليم',
                hint: 'يمكن الاختيار في أكثر من نوع',
                icon: Icons.category_rounded,
                options: kEduTypes,
                selected: _eduTypes,
                keyPrefix: 'edu-type',
              ),
              const SizedBox(height: 14),
              _multiSection(
                theme,
                title: 'المراحل التعليمية',
                hint: 'يمكن العمل في أكثر من مرحلة',
                icon: Icons.school_rounded,
                options: kEduStages,
                selected: _stages,
                keyPrefix: 'edu-stage',
                onToggle: (value, isOn) {
                  if (!isOn && value == kEduStageUniversity) {
                    _universityC.clear();
                  }
                },
              ),
              if (_stages.contains(kEduStageUniversity)) ...[
                const SizedBox(height: 12),
                _field(theme, _universityC, 'التخصص / الكلية (اكتبه بنفسك)',
                    Icons.edit_note_rounded,
                    key: const Key('edu-university-note')),
                const SizedBox(height: 2),
                Text('اكتب التخصصات الجامعية التي تدرّسها، وافصل بينها بفاصلة.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 14),
              _subjectPicker(theme),
              if (_kind == kEduKindTeacher) ...[
                const SizedBox(height: 14),
                _privateTutoringTile(theme),
              ],
            ] else
              _dropdown(
                  theme,
                  'الحرفة / الخدمة',
                  _specialtyOptions,
                  _specialty,
                  Icons.category_rounded,
                  (v) => setState(() => _specialty = v)),
            const SizedBox(height: 12),
            _field(theme, _phoneC, 'رقم الهاتف', Icons.phone_rounded,
                type: TextInputType.phone),
            const SizedBox(height: 12),
            _field(theme, _addressC, 'العنوان (اختياري)',
                Icons.location_on_rounded),
            const SizedBox(height: 12),
            _field(theme, _descC, 'نبذة عن الخدمة (اختياري)',
                Icons.description_rounded,
                maxLines: 3),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFB71C1C).withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: Color(0xFFB71C1C)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ستتم مراجعة الإضافة من الإدارة قبل نشرها في الدليل',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFB71C1C),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _saving ? null : _submit,
              icon: Icon(_isEdit ? Icons.save_rounded : Icons.send_rounded,
                  size: 18),
              label: Text(
                  _isEdit ? 'حفظ التعديلات' : 'إرسال للمراجعة',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      ThemeData theme, TextEditingController c, String label, IconData icon,
      {TextInputType? type, int maxLines = 1, Key? key}) {
    return TextField(
      key: key,
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _accent, size: 20),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// عنوان قسم داخل النموذج (أيقونة + اسم + سطر إرشادي + عدّاد اختيار).
  Widget _sectionHead(ThemeData theme, String title, IconData icon, String hint,
      {int? count}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _accent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
                Text(hint,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _accent)),
            ),
        ],
      ),
    );
  }

  /// رقائق اختيار متعدد مع إطار يوضّح حالة الاختيار.
  Widget _chipCloud(
    ThemeData theme,
    List<String> options,
    Set<String> selected,
    String keyPrefix, {
    void Function(String value, bool isOn)? onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        children: [
          for (final o in options)
            FilterChip(
              key: ValueKey('$keyPrefix-$o'),
              label: Text(o, style: const TextStyle(fontSize: 12)),
              selected: selected.contains(o),
              showCheckmark: false,
              selectedColor: _accent.withValues(alpha: 0.16),
              backgroundColor: theme.colorScheme.surface,
              side: BorderSide(
                  color: selected.contains(o)
                      ? _accent
                      : theme.colorScheme.outlineVariant),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected.contains(o) ? FontWeight.w800 : FontWeight.w600,
                color: selected.contains(o)
                    ? _accent
                    : theme.colorScheme.onSurfaceVariant,
              ),
              onSelected: (v) {
                setState(() => v ? selected.add(o) : selected.remove(o));
                onToggle?.call(o, v);
              },
            ),
        ],
      ),
    );
  }

  Widget _multiSection(
    ThemeData theme, {
    required String title,
    required String hint,
    required IconData icon,
    required List<String> options,
    required Set<String> selected,
    required String keyPrefix,
    void Function(String value, bool isOn)? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(theme, title, icon, hint, count: selected.length),
        _chipCloud(theme, options, selected, keyPrefix, onToggle: onToggle),
      ],
    );
  }

  /// اختيار المواد: بحث + رقائق مقسّمة حسب القسم.
  Widget _subjectPicker(ThemeData theme) {
    final q = _subjectQuery.trim();
    final matches = q.isEmpty
        ? null
        : kEgyptSubjects.where((s) => s.toLowerCase().contains(q)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(theme, 'المواد الدراسية', Icons.menu_book_rounded,
            'اختر كل المواد التي تدرّسها',
            count: _subjects.length),
        TextField(
          key: const Key('edu-subject-search'),
          controller: _subjectSearchC,
          onChanged: (v) => setState(() => _subjectQuery = v),
          decoration: InputDecoration(
            hintText: 'ابحث عن مادة…',
            prefixIcon: Icon(Icons.search_rounded, size: 19, color: _accent),
            suffixIcon: q.isNotEmpty
                ? IconButton(
                    tooltip: 'مسح',
                    icon: const Icon(Icons.clear_rounded, size: 17),
                    onPressed: () {
                      _subjectSearchC.clear();
                      setState(() => _subjectQuery = '');
                    },
                  )
                : null,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        if (matches != null)
          matches.isEmpty
              ? Text('لا مادة بهذا الاسم',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey))
              : _chipCloud(theme, matches, _subjects, 'edu-subject')
        else
          for (final entry in kEgyptSubjectSections.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 3),
              child: Text(entry.key,
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
            _chipCloud(theme, entry.value, _subjects, 'edu-subject'),
          ],
        const SizedBox(height: 10),
        _field(theme, _customSubjectC, 'تخصص آخر — اكتبه بنفسك',
            Icons.edit_note_rounded,
            key: const Key('edu-subject-custom')),
        const SizedBox(height: 2),
        Text(
            'إن لم تجد مادتك في القوائم اكتبها هنا (وافصل بين عدة تخصصات بفاصلة).',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  /// مدرّس / مدرسة.
  Widget _kindSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(theme, 'صفة مقدّم الخدمة', Icons.badge_rounded,
            'هل أنت مدرّس أم مدرسة؟'),
        Row(
          children: [
            for (final k in kEduKinds)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: k == kEduKinds.first ? 0 : 5,
                      right: k == kEduKinds.last ? 0 : 5),
                  child: InkWell(
                    key: ValueKey('edu-kind-$k'),
                    onTap: () => setState(() {
                      _kind = k;
                      if (k == kEduKindSchool) _privateTutoring = false;
                    }),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _kind == k
                            ? _accent.withValues(alpha: 0.12)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _kind == k
                                ? _accent
                                : theme.colorScheme.outlineVariant,
                            width: _kind == k ? 1.6 : 1),
                      ),
                      child: Column(
                        children: [
                          EduKindMark(kind: k, size: 20),
                          const SizedBox(height: 3),
                          Text(k,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: _kind == k
                                      ? _accent
                                      : theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// مفتاح «تدريس خاص» — يظهر للمدرّس فقط.
  Widget _privateTutoringTile(ThemeData theme) {
    return Container(
      key: const Key('edu-private-tile'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: (_privateTutoring
                ? const Color(0xFF00695C)
                : theme.colorScheme.onSurfaceVariant)
            .withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _privateTutoring
                ? const Color(0xFF00695C)
                : theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.cast_for_education_rounded,
              size: 20,
              color: _privateTutoring
                  ? const Color(0xFF00695C)
                  : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تدريس خاص',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900, fontSize: 13.5)),
                Text('لديّ إمكانية إعطاء دروس خصوصية',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            key: const Key('edu-private-toggle'),
            value: _privateTutoring,
            activeThumbColor: const Color(0xFF00695C),
            onChanged: (v) => setState(() => _privateTutoring = v),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(ThemeData theme, String label, List<String> values,
      String current, IconData icon, void Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: values.contains(current) ? current : values.first,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _accent, size: 20),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: values
          .map((v) => DropdownMenuItem(
              value: v,
              child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (v) => onChanged(v ?? current),
      menuMaxHeight: 340,
    );
  }
}
