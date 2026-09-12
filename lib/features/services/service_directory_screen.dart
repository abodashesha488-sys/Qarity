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
import '../../widgets/common_appbar_actions.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الخدمات',
            style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.98,
        children: [
          for (final c in _categories) _CategoryTile(category: c),
          const _PhoneBookTile(),
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
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: color)),
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
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.94, 0.94));
  }
}

class _PhoneBookTile extends StatelessWidget {
  const _PhoneBookTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFF00838F);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(context, AppRoutes.phoneDirectory),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [color, Color(0xFF4DD0E1)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x5900838F),
                        blurRadius: 12,
                        offset: Offset(0, 5)),
                  ],
                ),
                child: const Icon(Icons.phone_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              const Text('دليل الهاتف',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: color)),
              const SizedBox(height: 3),
              Text('أرقام أهالي القرية وجهاتها',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.94, 0.94));
  }
}

// ═══════════ شاشة الفئة: قائمة فئات منسدلة + بحث + مميز/الأكثر تقييماً ═══════════
class ProviderCategoryScreen extends StatefulWidget {
  const ProviderCategoryScreen({super.key, required this.category});
  final String category;

  @override
  State<ProviderCategoryScreen> createState() => _ProviderCategoryScreenState();
}

class _ProviderCategoryScreenState extends State<ProviderCategoryScreen> {
  late final Stream<List<ServiceProvider>> _stream =
      ServiceProviderService().getApprovedByCategory(widget.category);
  final TextEditingController _search = TextEditingController();
  String _group = '';
  String _query = '';

  bool get _isEdu => widget.category == ServiceCategory.educational;

  List<String> get _groupOptions =>
      _isEdu ? kEducationalStages : kSubcategoriesFor(widget.category);

  String _groupOf(ServiceProvider p) =>
      _isEdu ? (p.stage.isEmpty ? 'مراحل أخرى' : p.stage) : p.specialty;

  Color get _color => ServiceCategory.color(widget.category);

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
    if (_group.isNotEmpty && _groupOf(p) != _group) return false;
    if (_query.isEmpty) return true;
    return [
      p.name,
      p.specialty,
      p.stage,
      p.address,
      p.description,
      _groupOf(p),
      ServiceCategory.label(widget.category),
    ].join(' ').toLowerCase().contains(_query);
  }

  Future<void> _openForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('سجّل الدخول أولاً', error: true);
      return;
    }
    final identity = await UserService().resolveAuthor();
    if (!mounted) return;
    final res = await showModalBottomSheet<ServiceProvider>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _ProviderFormSheet(
        category: widget.category,
        userId: user.uid,
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
      backgroundColor: error ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ServiceCategory.label(widget.category),
            style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _color,
        foregroundColor: Colors.white,
        actions: CommonAppBarActions.actions(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'svc_cat_fab',
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          switch (widget.category) {
            ServiceCategory.technicians => 'أضف حرفياً',
            ServiceCategory.agricultural => 'أضف خدمة',
            _ => 'أضف مدرساً',
          },
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // قائمة منسدلة بالفئات + مربع البحث أسفلها
          Container(
            color: _color.withValues(alpha: 0.06),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _group,
                  isExpanded: true,
                  menuMaxHeight: 380,
                  borderRadius: BorderRadius.circular(16),
                  decoration: InputDecoration(
                    labelText: 'تصفية حسب الفئة',
                    prefixIcon:
                        Icon(Icons.filter_alt_rounded, size: 20, color: _color),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: _color.withValues(alpha: 0.4))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: _color.withValues(alpha: 0.4))),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: '', child: Text('كل الفئات')),
                    ..._groupOptions.map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis))),
                    if (_isEdu)
                      const DropdownMenuItem(
                          value: 'مراحل أخرى', child: Text('مراحل أخرى')),
                    if (!_isEdu)
                      const DropdownMenuItem(
                          value: 'غير مصنّف', child: Text('غير مصنّف')),
                  ],
                  onChanged: (v) => setState(() => _group = v ?? ''),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: switch (widget.category) {
                      ServiceCategory.technicians =>
                        'ابحث في السجلات: اسم أو حرفة…',
                      ServiceCategory.agricultural =>
                        'ابحث في السجلات: اسم أو خدمة…',
                      _ => 'ابحث في السجلات: اسم المدرّس أو المادة…',
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
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: _color.withValues(alpha: 0.4))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: _color.withValues(alpha: 0.4))),
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
                    .toList()
                  )
                  ..sort((a, b) => b.rating.compareTo(a.rating));
                final top5 = topRated.take(5).toList();
                final topIds = top5.map((p) => p.id).toSet();
                final rest = visible
                    .where((p) => !p.isFeatured && !topIds.contains(p.id))
                    .toList();

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
                          subtitle: _group.isNotEmpty
                              ? _group
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
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900, color: color)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (count != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = provider.isFeatured
        ? const Color(0xFFB8860B)
        : accent;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: color.withValues(alpha: provider.isFeatured ? 0.6 : 0.22)),
      ),
      color: provider.isFeatured
          ? const Color(0xFFB8860B).withValues(alpha: 0.06)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, AppRoutes.serviceProviderDetail,
            arguments: provider),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: provider.photoUrl != null &&
                          provider.photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: provider.photoUrl!,
                          fit: BoxFit.cover,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(provider.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5)),
                        ),
                        if (provider.isFeatured) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFF1C40F),
                                Color(0xFFB8860B)
                              ]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 10, color: Colors.white),
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
                    ),
                    if (provider.ratingCount > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: Colors.amber),
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
                    if (provider.displaySpecialty.isNotEmpty)
                      Text(provider.displaySpecialty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    if (provider.description.isNotEmpty)
                      Text(provider.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (provider.hasContact)
                IconButton.filledTonal(
                  tooltip: 'اتصال',
                  onPressed: () async {
                    final uri =
                        Uri(scheme: 'tel', path: provider.phone);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  icon: const Icon(Icons.call_rounded, size: 17),
                  style: IconButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.14),
                      foregroundColor: color),
                ),
              IconButton(
                tooltip: 'مشاركة',
                onPressed: () => ShareService.shareText(
                    title: '🛠️ ${provider.name}',
                    body: [
                      if (provider.displaySpecialty.isNotEmpty)
                        'التخصص: ${provider.displaySpecialty}',
                      if (provider.description.isNotEmpty)
                        provider.description,
                      if (provider.address.isNotEmpty)
                        'العنوان: ${provider.address}',
                      if (provider.phone.isNotEmpty)
                        'هاتف: ${provider.phone}',
                    ].join('\n')),
                icon: const Icon(Icons.share_rounded,
                    size: 16, color: Colors.grey),
              ),
              Icon(Icons.chevron_left_rounded,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(ThemeData theme, Color accent) => Container(
        color: accent.withValues(alpha: 0.1),
        alignment: Alignment.center,
        child: Text(
          provider.name.isNotEmpty ? provider.name.substring(0, 1) : '؟',
          style: TextStyle(
              color: accent, fontWeight: FontWeight.w900, fontSize: 18),
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
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ نموذج الإضافة ═══════════════════════════
class _ProviderFormSheet extends StatefulWidget {
  const _ProviderFormSheet(
      {required this.category, required this.userId, required this.userName});
  final String category;
  final String userId;
  final String userName;

  @override
  State<_ProviderFormSheet> createState() => _ProviderFormSheetState();
}

class _ProviderFormSheetState extends State<_ProviderFormSheet> {
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _descC = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late String _specialty = kSubcategoriesFor(widget.category).first;
  late String _stage = widget.category == ServiceCategory.educational
      ? kEducationalStages.first
      : '';
  bool _saving = false;
  bool _uploading = false;
  String? _photoUrl;

  Color get _accent => ServiceCategory.color(widget.category);

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _descC.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في رفع الصورة: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _submit() {
    final name = _nameC.text.trim();
    final phone = _phoneC.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('الاسم ورقم الهاتف مطلوبان'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _saving = true);
    Navigator.pop(
      context,
      ServiceProvider(
        id: '',
        category: widget.category,
        specialty: _specialty,
        stage: widget.category == ServiceCategory.educational ? _stage : '',
        name: name,
        phone: phone,
        address: _addressC.text.trim(),
        description: _descC.text.trim(),
        photoUrl: _photoUrl,
        submittedBy: widget.userId,
        submittedByName: widget.userName,
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
                Text('إضافة إلى ${ServiceCategory.label(widget.category)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 17)),
                const Spacer(),
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
                          ? Icon(Icons.person_rounded,
                              size: 36, color: _accent)
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
            _field(theme, _nameC, isEdu ? 'اسم المدرّس' : 'الاسم / اسم الورشة',
                Icons.person_rounded),
            const SizedBox(height: 12),
            if (isEdu) ...[
              _dropdown(theme, 'المرحلة الدراسية', kEducationalStages, _stage,
                  Icons.school_rounded, (v) => setState(() => _stage = v)),
              const SizedBox(height: 12),
            ],
            _dropdown(
                theme,
                isEdu ? 'المادة' : 'الحرفة / الخدمة',
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
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ستتم مراجعة الإضافة من الإدارة قبل نشرها في الدليل',
                      style: theme.textTheme.bodySmall,
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

  Widget _field(ThemeData theme, TextEditingController c, String label,
      IconData icon,
      {TextInputType? type, int maxLines = 1}) {
    return TextField(
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
              child: Text(v,
                  maxLines: 1, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (v) => onChanged(v ?? current),
      menuMaxHeight: 340,
    );
  }
}
