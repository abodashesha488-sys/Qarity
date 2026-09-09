import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/network/network_info.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/image_upload_service.dart';
import '../../services/obituary_service.dart';
import '../../services/share_service.dart';
import '../../widgets/common_appbar_actions.dart';

class AddObituaryScreen extends StatefulWidget {
  const AddObituaryScreen({super.key});

  @override
  State<AddObituaryScreen> createState() => _AddObituaryScreenState();
}

class _AddObituaryScreenState extends State<AddObituaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _funeralLocationController = TextEditingController();
  final _condolenceLocationController = TextEditingController();
  final _mosqueController = TextEditingController();

  final ObituaryService _obituaryService = ObituaryService();
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedDeathDate;
  DateTime? _selectedFuneralDate;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _submittedBy;

  final List<Relative> _relatives = [];

  @override
  void initState() {
    super.initState();
    _loadSubmitter();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _funeralLocationController.dispose();
    _condolenceLocationController.dispose();
    _mosqueController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmitter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() => _submittedBy = user.uid);
    }
  }

  Future<void> _pickDeathDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeathDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null && mounted) setState(() => _selectedDeathDate = picked);
  }

  Future<void> _pickFuneralDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFuneralDate ?? _selectedDeathDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    if (picked != null && mounted) {
      setState(() => _selectedFuneralDate = picked);
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploading = true);
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final url = await ImageUploadService().uploadImage(bytes);
      if (!mounted) return;
      setState(() => _imageUrl = url);
      AppHelpers.showSnackBar(context, 'تم رفع الصورة بنجاح', isSuccess: true);
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'خطأ في رفع الصورة: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage() => setState(() => _imageUrl = null);

  void _showRelativeDialog({Relative? existing, int? editIndex}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    var selectedType = existing?.type ?? RelativeType.son;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'إضافة قريب' : 'تعديل قريب'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<RelativeType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                      labelText: 'نوع القرابة',
                      prefixIcon: Icon(Icons.family_restroom_rounded)),
                  items: RelativeType.values
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(children: [
                            Icon(t.icon,
                                size: 18,
                                color: Theme.of(ctx).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(t.label),
                          ])))
                      .toList(),
                  onChanged: (v) => setSt(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'الاسم',
                      prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                      labelText: 'الهاتف (اختياري)',
                      prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final relative = Relative(
                  id: existing?.id ??
                      'rel_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  type: selectedType,
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  order: editIndex ?? _relatives.length,
                );
                setState(() {
                  if (editIndex != null) {
                    _relatives[editIndex] = relative;
                  } else {
                    _relatives.add(relative);
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeRelative(int index) {
    setState(() {
      _relatives.removeAt(index);
      for (var i = 0; i < _relatives.length; i++) {
        _relatives[i] = _relatives[i].copyWith(order: i);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeathDate == null) {
      AppHelpers.showSnackBar(context, 'يرجى اختيار تاريخ الوفاة',
          isError: true);
      return;
    }
    if (!await NetworkInfo().isConnected) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'لا يوجد اتصال بالإنترنت', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final obituary = Obituary(
        id: '',
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        dateOfDeath: DateFormat('yyyy/MM/dd').format(_selectedDeathDate!),
        funeralDate: _selectedFuneralDate != null
            ? DateFormat('yyyy/MM/dd').format(_selectedFuneralDate!)
            : '',
        funeralLocation: _funeralLocationController.text.trim(),
        condolenceLocation: _condolenceLocationController.text.trim(),
        mosque: _mosqueController.text.trim(),
        imageUrl: _imageUrl,
        description: _descriptionController.text.trim(),
        relatives: _relatives,
        submittedBy: _submittedBy,
      );
      await _obituaryService.addObituary(obituary);
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'تم إرسال التعزية للمراجعة',
          isSuccess: true);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'خطأ: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Obituary _buildPreviewObituary() {
    return Obituary(
      id: 'preview',
      name: _nameController.text.trim().isEmpty
          ? 'اسم المتوفى'
          : _nameController.text.trim(),
      age: _ageController.text.trim().isEmpty ? '—' : _ageController.text.trim(),
      dateOfDeath: _selectedDeathDate != null
          ? DateFormat('yyyy/MM/dd').format(_selectedDeathDate!)
          : '—',
      funeralDate: _selectedFuneralDate != null
          ? DateFormat('yyyy/MM/dd').format(_selectedFuneralDate!)
          : '',
      funeralLocation: _funeralLocationController.text.trim().isEmpty
          ? 'مكان الصلاة'
          : _funeralLocationController.text.trim(),
      condolenceLocation: _condolenceLocationController.text.trim().isEmpty
          ? 'مكان العزاء'
          : _condolenceLocationController.text.trim(),
      mosque: _mosqueController.text.trim(),
      imageUrl: _imageUrl,
      description: _descriptionController.text.trim(),
      relatives: _relatives,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة تعزية'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildReviewNotice(theme),
            const SizedBox(height: 16),
            _buildImageSection(theme)
                .animate()
                .fadeIn(delay: 100.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildDeceasedInfoCard(theme)
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildLocationsCard(theme)
                .animate()
                .fadeIn(delay: 300.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildRelativesSection(theme)
                .animate()
                .fadeIn(delay: 400.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildDescriptionCard(theme)
                .animate()
                .fadeIn(delay: 500.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildPreviewCard(theme)
                .animate()
                .fadeIn(delay: 600.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildSubmitButton(theme)
                .animate()
                .fadeIn(delay: 700.ms)
                .scale(delay: 700.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'سيتم مراجعة التعزية من قبل الإدارة قبل نشرها',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return _SectionCard(
      title: 'صورة المتوفى',
      icon: Icons.photo_library_rounded,
      children: [
        Text(
          'اختياري — إن لم تُرفع صورة ستظهر صورة رمزية في البطاقة',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        if (_imageUrl != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: _imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, _, __) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.broken_image_rounded,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _removeImage,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            height: 90,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon: _isUploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_a_photo_rounded, size: 24),
              label: Text(_isUploading ? 'جاري الرفع...' : 'إضافة صورة'),
            ),
          ),
      ],
    );
  }

  Widget _buildDeceasedInfoCard(ThemeData theme) {
    return _SectionCard(
      title: 'بيانات المتوفى',
      icon: Icons.person_rounded,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'الاسم *',
          hint: 'مثال: أحمد محمد علي',
          icon: Icons.person_outline_rounded,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _ageController,
                label: 'العمر *',
                hint: '0',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                theme: theme,
                label: 'تاريخ الوفاة *',
                value: _selectedDeathDate,
                onTap: _pickDeathDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDateField(
          theme: theme,
          label: 'تاريخ الدفن / الصلاة',
          value: _selectedFuneralDate,
          onTap: _pickFuneralDate,
        ),
      ],
    );
  }

  Widget _buildLocationsCard(ThemeData theme) {
    return _SectionCard(
      title: 'أماكن الدفن والعزاء',
      icon: Icons.location_on_rounded,
      children: [
        _buildTextField(
          controller: _funeralLocationController,
          label: 'مكان الصلاة / الجنازة',
          hint: 'مثال: مسجد النور، حي السلام',
          icon: Icons.mosque_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _condolenceLocationController,
          label: 'مكان العزاء',
          hint: 'مثال: منزل العائلة، شارع الملك فهد',
          icon: Icons.home_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _mosqueController,
          label: 'اسم المسجد (اختياري)',
          hint: 'مثال: مسجد القرية الكبير',
          icon: Icons.mosque_rounded,
        ),
      ],
    );
  }

  Widget _buildRelativesSection(ThemeData theme) {
    return _SectionCard(
      title: 'أقارب المتوفى',
      icon: Icons.family_restroom_rounded,
      trailing: TextButton.icon(
        onPressed: () => _showRelativeDialog(),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('إضافة قريب'),
      ),
      children: [
        Text(
          'أضف الأبناء والبنات والإخوة والأعمام والأخوال والنسايب',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        if (_relatives.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.family_restroom_rounded,
                    size: 40, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 10),
                Text('لا يوجد أقارب مضافون',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('اضغط "إضافة قريب" لإدراج أقرباء المتوفى',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ..._relatives.asMap().entries.map((entry) {
            final index = entry.key;
            final r = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(r.type.icon,
                          size: 18, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(r.type.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      onPressed: () =>
                          _showRelativeDialog(existing: r, editIndex: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded,
                          size: 20, color: Colors.red),
                      onPressed: () => _removeRelative(index),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDescriptionCard(ThemeData theme) {
    return _SectionCard(
      title: 'نبذة عن المتوفى',
      icon: Icons.description_rounded,
      children: [
        _buildTextField(
          controller: _descriptionController,
          label: 'نبذة (اختياري)',
          hint: 'كلمات عن حياة المتوفى وسيرته...',
          icon: Icons.description_outlined,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final obituary = _buildPreviewObituary();
    return _SectionCard(
      title: 'معاينة بطاقة المشاركة',
      icon: Icons.preview_rounded,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text('قرية أبوديشيشة',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (obituary.imageUrl != null &&
                  obituary.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: obituary.imageUrl!,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_rounded,
                      size: 48, color: theme.colorScheme.primary),
                ),
              const SizedBox(height: 12),
              Text('انتقل إلى رحمة الله تعالى',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(obituary.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('العمر: ${obituary.age}   •   الوفاة: ${obituary.dateOfDeath}',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
              if (obituary.relatives.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: obituary.relatives
                      .map((r) => Chip(
                            avatar: Icon(r.type.icon,
                                size: 14, color: theme.colorScheme.primary),
                            label: Text('${r.type.label}: ${r.name}'),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Text('"إنا لله وإنا إليه راجعون"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    ShareService.shareObituaryAsImage(context, obituary),
                icon: const Icon(Icons.image_outlined),
                label: const Text('مشاركة كصورة'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isSaving ? null : _submit,
        icon: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.send_rounded, size: 24),
        label: Text(
          _isSaving ? 'جاري الإرسال...' : 'إرسال التعزية للمراجعة',
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: theme.colorScheme.primary, width: 2)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.3),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateField({
    required ThemeData theme,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.3))),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Text(
          value == null ? 'اختر التاريخ' : DateFormat('yyyy/MM/dd').format(value),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: value == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(icon, color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}