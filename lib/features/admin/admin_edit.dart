import 'package:flutter/material.dart';

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
        return ['title', 'content'];
      case 'market_products':
        return ['name', 'description', 'price'];
      case 'obituaries':
        return ['deceasedName', 'message', 'location'];
      case 'occasions':
        return ['title', 'description', 'date', 'location'];
      case 'forum_posts':
        return ['title', 'content'];
      default:
        return ['title', 'content'];
    }
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
        data[key] = text;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل'),
        centerTitle: true,
        actions: [
          TextButton(onPressed: _isSaving ? null : _save, child: const Text('حفظ')),
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
                maxLines: entry.key == 'content' || entry.key == 'message' || entry.key == 'description' ? null : 1,
                decoration: InputDecoration(
                  labelText: entry.key,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
            )),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('حفظ التعديلات'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
