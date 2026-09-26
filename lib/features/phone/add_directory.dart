import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/data_models.dart';
import '../../services/image_upload_service.dart';
import '../../services/phone_directory_service.dart';
import '../../widgets/qurity_app_bar.dart';

/// إضافة جهة اتصال — الاسم + رقم الهاتف + الوظيفة (اختياري) + صورة اختيارية.
class AddPhoneDirectoryScreen extends StatefulWidget {
  const AddPhoneDirectoryScreen({super.key});

  @override
  State<AddPhoneDirectoryScreen> createState() =>
      _AddPhoneDirectoryScreenState();
}

class _AddPhoneDirectoryScreenState extends State<AddPhoneDirectoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobController = TextEditingController();
  final PhoneDirectoryService _service = PhoneDirectoryService();
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _uploadingPhoto = false;
  String? _photoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _uploadingPhoto = true);
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
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _phoneController.text.trim();
    setState(() => _isSaving = true);
    try {
      final entries = await _service.getApprovedEntriesList();
      final duplicate = entries.firstWhere(
        (e) => _normalizePhone(e.phone) == _normalizePhone(phone),
        orElse: () => const PhoneDirectoryEntry(
          id: '',
          name: '',
          title: '',
          phone: '',
        ),
      );
      if (duplicate.id.isNotEmpty && duplicate.phone.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('هذا الرقم مسجل في الدليل تحت اسم: ${duplicate.name}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final job = _jobController.text.trim();
      final entry = PhoneDirectoryEntry(
        id: '',
        name: _nameController.text.trim(),
        title: job,
        phone: phone,
        job: job.isNotEmpty ? job : null,
        photoUrl: _photoUrl,
        submittedBy: FirebaseAuth.instance.currentUser?.uid,
      );
      await _service.addPhoneDirectoryEntry(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إرسال الطلب للمراجعة'),
            backgroundColor: Color(0xFF6F4E37)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\+\(\)\.]+'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(title: 'إضافة جهة اتصال'),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة جهة الاتصال
                Center(
                  child: GestureDetector(
                    onTap: _uploadingPhoto ? null : _pickPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          backgroundImage: _photoUrl != null
                              ? CachedNetworkImageProvider(_photoUrl!)
                              : null,
                          child: _photoUrl == null
                              ? Icon(Icons.person_rounded,
                                  size: 44,
                                  color: theme.colorScheme.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.colorScheme.surface, width: 2),
                            ),
                            child: _uploadingPhoto
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.camera_alt_rounded,
                                    size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _photoUrl == null
                        ? 'إضافة صورة (اختياري)'
                        : 'المصورة جاهزة — اضغط للتغيير',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: _input(theme, 'الاسم', Icons.person_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'الاسم مطلوب'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _input(theme, 'رقم الهاتف', Icons.phone_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'رقم الهاتف مطلوب'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jobController,
                  decoration:
                      _input(theme, 'الوظيفة (اختياري)', Icons.work_rounded),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'سيتم مراجعة الإدخال من قبل الإدارة قبل نشره في الدليل',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface),
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
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSaving ? 'جاري الإرسال...' : 'إرسال للمراجعة'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _input(ThemeData theme, String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
}
