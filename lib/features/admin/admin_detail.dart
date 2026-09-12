import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../widgets/common_appbar_actions.dart';

class AdminDetailScreen extends StatefulWidget {
  final String collection;
  final String docId;
  final Map<String, dynamic> item;

  const AdminDetailScreen({super.key, required this.collection, required this.docId, required this.item});

  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  final AdminService _adminService = AdminService();
  final Set<String> _busy = {};

  bool _isBusy(String action) => _busy.contains(action);

  Future<void> _run(String action, Future<void> Function() fn) async {
    if (_isBusy(action)) return;
    setState(() => _busy.add(action));
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy.remove(action));
    }
  }

  bool _looksLikeImageUrl(dynamic value) {
    return value is String && value.startsWith('http') && (value.endsWith('.png') || value.endsWith('.jpg') || value.endsWith('.jpeg') || value.endsWith('.webp') || value.contains('firebasestorage'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final title = item['title'] ?? item['name'] ?? item['content'] ?? 'بدون عنوان';
    final isApproved = item['isApproved'] == true;

    final visualEntries = item.entries.where((e) {
      if (e.key == 'id') return false;
      final v = e.value;
      if (v is String && _looksLikeImageUrl(v)) return false;
      if (v is List && _isImageList(v)) return false;
      return true;
    }).toList();

    final imageEntries = item.entries.where((e) {
      final v = e.value;
      if (v is String && _looksLikeImageUrl(v)) return true;
      if (v is List && _isImageList(v)) return true;
      return false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title.length > 24 ? '${title.substring(0, 24)}...' : title),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          _busy.isEmpty
              ? TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRoutes.adminEdit,
                      arguments: {
                        'collection': widget.collection,
                        'docId': widget.docId,
                        'item': item,
                      },
                    );
                    if (result == true && mounted) setState(() {});
                  },
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('تعديل'),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                ),
          ...CommonAppBarActions.actions(context),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(_collectionIcon(widget.collection), color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.length > 30 ? '${title.substring(0, 30)}...' : title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(_collectionLabel(widget.collection), style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isApproved ? Icons.check_circle_rounded : Icons.pending_rounded, color: isApproved ? Colors.green.shade100 : Colors.orange.shade100, size: 14),
                      const SizedBox(width: 4),
                      Text(isApproved ? 'معتمد' : 'قيد المراجعة', style: TextStyle(color: isApproved ? Colors.green.shade100 : Colors.orange.shade100, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.collection == 'service_providers') ...[
            _FeaturedToggle(
              collection: widget.collection,
              docId: widget.docId,
              value: item['isFeatured'] == true,
              onChanged: (v) {
                setState(() => item['isFeatured'] = v);
                _adminService.updateItem(widget.collection, widget.docId,
                    {'isFeatured': v});
              },
            ),
            const SizedBox(height: 16),
          ],
          for (final entry in imageEntries) ...[
            _buildImages(theme, entry.value),
            const SizedBox(height: 16),
          ],
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...visualEntries.expand((entry) {
                    return [
                      if (visualEntries.first != entry) const Divider(height: 24),
                      _buildDetailRow(theme, entry.key, entry.value),
                    ];
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionFilled(theme, 'موافقة', Icons.check_rounded, Colors.green,
                  _isBusy('approve')
                      ? null
                      : () => _run('approve', () => _adminService.approveItem(widget.collection, widget.docId))),
              _buildActionFilled(theme, 'رفض', Icons.close_rounded, Colors.orange,
                  _isBusy('reject')
                      ? null
                      : () => _run('reject', () => _adminService.rejectItem(widget.collection, widget.docId))),
              _buildActionFilled(theme, 'حذف', Icons.delete_rounded, Colors.red,
                  _isBusy('delete')
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: const Text('هل أنت متأكد من حذف هذا العنصر؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('حذف')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _run('delete', () => _adminService.deleteItem(widget.collection, widget.docId));
                          }
                        }),
            ],
          ),
        ),
      ),
    );
  }

  bool _isImageList(List value) {
    return value.isNotEmpty && value.any((e) => e is String && _looksLikeImageUrl(e));
  }

  Widget _buildImages(ThemeData theme, dynamic value) {
    final urls = <String>[];
    if (value is String && _looksLikeImageUrl(value)) {
      urls.add(value);
    } else if (value is List) {
      for (final e in value) {
        if (e is String && _looksLikeImageUrl(e)) urls.add(e);
      }
    }
    if (urls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: urls[index],
            fit: BoxFit.cover,
            width: 160,
            placeholder: (c, u) => Container(width: 160, color: theme.colorScheme.surfaceContainerHighest),
            errorWidget: (c, u, e) => Container(width: 160, color: theme.colorScheme.surfaceContainerHighest, child: const Icon(Icons.broken_image_rounded)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String key, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_prettyKey(key), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(_formatValue(key, value), style: theme.textTheme.bodyMedium?.copyWith(height: 1.3)),
      ],
    );
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return 'لا يوجد';
    if (key == 'isApproved') return value == true ? 'معتمد' : 'قيد المراجعة';
    if (value is bool) return value ? 'نعم' : 'لا';
    if (value is List) {
      // قائمة أقارب المتوفى: كائنات فيها name/type
      if (key == 'relatives') {
        final names = value
            .whereType<Map>()
            .map((r) => (r['name'] ?? '').toString())
            .where((n) => n.isNotEmpty)
            .join('، ');
        return names.isEmpty ? 'لا يوجد' : names;
      }
      // قوائم كائنات عامة: نحاول استخراج الحقول النصية
      if (value.isNotEmpty && value.first is Map) {
        final parts = value.whereType<Map>().map((m) {
          final name = m['name'] ?? m['text'] ?? m['userName'] ?? m['title'];
          return name?.toString() ?? '';
        }).where((s) => s.isNotEmpty).join('، ');
        return parts.isEmpty ? '${value.length} عنصر' : parts;
      }
      return value.join('، ');
    }
    return value.toString();
  }

  String _prettyKey(String key) {
    const labels = {
      'title': 'العنوان',
      'name': 'الاسم',
      'content': 'المحتوى',
      'subtitle': 'المحتوى',
      'description': 'الوصف',
      'message': 'الرسالة',
      'deceasedName': 'اسم المتوفى',
      'location': 'الموقع',
      'date': 'التاريخ',
      'dateOfDeath': 'تاريخ الوفاة',
      'funeralDate': 'تاريخ الدفن',
      'funeralLocation': 'مكان الصلاة',
      'condolenceLocation': 'مكان العزاء',
      'mosque': 'المسجد',
      'relatives': 'أقارب المتوفى',
      'price': 'السعر',
      'isApproved': 'الحالة',
      'createdAt': 'تاريخ الإنشاء',
      'phone': 'الهاتف',
      'email': 'البريد الإلكتروني',
      'category': 'التصنيف',
      'specialty': 'التخصص',
      'stage': 'المرحلة',
      'homeCollection': 'سحب منزلي',
      'submittedByName': 'مقدّم البيان',
      'isFeatured': 'بيان مميز',
      'doctorName': 'الطبيب',
      'workingHours': 'مواعيد العمل',
      'fees': 'الأجر',
      'stock': 'الكمية',
      'sellerName': 'اسم البائع',
      'sellerPhone': 'هاتف البائع',
      'organizer': 'المنظّم',
      'type': 'النوع',
      'userId': 'المستخدم',
      'userName': 'اسم المستخدم',
    };
    return labels[key] ?? key;
  }

  IconData _collectionIcon(String collection) {
    switch (collection) {
      case 'news':
        return Icons.newspaper_rounded;
      case 'market_products':
        return Icons.store_rounded;
      case 'shops':
        return Icons.storefront_rounded;
      case 'obituaries':
        return Icons.grade_rounded;
      case 'occasions':
        return Icons.card_giftcard_rounded;
      case 'forum_posts':
        return Icons.forum_rounded;
      case 'service_providers':
        return Icons.category_rounded;
      case 'medical_labs':
        return Icons.science_rounded;
      case 'village_clinics':
        return Icons.add_business_rounded;
      case 'pharmacies':
        return Icons.local_pharmacy_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  String _collectionLabel(String collection) {
    switch (collection) {
      case 'news':
        return 'خبر';
      case 'market_products':
        return 'منتج';
      case 'shops':
        return 'محل';
      case 'obituaries':
        return 'عزاء';
      case 'occasions':
        return 'مناسبة';
      case 'forum_posts':
        return 'منشور';
      case 'service_providers':
        return 'بيان في دليل الخدمات';
      case 'medical_labs':
        return 'معمل تحاليل';
      case 'village_clinics':
        return 'عيادة';
      case 'pharmacies':
        return 'صيدلية';
      default:
        return 'عنصر';
    }
  }

  Widget _buildActionFilled(ThemeData theme, String label, IconData icon, Color color, VoidCallback? onPressed) {
    final isLoading = onPressed == null;
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: color.withValues(alpha: 0.25))),
      ),
      icon: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

/// مفتاح «بيان مميز / عادي» لمقدمي الخدمات — المميز يظهر ذهبيًا وفي المقدمة.
class _FeaturedToggle extends StatelessWidget {
  const _FeaturedToggle(
      {required this.collection,
      required this.docId,
      required this.value,
      required this.onChanged});
  final String collection;
  final String docId;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFFF1C40F).withValues(alpha: 0.12)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: value
                ? const Color(0xFFB8860B)
                : Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(value ? Icons.star_rounded : Icons.star_border_rounded,
              color: value ? const Color(0xFFB8860B) : Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value
                  ? 'هذا البيان مميز — يظهر باللون الذهبي وفي مقدمة القوائم'
                  : 'هذا البيان عادي — يمكنك تمييزه ليظهر ذهبيًا وفي المقدمة',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFB8860B),
            onChanged: (v) => onChanged(v),
          ),
        ],
      ),
    );
  }
}
