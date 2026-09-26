import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/service_provider_model.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/qurity_app_bar.dart';

const kFarmerWorkersEquipmentServices = [
  'عمال',
  'معدات',
  'أسمدة',
  'مبيدات',
  'زراعة'
];

/// شاشة عمال و معدات — البيانات الزراعية الحالية تنقل هنا
class WorkersEquipmentScreen extends StatefulWidget {
  const WorkersEquipmentScreen({super.key});

  @override
  State<WorkersEquipmentScreen> createState() => _WorkersEquipmentScreenState();
}

class _WorkersEquipmentScreenState extends State<WorkersEquipmentScreen> {
  final ServiceProviderService _service = ServiceProviderService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSubcategory = 'الكل';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFFEF6C00);

    return Scaffold(
      appBar:
          const QurityAppBar(title: 'عمال و معدات', color: Color(0xFFEF6C00)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة خدمة',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          _buildFilterHeader(theme, color),
          Expanded(
            child: StreamBuilder<List<ServiceProvider>>(
              stream: _service.getApprovedByCategory(
                  ServiceCategory.farmerWorkersEquipment),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _buildSkeleton(theme, color);
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('تعذر تحميل الخدمات'));
                }
                final all = snapshot.data ?? [];
                final filtered = _applyFilters(all);
                if (filtered.isEmpty) {
                  return _buildEmpty(theme, color);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _ProviderTile(
                    provider: filtered[index],
                    color: color,
                    index: index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(ThemeData theme, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن خدمة، معدات، مزود...',
              hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.search_rounded, color: color),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () => _searchController.clear(),
                      icon: const Icon(Icons.clear_rounded))
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['الكل', ...kFarmerWorkersEquipmentServices].map((s) {
                final selected = s == _selectedSubcategory;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _selectedSubcategory = s),
                    selectedColor: color.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected ? color : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                        color: selected
                            ? color
                            : theme.colorScheme.outlineVariant),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<ServiceProvider> _applyFilters(List<ServiceProvider> all) {
    final list = all.where((p) {
      if (_selectedSubcategory != 'الكل' &&
          p.specialty != _selectedSubcategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.specialty.toLowerCase().contains(q) &&
            !p.description.toLowerCase().contains(q) &&
            !p.address.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
    list.sort((a, b) {
      if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  Widget _buildSkeleton(ThemeData theme, Color color) {
    final base = theme.colorScheme.surfaceContainerHighest;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: theme.colorScheme.surface,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
                color: base, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.engineering_rounded, size: 48, color: color),
          ),
          const SizedBox(height: 16),
          Text('لا توجد خدمات في هذا التصنيف',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uid = await _requireUser(messenger);
    if (uid == null || !mounted) return;
    if (!context.mounted) return;
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final phoneC = TextEditingController();
    final addrC = TextEditingController();
    var specialty = kFarmerWorkersEquipmentServices.first;
    final images = <String>[];
    final maxImages = 3;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Expanded(child: Text('إضافة خدمة زراعية')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF6C00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'عمال و معدات',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF6C00),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ImageField(
                    maxImages: maxImages,
                    onChanged: (l) => setSt(() => images
                      ..clear()
                      ..addAll(l))),
                const SizedBox(height: 12),
                TextField(
                    controller: nameC,
                    decoration: const InputDecoration(
                        labelText: 'اسم الخدمة',
                        prefixIcon: Icon(Icons.engineering_rounded))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: specialty,
                  items: kFarmerWorkersEquipmentServices
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setSt(() => specialty = v ?? specialty),
                  decoration: const InputDecoration(
                      labelText: 'نوع الخدمة',
                      prefixIcon: Icon(Icons.category_rounded)),
                  menuMaxHeight: 360,
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: descC,
                    decoration: const InputDecoration(
                        labelText: 'الوصف',
                        prefixIcon: Icon(Icons.description_rounded)),
                    maxLines: 3),
                const SizedBox(height: 12),
                TextField(
                    controller: phoneC,
                    decoration: const InputDecoration(
                        labelText: 'الهاتف',
                        prefixIcon: Icon(Icons.phone_rounded)),
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(
                    controller: addrC,
                    decoration: const InputDecoration(
                        labelText: 'العنوان / المنطقة',
                        prefixIcon: Icon(Icons.location_on_rounded))),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C00)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نشر'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && nameC.text.trim().isNotEmpty) {
      if (!mounted) return;
      _submitService(uid, nameC.text.trim(), specialty, descC.text.trim(),
          phoneC.text.trim(), addrC.text.trim(), images);
    }
  }

  Future<void> _submitService(
    String uid,
    String name,
    String specialty,
    String desc,
    String phone,
    String addr,
    List<String> images,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final provider = ServiceProvider(
        id: '',
        category: ServiceCategory.farmerWorkersEquipment,
        specialty: specialty,
        name: name,
        phone: phone,
        address: addr,
        description: desc,
        photoUrl: images.isNotEmpty ? images.first : null,
        submittedBy: uid,
        submittedByName: '',
        createdAt: DateTime.now(),
      );
      await _service.create(provider);
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(
            content: Text('تم الإرسال للمراجعة'),
            backgroundColor: Color(0xFFEF6C00)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Future<String?> _requireUser([ScaffoldMessengerState? messenger]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      messenger?.showSnackBar(
        const SnackBar(
            content: Text('يرجى تسجيل الدخول أولاً'),
            backgroundColor: Colors.red),
      );
      return null;
    }
    return user.uid;
  }
}

class _ImageField extends StatefulWidget {
  final int maxImages;
  final void Function(List<String>) onChanged;
  const _ImageField({required this.maxImages, required this.onChanged});

  @override
  State<_ImageField> createState() => _ImageFieldState();
}

class _ImageFieldState extends State<_ImageField> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _images = [];
  bool _uploading = false;

  Future<void> _pick() async {
    if (_images.length >= widget.maxImages) return;
    setState(() => _uploading = true);
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final url = await ImageUploadService().uploadImage(bytes);
      if (!mounted) return;
      setState(() => _images.add(url.imageUrl));
      widget.onChanged(_images);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الصور (حتى ${widget.maxImages})',
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...List.generate(
                _images.length,
                (i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: _images[i],
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 14),
                              onPressed: () => setState(() {
                                _images.removeAt(i);
                                widget.onChanged(_images);
                              }),
                            ),
                          ),
                        ),
                      ],
                    )),
            if (_images.length < widget.maxImages)
              InkWell(
                onTap: _uploading ? null : _pick,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4)),
                  ),
                  child: _uploading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 28, color: theme.colorScheme.primary),
                            const SizedBox(height: 4),
                            Text('إضافة',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final ServiceProvider provider;
  final Color color;
  final int index;
  const _ProviderTile(
      {required this.provider, required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: provider.isFeatured
              ? color.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: provider.isFeatured ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
            context, AppRoutes.serviceProviderDetail,
            arguments: provider),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child:
                      provider.photoUrl != null && provider.photoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: provider.photoUrl!, fit: BoxFit.cover)
                          : ColoredBox(
                              color: color.withValues(alpha: 0.1),
                              child: Icon(Icons.engineering_rounded,
                                  color: color, size: 28),
                            ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (provider.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB8860B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('مميز',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category_rounded, size: 12, color: color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(provider.specialty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(provider.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        theme.colorScheme.onSurfaceVariant))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(provider.phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        theme.colorScheme.onSurfaceVariant))),
                      ],
                    ),
                    if (provider.rating > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                              '${provider.rating.toStringAsFixed(1)} (${provider.ratingCount})',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (index * 40).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1);
  }
}
