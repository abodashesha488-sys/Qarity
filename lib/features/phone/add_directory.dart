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
        _showDuplicatePhoneDialog(duplicate, phone);
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

  void _showDuplicatePhoneDialog(
      PhoneDirectoryEntry duplicate, String phone) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phone_locked_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('الرقم مسجل مسبقاً',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(ctx).colorScheme.onSurface,
                  fontFamily: 'Cairo',
                ),
                children: [
                  const TextSpan(text: 'هذا الرقم مسجل من قبل باسم: '),
                  TextSpan(
                    text: '«${duplicate.name}»\n\n',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.error,
                    ),
                  ),
                  const TextSpan(
                    text:
                        'لا يمكن تكرار نفس رقم الهاتف لأكثر من شخص في الدليل. إذا كان هذا الرقم يخصك حالياً، يمكنك تقديم طلب مراجعة للإدارة للتحقق منه.',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.rule_folder_rounded, size: 18),
            label: const Text('طلب مراجعة الرقم'),
            onPressed: () {
              Navigator.pop(ctx);
              _showDisputeSheet(duplicate, phone);
            },
          ),
        ],
      ),
    );
  }

  void _showDisputeSheet(PhoneDirectoryEntry duplicate, String phone) {
    final reasonController = TextEditingController();
    final newName = _nameController.text.trim();
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment_ind_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'طلب مراجعة ملكية الرقم',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _disputeRow('رقم الهاتف:', phone, isBold: true),
                      const Divider(height: 14),
                      _disputeRow('الاسم المسجل حالياً:', duplicate.name,
                          color: AppColors.error),
                      const Divider(height: 14),
                      _disputeRow('الاسم الجديد المطلوب:', newName,
                          color: AppColors.primary, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'سبب وتوضيح الطلب:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText:
                        'اكتب هنا توضيحك (مثلاً: قمت بشراء الخط حديثاً، أو الاسم القديم غير صحيح...)',
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.25),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isSubmitting ? null : () => Navigator.pop(sheetCtx),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final reason = reasonController.text.trim();
                                if (reason.isEmpty) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'يرجى كتابة سبب أو توضيح الطلب أولاً'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                setSheetState(() => isSubmitting = true);
                                try {
                                  await _service.submitPhoneDispute(
                                    phone: phone,
                                    newName: newName,
                                    oldEntryId: duplicate.id,
                                    oldEntryName: duplicate.name,
                                    reason: reason,
                                    job: _jobController.text.trim(),
                                    photoUrl: _photoUrl,
                                  );
                                  if (!sheetCtx.mounted) return;
                                  Navigator.pop(sheetCtx);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'تم إرسال طلب مراجعة الرقم للإدارة بنجاح وسيتم البت فيه.',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                  Navigator.pop(context, true);
                                } catch (e) {
                                  setSheetState(() => isSubmitting = false);
                                  if (sheetCtx.mounted) {
                                    ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                      SnackBar(content: Text('خطأ: $e')),
                                    );
                                  }
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                            isSubmitting ? 'جاري الإرسال...' : 'إرسال للإدارة'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _disputeRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
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
