import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/network/network_info.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/image_upload_service.dart';
import '../../services/news_service.dart';
import '../../services/user_service.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/qurity_app_bar.dart';

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({
    super.key,
    this.uploader,
    this.bytesSource,
    this.newsService,
    this.userService,
    this.existing,
  });

  /// اختياري لحقن محرّك الرفع ومصدر Bytes في الاختبارات (الإنتاج يتركهما فارغين).
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;

  /// اختياري للحقن في الاختبارات — الإنتاج يبني الخادم الحقيقي كسولًا كما كان.
  final NewsService? newsService;
  final UserService? userService;

  /// الخبر المحرَّر — عند وجوده يحفظ النموذج بتعديل صاحبه (البند ٨).
  final NewsItem? existing;

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _subtitleController =
      TextEditingController(text: widget.existing?.subtitle ?? '');
  late final NewsService _newsService = widget.newsService ?? NewsService();
  late final UserService _userService = widget.userService ?? UserService();

  static const List<String> _categories = ['عام', 'ثقافة', 'رياضة', 'مجتمع', 'تعليم', 'اقتصاد'];

  late String _selectedCategory = widget.existing?.category ?? 'عام';
  final List<String> _imageUrls = [];
  static const int _maxImages = 3;
  bool _isSaving = false;
  String? _authorId;
  String? _authorName;
  String? _authorRole;
  String? _authorSellerType;

  bool get _isEdit => widget.existing != null;

  /// المحرر المشترك يرفع ويحذف ويعرض؛ الباقي هنا مرآة القائمة التي تُكتب في الخبر.
  void _onImagesChanged(List<String> urls) {
    setState(() {
      _imageUrls
        ..clear()
        ..addAll(urls);
    });
  }

  @override
  void initState() {
    super.initState();
    _imageUrls.addAll(_existingImages);
    _loadAuthor();
  }

  /// صور الخبر المحرَّر: `imageUrls` إن وُجدت وإفالصورة الأولى المفردة.
  List<String> get _existingImages {
    final e = widget.existing;
    if (e == null) return const [];
    if (e.imageUrls.isNotEmpty) return e.imageUrls.take(_maxImages).toList();
    return e.imageUrl.isEmpty ? const <String>[] : [e.imageUrl];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final model = await _userService.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _authorId = user.uid;
        _authorName = model?.name ?? user.displayName ?? 'مستخدم';
        _authorRole = model?.role;
        _authorSellerType = model?.sellerType?.name;
      });
    } catch (_) {
      // بلا تهيئة Firebase (اختبارات الواجهة) يبقى التوقيع فارغًا ولا تسقط الشاشة
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!await NetworkInfo().isConnected) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'لا يوجد اتصال بالإنترنت', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    final editing = widget.existing;
    try {
      final news = NewsItem(
        id: editing?.id ?? '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        imageUrl: _imageUrls.isNotEmpty ? _imageUrls.first : '',
        imageUrls: List<String>.of(_imageUrls),
        // تاريخ الخبر ونسبته يبقى كما هو: فالتعديل مضمون لا إصدار جديد.
        date: editing?.date ?? DateFormat('yyyy/MM/dd').format(DateTime.now()),
        category: _selectedCategory,
        authorId: editing?.authorId ?? _authorId,
        authorName: editing?.authorName ?? _authorName,
        authorRole: editing?.authorRole ?? _authorRole,
        authorSellerType: editing?.authorSellerType ?? _authorSellerType,
        createdAt: editing?.createdAt,
      );
      if (editing == null) {
        await _newsService.addNews(news);
      } else {
        await _newsService.updateNews(news);
      }
      if (!mounted) return;
      AppHelpers.showSnackBar(context,
          editing == null ? 'تم إرسال الخبر للمراجعة' : 'تم حفظ التعديلات — أُعيد الخبر للمراجعة',
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(
          title: _isEdit ? 'تعديل الخبر' : 'إضافة خبر'),
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
                    ImageListEditor(
                      label: 'صور الخبر',
                      fieldKey: 'imageUrls',
                      urls: _imageUrls,
                      maxImages: _maxImages,
                      uploader: widget.uploader,
                      bytesSource: widget.bytesSource,
                      onChanged: _onImagesChanged,
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
                    label: Text(_isSaving
                        ? 'جاري الإرسال...'
                        : (_isEdit
                            ? 'حفظ التعديلات — يعاد للمراجعة'
                            : 'إرسال للمراجعة')),
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
