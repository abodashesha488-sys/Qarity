import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/comment_style.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/role_style.dart';
import '../../core/widgets/shared_cards.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/forum_service.dart';
import '../../services/moderation_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/facebook_comment_tile.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/qurity_app_bar.dart';

class ForumPostsScreen extends StatefulWidget {
  const ForumPostsScreen({super.key});

  @override
  State<ForumPostsScreen> createState() => _ForumPostsScreenState();
}

class _ForumPostsScreenState extends State<ForumPostsScreen> with AutomaticKeepAliveClientMixin {
  final ForumService _forumService = ForumService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = _latestFilter;
  String _topic = 'الكل';
  String _searchQuery = '';
  String _currentUserId = '';
  String _currentUserName = '';
  bool _isAdmin = false;
  bool _isLoadingUser = true;

  static const String _latestFilter = 'الأحدث';
  static const String _allFilter = 'الكل';
  static const String _topFilter = 'الأكثر إعجاباً';

  static const List<String> _topics = [
    'الكل',
    'عام',
    'نقاشات',
    'إعلانات القرية',
    'استشارات',
    'شكاوى ومقترحات',
    'طلبات وتواصل',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initUser();
    _searchController.addListener(_onSearchChanged);
    ModerationService.instance.getBlockedUserIds().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
      return;
    }
    try {
      final userModel = await _userService.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = userModel?.name ?? user.displayName ?? 'مستخدم';
        _isAdmin = userModel?.isAdmin ?? false;
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? 'مستخدم';
        _isLoadingUser = false;
      });
    }
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  Future<void> _refresh() async {
    try {
      await _forumService.getLatestPosts(forceRefresh: true);
    } catch (_) {
      // The list is stream driven; a failed cache refresh must not break the UI.
    }
    await _initUser();
    if (mounted) setState(() {});
  }

  List<ForumPost> _applyFilters(List<ForumPost> source) {
    var posts = List<ForumPost>.of(source);
    posts = posts.where((p) => !ModerationService.instance.isUserBlockedSync(p.userId)).toList();
    if (_topic != 'الكل') {
      posts = posts.where((p) => (p.category.isEmpty ? 'عام' : p.category) == _topic).toList();
    }
    if (_selectedFilter == _latestFilter) {
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedFilter == _topFilter) {
      posts.sort((a, b) => b.likes.compareTo(a.likes));
    }
    if (_searchQuery.isEmpty) return posts;
    return posts
        .where((p) =>
            p.userName.toLowerCase().contains(_searchQuery) ||
            p.title.toLowerCase().contains(_searchQuery) ||
            p.content.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: QurityAppBar(
        title: 'حوارات المندرة',
        onAdd: () => Navigator.pushNamed(context, AppRoutes.forumCreatePost),
        addTooltip: 'موضوع جديد',
      ),
      body: Column(
        children: [
          _buildFilterHeader(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _buildContent(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortPill(ThemeData theme, String value, IconData icon, String short) {
    final selected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(short,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ابحث في المواضيع...',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: theme.colorScheme.primary, size: 18),
                            onPressed: _searchController.clear,
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // أزرار الترتيب الحديثة بجانب البحث
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _sortPill(theme, _latestFilter, Icons.schedule_rounded, 'الأحدث'),
                    _sortPill(theme, _allFilter, Icons.apps_rounded, 'الكل'),
                    _sortPill(theme, _topFilter, Icons.favorite_rounded, 'إعجاب'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _topics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final selected = topic == _topic;
                return ChoiceChip(
                  label: Text(topic),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _topic = topic),
                  selectedColor: theme.colorScheme.secondary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoadingUser) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return OfflineStreamBuilder<List<ForumPost>>(
      stream: _forumService.getPostsStream(),
      onlineBuilder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return _buildErrorState(theme);
        }

        final posts = _applyFilters(snapshot.data ?? const <ForumPost>[]);
        if (posts.isEmpty) {
          final isSearching = _searchQuery.isNotEmpty;
          return _buildStateScroller(
            Column(
              children: [
                EmptyContentState(
                  icon: isSearching ? Icons.search_off_rounded : Icons.forum_rounded,
                  message: isSearching ? 'لا توجد مواضيع مطابقة' : 'لا توجد مواضيع بعد',
                ),
                const SizedBox(height: 8),
                Text(
                   isSearching ? 'جرّب كلمة بحث أخرى' : 'كن أول من يبدأ موضوعاً في حوارات المندرة',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _buildPostCard(theme, posts[index], index),
        );
      },
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getForumPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          final all = (snapshot.data ?? []).map((j) => ForumPost.fromJson(j, 'cache')).toList();
          final posts = _applyFilters(all);
           return Scaffold(
             body: ColoredBox(
               color: theme.colorScheme.surface,
               child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('وضع غير متصل', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(child: posts.isEmpty
                    ? _buildStateScroller(const EmptyContentState(icon: Icons.forum_rounded, message: 'لا توجد مواضيع بعد'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _buildPostCard(theme, posts[index], index),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateScroller(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
      children: [child],
    );
  }

  Widget _buildPostCard(ThemeData theme, ForumPost post, int index) {
    final isLiked = _currentUserId.isNotEmpty && post.likedBy.contains(_currentUserId);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerLow : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: post.isPinned
              ? const Color(0xFFB8860B).withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: post.isPinned ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(context, AppRoutes.forumPostDetail, arguments: post),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. رأس المنشور: الكاتب والرتبة والوقت والتثبيت
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: post.isPinned
                              ? const Color(0xFFB8860B)
                              : theme.colorScheme.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        backgroundImage: post.userPhotoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(post.userPhotoUrl)
                            : null,
                        child: post.userPhotoUrl.isEmpty
                            ? Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 22)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RoleNameText(
                            name: post.userName,
                            role: post.userRole,
                            sellerType: post.userSellerType,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 11.5, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                AppHelpers.formatRelativeDate(post.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (post.isPinned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFB8860B).withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFFB8860B)),
                            SizedBox(width: 3),
                            Text(
                              'مثبّت',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB8860B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      tooltip: 'مشاركة المنشور',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(Icons.share_rounded,
                          size: 17, color: theme.colorScheme.onSurfaceVariant),
                      onPressed: () => ShareService.shareText(
                        title: post.title.isNotEmpty
                            ? post.title
                            : 'منشور من ${post.userName}',
                        body: post.content,
                      ),
                    ),
                    ModerationService.instance.buildMoreOptionsButton(
                      context: context,
                      targetType: 'forum_post',
                      targetId: post.id,
                      authorId: post.userId,
                      authorName: post.userName,
                      contentSnippet: post.title.isNotEmpty ? post.title : post.content,
                      onBlocked: () => setState(() {}),
                      iconColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),

                // 2. تصنيف الموضوع
                if (post.category.isNotEmpty && post.category != 'عام') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '# ${post.category}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],

                // 3. العنوان والمحتوى
                if (post.title.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  post.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    fontSize: 13.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // 4. صورة المنشور (إن وجدت)
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        width: double.infinity,
                        height: 190,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 190,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 190,
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                          child: Center(
                            child: Icon(Icons.broken_image_rounded,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // 5. شريط التفاعل السفلي العصري
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // زر الإعجاب
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _currentUserId.isEmpty ? null : () => _toggleLike(post),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isLiked
                                ? Colors.red.withValues(alpha: 0.12)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 16,
                                color: isLiked ? Colors.red : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${post.likes}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isLiked ? Colors.red : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // زر التعليقات
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showComments(post),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 15,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${post.comments}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // عداد المشاهدات
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_red_eye_outlined,
                              size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${post.views}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 45).ms).fade(duration: 300.ms).slideY(begin: 0.08);
  }

  Widget _buildErrorState(ThemeData theme) {
    return _buildStateScroller(
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded, size: 40, color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              Text(
                'تعذر تحميل المواضيع',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'تحقق من الاتصال بالإنترنت ثم أعد المحاولة',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(ForumPost post) async {
    if (_currentUserId.isEmpty) return;
    AppHelpers.hapticLight();
    try {
      await _forumService.toggleLike(post.id, _currentUserId);
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'تعذر تحديث الإعجاب', isError: true);
    }
  }

  void _showComments(ForumPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(
        post: post,
        forumService: _forumService,
        currentUserName: _currentUserName,
        currentUserId: _currentUserId,
        canModerate: _isAdmin,
        canComment: _currentUserId.isNotEmpty,
      ),
    );
  }
}

/// Quick comments sheet used from the posts list.
class CommentsSheet extends StatefulWidget {
  const CommentsSheet({
    super.key,
    required this.post,
    required this.forumService,
    required this.currentUserName,
    this.currentUserId = '',
    this.canModerate = false,
    this.canComment = true,
  });

  final ForumPost post;
  final ForumService forumService;
  final String currentUserName;
  final String currentUserId;
  final bool canModerate;
  final bool canComment;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  String? _replyToCommentId;
  String? _replyToAuthorName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || !widget.canComment) return;
    setState(() => _isSending = true);
    try {
      await widget.forumService.addComment(
        widget.post.id,
        widget.currentUserName,
        text,
        parentId: _replyToCommentId,
        replyToUser: _replyToAuthorName,
      );
      _commentController.clear();
      if (_replyToCommentId != null) {
        setState(() {
          _replyToCommentId = null;
          _replyToAuthorName = null;
        });
      }
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'تعذر إضافة التعليق', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4), height: 1),
          SizedBox(
            height: 340,
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.forumService.getCommentsStream(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'تعذر تحميل التعليقات',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  );
                }
                final comments = snapshot.data?.docs ?? const [];
                if (comments.isEmpty) {
                  return const EmptyContentState(
                    icon: Icons.chat_bubble_outline_rounded,
                    message: 'لا توجد تعليقات بعد',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final doc = comments[index];
                    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
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
                      avatarRadius: CommentStyle.avatarRadius,
                      textStyle: CommentStyle.body(context),
                      commentId: doc.id,
                      authorId: commentAuthor,
                      authorName: data['userName'] as String? ?? 'زائر',
                      authorPhotoUrl: photo,
                      text: commentText,
                      createdAt: createdAt,
                      updatedAt: updatedAt,
                      likes: likes,
                      likedBy: likedBy,
                      parentId: parentId,
                      replyToUser: replyToUser,
                      currentUserId: widget.currentUserId,
                      isAdmin: widget.canModerate,
                      onLike: () => widget.forumService.toggleCommentLike(
                          widget.post.id, doc.id, widget.currentUserId),
                      onReply: () {
                        setState(() {
                          _replyToCommentId = doc.id;
                          _replyToAuthorName = data['userName'] as String? ?? 'مستخدم';
                        });
                      },
                      onEdit: (newText) =>
                          widget.forumService.editComment(widget.post.id, doc.id, newText),
                      onDelete: () => widget.forumService.deleteComment(widget.post.id, doc.id),
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
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyToCommentId != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.reply_rounded, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'الرد على ${_replyToAuthorName ?? "تعليق"}',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _replyToCommentId = null;
                            _replyToAuthorName = null;
                          }),
                          child: const Icon(Icons.close_rounded, size: 16),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        enabled: widget.canComment && !_isSending,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _addComment(),
                        decoration: InputDecoration(
                          hintText: widget.canComment ? 'أضف تعليقاً...' : 'سجّل الدخول لإضافة تعليق',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          enabledBorder:
                              OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: widget.canComment && !_isSending ? _addComment : null,
                      icon: _isSending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
