import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/network/network_info.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/image_upload_service.dart';
import '../../services/occasion_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_appbar_actions.dart';

class AddOccasionScreen extends StatefulWidget {
  const AddOccasionScreen({super.key});

  @override
  State<AddOccasionScreen> createState() => _AddOccasionScreenState();
}

class _AddOccasionScreenState extends State<AddOccasionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _organizerController = TextEditingController();
  final OccasionService _occasionService = OccasionService();
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedDate;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

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

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploading = true);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        if (mounted) setState(() => _isUploading = false);
        return;
      }
      final bytes = await image.readAsBytes();
      final url = await ImageUploadService().uploadImage(bytes);
      if (!mounted) return;
      setState(() => _imageUrl = url);
      AppHelpers.showSnackBar(context, 'تم رفع الصورة بنجاح', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'خطأ في رفع الصورة: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage() => setState(() => _imageUrl = null);

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
      final occasion = Occasion(
        id: '',
        title: _titleController.text.trim(),
        date: DateFormat('yyyy/MM/dd').format(_selectedDate!),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        organizer: _organizerController.text.trim().isEmpty ? null : _organizerController.text.trim(),
        imageUrl: _imageUrl,
        createdAt: DateTime.now(),
      );
      await _occasionService.addOccasion(occasion);
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'تم إرسال المناسبة للمراجعة', isSuccess: true);
      Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('إضافة مناسبة'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
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
                    if (_imageUrl != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: _imageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 180,
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 180,
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 40,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('إزالة الصورة'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5), width: 1.5),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickAndUploadImage,
                        icon: _isUploading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(_isUploading ? 'جاري الرفع...' : 'إضافة صورة'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSaving ? 'جاري الإرسال...' : 'إرسال للمراجعة',
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
