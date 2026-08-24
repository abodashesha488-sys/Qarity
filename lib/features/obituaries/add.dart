import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/network/network_info.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/image_upload_service.dart';
import '../../services/obituary_service.dart';

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
  final _placeController = TextEditingController();
  final _mosqueController = TextEditingController();
  final ObituaryService _obituaryService = ObituaryService();
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedDate;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _submittedBy;

  @override
  void initState() {
    super.initState();
    _loadSubmitter();
  }

  Future<void> _loadSubmitter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (!mounted) return;
      setState(() => _submittedBy = user.uid);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      AppHelpers.showSnackBar(context, 'يرجى اختيار تاريخ الوفاة', isError: true);
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
        date: DateFormat('yyyy/MM/dd').format(_selectedDate!),
        description: _descriptionController.text.trim(),
        place: _placeController.text.trim().isEmpty ? null : _placeController.text.trim(),
        mosque: _mosqueController.text.trim().isEmpty ? null : _mosqueController.text.trim(),
        imageUrl: _imageUrl,
        submittedBy: _submittedBy,
        createdAt: DateTime.now(),
      );
      await _obituaryService.addObituary(obituary);
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'تم إرسال التعزية للمراجعة', isSuccess: true);
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
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _placeController.dispose();
    _mosqueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة تعزية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('بيانات المتوفى', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person)),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'العمر', prefixIcon: Icon(Icons.cake)),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'تاريخ الوفاة', prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(
                    _selectedDate == null ? 'اختر التاريخ' : DateFormat('yyyy/MM/dd').format(_selectedDate!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(labelText: 'مكان العزاء (اختياري)', prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mosqueController,
                decoration: const InputDecoration(labelText: 'المسجد (اختياري)', prefixIcon: Icon(Icons.mosque)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'نبذة', prefixIcon: Icon(Icons.description)),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 24),
              Text('صورة (اختياري)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_imageUrl != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: _removeImage,
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 80,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadImage,
                    icon: _isUploading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.camera_alt),
                    label: Text(_isUploading ? 'جاري الرفع...' : 'إضافة صورة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('إرسال للمراجعة', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
