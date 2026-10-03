import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/network/network_info.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/image_upload_service.dart';
import '../../services/occasion_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/qurity_app_bar.dart';

class AddOccasionScreen extends StatefulWidget {
  const AddOccasionScreen({
    super.key,
    this.uploader,
    this.bytesSource,
    this.service,
    this.existing,
  });

  /// اختياري لاختبار المحرّر المشترك بلا شبكة ولا معرض جهاز.
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;

  /// اختياري للحقن في الاختبارات — الإنتاج يبني الخادم الحقيقي كسولًا كما كان.
  final OccasionService? service;

  /// مناسبة صاحبه يريد تعديلها: النموذج يمتلئ بها ويُحفظ في نفس المعرّف.
  final Occasion? existing;

  @override
  State<AddOccasionScreen> createState() => _AddOccasionScreenState();
}

class _AddOccasionScreenState extends State<AddOccasionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _locationController =
      TextEditingController(text: widget.existing?.location ?? '');
  late final _organizerController =
      TextEditingController(text: widget.existing?.organizer ?? '');
  late final OccasionService _occasionService =
      widget.service ?? OccasionService();

  DateTime? _selectedDate;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    _imageUrl = e.imageUrl;
    if (e.date.trim().isNotEmpty) {
      try {
        _selectedDate = DateFormat('yyyy/MM/dd').parseStrict(e.date.trim());
      } catch (_) {
        _selectedDate = DateTime.tryParse(e.date.trim());
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'يرجى اختيار تاريخ المناسبة', isError: true);
      return;
    }
    if (!await NetworkInfo().isConnected) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'لا يوجد اتصال بالإنترنت', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final editing = widget.existing;
      final occasion = Occasion(
        id: editing?.id ?? '',
        title: _titleController.text.trim(),
        date: DateFormat('yyyy/MM/dd').format(_selectedDate!),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        organizer: _organizerController.text.trim().isEmpty ? null : _organizerController.text.trim(),
        imageUrl: _imageUrl,
        // التعديل لا يرفع موافقة ولا يغيّر تاريخ الإنشاء ولا ينسب المناسبة لغير
        // صاحبها: تُقرأ من السجل نفسه وتُمرَّر كما هي.
        isApproved: editing?.isApproved ?? false,
        submittedBy: editing?.submittedBy,
        createdAt: editing?.createdAt,
      );
      if (editing != null) {
        await _occasionService.updateOccasion(occasion);
      } else {
        await _occasionService.addOccasion(occasion);
      }
      if (!mounted) return;
      AppHelpers.showSnackBar(context,
          editing == null
              ? 'تم إرسال المناسبة للمراجعة'
              : 'تم حفظ التعديلات — أُعيدت المناسبة للمراجعة',
          isSuccess: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(title: _isEdit ? 'تعديل المناسبة' : 'إضافة مناسبة'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewNotice(theme: theme),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'تفاصيل المناسبة',
                  icon: Icons.event_rounded,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'عنوان المناسبة',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'التاريخ',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'اختر التاريخ'
                              : DateFormat('yyyy/MM/dd').format(_selectedDate!),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _selectedDate == null
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'المكان والتنظيم',
                  icon: Icons.location_on_rounded,
                  children: [
                    TextFormField(
                      controller: _locationController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'المكان',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _organizerController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'المنظم (اختياري)',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'الوصف',
                  icon: Icons.description_rounded,
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'الوصف',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'صورة (اختياري)',
                  icon: Icons.image_rounded,
                  children: [
                    ImageListEditor(
                      label: 'صورة المناسبة',
                      fieldKey: 'imageUrl',
                      single: true,
                      urls: _imageUrl == null
                          ? const <String>[]
                          : <String>[_imageUrl!],
                      uploader: widget.uploader,
                      bytesSource: widget.bytesSource,
                      onBusyChanged:
                          (busy) => setState(() => _isUploading = busy),
                      onChanged: (urls) => setState(
                          () => _imageUrl = urls.isEmpty ? null : urls.first),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving || _isUploading ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSaving
                          ? (_isEdit ? 'جاري الحفظ...' : 'جاري الإرسال...')
                          : (_isEdit ? 'حفظ التعديلات' : 'إرسال للمراجعة'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'سيتم مراجعة المناسبة من قبل الإدارة قبل نشرها',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
