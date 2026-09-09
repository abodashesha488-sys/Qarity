import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/data_models.dart';
import '../../services/phone_directory_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

class AddPhoneDirectoryScreen extends StatefulWidget {
  const AddPhoneDirectoryScreen({super.key});

  @override
  State<AddPhoneDirectoryScreen> createState() => _AddPhoneDirectoryScreenState();
}

class _AddPhoneDirectoryScreenState extends State<AddPhoneDirectoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _jobController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final PhoneDirectoryService _service = PhoneDirectoryService();
  final UserService _userService = UserService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userService.getUser(user.uid);
      if (!mounted) return;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _jobController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final entry = PhoneDirectoryEntry(
        id: '',
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        phone: _phoneController.text.trim(),
        secondaryPhone: _secondaryPhoneController.text.trim().isNotEmpty
            ? _secondaryPhoneController.text.trim()
            : null,
        job: _jobController.text.trim().isNotEmpty ? _jobController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      );
      await _service.addPhoneDirectoryEntry(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب للمراجعة'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة جهة اتصال'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(theme, _nameController, 'الاسم', Icons.person_rounded, required: true),
                const SizedBox(height: 12),
                _buildTextField(theme, _titleController, 'الوظيفية أو الاسم الوظيفي', Icons.badge_rounded),
                const SizedBox(height: 12),
                _buildTextField(theme, _phoneController, 'رقم الهاتف', Icons.phone_rounded, required: true),
                const SizedBox(height: 12),
                _buildTextField(theme, _secondaryPhoneController, 'هاتف إضافي (اختياري)', Icons.phone_iphone),
                const SizedBox(height: 12),
                _buildTextField(theme, _jobController, 'الوظيفية', Icons.work_rounded),
                const SizedBox(height: 12),
                _buildTextField(theme, _addressController, 'العنوان', Icons.location_on_rounded),
                const SizedBox(height: 12),
                _buildTextField(theme, _emailController, 'البريد الإلكتروني', Icons.email_rounded),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'سيتم مراجعة الإدخال من قبل الإدارة قبل نشره في الدليل',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSaving ? 'جاري الإرسال...' : 'إرسال للمراجعة'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(ThemeData theme, TextEditingController controller, String label, IconData prefixIcon,
      {bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: theme.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }
}