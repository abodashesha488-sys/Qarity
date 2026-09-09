import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/helpers.dart';
import '../../core/utils/role_style.dart';
import '../../core/widgets/shared_cards.dart';
import '../../models/data_models.dart';
import '../../services/news_service.dart';
import '../../widgets/common_appbar_actions.dart';

/// Full article reader. Opened with a [NewsItem] as route argument
/// (see `AppRoutes.newsView`).
class NewsViewScreen extends StatefulWidget {
  const NewsViewScreen({super.key});

  @override
  State<NewsViewScreen> createState() => _NewsViewScreenState();
}

class _NewsViewScreenState extends State<NewsViewScreen> {
  final NewsService _newsService = NewsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();

  NewsItem? _news;
  bool _isSendingComment = false;
  bool _viewCounted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is NewsItem) _news = args;
    if (!_viewCounted && _news != null && _news!.id.isNotEmpty) {
      _viewCounted = true;
      _newsService.incrementViews(_news!.id);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final current = _news;
    if (current == null || current.id.isEmpty) return;
    try {
      final fresh = await _newsService.getNewsById(current.id);
      if (fresh != null && mounted) setState(() => _news = fresh);
    } catch (_) {
      // Live streams keep the screen usable, a failed refresh is not fatal.
    }
  }

  Future<void> _toggleLike(NewsItem item) async {
    final user = _auth.currentUser;
    if (user == null) {
      AppHelpers.showSnackBar(context, 'يجب تسجيل الدخول للإعجاب', isError: true);
      return;
    }
    try {
      await _newsService.toggleNewsLike(item.id, user.uid);
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'تعذر تحديث الإعجاب', isError: true);
    }
  }

  Future<void> _addComment(NewsItem item) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (_auth.currentUser == null) {
      AppHelpers.showSnackBar(context, 'يجب تسجيل الدخول لإضافة تعليق', isError: true);
      return;
    }
    setState(() => _isSendingComment = true);
    try {
      await _newsService.addComment(item.id, _auth.currentUser?.displayName ?? 'زائر', text);
      _commentController.clear();
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'تعذر إضافة التعليق', isError: true);
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _shareNews(NewsItem item) async {
    final text = '${item.title}\n${item.subtitle}';
    try {
      final uri = Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        AppHelpers.showSnackBar(context, 'لا يمكن فتح تطبيق المشاركة', isError: true);
      }
    } catch (_) {
      if (mounted) AppHelpers.showSnackBar(context, 'تعذر مشاركة الخبر', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passedItem = _news;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الخبر'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          if (passedItem != null)
            IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _shareNews(passedItem),
            ),
          ...CommonAppBarActions.actions(context),
        ],
      ),
      body: passedItem == null
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyContentState(icon: Icons.newspaper_rounded, message: 'تعذر تحميل الخبر'),
            )
          : StreamBuilder<NewsItem?>(
              initialData: passedItem,
              stream: passedItem.id.isEmpty ? const Stream<NewsItem?>.empty() : _newsService.getNewsItemStream(passedItem.id),
              builder: (context, snapshot) {
                final item = snapshot.data ?? passedItem;
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: _buildArticle(theme, item),
                      ),
                    ),
                    _buildCommentBar(theme, item),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildArticle(ThemeData theme, NewsItem item) {
    final images = item.imageUrls.isNotEmpty
        ? item.imageUrls
        : (item.imageUrl.isNotEmpty ? [item.imageUrl] : const <String>[]);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (images.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _ArticleGallery(images: images),
          ),
        if (images.isNotEmpty) const SizedBox(height: 16),
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
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category.isEmpty ? 'عام' : item.category,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (item.date.isNotEmpty)
                      _MetaRow(icon: Icons.calendar_today_outlined, label: item.date),
                    _MetaRow(icon: Icons.visibility_outlined, label: '${item.views} مشاهدة'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.title,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.35),
                ),
                const SizedBox(height: 12),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.8, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      child: Icon(Icons.person_rounded, size: 18, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RoleNameText(
                            name: item.authorName ?? 'محرر النظام',
                            role: item.authorRole,
                            sellerType: item.authorSellerType,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'محرر الخبر',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    _buildLikeButton(theme, item),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareNews(item),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('مشاركة الخبر'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Text('التعليقات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        _buildComments(theme, item),
      ],
    );
  }

  Widget _buildLikeButton(ThemeData theme, NewsItem item) {
    final userId = _auth.currentUser?.uid;
    return StreamBuilder<({int likes, bool isLiked})>(
      initialData: (likes: item.likes, isLiked: false),
      stream: item.id.isEmpty
          ? const Stream<({int likes, bool isLiked})>.empty()
          : _newsService.getNewsLikeStream(item.id, userId: userId),
      builder: (context, snapshot) {
        final state = snapshot.data ?? (likes: item.likes, isLiked: false);
        return InkWell(
          onTap: () => _toggleLike(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: state.isLiked
                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                  color: state.isLiked ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '${state.likes}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: state.isLiked ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComments(ThemeData theme, NewsItem item) {
    if (item.id.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: EmptyContentState(icon: Icons.chat_bubble_outline_rounded, message: 'لا توجد تعليقات'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _newsService.getCommentsStream(item.id),
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

  Widget _buildCommentBar(ThemeData theme, NewsItem item) {
    final isLoggedIn = _auth.currentUser != null;
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
              enabled: isLoggedIn && !_isSendingComment,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(item),
              decoration: InputDecoration(
                hintText: isLoggedIn ? 'أضف تعليقاً...' : 'سجّل الدخول لإضافة تعليق',
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
            onPressed: isLoggedIn && !_isSendingComment ? () => _addComment(item) : null,
            icon: _isSendingComment
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Hero gallery for the article: swipeable with live page indicators.
class _ArticleGallery extends StatefulWidget {
  const _ArticleGallery({required this.images});

  final List<String> images;

  @override
  State<_ArticleGallery> createState() => _ArticleGalleryState();
}

class _ArticleGalleryState extends State<_ArticleGallery> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                child: Center(
                  child: Icon(Icons.broken_image_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i == _current ? 0.95 : 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
