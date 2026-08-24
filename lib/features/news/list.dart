import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/widgets/shared_cards.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/news_service.dart';
import '../../widgets/common_appbar_actions.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with AutomaticKeepAliveClientMixin {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = _allLabel;
  String _searchQuery = '';

  static const String _allLabel = 'الكل';
  static const List<String> _baseCategories = ['عام', 'ثقافة', 'رياضة', 'مجتمع', 'تعليم', 'اقتصاد'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
  }

  Future<void> _refresh() async {
    try {
      await _newsService.getNewsList(forceRefresh: true);
    } catch (_) {
      // The list is stream driven; a failed cache refresh must not break the UI.
    }
    if (mounted) setState(() {});
  }

  List<String> _buildCategories(List<NewsItem> all) {
    final categories = <String>[_allLabel, ..._baseCategories];
    for (final item in all) {
      if (item.category.isNotEmpty && !categories.contains(item.category)) {
        categories.add(item.category);
      }
    }
    return categories;
  }

  List<NewsItem> _filter(List<NewsItem> all) {
    var list = all;
    if (_selectedCategory != _allLabel) {
      list = list.where((i) => i.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((i) =>
              i.title.toLowerCase().contains(_searchQuery) ||
              i.subtitle.toLowerCase().contains(_searchQuery) ||
              i.category.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('أخبار القرية'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.newsAdd),
        tooltip: 'إضافة خبر',
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة خبر'),
      ),
      body: StreamBuilder<List<NewsItem>>(
        stream: _newsService.getNewsStream(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <NewsItem>[];
          final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

          return Column(
            children: [
              _buildFilterHeader(theme, _buildCategories(all)),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: _buildContent(theme, snapshot, all, isLoading: isLoading),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    AsyncSnapshot<List<NewsItem>> snapshot,
    List<NewsItem> all, {
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (snapshot.hasError && all.isEmpty) {
      return _buildErrorState(theme);
    }

    final filtered = _filter(all);
    if (filtered.isEmpty) {
      final isFiltered = _searchQuery.isNotEmpty || _selectedCategory != _allLabel;
      return _buildStateScroller(
        Column(
          children: [
            EmptyContentState(
              icon: isFiltered ? Icons.search_off_rounded : Icons.newspaper_rounded,
              message: isFiltered ? 'لا توجد أخبار مطابقة' : 'لا توجد أخبار بعد',
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered ? 'جرّب تغيير الفئة أو كلمة البحث' : 'كن أول من ينشر خبراً عن القرية',
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
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildNewsCard(theme, filtered[index], index),
    );
  }

  Widget _buildStateScroller(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
      children: [child],
    );
  }

  Widget _buildFilterHeader(ThemeData theme, List<String> categories) {
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
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث في الأخبار...',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: theme.colorScheme.primary, size: 18),
                      onPressed: _searchController.clear,
                    )
                  : null,
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
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => _selectCategory(category),
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  side: BorderSide(
                    color: selected
                        ? Colors.transparent
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(ThemeData theme, NewsItem item, int index) {
    final images = item.imageUrls.isNotEmpty
        ? item.imageUrls
        : (item.imageUrl.isNotEmpty ? [item.imageUrl] : const <String>[]);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, AppRoutes.newsView, arguments: item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _NewsCardGallery(images: images, height: 180),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _CategoryBadge(category: item.category),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      if (item.date.isNotEmpty) _MetaItem(icon: Icons.calendar_today_outlined, label: item.date),
                      if (item.authorName != null && item.authorName!.isNotEmpty)
                        _MetaItem(icon: Icons.person_outline_rounded, label: item.authorName!),
                      _MetaItem(icon: Icons.favorite_border_rounded, label: '${item.likes}'),
                      _MetaItem(icon: Icons.chat_bubble_outline_rounded, label: '${item.comments}'),
                      _MetaItem(icon: Icons.visibility_outlined, label: '${item.views}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 60).ms).fade(duration: 350.ms).slideY(begin: 0.1);
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
                'تعذر تحميل الأخبار',
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
}

/// Cover gallery used by the news cards: swipeable when the item has
/// multiple images, with page indicators that follow the active page.
class _NewsCardGallery extends StatefulWidget {
  const _NewsCardGallery({required this.images, required this.height});

  final List<String> images;
  final double height;

  @override
  State<_NewsCardGallery> createState() => _NewsCardGalleryState();
}

class _NewsCardGalleryState extends State<_NewsCardGallery> {
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

    if (widget.images.isEmpty) {
      return _NewsImagePlaceholder(height: widget.height, icon: Icons.newspaper_rounded);
    }

    return SizedBox(
      height: widget.height,
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
              errorWidget: (context, url, error) =>
                  _NewsImagePlaceholder(height: widget.height, icon: Icons.broken_image_rounded),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 18 : 8,
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

class _NewsImagePlaceholder extends StatelessWidget {
  const _NewsImagePlaceholder({required this.height, required this.icon});

  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: Center(child: Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.isEmpty ? 'عام' : category,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

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
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
