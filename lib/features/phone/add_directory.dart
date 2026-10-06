import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/data_models.dart';
import '../../services/image_upload_service.dart';
import '../../services/phone_directory_service.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/qurity_app_bar.dart';

/// إضافة جهة اتصال — الاسم + رقم الهاتف + الوظيفة (اختياري) + صورة اختيارية.
/// يقبل `existing` فيصبح نفس النموذج أداةً لتعديل صاحب البيان سجله (البند ٨).
class AddPhoneDirectoryScreen extends StatefulWidget {
  const AddPhoneDirectoryScreen({
    super.key,
    this.uploader,
    this.bytesSource,
    this.service,
    this.existing,
  });

  /// اختياري لاختبار المحرّر المشترك بلا شبكة ولا معرض جهاز.
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;

  /// اختياري للحقن في الاختبارات.
  final PhoneDirectoryService? service;

  /// بيان يملكه المستخدم الحالي — الحفظ يكتب فوقه بدل بيان جديد.
  final PhoneDirectoryEntry? existing;

  @override
  State<AddPhoneDirectoryScreen> createState() =>
      _AddPhoneDirectoryScreenState();
}

class _AddPhoneDirectoryScreenState extends State<AddPhoneDirectoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _phoneController =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final _jobController =
      TextEditingController(text: widget.existing?.job ?? '');
  late final PhoneDirectoryService _service =
      widget.service ?? PhoneDirectoryService();
  bool _isSaving = false;
  bool _uploadingPhoto = false;
  String? _photoUrl;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.existing?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _phoneController.text.trim();
    final editing = widget.existing;
    setState(() => _isSaving = true);
    try {
      final entries = await _service.getApprovedEntriesList();
      final duplicate = entries.firstWhere(
        (e) =>
            _normalizePhone(e.phone) == _normalizePhone(phone) &&
            e.id != editing?.id,
        orElse: () => const PhoneDirectoryEntry(
          id: '',
          name: '',
          title: '',
          phone: '',
        ),
      );
      if (duplicate.id.isNotEmpty && duplicate.phone.isNotEmpty) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          // أرضيات الشريط هنا ألوان ثابتة في السمتين (`error` و`primary`)، بينما
          // حبره الافتراضي يُقرأ من `onInverseSurface` وهو في الداكن داكن ⇒
          // البياض يُثبَّت. الأحمر هنا الهادئ الموثّق لا `Colors.red` الساطع.
          SnackBar(
            content: Text('هذا الرقم مسجل في الدليل تحت اسم: ${duplicate.name}',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final job = _jobController.text.trim();
      final entry = PhoneDirectoryEntry(
        id: editing?.id ?? '',
        name: _nameController.text.trim(),
        title: job,
        phone: phone,
        secondaryPhone: editing?.secondaryPhone,
        job: job.isNotEmpty ? job : null,
        address: editing?.address,
        email: editing?.email,
        photoUrl: _photoUrl,
        isPublic: editing?.isPublic ?? true,
        submittedBy: editing?.submittedBy ??
            FirebaseAuth.instance.currentUser?.uid,
      );
      if (editing == null) {
        await _service.addPhoneDirectoryEntry(entry);
      } else {
        await _service.updatePhoneDirectoryEntry(entry);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(editing == null
                    ? 'تم إرسال الطلب للمراجعة'
                    : 'تم حفظ التعديلات — عاد البيان للمراجعة',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.primary));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ: $e',
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: AppColors.error));
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
      appBar: QurityAppBar(
          title: _isEdit ? 'تعديل جهة اتصال' : 'إضافة جهة اتصال'),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة جهة الاتصال — المعاينة دائرية والمرفع/الحذف للمحرّر المشترك
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: _photoUrl != null
                        ? CachedNetworkImageProvider(_photoUrl!)
                        : null,
                    child: _photoUrl == null
                        ? Icon(Icons.person_rounded,
                            size: 44, color: theme.colorScheme.primary)
                        : null,
                  ),
                ),
                if (_uploadingPhoto)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Center(
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                const SizedBox(height: 16),
                ImageListEditor(
                  label: 'صورة جهة الاتصال (اختياري)',
                  fieldKey: 'photoUrl',
                  single: true,
                  urls:
                      _photoUrl == null ? const <String>[] : <String>[_photoUrl!],
                  uploader: widget.uploader,
                  bytesSource: widget.bytesSource,
                  maxSide: 600,
                  onBusyChanged:
                      (busy) => setState(() => _uploadingPhoto = busy),
                  onChanged: (urls) =>
                      setState(() => _photoUrl = urls.isEmpty ? null : urls.first),
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
                          _isEdit
                              ? 'حفظ التعديلات يعيد البيان إلى المراجعة قبل أن يظهر في الدليل'
                              : 'سيتم مراجعة الإدخال من قبل الإدارة قبل نشره في الدليل',
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
                    onPressed: _isSaving || _uploadingPhoto ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSaving
                        ? 'جاري الحفظ...'
                        : (_isEdit ? 'حفظ التعديلات' : 'إرسال للمراجعة')),
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
