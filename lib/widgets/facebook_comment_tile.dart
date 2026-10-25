import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/comment_style.dart';

/// بطاقة تعليق تفاعلية على طريقة فيسبوك:
/// - تعديل وحذف (لصاحب التعليق أو الأدمن)
/// - إعجاب وإلغاء إعجاب مع عدّاد الإعجابات
/// - رد متفرع مع إمكانية الرد على شخص محدد
/// - شارة (معدّل) وتوقيت نسبي
class FacebookCommentTile extends StatelessWidget {
  const FacebookCommentTile({
    super.key,
    required this.commentId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    this.createdAt,
    this.updatedAt,
    this.likes = 0,
    this.likedBy = const [],
    this.parentId,
    this.replyToUser,
    required this.currentUserId,
    this.isAdmin = false,
    this.avatarRadius,
    this.textStyle,
    this.onLike,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  final double? avatarRadius;
  final TextStyle? textStyle;

  final String commentId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int likes;
  final List<String> likedBy;
  final String? parentId;
  final String? replyToUser;
  final String currentUserId;
  final bool isAdmin;
  final Future<void> Function()? onLike;
  final VoidCallback? onReply;
  final Future<void> Function(String newText)? onEdit;
  final Future<void> Function()? onDelete;

  bool get isOwner =>
      currentUserId.isNotEmpty && authorId.isNotEmpty && currentUserId == authorId;
  bool get canEdit => isOwner || isAdmin;
  bool get canDelete => isOwner || isAdmin;
  bool get isLiked => currentUserId.isNotEmpty && likedBy.contains(currentUserId);
  bool get isReply => parentId != null && parentId!.isNotEmpty;
  bool get isEdited => updatedAt != null;

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 45) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${t.year}/${t.month}/${t.day}';
  }

  Future<void> _handleEdit(BuildContext context) async {
    final controller = TextEditingController(text: text);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل التعليق',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 3,
            maxLength: 500,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'اكتب التعديل هنا...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'لا يمكن ترك التعليق فارغاً' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != text) {
      await onEdit?.call(result);
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف التعليق'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا التعليق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bubbleBg = isDark
        ? const Color(0xFF242424)
        : (isReply ? const Color(0xFFF0F2F5) : const Color(0xFFF7F8FA));

    return Padding(
      padding: EdgeInsets.only(
        right: isReply ? 32 : 0,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // خط الشجرة للردود المتفرعة
          if (isReply) ...[
            Container(
              width: 14,
              height: 28,
              margin: const EdgeInsets.only(left: 4, top: 4),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ],

          // الصورة الشخصية
          CircleAvatar(
            radius: isReply ? 16 : (avatarRadius ?? CommentStyle.avatarRadius),
            backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            backgroundImage: CommentStyle.photoProvider(authorPhotoUrl),
            child: (authorPhotoUrl == null || authorPhotoUrl!.trim().isEmpty)
                ? Icon(
                    Icons.person_rounded,
                    size: isReply ? 16 : 20,
                    color: theme.colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(width: 8),

          // محتوى التعليق + الأزرار
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // فقاعة التعليق
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم الكاتب والوقت وشارة معدل
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              authorName.isEmpty ? 'زائر' : authorName,
                              style: CommentStyle.author(context).copyWith(
                                fontSize: isReply ? 12.5 : 13.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· ${_formatTime(createdAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                          if (isEdited) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(معدّل)',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // الرد على شخص معين
                      if (replyToUser != null && replyToUser!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ردًا على @$replyToUser',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 5),

                      // نص التعليق
                      Text(
                        text,
                        style: textStyle ?? CommentStyle.body(context),
                      ),
                    ],
                  ),
                ),

                // شريط التفاعل والردود (أزرار فيسبوك)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 6, left: 6),
                  child: Row(
                    children: [
                      // زر الإعجاب
                      InkWell(
                        onTap: onLike,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                                size: 14,
                                color: isLiked ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isLiked ? 'أعجبني' : 'إعجاب',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isLiked ? FontWeight.w800 : FontWeight.w600,
                                  color: isLiked ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (likes > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$likes',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // زر الرد
                      if (onReply != null) ...[
                        InkWell(
                          onTap: onReply,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 15,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'رد',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // زر التعديل
                      if (canEdit && onEdit != null) ...[
                        InkWell(
                          onTap: () => _handleEdit(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'تعديل',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // زر الحذف
                      if (canDelete && onDelete != null) ...[
                        InkWell(
                          key: key,
                          onTap: () => _handleDelete(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 13,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'حذف',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
