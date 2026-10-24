import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/relative_time.dart';
import '../../services/favorites_service.dart';
import '../../widgets/qurity_app_bar.dart';

/// شاشة المفضلة المركزية في الملف الشخصي
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'label': 'الكل', 'icon': '⭐'},
    {'id': 'products', 'label': 'المنتجات', 'icon': '🛒'},
    {'id': 'news', 'label': 'الأخبار', 'icon': '📰'},
    {'id': 'technicians', 'label': 'فنيون وحرفيون', 'icon': '🛠️'},
    {'id': 'teachers', 'label': 'المعلمون', 'icon': '🎓'},
    {'id': 'lawyers', 'label': 'المحامون', 'icon': '⚖️'},
    {'id': 'crops', 'label': 'المحاصيل', 'icon': '🌾'},
    {'id': 'shops', 'label': 'المحلات', 'icon': '🏪'},
    {'id': 'ads', 'label': 'الإعلانات', 'icon': '📢'},
  ];

  @override
  void initState() {
    super.initState();
    FavoritesService.instance.init();
  }

  void _navigateToItem(FavoriteItem item) {
    if (item.route.isEmpty) return;
    try {
      Navigator.of(context).pushNamed(
        item.route,
        arguments: item.arguments.isNotEmpty ? item.arguments : item.targetId,
      );
    } catch (_) {
      // إذا كان المسار يتطلب استدعاءً مخصصاً
    }
  }

  Future<void> _confirmRemove(FavoriteItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة من المفضلة'),
        content: Text('هل تريد إزالة «${item.title}» من قائمتك المفضلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FavoritesService.instance
          .removeFavorite(item.targetId, item.collection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const QurityAppBar(
        title: 'قائمتي المفضلة',
      ),
      body: ValueListenableBuilder<List<FavoriteItem>>(
        valueListenable: FavoritesService.instance.favoritesNotifier,
        builder: (context, allItems, _) {
          final filtered = _selectedCategory == 'all'
              ? allItems
              : allItems.where((it) => it.collection == _selectedCategory).toList();

          return Column(
            children: [
              // شريط تصنيفات المفضلة
              Container(
                height: 48,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final catId = cat['id']!;
                    final isSelected = _selectedCategory == catId;
                    final count = catId == 'all'
                        ? allItems.length
                        : allItems.where((it) => it.collection == catId).length;

                    return FilterChip(
                      selected: isSelected,
                      label: Text('${cat['icon']} ${cat['label']} ($count)'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                      onSelected: (_) {
                        setState(() => _selectedCategory = catId);
                      },
                    );
                  },
                ),
              ),

              // محتوى المفضلة أو الحالة الفارغة
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildFavoriteCard(context, theme, item);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'لا توجد عناصر في المفضلة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك حفظ الأخبار، منتجات السوق، الفنيين، المعلمين، المحامين، والمحاصيل بالضغط على أيقونة المفضلة للرجوع إليها في أي وقت.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(
      BuildContext context, ThemeData theme, FavoriteItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToItem(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // صورة أو أيقونة العنصر
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (_, __, ___) => _buildFallbackIcon(item),
                        )
                      : _buildFallbackIcon(item),
                ),
              ),
              const SizedBox(width: 12),
              // التفاصيل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.collectionIcon} ${item.collectionLabel}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          relativeTimeLabelAr(item.createdAt),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // زر الحذف من المفضلة
              IconButton(
                icon: const Icon(Icons.favorite_rounded,
                    color: Color(0xFFE53935), size: 22),
                tooltip: 'إزالة من المفضلة',
                onPressed: () => _confirmRemove(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(FavoriteItem item) {
    return ColoredBox(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Text(
          item.collectionIcon,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}
