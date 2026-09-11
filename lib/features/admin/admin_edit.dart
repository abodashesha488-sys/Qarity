import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/admin_service.dart';

/// شاشة تعديل الأدمن لأي عنصر — تغطي كل المجموعات بحقولها الحقيقية،
/// مع أنواع صحيحة (نص/رقم/منطقي) ووسوم عربية.
class AdminEditScreen extends StatefulWidget {
  final String collection;
  final String docId;
  final Map<String, dynamic> item;

  const AdminEditScreen(
      {super.key,
      required this.collection,
      required this.docId,
      required this.item});

  @override
  State<AdminEditScreen> createState() => _AdminEditScreenState();
}

class _FieldSpec {
  final String key;
  final String label;
  final bool required;
  final bool numeric;
  final bool multiline;
  final bool boolean;
  const _FieldSpec(this.key, this.label,
      {this.required = false,
      this.numeric = false,
      this.multiline = false,
      this.boolean = false});
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _bools = {};
  late final List<_FieldSpec> _fields;
  bool _isSaving = false;

  static const Set<String> _systemKeys = {
    'id',
    'createdAt',
    'updatedAt',
    'approvedAt',
    'approvedBy',
    'rejectedAt',
    'rejectedBy',
    'reviewedAt',
    'reviewedBy',
    'isApproved',
    'imageUrls',
    'likedBy',
    'categories',
    'fcmToken',
    'fcmTokenUpdatedAt',
    'relatives',
  };

  @override
  void initState() {
    super.initState();
    _fields = _fieldsFor(widget.collection);
    for (final f in _fields) {
      final v = widget.item[f.key];
      if (f.boolean) {
        _bools[f.key] = v is bool ? v : false;
      } else {
        _controllers[f.key] =
            TextEditingController(text: v?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<_FieldSpec> _fieldsFor(String c) {
    switch (c) {
      case 'news':
        return const [
          _FieldSpec('title', 'العنوان', required: true),
          _FieldSpec('subtitle', 'المحتوى', multiline: true),
          _FieldSpec('category', 'التصنيف'),
          _FieldSpec('authorName', 'اسم الكاتب'),
        ];
      case 'market_products':
        return const [
          _FieldSpec('name', 'اسم المنتج', required: true),
          _FieldSpec('description', 'الوصف', multiline: true),
          _FieldSpec('price', 'السعر', numeric: true),
          _FieldSpec('offerPrice', 'سعر العرض', numeric: true),
          _FieldSpec('category', 'الفئة'),
          _FieldSpec('stock', 'المخزون', numeric: true),
          _FieldSpec('sellerName', 'اسم البائع'),
          _FieldSpec('sellerPhone', 'هاتف البائع'),
        ];
      case 'obituaries':
        return const [
          _FieldSpec('name', 'اسم المتوفى', required: true),
          _FieldSpec('age', 'السن'),
          _FieldSpec('dateOfDeath', 'تاريخ الوفاة'),
          _FieldSpec('funeralDate', 'تاريخ الدفن'),
          _FieldSpec('funeralLocation', 'مكان الصلاة'),
          _FieldSpec('condolenceLocation', 'مكان العزاء'),
          _FieldSpec('mosque', 'المسجد'),
          _FieldSpec('description', 'نبذة', multiline: true),
        ];
      case 'occasions':
        return const [
          _FieldSpec('title', 'العنوان', required: true),
          _FieldSpec('description', 'الوصف', multiline: true),
          _FieldSpec('date', 'التاريخ'),
          _FieldSpec('location', 'المكان'),
          _FieldSpec('organizer', 'المنظم'),
        ];
      case 'forum_posts':
        return const [
          _FieldSpec('title', 'العنوان'),
          _FieldSpec('content', 'المحتوى', required: true, multiline: true),
          _FieldSpec('category', 'التصنيف'),
          _FieldSpec('userName', 'اسم الناشر'),
        ];
      case 'phone_directory':
        return const [
          _FieldSpec('name', 'الاسم', required: true),
          _FieldSpec('title', 'المسمى/اللقب'),
          _FieldSpec('phone', 'الهاتف'),
          _FieldSpec('secondaryPhone', 'هاتف إضافي'),
          _FieldSpec('job', 'الوظيفة'),
          _FieldSpec('address', 'العنوان'),
          _FieldSpec('email', 'البريد'),
          _FieldSpec('isPublic', 'ظاهر للجميع', boolean: true),
        ];
      case 'shops':
        return const [
          _FieldSpec('name', 'اسم المحل', required: true),
          _FieldSpec('category', 'التصنيف'),
          _FieldSpec('description', 'نبذة', multiline: true),
          _FieldSpec('whatsapp', 'واتساب للتواصل'),
          _FieldSpec('ownerName', 'اسم المالك'),
          _FieldSpec('isActive', 'نشط', boolean: true),
        ];
      case 'seller_profiles':
        return const [
          _FieldSpec('name', 'اسم المتجر', required: true),
          _FieldSpec('bio', 'نبذة', multiline: true),
          _FieldSpec('phone', 'الهاتف'),
          _FieldSpec('address', 'العنوان'),
          _FieldSpec('isVerified', 'موثّق', boolean: true),
        ];
      case 'village_clinics':
        return const [
          _FieldSpec('name', 'اسم العيادة', required: true),
          _FieldSpec('specialty', 'التخصص'),
          _FieldSpec('ownerName', 'اسم الطبيب'),
          _FieldSpec('phone', 'الهاتف'),
          _FieldSpec('address', 'العنوان'),
          _FieldSpec('workingHours', 'مواعيد العمل'),
          _FieldSpec('description', 'نبذة', multiline: true),
        ];
      case 'pharmacies':
        return const [
          _FieldSpec('name', 'اسم الصيدلية', required: true),
          _FieldSpec('ownerName', 'الصيدلي/المسؤول'),
          _FieldSpec('phone', 'الهاتف'),
          _FieldSpec('address', 'العنوان'),
          _FieldSpec('workingHours', 'مواعيد العمل'),
          _FieldSpec('description', 'نبذة', multiline: true),
          _FieldSpec('is24Hours', '٢٤ ساعة', boolean: true),
        ];
      case 'blood_requests':
        return const [
          _FieldSpec('patientName', 'اسم المريض', required: true),
          _FieldSpec('bloodType', 'الفصيلة'),
          _FieldSpec('units', 'عدد الوحدات', numeric: true),
          _FieldSpec('hospital', 'المستشفى/المكان'),
          _FieldSpec('phone', 'هاتف التواصل'),
          _FieldSpec('urgency', 'درجة الأهمية'),
          _FieldSpec('notes', 'ملاحظات', multiline: true),
          _FieldSpec('requesterName', 'اسم مقدم الطلب'),
        ];
      case 'blood_donors':
        return const [
          _FieldSpec('name', 'اسم المتبرع', required: true),
          _FieldSpec('bloodType', 'الفصيلة'),
          _FieldSpec('phone', 'الهاتف'),
          _FieldSpec('age', 'السن', numeric: true),
          _FieldSpec('gender', 'النوع'),
          _FieldSpec('address', 'العنوان'),
          _FieldSpec('isAvailable', 'متبرع متاح', boolean: true),
        ];
      case 'service_providers':
        return const [
          _FieldSpec('name', 'الاسم / اسم الورشة', required: true),
          _FieldSpec('category', 'الفئة (technicians/agricultural/educational)'),
          _FieldSpec('specialty', 'الحرفة / الخدمة / المادة'),
          _FieldSpec('stage', 'المرحلة الدراسية (للخدمات التعليمية)'),
          _FieldSpec('phone', 'الهاتف'),
          _FieldSpec('address', 'العنوان'),
          _FieldSpec('description', 'نبذة', multiline: true),
          _FieldSpec('isFeatured', 'بيان مميز (يظهر ذهبيًا وفي المقدمة)', boolean: true),
        ];
      case 'medical_center_clinics':
        return const [
          _FieldSpec('name', 'اسم العيادة', required: true),
          _FieldSpec('specialty', 'التخصص'),
          _FieldSpec('doctorName', 'اسم الطبيب'),
          _FieldSpec('workingHours', 'مواعيد العمل'),
          _FieldSpec('fees', 'الأجر الرمزي', numeric: true),
          _FieldSpec('description', 'نبذة', multiline: true),
          _FieldSpec('isActive', 'ظاهرة للجمهور', boolean: true),
        ];
      case 'service_requests':
        return const [
          _FieldSpec('type', 'نوع الطلب', required: true),
          _FieldSpec('description', 'الوصف', multiline: true),
          _FieldSpec('location', 'الموقع'),
          _FieldSpec('status', 'الحالة (pending/in_progress/completed/cancelled)'),
          _FieldSpec('notes', 'ملاحظات', multiline: true),
          _FieldSpec('userName', 'اسم مقدم الطلب'),
        ];
      case 'product_reviews':
        return const [
          _FieldSpec('comment', 'نص المراجعة', multiline: true),
          _FieldSpec('rating', 'التقييم (1-5)', numeric: true),
          _FieldSpec('userName', 'اسم المراجع'),
        ];
      case 'reviews':
        return const [
          _FieldSpec('comment', 'نص المراجعة', multiline: true),
          _FieldSpec('rating', 'التقييم (1-5)', numeric: true),
          _FieldSpec('userName', 'اسم المراجع'),
        ];
      case 'donations':
        return const [
          _FieldSpec('title', 'اسم السلعة', required: true),
          _FieldSpec('description', 'الوصف', multiline: true),
          _FieldSpec('category', 'التصنيف'),
          _FieldSpec('contactPhone', 'هاتف التواصل'),
          _FieldSpec('status', 'الحالة (available/donated)'),
        ];
      case 'buy_requests':
        return const [
          _FieldSpec('title', 'العنوان', required: true),
          _FieldSpec('details', 'التفاصيل', multiline: true),
          _FieldSpec('budget', 'الميزانية'),
          _FieldSpec('status', 'الحالة (open/closed)'),
        ];
      default:
        return _genericFields();
    }
  }

  List<_FieldSpec> _genericFields() {
    return widget.item.entries
        .where((e) =>
            !_systemKeys.contains(e.key) &&
            (e.value is String || e.value is num || e.value == null))
        .map((e) => _FieldSpec(e.key, _labelFor(e.key),
            multiline: (e.value?.toString().length ?? 0) > 60))
        .toList();
  }

  static String _labelFor(String key) {
    const labels = {
      'title': 'العنوان',
      'name': 'الاسم',
      'content': 'المحتوى',
      'description': 'الوصف',
      'details': 'التفاصيل',
      'category': 'التصنيف',
      'phone': 'الهاتف',
      'address': 'العنوان',
      'status': 'الحالة',
      'notes': 'ملاحظات',
    };
    return labels[key] ?? key;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{};
      for (final f in _fields) {
        if (f.boolean) {
          data[f.key] = _bools[f.key] ?? false;
          continue;
        }
        final text = _controllers[f.key]!.text.trim();
        if (text.isEmpty && !f.required) continue;
        if (f.numeric) {
          final n = num.tryParse(text);
          if (n != null) data[f.key] = n;
        } else {
          data[f.key] = text;
        }
      }
      await AdminService().updateItem(widget.collection, widget.docId, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم الحفظ بنجاح'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('حفظ'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._fields.map((f) => _buildField(theme, f)),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                    _isSaving ? 'جاري الحفظ...' : 'حفظ التعديلات',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(ThemeData theme, _FieldSpec f) {
    if (f.boolean) {
      return SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Text(f.label),
        value: _bools[f.key] ?? false,
        onChanged: (v) => setState(() => _bools[f.key] = v),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[f.key],
        maxLines: f.multiline ? 4 : 1,
        keyboardType: f.numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: f.label + (f.required ? ' *' : ''),
          alignLabelWithHint: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.5))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6))),
          prefixIcon: Icon(_fieldIcon(f.key), color: theme.colorScheme.primary),
        ),
        validator: f.required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
            : null,
      ),
    );
  }

  IconData _fieldIcon(String key) {
    switch (key) {
      case 'title':
      case 'name':
        return Icons.title_rounded;
      case 'content':
      case 'subtitle':
      case 'message':
      case 'description':
      case 'details':
        return Icons.notes_rounded;
      case 'price':
      case 'offerPrice':
      case 'budget':
        return Icons.attach_money_rounded;
      case 'stock':
      case 'units':
      case 'age':
      case 'rating':
        return Icons.straighten_rounded;
      case 'location':
      case 'funeralLocation':
      case 'condolenceLocation':
      case 'address':
      case 'hospital':
        return Icons.location_on_rounded;
      case 'mosque':
        return Icons.mosque_rounded;
      case 'date':
      case 'dateOfDeath':
      case 'funeralDate':
        return Icons.calendar_today_rounded;
      case 'phone':
      case 'sellerPhone':
      case 'contactPhone':
      case 'secondaryPhone':
      case 'whatsapp':
        return Icons.phone_rounded;
      case 'category':
      case 'specialty':
        return Icons.category_rounded;
      case 'status':
        return Icons.flag_rounded;
      default:
        return Icons.edit_rounded;
    }
  }
}
