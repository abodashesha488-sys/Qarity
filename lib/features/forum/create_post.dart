import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/forum_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/user_service.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/qurity_app_bar.dart';

/// Creates a forum post. The post is stored unapproved (`isApproved: false`)
/// so it goes through the admin review flow before appearing in the feed.
///
/// تمرّ الشاشة نفسها للتعديل حين يُمرَّر [existing] (البند ٨): الحقول تُملأ من
/// المنشور، والحفظ يكتب عبر `updatePost` الذي يفرض العودة إلى المراجعة.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    this.existing,
    this.uploader,
    this.bytesSource,
    this.forumService,
    this.userService,
  });

  /// منشور قائم يملكه المستخدم الحالي — للتعديل لا للإنشاء.
  final ForumPost? existing;

  /// اختياري لاختبار المحرّر المشترك بلا شبكة ولا معرض جهاز.
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;

  /// اختياري للحقن في الاختبارات.
  final ForumService? forumService;
  final UserService? userService;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _contentController =
      TextEditingController(text: widget.existing?.content ?? '');
  late final ForumService _forumService =
      widget.forumService ?? ForumService();
  late final UserService _userService = widget.userService ?? UserService();

  static const List<String> _topics = [
    'عام',
    'نقاشات',
    'إعلانات القرية',
    'استشارات',
    'شكاوى ومقترحات',
    'طلبات وتواصل',
  ];
  String _category = 'عام';

  bool _isPosting = false;
  bool _isUploading = false;
  bool _isLoadingUser = true;
  String _userName = '';
  String _userPhoto = '';
  String? _userRole;
  String? _userSellerType;
  String? _uploadedImageUrl;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.existing;
    if (editing != null) {
      _category = _topics.contains(editing.category) ? editing.category : 'عام';
      final link = editing.imageUrl;
      _uploadedImageUrl = (link == null || link.isEmpty) ? null : link;
    }
    _loadUser();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _userName = user?.name ?? _userService.currentUser?.displayName ?? 'مستخدم';
        _userPhoto = user?.photoUrl ?? '';
        _userRole = user?.role;
        _userSellerType = user?.sellerType?.name;
        _isLoadingUser = false;
      });
    } catch (_) {
      // بلا تهيئة Firebase (اختبارات الواجهة) يبقى الاسم فارغًا ولا تسقط
      // الشاشة — لذا هنا لا نعيد قراءة المصادقة مرة ثانية.
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _post() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authUser = _userService.currentUser;
    if (authUser == null) {
      AppHelpers.showSnackBar(context, 'يجب تسجيل الدخول أولاً', isError: true);
      return;
    }
    setState(() => _isPosting = true);
    try {
      final editing = widget.existing;
      final post = ForumPost(
        id: editing?.id ?? '',
        userId: editing?.userId ?? authUser.uid,
        userName: _userName.isEmpty ? (authUser.displayName ?? 'مستخدم') : _userName,
        userPhotoUrl: _userPhoto,
        title: _titleController.text.trim(),
        category: _category,
        content: _contentController.text.trim(),
        imageUrl: _uploadedImageUrl ?? '',
        createdAt: editing?.createdAt ?? DateTime.now(),
        userRole: _userRole,
        userSellerType: _userSellerType,
        // `isApproved` يبقى false (الافتراضي): والإنشاء يدخل طابور المراجعة،
        // والتعديل يمرّ بـ`OwnerContentService.edit` الذي يفرض false أيضًا.
      );
      if (editing != null) {
        await _forumService.updatePost(post);
      } else {
        await _forumService.addPost(post);
      }
      if (!mounted) return;
      AppHelpers.showSnackBar(
          context,
          editing == null
              ? 'تم إرسال المنشور للمراجعة'
              : 'تم حفظ التعديلات — أُعيد المنشور للمراجعة',
          isSuccess: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: QurityAppBar(title: _isEdit ? 'تعديل المنشور' : 'إنشاء منشور'),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : AbsorbPointer(
              absorbing: _isPosting,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
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
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                    backgroundImage: _userPhoto.isNotEmpty
                                        ? CachedNetworkImageProvider(_userPhoto)
                                        : null,
                                    child: _userPhoto.isEmpty
                                        ? Icon(Icons.person_rounded, color: theme.colorScheme.primary)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _userName.isEmpty ? 'مستخدم' : _userName,
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                        ),
                                        Text(
                                          'ينشر في حوارات المندرة',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _titleController,
                                textCapitalization: TextCapitalization.sentences,
                                textInputAction: TextInputAction.next,
                                style: theme.textTheme.titleMedium,
                                decoration: const InputDecoration(
                                  hintText: 'عنوان الموضوع',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                              ),
                              const SizedBox(height: 16),
                              Text('اختر الموضوع',
                                  style: theme.textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _topics.map((t) {
                                  final selected = t == _category;
                                  return ChoiceChip(
                                    label: Text(t),
                                    selected: selected,
                                    showCheckmark: false,
                                    onSelected: (_) => setState(() => _category = t),
                                    selectedColor: theme.colorScheme.primary,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.4),
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contentController,
                                maxLines: 8,
                                minLines: 5,
                                autofocus: true,
                                textCapitalization: TextCapitalization.sentences,
                                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                                decoration: const InputDecoration(
                                  hintText: 'شارك فكرتك مع المجتمع...',
                                  alignLabelWithHint: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال المحتوى' : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
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
                                    child: Icon(Icons.image_rounded, size: 18, color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'صورة المنشور (اختياري)',
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ImageListEditor(
                                label: 'صورة المنشور',
                                fieldKey: 'imageUrl',
                                single: true,
                                urls: _uploadedImageUrl == null
                                    ? const <String>[]
                                    : <String>[_uploadedImageUrl!],
                                uploader: widget.uploader,
                                bytesSource: widget.bytesSource,
                                onBusyChanged:
                                    (busy) => setState(() => _isUploading = busy),
                                onChanged: (urls) => setState(() => _uploadedImageUrl =
                                    urls.isEmpty ? null : urls.first),
                              ),
                            ],
                          ),
                        ),
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
                                 'تتم مراجعة المنشورات من الإدارة قبل ظهورها في حوارات المندرة',
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
                          onPressed: _isPosting || _isUploading ? null : _post,
                          icon: _isPosting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send_rounded),
                          label: Text(_isPosting
                              ? (_isEdit ? 'جاري الحفظ...' : 'جاري النشر...')
                              : (_isEdit ? 'حفظ التعديلات' : 'نشر')),
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
