import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/service_provider_model.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/service_provider_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/edu_kind_mark.dart';
import '../../widgets/qurity_app_bar.dart';

/// دليل الخدمات — شبكة أزرار لفئات قابلة للتوسّع مستقبلاً.
/// كل زر يفتح شاشة الفئة الخاصة بها (بحث منسدل + مربّع بحث + مميز/الأكثر تقييماً).
class ServiceDirectoryScreen extends StatelessWidget {
  const ServiceDirectoryScreen({super.key});

  static const _categories = [
    ServiceCategory.technicians,
    ServiceCategory.agricultural,
    ServiceCategory.educational,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const QurityAppBar(title: 'دليل الخدمات'),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.98,
        children: [
          for (final c in _categories) _CategoryTile(category: c),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ServiceCategory.color(category);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(context, AppRoutes.serviceCategory,
            arguments: category),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    color,
                    color.withValues(alpha: 0.72),
                  ]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: Icon(ServiceCategory.icon(category),
                    color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(ServiceCategory.label(category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14, color: color)),
              const SizedBox(height: 3),
              Text(
                switch (category) {
                  ServiceCategory.technicians => 'كل الحرف والورش الفنية',
                  ServiceCategory.agricultural => 'آلات وخدمات المزارعين',
                  _ => 'مدرّسون لكل المراحل والمواد',
                },
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.94, 0.94));
  }
}

// ═══════════ شاشة الفئة: قائمة فئات منسدلة + بحث + مميز/الأكثر تقييماً ═══════════
class ProviderCategoryScreen extends StatefulWidget {
  const ProviderCategoryScreen({super.key, required this.category, this.service});
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

  bool get _isEdu => widget.category == ServiceCategory.educational;

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

  Future<void> _openForm() async {
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
      ),
    );
    if (res == null) return;
    try {
      await ServiceProviderService().create(res);
      _snack('تم إرسال الإضافة — تظهر في الدليل بعد موافقة الإدارة');
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

  /// قائمة الفئات المنسدلة (الفنيون والخدمات الزراعية).
  Widget _groupDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _group,
      isExpanded: true,
      menuMaxHeight: 380,
      borderRadius: BorderRadius.circular(16),
      decoration: InputDecoration(
        labelText: 'تصفية حسب الفئة',
        prefixIcon: Icon(Icons.filter_alt_rounded, size: 20, color: _color),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('كل الفئات')),
        ..._groupOptions.map((g) => DropdownMenuItem(
            value: g, child: Text(g, maxLines: 1, overflow: TextOverflow.ellipsis))),
        const DropdownMenuItem(value: 'غير مصنّف', child: Text('غير مصنّف')),
      ],
      onChanged: (v) => setState(() => _group = v ?? ''),
    );
  }

  /// مرشّحات الخدمات التعليمية: الصفة + تدريس خاص + المرحلة + نوع التعليم + المواد.
  List<Widget> _eduFilters(ThemeData theme) {
    return [
      Wrap(
        spacing: 6,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final k in ['', ...kEduKinds])
            ChoiceChip(
              key: ValueKey('filter-kind-${k.isEmpty ? 'all' : k}'),
              label: Text(k.isEmpty ? 'الكل' : k,
                  style: const TextStyle(fontSize: 12)),
              selected: _kindFilter == k,
              showCheckmark: false,
              avatar: k.isEmpty ? null : EduKindMark(kind: k),
              selectedColor: _color.withValues(alpha: 0.16),
              side: BorderSide(
                  color: _kindFilter == k
                      ? _color
                      : theme.colorScheme.outlineVariant),
              labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: _kindFilter == k ? FontWeight.w800 : FontWeight.w600,
                  color: _kindFilter == k
                      ? _color
                      : theme.colorScheme.onSurfaceVariant),
              onSelected: (_) => setState(() => _kindFilter = k),
            ),
          ChoiceChip(
            key: const Key('filter-private-only'),
            label: const Text('تدريس خاص', style: TextStyle(fontSize: 12)),
            selected: _privateOnly,
            showCheckmark: false,
            avatar: Icon(Icons.cast_for_education_rounded,
                size: 15,
                color: _privateOnly
                    ? kEduPrivateTagColor
                    : theme.colorScheme.onSurfaceVariant),
            selectedColor: kEduPrivateTagColor.withValues(alpha: 0.16),
            side: BorderSide(
                color: _privateOnly
                    ? kEduPrivateTagColor
                    : theme.colorScheme.outlineVariant),
            labelStyle: TextStyle(
                fontSize: 12,
                fontWeight:
                    _privateOnly ? FontWeight.w800 : FontWeight.w600,
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
            child: _filterDropdown(
              key: const Key('filter-stage'),
              label: 'المرحلة',
              icon: Icons.school_rounded,
              value: _stageFilter,
              allLabel: 'كل المراحل',
              options: [...kEduStages, kEduStageOther],
              onChanged: (v) => setState(() => _stageFilter = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _filterDropdown(
              key: const Key('filter-edu-type'),
              label: 'نوع التعليم',
              icon: Icons.category_rounded,
              value: _eduTypeFilter,
              allLabel: 'كل الأنواع',
              options: kEduTypes,
              onChanged: (v) => setState(() => _eduTypeFilter = v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _filterDropdown(
        key: const Key('filter-subject'),
        label: 'المواد التعليمية',
        icon: Icons.menu_book_rounded,
        value: _subjectFilter,
        allLabel: 'كل المواد',
        options: kEgyptSubjects,
        onChanged: (v) => setState(() => _subjectFilter = v),
      ),
    ];
  }

  Widget _filterDropdown({
    required Key key,
    required String label,
    required IconData icon,
    required String value,
    required String allLabel,
    required List<String> options,
    required void Function(String) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 340,
      borderRadius: BorderRadius.circular(16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19, color: _color),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: [
        DropdownMenuItem(value: '', child: Text(allLabel)),
        ...options.map((o) => DropdownMenuItem(
            value: o, child: Text(o, maxLines: 1, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(
          title: ServiceCategory.label(widget.category), color: _color),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'svc_cat_fab',
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          switch (widget.category) {
            ServiceCategory.technicians => 'أضف حرفياً',
            ServiceCategory.agricultural => 'أضف خدمة',
            _ => 'أضف مدرّساً أو مدرسة',
          },
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // المرشّحات + مربع البحث أسفلها
          Container(
            color: _color.withValues(alpha: 0.06),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                if (_isEdu) ..._eduFilters(theme) else _groupDropdown(theme),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: switch (widget.category) {
                      ServiceCategory.technicians =>
                        'ابحث في السجلات: اسم أو حرفة…',
                      ServiceCategory.agricultural =>
                        'ابحث في السجلات: اسم أو خدمة…',
                      _ => 'ابحث: اسم، مادة، مرحلة، تخصص جامعي…',
                    },
                    prefixIcon:
                        Icon(Icons.search_rounded, color: _color, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            tooltip: 'مسح',
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => _search.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
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
              ClipRRect(
                key: ValueKey('card-image-${provider.id}'),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: _kImageSide,
                  height: _kImageSide,
                  child: provider.photoUrl != null &&
                          provider.photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: provider.photoUrl!,
                          fit: BoxFit.cover,
                          width: _kImageSide,
                          height: _kImageSide,
                          memCacheWidth: (_kImageSide * 3).round(),
                          errorWidget: (_, __, ___) => _avatar(theme, color),
                        )
                      : _avatar(theme, color),
                ),
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
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 14)),
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

  /// زرا الاتصال (أخضر) ومشاركة (أزرق).
  Widget _actions() {
    return Row(
      children: [
        if (provider.hasContact) ...[
          Expanded(
            child: FilledButton.icon(
              key: ValueKey('card-call-${provider.id}'),
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: provider.phone);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              style: FilledButton.styleFrom(
                  backgroundColor: kCallButtonColor,
                  padding: const EdgeInsets.symmetric(vertical: 7)),
              icon: const Icon(Icons.call_rounded, size: 15),
              label: const Text('اتصال',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: FilledButton.icon(
            key: ValueKey('card-share-${provider.id}'),
            onPressed: _share,
            style: FilledButton.styleFrom(
                backgroundColor: kShareButtonColor,
                padding: const EdgeInsets.symmetric(vertical: 7)),
            icon: const Icon(Icons.share_rounded, size: 15),
            label: const Text('مشاركة',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
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

  Widget _avatar(ThemeData theme, Color accent) => Container(
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
      required this.userName});
  final String category;
  final String userId;
  final String userName;

  @override
  State<ProviderFormSheet> createState() => _ProviderFormSheetState();
}

class _ProviderFormSheetState extends State<ProviderFormSheet> {
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _descC = TextEditingController();
  final _universityC = TextEditingController();
  final _subjectSearchC = TextEditingController();
  final _customSubjectC = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late String _specialty = kSubcategoriesFor(widget.category).first;

  // ── الخدمات التعليمية: صفة + اختيار متعدد ──
  String _kind = kEduKindTeacher;
  final Set<String> _eduTypes = {};
  final Set<String> _stages = {};
  final Set<String> _subjects = {};
  bool _privateTutoring = false;
  String _subjectQuery = '';

  bool _saving = false;
  bool _uploading = false;
  String? _photoUrl;

  bool get _isEdu => widget.category == ServiceCategory.educational;

  /// تخصصات كتبها صاحب السجل بنفسه (تُقبل عدة قيم مفصولة بفواصل).
  List<String> get _customSubjects => _customSubjectC.text
      .split(RegExp(r'[،,]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  Color get _accent => ServiceCategory.color(widget.category);

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

  Future<void> _pickPhoto() async {
    setState(() => _uploading = true);
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 600,
          maxHeight: 600);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final url = await ImageUploadService().uploadImage(bytes);
      if (!mounted) return;
      setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ في رفع الصورة: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
    Navigator.pop(
      context,
      ServiceProvider(
        id: '',
        category: widget.category,
        specialty: _isEdu ? '' : _specialty,
        name: name,
        phone: phone,
        address: _addressC.text.trim(),
        description: _descC.text.trim(),
        photoUrl: _photoUrl,
        submittedBy: widget.userId,
        submittedByName: widget.userName,
        providerKind: _kind,
        eduTypes: _isEdu ? kEduTypes.where(_eduTypes.contains).toList() : const [],
        stages: _isEdu ? kEduStages.where(_stages.contains).toList() : const [],
        subjects: _isEdu ? subjects : const [],
        universityNote: wantsUniversity ? _universityC.text.trim() : '',
        offersPrivateTutoring: _isEdu && _kind == kEduKindTeacher && _privateTutoring,
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
                  child: Text('إضافة إلى ${ServiceCategory.label(widget.category)}',
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
              child: GestureDetector(
                onTap: _uploading ? null : _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: _accent.withValues(alpha: 0.1),
                      foregroundImage: _photoUrl != null
                          ? CachedNetworkImageProvider(_photoUrl!)
                          : null,
                      child: _photoUrl == null
                          ? Icon(Icons.person_rounded, size: 36, color: _accent)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.surface, width: 2),
                        ),
                        child: _uploading
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt_rounded,
                                size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
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
                _field(
                    theme,
                    _universityC,
                    'التخصص / الكلية (اكتبه بنفسك)',
                    Icons.edit_note_rounded,
                    key: const Key('edu-university-note')),
                const SizedBox(height: 2),
                Text(
                    'اكتب التخصصات الجامعية التي تدرّسها، وافصل بينها بفاصلة.',
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
                  kSubcategoriesFor(widget.category),
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
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('إرسال للمراجعة',
                  style: TextStyle(fontWeight: FontWeight.w800)),
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
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
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
                      fontSize: 11, fontWeight: FontWeight.w900, color: _accent)),
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
                fontWeight: selected.contains(o)
                    ? FontWeight.w800
                    : FontWeight.w600,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        if (matches != null)
          matches.isEmpty
              ? Text('لا مادة بهذا الاسم',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey))
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
        _field(
            theme,
            _customSubjectC,
            'تخصص آخر — اكتبه بنفسك',
            Icons.edit_note_rounded,
            key: const Key('edu-subject-custom')),
        const SizedBox(height: 2),
        Text('إن لم تجد مادتك في القوائم اكتبها هنا (وافصل بين عدة تخصصات بفاصلة).',
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
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900, fontSize: 13.5)),
                Text('لديّ إمكانية إعطاء دروس خصوصية',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
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
