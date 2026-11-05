import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_image_cache.dart';
import '../../core/utils/comment_style.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/launch_link.dart';
import '../../core/widgets/shared_cards.dart';
import '../../models/medical_models.dart';
import '../../services/admin_service.dart';
import '../../services/medical_service.dart';
import '../../services/share_service.dart';
import '../../widgets/common_appbar_actions.dart';
import '../../widgets/facebook_comment_tile.dart';
import '../../widgets/header_action_buttons.dart';
import '../../widgets/image_gallery_wrap.dart';
import '../../widgets/owner_actions.dart';
import '../../widgets/qurity_app_bar.dart';
import 'medical_home_screen.dart';

/// صف معلومة (أيقونة + عنوان + قيمة) — مشترك بين شاشات التفاصيل الطبية.
class MedInfoRow extends StatelessWidget {
  const MedInfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      this.accent = const Color(0xFF00897B)});
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon,
                size: 18, color: AppColors.inkOn(accent, theme.brightness)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة قسم بعنوان — مشتركة.
class MedSection extends StatelessWidget {
  const MedSection(
      {super.key,
      required this.title,
      required this.accent,
      required this.child});
  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.inkOn(accent, theme.brightness))),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// رأس متدرج/صورة مشترك لشاشات التفاصيل.
class MedDetailHeader extends StatelessWidget {
  const MedDetailHeader({
    super.key,
    required this.title,
    required this.accent,
    required this.accentDark,
    required this.imageUrl,
    required this.icon,
    this.onShare,
    this.onAdd,
    this.addTooltip = 'إضافة',
    this.favoriteButton,
  });
  final String title;
  final Color accent;
  final Color accentDark;
  final String imageUrl;
  final IconData icon;
  final VoidCallback? onShare;

  /// إجراء إضافة الشاشة — يظهر كزر «+» الأخضر في الهيدر (لا في شاشات لا إضافة لها).
  final VoidCallback? onAdd;
  final String addTooltip;
  final Widget? favoriteButton;

  @override
  Widget build(BuildContext context) {
    final headerColor =
        QurityAppBar.headerColorFor(Theme.of(context).brightness);
    return SliverMainAxisGroup(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: headerColor,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 10,
          title: Row(
            children: [
              const HeaderHomeButton(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          actions: [
            if (favoriteButton != null) favoriteButton!,
            if (onShare != null)
              IconButton(
                  tooltip: 'مشاركة',
                  icon: const Icon(Icons.share_rounded),
                  onPressed: onShare),
            if (onAdd != null)
              HeaderAddButton(onPressed: onAdd!, tooltip: addTooltip),
            const NotificationBellButton(),
          ],
        ),
        if (imageUrl.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 180,
                maxHeight: 320,
              ),
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.04),
              child: GestureDetector(
                onTap: () {
                  showDialog<void>(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.85),
                    builder: (ctx) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(16),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Center(
                            child: InteractiveViewer(
                              maxScale: 4.0,
                              child: AppImageCache.image(
                                url: imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: AppImageCache.image(
                  url: imageUrl,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => _gradientFallback(context),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _gradientFallback(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [accentDark, accent])),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Icon(icon, size: 72, color: Colors.white.withValues(alpha: 0.55)),
          ),
        ),
      );
}

/// شاشة تفاصيل عيادة القرية — عرض احترافي كامل مع الاتصال والمشاركة،
/// و«عدّل/احذف» لصاحب العيادة وحده على بياناته (البند ٨).
class VillageClinicDetailScreen extends StatefulWidget {
  const VillageClinicDetailScreen({super.key});

  @override
  State<VillageClinicDetailScreen> createState() =>
      _VillageClinicDetailScreenState();
}

class _VillageClinicDetailScreenState extends State<VillageClinicDetailScreen> {
  static const _teal = Color(0xFF00897B);
  static const _tealDark = Color(0xFF00695C);

  VillageClinic? _saved;
  late final VillageClinicService _service = VillageClinicService();

  final TextEditingController _commentController = TextEditingController();
  String? _replyToCommentId;
  String? _replyToAuthorName;
  bool _isPostingComment = false;
  bool _canModerate = false;

  String get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    if (_currentUid.isNotEmpty) { AdminService().isAdminUser(_currentUid).then((val) {
      if (mounted) setState(() => _canModerate = val);
    }); }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openEdit(VillageClinic clinic) async {
    final res = await showModalBottomSheet<VillageClinic>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VillageClinicFormSheet(
        userName: clinic.submittedByName ?? '',
        userId: _currentUid,
        existing: clinic,
      ),
    );
    if (res == null || !mounted) return;
    try {
      await _service.update(res);
      if (!mounted) return;
      setState(() => _saved = res);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ التعديلات — عادت العيادة للمراجعة')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذّر حفظ التعديل — تحقّق من الصلاحيات أو من الاتصال')));
    }
  }

  Future<bool> _deleteRecord(VillageClinic clinic) async {
    try {
      await _service.delete(clinic.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget? _ownerActions(VillageClinic clinic) {
    final owner = clinic.submittedBy ?? '';
    if (_currentUid.isEmpty || _currentUid != owner) return null;
    return OwnerActions(
      keyTag: 'clinic-detail',
      ownerId: owner,
      currentUserId: _currentUid,
      itemName: clinic.name,
      editLabel: 'تعديل العيادة',
      deleteLabel: 'حذف العيادة',
      onEdit: () => _openEdit(clinic),
      onDelete: () => _deleteRecord(clinic),
    );
  }

  Future<void> _addComment(VillageClinic clinic) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPostingComment) return;
    setState(() => _isPostingComment = true);
    try {
      await _service.addComment(
        clinic.id,
        text,
        parentId: _replyToCommentId,
        replyToUser: _replyToAuthorName,
      );
      _commentController.clear();
      setState(() {
        _replyToCommentId = null;
        _replyToAuthorName = null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إرسال التعليق')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _deleteComment(
      VillageClinic clinic, String commentId, String text) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا التعليق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _service.deleteComment(clinic.id, commentId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حذف التعليق')),
        );
      }
    }
  }

  Widget _buildRatingBar(ThemeData theme, VillageClinic clinic) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _teal.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        clinic.rating > 0 ? clinic.rating.toStringAsFixed(1) : 'لا تقييم بعد',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    clinic.ratingCount > 0 ? '(${clinic.ratingCount} تقييم)' : 'كن أول من يقيّم العيادة',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (_currentUid.isNotEmpty)
                StreamBuilder<double?>(
                  stream: _service.getUserRatingStream(clinic.id, _currentUid),
                  builder: (context, snapshot) {
                    final myRating = snapshot.data ?? 0.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          myRating > 0 ? 'تقييمك: ${myRating.toInt()} نجوم' : 'قيّم هذه العيادة',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _teal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RatingBar.builder(
                          initialRating: myRating,
                          minRating: 1,
                          itemSize: 22,
                          unratedColor: Colors.grey.withValues(alpha: 0.3),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) async {
                            try {
                              await _service.rateClinic(clinic.id, rating);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('شكراً لتقييمك!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تعذر حفظ التقييم')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComments(ThemeData theme, VillageClinic clinic) {
    if (clinic.id.isEmpty) return const SizedBox.shrink();

    return MedSection(
      title: 'التعليقات والتقييمات',
      accent: _teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRatingBar(theme, clinic),
          StreamBuilder<QuerySnapshot>(
        stream: _service.getCommentsStream(clinic.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final comments = snapshot.data?.docs ?? const [];
          if (comments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: EmptyContentState(
                icon: Icons.chat_bubble_outline_rounded,
                message: 'لا توجد تعليقات بعد — شاركنا رأيك أو استفسارك عن العيادة.',
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final doc = comments[index];
              final data =
                  doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
              final photo = (data['userPhotoUrl'] as String? ?? '').trim();
              final commentText = data['text'] as String? ?? '';
              final commentAuthor = (data['userId'] as String? ?? '').trim();
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
              final likes = (data['likes'] as num?)?.toInt() ?? 0;
              final likedBy = (data['likedBy'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  <String>[];
              final parentId = data['parentId'] as String?;
              final replyToUser = data['replyToUser'] as String?;

              return FacebookCommentTile(
                key: ValueKey('clinic-comment-${doc.id}'),
                avatarRadius: CommentStyle.avatarRadius,
                textStyle: CommentStyle.body(context),
                commentId: doc.id,
                authorId: commentAuthor,
                authorName: data['userName'] as String? ?? 'مستخدم',
                authorPhotoUrl: photo,
                text: commentText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                likes: likes,
                likedBy: likedBy,
                parentId: parentId,
                replyToUser: replyToUser,
                currentUserId: _currentUid,
                isAdmin: _canModerate,
                onLike: () =>
                    _service.toggleCommentLike(clinic.id, doc.id, _currentUid),
                onReply: () {
                  setState(() {
                    _replyToCommentId = doc.id;
                    _replyToAuthorName =
                        data['userName'] as String? ?? 'مستخدم';
                  });
                },
                onEdit: (newText) =>
                    _service.editComment(clinic.id, doc.id, newText),
                onDelete: () =>
                    _deleteComment(clinic, doc.id, commentText),
              );
            },
          );
        },
      ),
        ],
      ),
    );
  }

  Widget _buildCommentBar(ThemeData theme, VillageClinic clinic) {
    if (_currentUid.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: theme.colorScheme.surface,
        child: const Text(
          'سجل دخولك لتتمكن من إضافة تعليق أو استفسار',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToCommentId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 16, color: _teal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'الرد على ${_replyToAuthorName ?? 'التعليق'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _teal,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _replyToCommentId = null;
                      _replyToAuthorName = null;
                    }),
                    child: const Icon(Icons.close_rounded, size: 16, color: _teal),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _addComment(clinic),
                  decoration: InputDecoration(
                    hintText: _replyToCommentId != null
                        ? 'اكتب ردك هنا...'
                        : 'أضف تعليقاً أو استفساراً عن العيادة...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: _teal.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: _teal.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: _teal, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: _teal),
                icon: _isPostingComment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                onPressed: _isPostingComment ? null : () => _addComment(clinic),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = _saved ??
        ModalRoute.of(context)!.settings.arguments as VillageClinic? ??
            const VillageClinic(id: '', name: '');
    final ownerRow = _ownerActions(clinic);
    final isOpen = clinic.isCurrentlyOpen;

    return Scaffold(
      bottomNavigationBar: _buildCommentBar(theme, clinic),
      body: CustomScrollView(
        slivers: [
          MedDetailHeader(
            title: clinic.name,
            accent: _teal,
            accentDark: _tealDark,
            imageUrl: clinic.imageUrl,
            icon: Icons.add_business_rounded,
            onShare: () => ShareService.shareClinicDetails(
              clinicName: clinic.name,
              doctorName: clinic.ownerName,
              specialty: clinic.specialty,
              phone: clinic.phone,
              address: clinic.address,
              workingHours: '${clinic.workDaysSummary} • ${clinic.shiftsSummary}',
              imageUrl: clinic.imageUrl,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(clinic.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      // الشارة الحية اللحظية
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xFF2ECC71).withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOpen
                                ? const Color(0xFF2ECC71).withValues(alpha: 0.5)
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? const Color(0xFF00E676)
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOpen ? 'مفتوحة الآن' : 'مغلقة الآن',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOpen
                                    ? const Color(0xFF27AE60)
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (clinic.specialty.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: _teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _teal.withValues(alpha: 0.3))),
                        child: Text(clinic.specialty,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _teal)),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── بيانات العيادة الأساسية ──
                  MedSection(
                    title: 'بيانات العيادة',
                    accent: _teal,
                    child: Column(
                      children: [
                        MedInfoRow(
                            icon: Icons.fiber_manual_record_rounded,
                            label: 'حالة العيادة',
                            value: isOpen ? 'مفتوحة الآن وتستقبل المراجعين' : 'مغلقة الآن'),
                        if (clinic.ownerName.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.person_rounded,
                              label: 'الطبيب المسؤول',
                              value: clinic.ownerName),
                        if (clinic.phone.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.phone_rounded,
                              label: 'هاتف العيادة',
                              value: clinic.phone),
                        if (clinic.address.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'العنوان',
                              value: clinic.address),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── مواعيد وأيام وفترات العمل التفصيلية ──
                  MedSection(
                    title: 'مواعيد وأيام العمل',
                    accent: _teal,
                    child: Column(
                      children: [
                        MedInfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'أيام العمل',
                          value: clinic.workDaysSummary,
                        ),
                        if (clinic.hasMorningShift && clinic.morningStart.isNotEmpty)
                          MedInfoRow(
                            icon: Icons.wb_sunny_rounded,
                            label: 'الفترة الصباحية',
                            value: 'من ${clinic.formattedMorningStart} إلى ${clinic.formattedMorningEnd}',
                          ),
                        if (clinic.hasEveningShift && clinic.eveningStart.isNotEmpty)
                          MedInfoRow(
                            icon: Icons.nights_stay_rounded,
                            label: 'الفترة المسائية',
                            value: 'من ${clinic.formattedEveningStart} إلى ${clinic.formattedEveningEnd}',
                          ),
                        if (!clinic.hasMorningShift && !clinic.hasEveningShift && clinic.workingHours.isNotEmpty)
                          MedInfoRow(
                            icon: Icons.access_time_rounded,
                            label: 'المواعيد العامة',
                            value: clinic.workingHours,
                          ),
                      ],
                    ),
                  ),

                  if (clinic.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'عن العيادة',
                      accent: _teal,
                      child: Text(clinic.description,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6)),
                    ),
                  ],
                  if (clinic.imageUrls.length > 1) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'صور العيادة',
                      accent: _teal,
                      child: ImageGalleryWrap(urls: clinic.imageUrls, tileWidth: 180),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (clinic.phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        final error = await launchPhoneCall(clinic.phone);
                        if (error != null) {
                          AppHelpers.showToast(error, isError: true);
                        }
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('اتصال بالعيادة',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  if (ownerRow != null) ...[
                    const SizedBox(height: 12),
                    ownerRow,
                  ],

                  const SizedBox(height: 22),
                  // قسم التعليقات والردود
                  _buildComments(theme, clinic),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شاشة تفاصيل صيدلية القرية — مع «عدّل/احذف» لصاحب الصيدلية وحده (البند ٨).
class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({super.key});

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  static Color get _green => AppColors.primary;
  static Color get _greenDark => AppColors.primaryDark;

  Pharmacy? _saved;
  late final PharmacyService _service = PharmacyService();

  String get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openEdit(Pharmacy pharmacy) async {
    final res = await showModalBottomSheet<Pharmacy>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PharmacyFormSheet(
        userName: pharmacy.submittedByName ?? '',
        userId: _currentUid,
        existing: pharmacy,
      ),
    );
    if (res == null || !mounted) return;
    try {
      await _service.update(res);
      if (!mounted) return;
      setState(() => _saved = res);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ التعديلات — عادت الصيدلية للمراجعة')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذّر حفظ التعديل — تحقّق من الصلاحيات أو من الاتصال')));
    }
  }

  Future<bool> _deleteRecord(Pharmacy pharmacy) async {
    try {
      await _service.delete(pharmacy.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget? _ownerActions(Pharmacy pharmacy) {
    final owner = pharmacy.submittedBy ?? '';
    if (_currentUid.isEmpty || _currentUid != owner) return null;
    return OwnerActions(
      keyTag: 'pharmacy-detail',
      ownerId: owner,
      currentUserId: _currentUid,
      itemName: pharmacy.name,
      editLabel: 'تعديل الصيدلية',
      deleteLabel: 'حذف الصيدلية',
      onEdit: () => _openEdit(pharmacy),
      onDelete: () => _deleteRecord(pharmacy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pharmacy = _saved ??
        ModalRoute.of(context)!.settings.arguments as Pharmacy? ??
            const Pharmacy(id: '', name: '');
    final ownerRow = _ownerActions(pharmacy);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          MedDetailHeader(
            title: pharmacy.name,
            accent: _green,
            accentDark: _greenDark,
            imageUrl: pharmacy.imageUrl,
            icon: Icons.local_pharmacy_rounded,
            onShare: () => ShareService.shareText(
                title: '💊 ${pharmacy.name}',
                body: [
                  if (pharmacy.ownerName.isNotEmpty)
                    'المسؤول: ${pharmacy.ownerName}',
                  pharmacy.is24Hours
                      ? 'تعمل على مدار ٢٤ ساعة'
                      : (pharmacy.workingHours.isNotEmpty
                          ? 'المواعيد: ${pharmacy.workingHours}'
                          : ''),
                  if (pharmacy.address.isNotEmpty)
                    'العنوان: ${pharmacy.address}',
                  if (pharmacy.phone.isNotEmpty) 'هاتف: ${pharmacy.phone}',
                ].where((e) => e.isNotEmpty).join('\n')),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(pharmacy.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900)),
                      ),
                      if (pharmacy.is24Hours)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _green.withValues(alpha: 0.3))),
                          child: Text('٢٤ ساعة',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _green)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MedSection(
                    title: 'بيانات الصيدلية',
                    accent: _green,
                    child: Column(
                      children: [
                        if (pharmacy.ownerName.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.person_rounded,
                              label: 'الصيدلي المسؤول',
                              value: pharmacy.ownerName,
                              accent: _green),
                        if (pharmacy.phone.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.phone_rounded,
                              label: 'الهاتف',
                              value: pharmacy.phone,
                              accent: _green),
                        if (pharmacy.workingHours.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'مواعيد العمل',
                              value: pharmacy.workingHours,
                              accent: _green),
                        if (pharmacy.address.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'العنوان',
                              value: pharmacy.address,
                              accent: _green),
                      ],
                    ),
                  ),
                  if (pharmacy.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'عن الصيدلية',
                      accent: _green,
                      child: Text(pharmacy.description,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6)),
                    ),
                  ],
                  if (pharmacy.imageUrls.length > 1) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'صور الصيدلية',
                      accent: _green,
                      child: ImageGalleryWrap(urls: pharmacy.imageUrls, tileWidth: 180),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (pharmacy.phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        final error = await launchPhoneCall(pharmacy.phone);
                        if (error != null) {
                          AppHelpers.showToast(error, isError: true);
                        }
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('اتصال بالصيدلية',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  if (ownerRow != null) ...[
                    const SizedBox(height: 12),
                    ownerRow,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شاشة تفاصيل معمل التحاليل — مع «عدّل/احذف» لصاحب المعمل وحده (البند ٨).
class MedicalLabDetailScreen extends StatefulWidget {
  const MedicalLabDetailScreen({super.key});

  @override
  State<MedicalLabDetailScreen> createState() => _MedicalLabDetailScreenState();
}

class _MedicalLabDetailScreenState extends State<MedicalLabDetailScreen> {
  static const _purple = Color(0xFF6A1B9A);
  static const _purpleDark = Color(0xFF4A148C);

  MedicalLab? _saved;
  late final MedicalLabService _service = MedicalLabService();

  String get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openEdit(MedicalLab lab) async {
    final res = await showModalBottomSheet<MedicalLab>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LabFormSheet(
        userName: lab.submittedByName ?? '',
        userId: _currentUid,
        existing: lab,
      ),
    );
    if (res == null || !mounted) return;
    try {
      await _service.update(res);
      if (!mounted) return;
      setState(() => _saved = res);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ التعديلات — عاد المعمل للمراجعة')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذّر حفظ التعديل — تحقّق من الصلاحيات أو من الاتصال')));
    }
  }

  Future<bool> _deleteRecord(MedicalLab lab) async {
    try {
      await _service.delete(lab.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget? _ownerActions(MedicalLab lab) {
    final owner = lab.submittedBy ?? '';
    if (_currentUid.isEmpty || _currentUid != owner) return null;
    return OwnerActions(
      keyTag: 'lab-detail',
      ownerId: owner,
      currentUserId: _currentUid,
      itemName: lab.name,
      editLabel: 'تعديل المعمل',
      deleteLabel: 'حذف المعمل',
      onEdit: () => _openEdit(lab),
      onDelete: () => _deleteRecord(lab),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lab = _saved ??
        ModalRoute.of(context)?.settings.arguments as MedicalLab? ??
            const MedicalLab(id: '', name: '');
    final ownerRow = _ownerActions(lab);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          MedDetailHeader(
            title: lab.name,
            accent: _purple,
            accentDark: _purpleDark,
            imageUrl: lab.imageUrl,
            icon: Icons.science_rounded,
            onShare: () => ShareService.shareText(
                title: '🧪 ${lab.name}',
                body: [
                  if (lab.category.isNotEmpty)
                    'نوع التحاليل: ${lab.category}',
                  if (lab.homeCollection) '✅ يتوفر سحب عينة بالمنزل',
                  if (lab.ownerName.isNotEmpty)
                    'المسؤول: ${lab.ownerName}',
                  if (lab.workingHours.isNotEmpty)
                    'المواعيد: ${lab.workingHours}',
                  if (lab.address.isNotEmpty) 'العنوان: ${lab.address}',
                  if (lab.phone.isNotEmpty) 'هاتف: ${lab.phone}',
                ].join('\n')),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(lab.name,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      if (lab.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: _purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _purple.withValues(alpha: 0.3))),
                          child: Text(lab.category,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _purple)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MedSection(
                    title: 'بيانات المعمل',
                    accent: _purple,
                    child: Column(
                      children: [
                        if (lab.ownerName.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.person_rounded,
                              label: 'مدير المعمل',
                              value: lab.ownerName,
                              accent: _purple),
                        if (lab.phone.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.phone_rounded,
                              label: 'الهاتف',
                              value: lab.phone,
                              accent: _purple),
                        if (lab.workingHours.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'مواعيد العمل',
                              value: lab.workingHours,
                              accent: _purple),
                        if (lab.address.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'العنوان',
                              value: lab.address,
                              accent: _purple),
                        MedInfoRow(
                            icon: Icons.home_work_rounded,
                            label: 'سحب العينات بالمنزل',
                            value: lab.homeCollection
                                ? 'متوفر — اتصل للترتيب'
                                : 'غير متوفر',
                            accent: _purple),
                      ],
                    ),
                  ),
                  if (lab.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'عن المعمل وتحاليله',
                      accent: _purple,
                      child: Text(lab.description,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6)),
                    ),
                  ],
                  if (lab.imageUrls.length > 1) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'صور المعمل',
                      accent: _purple,
                      child: ImageGalleryWrap(urls: lab.imageUrls, tileWidth: 180),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (lab.phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _purple,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        final error = await launchPhoneCall(lab.phone);
                        if (error != null) {
                          AppHelpers.showToast(error, isError: true);
                        }
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('اتصال بالمعمل',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  if (ownerRow != null) ...[
                    const SizedBox(height: 12),
                    ownerRow,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
