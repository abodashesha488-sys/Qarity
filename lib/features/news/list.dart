import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/news_service.dart';
import '../../widgets/common_appbar_actions.dart';
import '../../widgets/header_action_buttons.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/qurity_app_bar.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, this.newsService});

  /// اختياري لحقن Firestore في الاختبارات (الإنتاج يتركه فارغاً).
  final NewsService? newsService;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with AutomaticKeepAliveClientMixin {
  late final NewsService _newsService = widget.newsService ?? NewsService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  bool _loading = true;

  static const List<String> _categories = [
    'الكل',
    'عام',
    'ثقافة',
    'رياضة',
    'مجتمع',
    'تعليم',
    'اقتصاد',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'الكل': Icons.apps_rounded,
    'عام': Icons.public_rounded,
    'ثقافة': Icons.menu_book_rounded,
    'رياضة': Icons.sports_soccer_rounded,
    'مجتمع': Icons.groups_rounded,
    'تعليم': Icons.school_rounded,
    'اقتصاد': Icons.trending_up_rounded,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NewsItem> _sortedByDate(List<NewsItem> all) {
    final list = List<NewsItem>.of(all);
    list.sort((a, b) => (b.createdAt ?? DateTime(1970))
        .compareTo(a.createdAt ?? DateTime(1970)));
    return list;
  }

  List<NewsItem> _filter(List<NewsItem> all) {
    var list = all;
    if (_selectedCategory != 'الكل') {
      list = list.where((n) => n.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((n) =>
              n.title.toLowerCase().contains(_searchQuery) ||
              n.subtitle.toLowerCase().contains(_searchQuery) ||
              n.category.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  List<NewsItem> _trending(List<NewsItem> all) {
    final list = List<NewsItem>.of(all);
    list.sort((a, b) =>
        (b.views + b.likes * 3).compareTo(a.views + a.likes * 3));
    return list.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: OfflineStreamBuilder<List<NewsItem>>(
        stream: _newsService.getNewsStream(),
        onlineBuilder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _loading) {
            return const _NewsSkeleton();
          }
          if (snapshot.hasError) {
            return _ErrorState(onRetry: () => setState(() {}));
          }
          final all = _sortedByDate(snapshot.data ?? const []);
          _loading = false;
          return _buildContent(theme, all);
        },
        cacheBuilder: (context) => FutureBuilder(
          future: CacheService.getNews(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const _NewsSkeleton();
            final all = (snapshot.data ?? []).map((j) => NewsItem.fromJson(j, 'cache')).toList();
             return Scaffold(
               body: ColoredBox(
                 color: theme.colorScheme.surface,
                 child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 16, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          const Text('وضع غير متصل', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(child: _buildContent(theme, _sortedByDate(all))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, List<NewsItem> all) {
    final filtered = _filter(all);
    final showHero = _selectedCategory == 'الكل' && _searchQuery.isEmpty;
    final featured = showHero && all.isNotEmpty ? all.first : null;
    final trending = showHero ? _trending(all) : <NewsItem>[];
    final rest = showHero
        ? filtered.where((n) => n.id != featured?.id).toList()
        : filtered;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(theme),
        if (featured != null)
          SliverToBoxAdapter(child: _FeaturedHero(item: featured)),
        SliverToBoxAdapter(child: _buildCategoryChips(theme)),
        if (trending.length > 1)
          SliverToBoxAdapter(child: _buildTrending(theme, trending)),
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: _selectedCategory == 'الكل' ? 'أحدث الأخبار' : _selectedCategory,
            count: rest.length,
          ),
        ),
        if (rest.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyNews(
              filtered: _searchQuery.isNotEmpty || _selectedCategory != 'الكل',
              onClear: () {
                setState(() {
                  _selectedCategory = 'الكل';
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList.separated(
              itemCount: rest.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _NewsCard(item: rest[i], index: i),
            ),
          ),
      ],
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: QurityAppBar.headerColor,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 10,
      title: const Row(
        children: [
          HeaderHomeButton(),
          SizedBox(width: 10),
          Expanded(
            child: Text('أخبار القرية',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      actions: [
        HeaderAddButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.newsAdd),
          tooltip: 'إضافة خبر',
        ),
        ...CommonAppBarActions.actions(context),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(74),
child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'ابحث في الأخبار...',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: _clearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    if (mounted) setState(() => _searchQuery = '');
  }

  Widget _buildCategoryChips(ThemeData theme) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    _categoryIcons[cat] ?? Icons.label_outline_rounded,
                    size: 16,
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat,
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrending(ThemeData theme, List<NewsItem> trending) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text('الأكثر قراءة',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1.5,
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: trending.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final n = trending[i];
              return GestureDetector(
                onTap: () => _open(n),
                child: SizedBox(
                  width: 152,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: double.infinity,
                                child: _thumb(n),
                              ),
                            ),
                            // ترتيب القراءة (رقم الزاوية)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _open(NewsItem item) =>
      Navigator.pushNamed(context, AppRoutes.newsView, arguments: item);

  Widget _thumb(NewsItem item, {BoxFit fit = BoxFit.cover}) {
    final theme = Theme.of(context);
    final url = item.imageUrls.isNotEmpty ? item.imageUrls.first : item.imageUrl;
    if (url.isEmpty) {
      return ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.newspaper_rounded,
            size: 40, color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (c, u) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (c, u, e) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_rounded,
            color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// ═══════════════════════ Featured hero ═══════════════════════
class _FeaturedHero extends StatelessWidget {
  const _FeaturedHero({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.newsView,
          arguments: item),
      child: Container(
        height: 250,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _HeroThumb(item: item),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(item.category,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800)),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded,
                              size: 13, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          const Text('الخبر الرئيسي',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const Spacer(),
                      Text(item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 21,
                              height: 1.25)),
                      const SizedBox(height: 6),
                      if (item.subtitle.isNotEmpty)
                        Text(item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                height: 1.4)),
                      const SizedBox(height: 10),
                      _NewsMeta(item: item, light: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _HeroThumb extends StatelessWidget {
  const _HeroThumb({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = item.imageUrls.isNotEmpty ? item.imageUrls.first : item.imageUrl;
    if (url.isEmpty) {
      return ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.newspaper_rounded,
            size: 60, color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (c, u) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (c, u, e) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_rounded,
            color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// ═══════════════════════ Section header ═══════════════════════
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════ News card (compact list row) ═══════════════════════
class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.index});
  final NewsItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.newsView,
            arguments: item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.category.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.category,
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800)),
                      ),
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.35)),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 10),
                    _NewsMeta(item: item),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child: _CardThumb(item: item),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 45).ms).fadeIn(duration: 350.ms).slideY(begin: 0.06);
  }
}

class _CardThumb extends StatelessWidget {
  const _CardThumb({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = item.imageUrls.isNotEmpty ? item.imageUrls.first : item.imageUrl;
    if (url.isEmpty) {
      return ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.newspaper_rounded,
            size: 36, color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (c, u) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (c, u, e) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_rounded,
            color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _NewsMeta extends StatelessWidget {
  const _NewsMeta({required this.item, this.light = false});
  final NewsItem item;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant;
    final readMin = (item.subtitle.split(RegExp(r'\s+')).length / 180).ceil().clamp(1, 20);
    return Row(
      children: [
        Icon(Icons.visibility_rounded, size: 13, color: color),
        const SizedBox(width: 3),
        Text('${item.views}', style: TextStyle(fontSize: 10.5, color: color)),
        const SizedBox(width: 10),
        Icon(Icons.favorite_rounded, size: 13, color: color),
        const SizedBox(width: 3),
        Text('${item.likes}', style: TextStyle(fontSize: 10.5, color: color)),
        const SizedBox(width: 10),
        Icon(Icons.mode_comment_outlined, size: 13, color: color),
        const SizedBox(width: 3),
        Text('${item.comments}', style: TextStyle(fontSize: 10.5, color: color)),
        const SizedBox(width: 10),
        Icon(Icons.schedule_rounded, size: 13, color: color),
        const SizedBox(width: 3),
        Text('$readMin د', style: TextStyle(fontSize: 10.5, color: color)),
      ],
    );
  }
}

// ═══════════════════════ States ═══════════════════════
class _EmptyNews extends StatelessWidget {
  const _EmptyNews({required this.filtered, required this.onClear});
  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(filtered ? Icons.search_off_rounded : Icons.newspaper_rounded,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(filtered ? 'لا توجد أخبار مطابقة' : 'لا توجد أخبار بعد',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              filtered ? 'جرّب تغيير الفئة أو كلمة البحث' : 'كن أول من ينشر خبراً عن القرية',

              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (filtered) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('عرض الكل'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('تعذر تحميل الأخبار',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: theme.colorScheme.surface,
            child: Container(
              height: i == 0 ? 220 : 130,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
