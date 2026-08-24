import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/image_upload_service.dart';
import '../../services/news_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

/// News publishing screen registered on `AppRoutes.newsDetail`.
///
/// It takes no route arguments and submits a multi-image news item that is
/// stored unapproved (`isApproved: false`) for the admin review flow.
class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _dateController = TextEditingController();
  final List<String> _imageUrls = [];

  final ImagePicker _picker = ImagePicker();
  final NewsService _newsService = NewsService();
  final UserService _userService = UserService();

  static const List<String> _categories = ['عام', 'ثقافة', 'رياضة', 'مجتمع', 'تعليم', 'اقتصاد'];

  String _selectedCategory = 'عام';
  bool _isUploading = false;
  bool _isSaving = false;
  String? _authorId;
  String? _authorName;

  @override
  void initState() {
    super.initState();
    _dateController.text = AppHelpers.formatDate(DateTime.now());
    _loadAuthor();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final model = await _userService.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _authorId = user.uid;
        _authorName = model?.name ?? user.displayName ?? 'مستخدم';
      });
    } catch (_) {
      // Author data is optional metadata, never block publishing.
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
      setState(() => _imageUrls.add(url));
      AppHelpers.showSnackBar(context, 'تم رفع الصورة بنجاح', isSuccess: true);
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'خطأ في رفع الصورة: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) => setState(() => _imageUrls.removeAt(index));

  Future<void> _saveNews() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_imageUrls.isEmpty) {
      AppHelpers.showSnackBar(context, 'يرجى اختيار صورة الخبر', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final news = NewsItem(
        id: '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        imageUrl: _imageUrls.first,
        imageUrls: _imageUrls,
        date: _dateController.text,
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
      if (mounted) AppHelpers.showSnackBar(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('نشر خبر جديد'),
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
                _FormSection(
                  title: 'معلومات الخبر',
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
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                      maxLines: 6,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'المحتوى مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'تاريخ النشر',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'صور الخبر (${_imageUrls.length})',
                  icon: Icons.photo_library_rounded,
                  children: [
                    if (_imageUrls.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.image_outlined, size: 36, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(
                              'أضف صورة واحدة على الأقل',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) => _ImageThumb(
                            imageUrl: _imageUrls[index],
                            onRemove: _isSaving ? null : () => _removeImage(index),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading || _isSaving ? null : _pickAndUploadImage,
                        icon: _isUploading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_photo_alternate_rounded),
                        label: Text(_isUploading ? 'جاري الرفع...' : 'إضافة صورة'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                          'يتم مراجعة الخبر من الإدارة قبل نشره في القرية',
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
                    onPressed: _isSaving ? null : _saveNews,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSaving ? 'جاري النشر...' : 'نشر الخبر'),
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

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.icon, required this.children});

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

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.imageUrl, this.onRemove});

  final String imageUrl;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 110,
            height: 110,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 110,
              height: 110,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
              width: 110,
              height: 110,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.broken_image_rounded, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: theme.colorScheme.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
