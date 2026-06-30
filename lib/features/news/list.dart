import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/news_service.dart';
import '../../widgets/common_appbar_actions.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  List<NewsItem> _allNews = [];
  List<NewsItem> _filteredNews = [];
  bool _isLoading = true;
  bool _hasError = false;
  final NewsService _newsService = NewsService();

  static const List<String> _categories = ['الكل', 'ثقافة', 'رياضة', 'مجتمع', 'تعليم', 'اقتصاد'];

  @override
  void initState() {
    super.initState();
    _loadNews();
    _searchController.addListener(_updateSearchResults);
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final news = await _newsService.getNewsList();
      setState(() {
        _allNews = news;
        _filteredNews = news;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_updateSearchResults);
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchResults() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _applyCategoryFilter());
    } else {
      final filtered = _allNews.where((item) {
        return item.title.toLowerCase().contains(query) ||
            item.subtitle.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
      setState(() => _filteredNews = filtered);
    }
  }

  void _applyCategoryFilter() {
    _filteredNews = _selectedCategory == 'الكل'
        ? _allNews
        : _allNews.where((item) => item.category == _selectedCategory).toList();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _applyCategoryFilter();
    });
  }

  Future<void> _refreshNews() async {
    await _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أخبار القرية'), actions: CommonAppBarActions.actions(context)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'news-add',
        child: const Icon(Icons.add_rounded),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.newsDetail),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNews,
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
                ? _buildErrorState()
                : _allNews.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredNews.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSearchField(context),
                                const SizedBox(height: 20),
                                _buildCategoryChips(context),
                                const SizedBox(height: 24),
                              ],
                            );
                          }
                          final newsItem = _filteredNews[index - 1];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _buildNewsCard(context, newsItem, index - 1),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Container(width: double.infinity, height: 180, color: Colors.grey[300], child: const Center(child: CircularProgressIndicator())),
              const SizedBox(height: 12),
              Container(width: double.infinity, height: 20, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Container(width: double.infinity, height: 16, color: Colors.grey[200]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('خطأ في تحميل الأخبار', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextButton(onPressed: _refreshNews, child: const Text('حاول مرة أخرى')),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.newspaper_rounded, size: 100, color: Colors.grey[300]),
        const SizedBox(height: 20),
        Text('لا توجد أخبار بعد', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text('كن أول من ينشر أخباراً عن قرية أبوديشيشة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, AppRoutes.newsDetail), icon: const Icon(Icons.add_rounded), label: const Text('نشر خبر جديد')),
      ]),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'ابحث في الأخبار...',
        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category, style: const TextStyle(fontWeight: FontWeight.w600)),
            selected: selected,
            onSelected: (_) => _selectCategory(category),
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            labelStyle: TextStyle(color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsItem item, int index) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(context, AppRoutes.newsView, arguments: item),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(children: [
                if (item.imageUrls.isNotEmpty)
                  PageView.builder(
                    itemCount: item.imageUrls.length,
                    itemBuilder: (context, i) => CachedNetworkImage(imageUrl: item.imageUrls[i], fit: BoxFit.cover, width: double.infinity),
                  )
                else
                  CachedNetworkImage(imageUrl: item.imageUrl, fit: BoxFit.cover, width: double.infinity),
                if (item.imageUrls.isNotEmpty)
                  Positioned(bottom: 8, left: 8, right: 8, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(item.imageUrls.length, (i) => Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.7)))))),
              ]),
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(item.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700))),
              const Spacer(),
              Text(item.date, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary)),
            ]),
            const SizedBox(height: 10),
            Text(item.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            if (item.authorName != null && item.authorName!.isNotEmpty) Text(item.authorName!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Text(item.subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.favorite_border, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('${item.likes}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary)),
              const SizedBox(width: 12),
              const Icon(Icons.visibility_rounded, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('${item.views} مشاهدة', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary)),
            ]),
          ])),
        ]),
      ),
    ).animate(delay: (index * 100).ms).fade(duration: 400.ms).slideY(begin: 0.2);
  }
}