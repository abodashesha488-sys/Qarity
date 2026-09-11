import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/service_provider_model.dart';
import '../../services/image_upload_service.dart';
import '../../services/service_provider_service.dart';
import '../../services/share_service.dart';
import '../../widgets/common_appbar_actions.dart';
import '../phone/directory.dart';

/// دليل الخدمات — تبويبات: الفنيون، خدمات زراعية، خدمات تعليمية، دليل الهاتف.
/// العروض داخل التبويبات الأولى تُعرض في قوائم منسدلة حسب الحرفة/الخدمة/المادة.
class ServiceDirectoryScreen extends StatefulWidget {
  const ServiceDirectoryScreen({super.key});

  @override
  State<ServiceDirectoryScreen> createState() => _ServiceDirectoryScreenState();
}

class _ServiceDirectoryScreenState extends State<ServiceDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ServiceProviderService _service = ServiceProviderService();

  static const _categories = [
    ServiceCategory.technicians,
    ServiceCategory.agricultural,
    ServiceCategory.educational,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _openForm(String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('سجّل الدخول أولاً', error: true);
      return;
    }
    final res = await showModalBottomSheet<ServiceProvider>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _ProviderFormSheet(
        category: category,
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'مستخدم',
      ),
    );
    if (res == null) return;
    try {
      await _service.create(res);
      _snack('تم إرسال الإضافة — تظهر في الدليل بعد موافقة الإدارة');
    } catch (e) {
      _snack('خطأ: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idx = _tabController.index;
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الخدمات',
            style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'الفنيون'),
            Tab(text: 'خدمات زراعية'),
            Tab(text: 'خدمات تعليمية'),
            Tab(text: 'دليل الهاتف'),
          ],
        ),
      ),
      floatingActionButton: idx < 3
          ? FloatingActionButton.extended(
              heroTag: 'service_dir_fab_$idx',
              onPressed: () => _openForm(_categories[idx]),
              icon: Icon(ServiceCategory.icon(_categories[idx])),
              label: Text(
                switch (_categories[idx]) {
                  ServiceCategory.technicians => 'أضف حرفياً',
                  ServiceCategory.agricultural => 'أضف خدمة',
                  _ => 'أضف مدرساً',
                },
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              backgroundColor: ServiceCategory.color(_categories[idx]),
              foregroundColor: Colors.white,
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProvidersTab(category: ServiceCategory.technicians),
          _ProvidersTab(category: ServiceCategory.agricultural),
          _ProvidersTab(category: ServiceCategory.educational),
          PhoneDirectoryScreen(embedded: true),
        ],
      ),
    );
  }
}

// ═══════════════ تبويب فئة (قوائم منسدلة حسب الحرفة/الخدمة/المادة) ═══════════════
class _ProvidersTab extends StatelessWidget {
  const _ProvidersTab({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ServiceCategory.color(category);
    return StreamBuilder<List<ServiceProvider>>(
      stream: ServiceProviderService().getApprovedByCategory(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _EmptyCategory(category: category);
        }
        // التجميع: تعليمي → حسب المرحلة، وغيره → حسب الحرفة/الخدمة.
        final groups = <String, List<ServiceProvider>>{};
        for (final p in items) {
          final key = category == ServiceCategory.educational
              ? (p.stage.isEmpty ? 'مراحل أخرى' : p.stage)
              : (p.specialty.isEmpty ? 'غير مصنّف' : p.specialty);
          groups.putIfAbsent(key, () => []).add(p);
        }
        final keys = groups.keys.toList()..sort();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(ServiceCategory.icon(category), size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    '${ServiceCategory.label(category)} — ${items.length} خدمة معتمدة',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final key in keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: theme.colorScheme.surface,
                    child: Theme(
                      data: theme
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        shape: const Border(),
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        leading: CircleAvatar(
                          radius: 17,
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: Icon(
                            category == ServiceCategory.educational
                                ? Icons.school_rounded
                                : Icons.category_rounded,
                            size: 17,
                            color: color,
                          ),
                        ),
                        title: Text(key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        subtitle: Text('${groups[key]!.length} تقديم',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                        children: [
                          for (final p in groups[key]!)
                            _ProviderCard(provider: p, accent: color),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms),
          ],
        );
      },
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.accent});
  final ServiceProvider provider;
  final Color accent;

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: provider.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.22)),
      ),
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
                        errorWidget: (_, __, ___) => _avatar(theme),
                      )
                    : _avatar(theme),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13.5)),
                  if (provider.displaySpecialty.isNotEmpty)
                    Text(provider.displaySpecialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent)),
                  if (provider.description.isNotEmpty)
                    Text(provider.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant)),
                  if (provider.address.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(provider.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10.5, color: Colors.grey)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (provider.hasContact)
              IconButton.filledTonal(
                tooltip: 'اتصال',
                onPressed: _call,
                icon: const Icon(Icons.call_rounded, size: 17),
                style: IconButton.styleFrom(
                    backgroundColor: accent.withValues(alpha: 0.14),
                    foregroundColor: accent),
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
          ],
        ),
      ),
    );
  }

  Widget _avatar(ThemeData theme) => Container(
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
