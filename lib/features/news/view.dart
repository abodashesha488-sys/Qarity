import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/utils/comment_style.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/relative_time.dart';
import '../../core/utils/role_style.dart';
import '../../core/widgets/shared_cards.dart';
import '../../models/data_models.dart';
import '../../services/news_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/qurity_app_bar.dart';

/// Full article reader. Opened with a [NewsItem] as route argument
/// (see `AppRoutes.newsView`).
class NewsViewScreen extends StatefulWidget {
  const NewsViewScreen({super.key, this.newsService, this.userService});

  /// اختياري لحقن Firestore في الاختبارات (الإنتاج يتركه فارغاً).
  final NewsService? newsService;

  /// اختياري لقراءة صورة محرر الخبر من ملفه (نفس نمط الحقن).
  final UserService? userService;

  @override
  State<NewsViewScreen> createState() => _NewsViewScreenState();
}

class _NewsViewScreenState extends State<NewsViewScreen> {
  late final NewsService _newsService = widget.newsService ?? NewsService();
  late final UserService _userService = widget.userService ?? UserService();
  final TextEditingController _commentController = TextEditingController();

  NewsItem? _news;
  bool _isSendingComment = false;
  bool _viewCounted = false;
  String _currentUserId = '';
  String _currentUserName = '';
  // الأدمن العام أو الأدمن المساعد فقط يستطيع حذف التعليقات.
  bool _canModerate = false;
  // صورة محرر الخبر (من users/{authorId}) — تُقرأ وقت العرض.
  String _authorPhotoUrl = '';
  String _authorPhotoFor = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadAuthorPhoto(String authorId) async {
    try {
      final model = await _userService.getUser(authorId);
      if (!mounted) return;
      setState(() => _authorPhotoUrl = (model?.photoUrl ?? '').trim());
    } catch (_) {
      // بلا اتصال أو بلا وثيقة: أيقونة الشخص تكفي، لا تُرك الشاشة معلقة.
    }
  }

  Future<void> _loadUser() async {
    // FirebaseAuth قد لا يكون مهيّأً (اختبارات بدون Firebase) — نتجاهله بأمان.
    User? fetched;
    try {
      fetched = FirebaseAuth.instance.currentUser;
    } catch (_) {
      return;
    }
    final user = fetched;
    if (user == null) return;
    try {
      final model = await _userService.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = model?.name ?? user.displayName ?? 'مستخدم';
        _canModerate = model?.isAdmin ?? false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? 'مستخدم';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is NewsItem) _news = args;
    if (!_viewCounted && _news != null && _news!.id.isNotEmpty) {
      _viewCounted = true;
      _newsService.incrementViews(_news!.id);
    }
    final authorId = _news?.authorId ?? '';
    if (authorId.isNotEmpty && _authorPhotoFor != authorId) {
      _authorPhotoFor = authorId;
      _loadAuthorPhoto(authorId);
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
    if (_currentUserId.isEmpty) {
      AppHelpers.showSnackBar(context, 'يجب تسجيل الدخول للإعجاب', isError: true);
      return;
    }
    try {
      await _newsService.toggleNewsLike(item.id, _currentUserId);
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'تعذر تحديث الإعجاب', isError: true);
    }
  }

  Future<void> _addComment(NewsItem item) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (_currentUserId.isEmpty) {
      AppHelpers.showSnackBar(context, 'يجب تسجيل الدخول لإضافة تعليق', isError: true);
      return;
    }
    setState(() => _isSendingComment = true);
    try {
      await _newsService.addComment(item.id, _currentUserName, text);
      _commentController.clear();
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'تعذر إضافة التعليق', isError: true);
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  /// حذف تعليق — للأدمن/الأدمن المساعد فقط، مع تأكيد مسبق.
  Future<void> _deleteComment(NewsItem item, String commentId, String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: Text(
          text.isEmpty
              ? 'هل أنت متأكد من حذف هذا التعليق؟'
              : 'هل أنت متأكد من حذف التعليق: "$text"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _newsService.deleteComment(item.id, commentId);
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'تعذر حذف التعليق — تحقق من الصلاحيات', isError: true);
      }
    }
  }

  Future<void> _shareNews(NewsItem item) async {
    await ShareService.shareText(title: item.title, body: item.subtitle);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passedItem = _news;

    return Scaffold(
      appBar: QurityAppBar(
        title: 'تفاصيل الخبر',
        actions: [
          if (passedItem != null)
            IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _shareNews(passedItem),
            ),
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
    final since = relativeTimeLabelAr(item.createdAt);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Category badge at top (above image)
        if (item.category.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
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
                    if (since.isNotEmpty)
                      _MetaRow(icon: Icons.schedule_rounded, label: since),
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
                      key: const Key('article-author-avatar'),
                      radius: CommentStyle.avatarRadius,
                      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      backgroundImage: CommentStyle.photoProvider(_authorPhotoUrl),
                      child: _authorPhotoUrl.isEmpty
                          ? Icon(Icons.person_rounded,
                              size: 20, color: theme.colorScheme.primary)
                          : null,
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
        _buildCommentsSection(theme, item),
      ],
    );
  }

  Widget _buildLikeButton(ThemeData theme, NewsItem item) {
    final userId = _currentUserId;
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

  Widget _buildCommentsSection(ThemeData theme, NewsItem item) {
    if (item.id.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _commentsHeader(theme, 0),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: EmptyContentState(icon: Icons.chat_bubble_outline_rounded, message: 'لا توجد تعليقات'),
          ),
        ],
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _newsService.getCommentsStream(item.id),
      builder: (context, snapshot) {
        // العدّاد يُؤخذ من عدد التعليقات الفعلية (مصدر الحقيقة) لا من حقل مخزّن.
        final count = snapshot.data?.docs.length ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _commentsHeader(theme, count),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'تعذر تحميل التعليقات',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              )
            else if (count == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyContentState(icon: Icons.chat_bubble_outline_rounded, message: 'لا توجد تعليقات بعد'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: count,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
                  final photo = (data['userPhotoUrl'] as String? ?? '').trim();
                  final commentText = data['text'] as String? ?? '';
                  return InfoListCard(
                    padding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      radius: CommentStyle.avatarRadius,
                      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      backgroundImage:
                          photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
                      child: photo.isEmpty
                          ? Icon(Icons.person_rounded, size: 20, color: theme.colorScheme.primary)
                          : null,
                    ),
                    title: data['userName'] as String? ?? 'زائر',
                    subtitleBuilder: (context) => [
                      Text(
                        data['userName'] as String? ?? 'زائر',
                        style: CommentStyle.author,
                      ),
                      const SizedBox(height: 5),
                      // نص التعليق: أسود بحجم واضح (تنسيق موحّد لكل التعليقات)
                      Text(commentText, style: CommentStyle.body),
                    ],
                    trailing: _canModerate
                        ? IconButton(
                            tooltip: 'حذف التعليق',
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 20, color: theme.colorScheme.error),
                            onPressed: () =>
                                _deleteComment(item, doc.id, commentText),
                          )
                        : null,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _commentsHeader(ThemeData theme, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'التعليقات ($count)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentBar(ThemeData theme, NewsItem item) {
    final isLoggedIn = _currentUserId.isNotEmpty;
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
///
/// الصورة تُعرض كاملة بِنِسبها الطبيعية على عرض الشاشة (بلا اقتصاص ولا تمديد)،
/// مع أسهم السابق/التالي وعدّاد ونقاط تمرير، والعدسة تفتحها بملء الشاشة.
class _ArticleGallery extends StatefulWidget {
  const _ArticleGallery({required this.images});

  final List<String> images;

  @override
  State<_ArticleGallery> createState() => _ArticleGalleryState();
}

class _ArticleGalleryState extends State<_ArticleGallery> {
  static const double _minHeight = 180;
  static const double _maxHeight = 420;
  static const double _fallbackRatio = 4 / 3;

  final PageController _controller = PageController();
  final Map<int, double> _ratios = {};
  final Set<int> _probing = {};
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _probeRatios();
  }

  /// يقيس نسبة كل صورة حقيقية (العرض ÷ الارتفاع) فيُقسّط الشريط على مقاسها
  /// الطبيعي بدل أن يقتطع منها. الفشل يترك النسبة الافتراضية.
  void _probeRatios() {
    for (int i = 0; i < widget.images.length; i++) {
      _probeOne(i, widget.images[i]);
    }
  }

  void _probeOne(int index, String url) {
    if (url.isEmpty || _probing.contains(index)) return;
    _probing.add(index);
    try {
      CachedNetworkImageProvider(url)
          .resolve(ImageConfiguration.empty)
          .addListener(ImageStreamListener((info, _) {
        final h = info.image.height;
        if (!mounted || h <= 0) return;
        setState(() => _ratios[index] = info.image.width / h);
      }, onError: (Object _, StackTrace? __) {}));
    } catch (_) {
      // لا Firebase في اختبارات الواجهة — النسبة الافتراضية تكفي.
    }
  }

  @override
  void didUpdateWidget(covariant _ArticleGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) _probeRatios();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final target = _current + delta;
    if (target < 0 || target >= widget.images.length) return;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _showFullScreenImage(BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        pageBuilder: (context, animation, secondaryAnimation) => _FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final multi = widget.images.length > 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = _ratios[_current] ?? _fallbackRatio;
        final height =
            (constraints.maxWidth / ratio).clamp(_minHeight, _maxHeight);
        return SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // خلفية داكنة خلف حواف الصور عند العرض الكامل (تحت الصورة دائمًا)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    _showFullScreenImage(context, widget.images, _current),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.images.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (context, i) => _GalleryPage(url: widget.images[i]),
                ),
              ),
              if (multi) ...[
                // سابق (يمين في RTL) / تالي (يسار)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: _NavButton(
                    key: const Key('gallery-prev'),
                    icon: Icons.chevron_right_rounded,
                    onTap: _current > 0 ? () => _step(-1) : null,
                    tooltip: 'السابق',
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: _NavButton(
                    key: const Key('gallery-next'),
                    icon: Icons.chevron_left_rounded,
                    onTap: _current < widget.images.length - 1
                        ? () => _step(1)
                        : null,
                    tooltip: 'التالي',
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_current + 1} / ${widget.images.length}',
                        key: const Key('gallery-counter'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.images.length,
                      (i) => GestureDetector(
                        onTap: () => _controller.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _current ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: i == _current ? 0.95 : 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // عدسة العرض بملء الشاشة
              Positioned(
                bottom: 12,
                right: 12,
                child: Tooltip(
                  message: 'عرض بملء الشاشة',
                  child: Material(
                    key: const Key('gallery-zoom'),
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _showFullScreenImage(
                          context, widget.images, _current),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.zoom_in_rounded,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// صفحة صورة واحدة داخل الشريط: تُعرض كاملة (contain) بلا اقتصاص.
class _GalleryPage extends StatelessWidget {
  const _GalleryPage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (context, url) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        child: Center(
          child: Icon(Icons.broken_image_rounded,
              size: 40, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Center(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.black.withValues(alpha: enabled ? 0.45 : 0.22),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon,
                  size: 26,
                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.5)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen image viewer with swipe navigation and zoom
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({required this.images, required this.initialIndex});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final target = _currentIndex + delta;
    if (target < 0 || target >= widget.images.length) return;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) => InteractiveViewer(
              maxScale: 4,
              minScale: 1,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.images[i],
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
          ),
          if (widget.images.length > 1) ...[
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: _NavButton(
                key: const Key('viewer-prev'),
                icon: Icons.chevron_right_rounded,
                onTap: _currentIndex > 0 ? () => _step(-1) : null,
                tooltip: 'السابق',
              ),
            ),
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: _NavButton(
                key: const Key('viewer-next'),
                icon: Icons.chevron_left_rounded,
                onTap: _currentIndex < widget.images.length - 1
                    ? () => _step(1)
                    : null,
                tooltip: 'التالي',
              ),
            ),
          ],
          SafeArea(
            child: Column(
              children: [
                // Top bar with close button and counter
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${_currentIndex + 1} / ${widget.images.length}',
                            key: const Key('viewer-counter'),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Bottom indicators
                if (widget.images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentIndex ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: i == _currentIndex ? 0.95 : 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
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
