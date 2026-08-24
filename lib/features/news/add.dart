import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/network/network_info.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/image_upload_service.dart';
import '../../services/news_service.dart';
import '../../services/user_service.dart';

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({super.key});

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final NewsService _newsService = NewsService();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = ['عام', 'ثقافة', 'رياضة', 'مجتمع', 'تعليم', 'اقتصاد'];
  String _selectedCategory = 'عام';
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _authorId;
  String? _authorName;

  @override
  void initState() {
    super.initState();
    _loadAuthor();
  }

  Future<void> _loadAuthor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final model = await _userService.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _authorId = user.uid;
        _authorName = model?.name ?? user.displayName ?? 'مستخدم';
      });
    }
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
    if (!await NetworkInfo().isConnected) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'لا يوجد اتصال بالإنترنت', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final news = NewsItem(
        id: '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        imageUrl: _imageUrl ?? '',
        imageUrls: _imageUrl != null ? [_imageUrl!] : const [],
        date: DateFormat('yyyy/MM/dd').format(DateTime.now()),
        category: _selectedCategory,
        authorId: _authorId,
        authorName: _authorName,
        createdAt: DateTime.now(),
      );
      await _newsService.addNews(news);
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'تم إرسال الخبر للمراجعة', isSuccess: true);
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
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة خبر')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تفاصيل الخبر', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان الخبر', prefixIcon: Icon(Icons.title)),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v ?? 'عام'),
                  decoration: const InputDecoration(labelText: 'الفئة', prefixIcon: Icon(Icons.category)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: 'محتوى الخبر', prefixIcon: Icon(Icons.article)),
                maxLines: 6,
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 24),
              Text('صورة الخبر (اختياري)', style: theme.textTheme.titleMedium),
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
