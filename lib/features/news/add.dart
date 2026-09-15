import 'package:cached_network_image/cached_network_image.dart';
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
import '../../widgets/qurity_app_bar.dart';

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

  static const List<String> _categories = ['عام', 'ثقافة', 'رياضة', 'مجتمع', 'تعليم', 'اقتصاد'];

  String _selectedCategory = 'عام';
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _authorId;
  String? _authorName;
  String? _authorRole;
  String? _authorSellerType;

  @override
  void initState() {
    super.initState();
    _loadAuthor();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final model = await _userService.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _authorId = user.uid;
        _authorName = model?.name ?? user.displayName ?? 'مستخدم';
        _authorRole = model?.role;
        _authorSellerType = model?.sellerType?.name;
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
        authorRole: _authorRole,
        authorSellerType: _authorSellerType,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(title: 'إضافة خبر'),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'تفاصيل الخبر',
                  icon: Icons.newspaper_rounded,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الخبر',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'الفئة',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v ?? 'عام'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'محتوى الخبر',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.article_rounded),
                      ),
                      maxLines: 6,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'المحتوى مطلوب' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'صورة الخبر (اختياري)',
                  icon: Icons.image_rounded,
                  children: [
                    if (_imageUrl != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: _imageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 180,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 180,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Icon(Icons.broken_image_rounded, color: theme.colorScheme.onSurfaceVariant),
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
                                onTap: _isSaving ? null : _removeImage,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.error),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isUploading || _isSaving ? null : _pickAndUploadImage,
                          icon: _isUploading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.add_photo_alternate_rounded),
                          label: Text(_isUploading ? 'جاري الرفع...' : 'إضافة صورة'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
                          ),
                        ),
                      ),
                  ],
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
                      Icon(Icons.info_outline_rounded, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'سيتم مراجعة الخبر من الإدارة قبل ظهوره في قائمة الأخبار',
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
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  child: Icon(icon, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
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
