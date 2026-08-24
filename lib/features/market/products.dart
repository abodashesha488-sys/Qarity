import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

class MarketProductsScreen extends StatefulWidget {
  const MarketProductsScreen({super.key});

  @override
  State<MarketProductsScreen> createState() => _MarketProductsScreenState();
}

class _MarketProductsScreenState extends State<MarketProductsScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  List<MarketProduct> _allProducts = [];
  List<MarketProduct> _filteredProducts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  final MarketService _marketService = MarketService();
  final UserService _userService = UserService();
  String? _currentUserId;

  static const List<String> _categories = [
    'الكل',
    'مواد غذائية',
    'خضار وفواكه',
    'لحوم وطيور وأسماك',
    'ألبان وخير البلد',
    'حلويات ومخبوزات',
    'مشروبات ومقاهي',
    'أدوات منزلية ومنظفات',
    'إلكترونيات وهواتف',
    'أثاث ومفروشات',
    'ملابس وأحذية',
    'مستلزمات زراعة وأعلاف',
    'سوق المستعمل',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initCurrentUser();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    setState(() => _currentUserId = user?.uid);
    await _loadProducts();
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final products = await _marketService.getProductsList(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = _getFirebaseErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'ليس لديك صلاحية الوصول';
      case 'unavailable':
        return 'الخدمة غير متاحة حالياً';
      case 'deadline-exceeded':
        return 'انتهت مهلة الاتصال';
      default:
        return 'خطأ في تحميل المنتجات';
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _applyCategoryFilter();
    } else {
      final filtered = _allProducts.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
      setState(() => _filteredProducts = filtered);
    }
  }

  void _applyCategoryFilter() {
    final filtered = _selectedCategory == 'الكل'
        ? _allProducts
        : _allProducts.where((item) => item.category == _selectedCategory).toList();
    setState(() => _filteredProducts = filtered);
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _applyCategoryFilter();
    });
  }

  Future<void> _refreshProducts() async {
    await _loadProducts(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final offerProducts = _allProducts.where((p) => p.isOnOffer).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('سوق القرية'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      floatingActionButton: _currentUserId != null
          ? FloatingActionButton.extended(
              heroTag: 'market-add',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.marketAdd),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة منتج'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        strokeWidth: 3,
        child: _buildBody(theme, offerProducts),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, List<MarketProduct> offerProducts) {
    if (_isLoading) return _buildLoadingState(theme);
    if (_hasError) return _buildErrorState(theme);
    if (_allProducts.isEmpty) return _buildEmptyState(theme);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSearchField(theme),
              const SizedBox(height: 16),
              _buildCategoryChips(theme),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (offerProducts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🔥 عروض اليوم',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${offerProducts.length} عرض',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 12)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: offerProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) => _buildOfferCard(theme, offerProducts[index], index),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              top: 24,
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المنتجات (${_filteredProducts.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_selectedCategory != 'الكل')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedCategory,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.symmetric(vertical: 12)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = _filteredProducts[index];
                return _buildProductCard(theme, product, index);
              },
              childCount: _filteredProducts.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج أو فئة...',
          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _applyCategoryFilter();
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
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: ChoiceChip(
              label: Text(category, style: const TextStyle(fontWeight: FontWeight.w600)),
              selected: selected,
              onSelected: (_) => _selectCategory(category),
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

  Widget _buildOfferCard(ThemeData theme, MarketProduct product, int index) {
    final price = product.effectivePrice;
    final hasOffer = product.isOnOffer && product.offerPrice != null;

    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.marketProductDetail,
            arguments: product,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image_rounded, size: 32, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'عرض',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${price.toStringAsFixed(0)} ج.م',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (hasOffer) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              product.price.toStringAsFixed(0),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 80).ms).fade(duration: 400.ms).slideY(begin: 0.15);
  }

  Widget _buildProductCard(ThemeData theme, MarketProduct product, int index) {
    final price = product.effectivePrice;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.marketProductDetail,
            arguments: product,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image_rounded, size: 32, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  if (product.isOnOffer)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'عرض',
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${price.toStringAsFixed(0)} ج.م',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
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
    ).animate(delay: (index * 50).ms).fade(duration: 400.ms).scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 80, height: 16, color: theme.colorScheme.surfaceContainerHighest),
                      const SizedBox(height: 8),
                      Container(width: double.infinity, height: 14, color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)),
                      const SizedBox(height: 8),
                      Container(width: 60, height: 16, color: theme.colorScheme.surfaceContainerHighest),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: (index * 80).ms).fade(duration: 400.ms);
      },
    );
  }

  Widget _buildErrorState(ThemeData theme) {
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
              'تعذر تحميل المنتجات',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refreshProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isSeller = _userService.currentUser != null && _allProducts.any((p) => p.sellerId == _userService.currentUser!.uid);

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
              child: Icon(Icons.store_rounded, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedCategory == 'الكل' ? 'لا توجد منتجات بعد' : 'لا توجد منتجات في هذا القسم',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isSeller ? 'أضف منتجاتك الأولى لتبدأ البيع' : 'كن أول من يضيف منتجات إلى السوق',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSeller) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.marketAdd),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة منتج'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
