import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/admin_service.dart';

class AdminEditScreen extends StatefulWidget {
  final String collection;
  final String docId;
  final Map<String, dynamic> item;

  const AdminEditScreen({super.key, required this.collection, required this.docId, required this.item});

  @override
  State<AdminEditScreen> createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFields() {
    final editable = _editableFields();
    for (final key in editable) {
      final value = widget.item[key];
      _controllers[key] = TextEditingController(text: value is String ? value : value?.toString() ?? '');
    }
  }

  List<String> _editableFields() {
    switch (widget.collection) {
      case 'news':
        return ['title', 'subtitle'];
      case 'market_products':
        return ['name', 'description', 'price'];
      case 'obituaries':
        return [
          'name',
          'dateOfDeath',
          'funeralDate',
          'funeralLocation',
          'condolenceLocation',
          'mosque',
          'description',
        ];
      case 'occasions':
        return ['title', 'description', 'date', 'location'];
      case 'forum_posts':
        return ['title', 'content'];
      default:
        return ['title', 'content'];
    }
  }

  String _fieldLabel(String key) {
    const labels = {
      'title': 'العنوان',
      'content': 'المحتوى',
      'subtitle': 'المحتوى',
      'name': 'الاسم',
      'description': 'الوصف',
      'price': 'السعر',
      'dateOfDeath': 'تاريخ الوفاة',
      'funeralDate': 'تاريخ الدفن',
      'funeralLocation': 'مكان الصلاة',
      'condolenceLocation': 'مكان العزاء',
      'mosque': 'المسجد',
      'location': 'الموقع',
      'date': 'التاريخ',
    };
    return labels[key] ?? key;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{};
      for (final entry in _controllers.entries) {
        final key = entry.key;
        final text = entry.value.text.trim();
        if (text.isEmpty) continue;
        // السعر يُحفظ كرقم مزدوج وليس نصاً
        if (key == 'price') {
          final parsed = double.tryParse(text);
          if (parsed != null) data[key] = parsed;
        } else {
          data[key] = text;
        }
      }
      await AdminService().updateItem(widget.collection, widget.docId, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
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
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                )
              : TextButton.icon(
                  onPressed: _save,
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
            ..._controllers.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: entry.value,
                maxLines: entry.key == 'content' || entry.key == 'message' || entry.key == 'description' ? 4 : 1,
                keyboardType: entry.key == 'price' ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  labelText: _fieldLabel(entry.key),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.6))),
                  prefixIcon: Icon(_fieldIcon(entry.key), color: theme.colorScheme.primary),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
            )),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, size: 20),
                label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ التعديلات', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
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
        return Icons.notes_rounded;
      case 'price':
        return Icons.attach_money_rounded;
      case 'location':
      case 'funeralLocation':
      case 'condolenceLocation':
        return Icons.location_on_rounded;
      case 'mosque':
        return Icons.mosque_rounded;
      case 'date':
      case 'dateOfDeath':
      case 'funeralDate':
        return Icons.calendar_today_rounded;
      default:
        return Icons.edit_rounded;
    }
  }
}
