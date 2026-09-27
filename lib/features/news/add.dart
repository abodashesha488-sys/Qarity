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
  final List<String> _imageUrls = [];
  static const int _maxImages = 3;
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

  Future<void> _pickAndUploadImages() async {
    final remaining = _maxImages - _imageUrls.length;
    if (remaining <= 0) {
      AppHelpers.showSnackBar(context, 'الحد الأقصى $_maxImages صور', isError: true);
      return;
    }
    setState(() => _isUploading = true);
    try {
      final List<XFile> images =
          await _picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) {
        if (mounted) setState(() => _isUploading = false);
        return;
      }
      // لا نتعدّى الحد الأقصى المسموح
      final picked = images.take(remaining).toList();
      final uploaded = <String>[];
      for (final image in picked) {
        final bytes = await image.readAsBytes();
        uploaded.add(await ImageUploadService().uploadImage(bytes));
      }
      if (!mounted) return;
      setState(() => _imageUrls.addAll(uploaded));
      final skipped = images.length - picked.length;
      AppHelpers.showSnackBar(
        context,
        skipped > 0
            ? 'تم رفع ${picked.length} صورة (تجاوزت الحد الأقصى $_maxImages)'
            : 'تم رفع ${picked.length} صورة بنجاح',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'خطأ في رفع الصور: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) => setState(() => _imageUrls.removeAt(index));

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 4,
              minScale: 1,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(ctx),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageTile(BuildContext context, String url, int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showFullScreenImage(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 108,
              height: 108,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 108,
                height: 108,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                width: 108,
                height: 108,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black.withValues(alpha: 0.65),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isSaving ? null : () => _removeImage(index),
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addImageTile(ThemeData theme) {
    return SizedBox(
      width: 108,
      height: 108,
      child: OutlinedButton(
        onPressed: _isUploading || _isSaving ? null : _pickAndUploadImages,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: _isUploading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      color: theme.colorScheme.primary, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    'إضافة',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary),
                  ),
                ],
              ),
      ),
    );
  }

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
        imageUrl: _imageUrls.isNotEmpty ? _imageUrls.first : '',
        imageUrls: List<String>.of(_imageUrls),
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
                  title: 'صور الخبر (حتى $_maxImages صور)',
                  icon: Icons.image_rounded,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (int i = 0; i < _imageUrls.length; i++)
                          _imageTile(context, _imageUrls[i], i),
                        if (_imageUrls.length < _maxImages)
                          _addImageTile(theme),
                      ],
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
