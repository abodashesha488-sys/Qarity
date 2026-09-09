import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/utils/helpers.dart';
import '../../core/widgets/shared_cards.dart';
import '../../models/data_models.dart';
import '../../services/forum_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

/// Forum post reader. Opened with a [ForumPost] as route argument
/// (see `AppRoutes.forumPostDetail`).
class ForumPostDetailScreen extends StatefulWidget {
  const ForumPostDetailScreen({super.key});

  @override
  State<ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends State<ForumPostDetailScreen> {
  final ForumService _forumService = ForumService();
  final UserService _userService = UserService();
  final TextEditingController _commentController = TextEditingController();

  ForumPost? _post;
  String _currentUserId = '';
  String _currentUserName = '';
  bool _isSendingComment = false;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ForumPost) _post = args;
    if (!_viewCounted && _post != null && _post!.id.isNotEmpty) {
      _viewCounted = true;
      _forumService.incrementViews(_post!.id);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userModel = await _userService.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = userModel?.name ?? user.displayName ?? 'مستخدم';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? 'مستخدم';
      });
    }
  }

  Future<void> _refresh() async {
    await _loadUser();
    if (mounted) setState(() {});
  }

  Future<void> _toggleLike(ForumPost post) async {
    if (_currentUserId.isEmpty) {
      AppHelpers.showSnackBar(context, 'يجب تسجيل الدخول للإعجاب', isError: true);
      return;
    }
    AppHelpers.hapticLight();
    try {
      await _forumService.toggleLike(post.id, _currentUserId);
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'تعذر تحديث الإعجاب', isError: true);
    }
  }

  Future<void> _addComment(ForumPost post) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (_currentUserId.isEmpty) {
      AppHelpers.showSnackBar(context, 'يجب تسجيل الدخول لإضافة تعليق', isError: true);
      return;
    }
    setState(() => _isSendingComment = true);
    try {
      await _forumService.addComment(post.id, _currentUserName, text);
      _commentController.clear();
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'تعذر إضافة التعليق', isError: true);
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passedPost = _post;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          (passedPost != null && passedPost.title.isNotEmpty)
              ? passedPost.title
              : (passedPost?.userName.isNotEmpty == true ? passedPost!.userName : 'الموضوع'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: passedPost == null
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyContentState(icon: Icons.forum_rounded, message: 'تعذر تحميل الموضوع'),
            )
          : StreamBuilder<ForumPost?>(
              initialData: passedPost,
              stream: passedPost.id.isEmpty
                  ? const Stream<ForumPost?>.empty()
                  : _forumService.getPostStream(passedPost.id),
              builder: (context, snapshot) {
                final post = snapshot.data ?? passedPost;
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [
                            _buildPostCard(theme, post),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'التعليقات',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildComments(theme, post),
                          ],
                        ),
                      ),
                    ),
                    _buildCommentBar(theme, post),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildPostCard(ThemeData theme, ForumPost post) {
    final isLiked = _currentUserId.isNotEmpty && post.likedBy.contains(_currentUserId);

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
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  backgroundImage:
                      post.userPhotoUrl.isNotEmpty ? CachedNetworkImageProvider(post.userPhotoUrl) : null,
                  child: post.userPhotoUrl.isEmpty
                      ? Icon(Icons.person_rounded, color: theme.colorScheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName.isEmpty ? 'مستخدم' : post.userName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppHelpers.formatRelativeDate(post.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (post.isPinned) Icon(Icons.push_pin_rounded, size: 18, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),
            if (post.category.isNotEmpty && post.category != 'عام')
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(post.category,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.secondary)),
                ),
              ),
            if (post.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  post.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.3),
                ),
              ),
            Text(
              post.content,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.8, color: theme.colorScheme.onSurface),
            ),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    child: Center(
                      child: Icon(Icons.broken_image_rounded, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(icon: Icons.visibility_outlined, label: '${post.views} مشاهدة'),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.chat_bubble_outline_rounded, label: '${post.comments} تعليق'),
                const Spacer(),
                InkWell(
                  onTap: () => _toggleLike(post),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                          size: 18,
                          color: isLiked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isLiked ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComments(ThemeData theme, ForumPost post) {
    if (post.id.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: EmptyContentState(icon: Icons.chat_bubble_outline_rounded, message: 'لا توجد تعليقات'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _forumService.getCommentsStream(post.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'تعذر تحميل التعليقات',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          );
        }
        final comments = snapshot.data?.docs ?? const [];
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: EmptyContentState(icon: Icons.chat_bubble_outline_rounded, message: 'لا توجد تعليقات بعد'),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = comments[index].data() as Map<String, dynamic>? ?? <String, dynamic>{};
            return InfoListCard(
              padding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                child: Icon(Icons.person_rounded, size: 16, color: theme.colorScheme.primary),
              ),
              title: data['userName'] as String? ?? 'زائر',
              subtitleBuilder: (context) => [
                Text(
                  data['userName'] as String? ?? 'زائر',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(data['text'] as String? ?? '', style: theme.textTheme.bodySmall),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCommentBar(ThemeData theme, ForumPost post) {
    final canComment = _currentUserId.isNotEmpty;
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              enabled: canComment && !_isSendingComment,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(post),
              decoration: InputDecoration(
                hintText: canComment ? 'أضف تعليقاً...' : 'سجّل الدخول لإضافة تعليق',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: canComment && !_isSendingComment ? () => _addComment(post) : null,
            icon: _isSendingComment
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
