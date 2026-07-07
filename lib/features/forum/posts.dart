import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/forum_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

class ForumPostsScreen extends StatefulWidget {
  const ForumPostsScreen({super.key});

  @override
  State<ForumPostsScreen> createState() => _ForumPostsScreenState();
}

class _ForumPostsScreenState extends State<ForumPostsScreen> with AutomaticKeepAliveClientMixin {
  final ForumService _forumService = ForumService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'الأحدث';
  String _searchQuery = '';
  String _currentUserId = '';
  String _currentUserName = '';
  bool _isLoading = true;
  bool _hasError = false;

  static const List<String> _filters = ['الأحدث', 'الكل', 'الأكثر إعجاباً'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initUser();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final auth = FirebaseAuth.instance;
    final userService = UserService();
    final user = auth.currentUser;
    if (user != null) {
      final userModel = await userService.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = userModel?.name ?? user.displayName ?? 'مستخدم';
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() => _searchQuery = query);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتدى المجتمعي'),
        actions: CommonAppBarActions.actions(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.forumCreatePost),
        icon: const Icon(Icons.add_rounded),
        label: const Text('موضوع جديد'),
      ),
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(theme),
          const SizedBox(height: 16),
          _buildFilterChips(theme),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'ابحث في المواضيع...',
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = filter == _selectedFilter;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ChoiceChip(
              label: Text(filter, style: const TextStyle(fontWeight: FontWeight.w600)),
              selected: selected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) return _buildLoadingState(theme);
    if (_hasError) return _buildErrorState(theme);
    
    return StreamBuilder<List<ForumPost>>(
      stream: _forumService.getPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(theme, message: 'خطأ في الاتصال');
        }

        var posts = snapshot.data ?? [];

        // Apply filters
        if (_selectedFilter == 'الأحدث') {
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } else if (_selectedFilter == 'الأكثر إعجاباً') {
          posts.sort((a, b) => b.likes.compareTo(a.likes));
        }

        // Apply search
        if (_searchQuery.isNotEmpty) {
          posts = posts.where((p) =>
            p.userName.contains(_searchQuery) ||
            p.content.contains(_searchQuery)
          ).toList();
        }

        if (posts.isEmpty) {
          return _buildEmptyState(theme);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostCard(theme, posts[index], index),
        );
      },
    );
  }

  Widget _buildPostCard(ThemeData theme, ForumPost post, int index) {
    final dateStr = AppHelpers.formatRelativeDate(post.createdAt);
    final isLiked = _currentUserId.isNotEmpty && post.likedBy.contains(_currentUserId);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(context, AppRoutes.forumPostDetail, arguments: post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: post.userPhotoUrl.isNotEmpty ? CachedNetworkImageProvider(post.userPhotoUrl) : null,
                    child: post.userPhotoUrl.isEmpty
                        ? Icon(Icons.person_rounded, color: theme.colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          post.userName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 160,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.broken_image_rounded, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildActionButton(
                    theme,
                    icon: isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                    label: '${post.likes}',
                    color: isLiked ? theme.colorScheme.primary : null,
                    onTap: () => _toggleLike(context, post),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    theme,
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.comments}',
                    onTap: () => _showComments(context, post),
                  ),
                  const Spacer(),
                  Text(
                    '${post.views} مشاهدة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 60).ms).fade(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildActionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color ?? theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(radius: 24, backgroundColor: theme.colorScheme.surfaceContainerHighest),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: double.infinity, height: 16, color: theme.colorScheme.surfaceContainerHighest),
                    const SizedBox(height: 8),
                    Container(width: 80, height: 12, color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)),
                  ])),
                ]),
                const SizedBox(height: 16),
                Container(width: double.infinity, height: 14, color: theme.colorScheme.surfaceContainerHighest),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 14, color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)),
                const SizedBox(height: 8),
                Container(width: 120, height: 14, color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ).animate(delay: (index * 100).ms).fade(duration: 400.ms);
      },
    );
  }

  Widget _buildErrorState(ThemeData theme, {String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 48, color: theme.colorScheme.error),
            ),
            const SizedBox(height: 24),
            Text(
              'تعذر تحميل المواضيع',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _initUser();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.forum_rounded, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد مواضيع بعد',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'كن أول من يبدأ موضوعاً في المنتدى',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(BuildContext themeContext, ForumPost post) async {
    if (_currentUserId.isEmpty) return;
    try {
      final wasLiked = post.likedBy.contains(_currentUserId);
      await _forumService.toggleLike(post.id, _currentUserId);
      if (!mounted) return;
      setState(() {
        final updatedLikedby = List<String>.from(post.likedBy);
        if (wasLiked) {
          updatedLikedby.remove(_currentUserId);
        } else {
          updatedLikedby.add(_currentUserId);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(themeContext).showSnackBar(
          SnackBar(
            content: Text('خطأ في الإعجاب: $e'),
            backgroundColor: Theme.of(themeContext).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showComments(BuildContext context, ForumPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(
        post: post,
        forumService: _forumService,
        currentUserName: _currentUserName,
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final ForumPost post;
  final ForumService forumService;
  final String currentUserName;

  const CommentsSheet({
    super.key,
    required this.post,
    required this.forumService,
    required this.currentUserName,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.post.content,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.forumService.getCommentsStream(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('خطأ في تحميل التعليقات', style: TextStyle(color: theme.colorScheme.error)),
                  );
                }
                final comments = snapshot.data?.docs ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد تعليقات بعد',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['userName'] as String? ?? 'مستخدم',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c['text'] as String? ?? '',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'أضف تعليقاً...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      await widget.forumService.addComment(
        widget.post.id,
        widget.currentUserName,
        _commentController.text.trim(),
      );
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة التعليق: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
