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

  static const List<String> _categories = ['الكل', 'مواد غذائية', 'خضار وفواكه', 'لحوم وطيور وأسماك', 'ألبان وخير البلد', 'حلويات ومخبوزات', 'مشروبات ومقاهي', 'أدوات منزلية ومنظفات', 'إلكترونيات وهواتف', 'أثاث ومفروشات', 'ملابس وأحذية', 'مستلزمات زراعة وأعلاف', 'سوق المستعمل'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initCurrentUser();
    _searchController.addListener(_updateSearchResults);
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

  @override
  void dispose() {
    _searchController.removeListener(_updateSearchResults);
    _searchController.dispose();
    super.dispose();
  }

  List<MarketProduct> get _displayedProducts {
    final categoryFiltered = _selectedCategory == 'الكل'
        ? _filteredProducts
        : _filteredProducts.where((item) => item.category == _selectedCategory).toList();
    return categoryFiltered;
  }

  void _updateSearchResults() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _applyCategoryFilter());
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
    _filteredProducts = _selectedCategory == 'الكل' ? _allProducts : _allProducts.where((item) => item.category == _selectedCategory).toList();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _applyCategoryFilter();
    });
  }

  Future<void> _refreshProducts() async {
    await _loadProducts();
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
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (offerProducts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [theme.colorScheme.error, theme.colorScheme.errorContainer]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.error.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'عروض اليوم',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 400.ms).slideX(begin: -0.2),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${offerProducts.length}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
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
                  'المنتجات (${_displayedProducts.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                if (_selectedCategory != 'الكل')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [theme.colorScheme.primaryContainer, theme.colorScheme.primaryContainer.withValues(alpha: 0.6)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedCategory,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
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
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = _displayedProducts[index];
                return _buildProductCard(theme, product, index);
              },
              childCount: _displayedProducts.length,
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج أو فئة...',
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.clear_rounded, color: theme.colorScheme.primary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _applyCategoryFilter();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  )
                : null,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 1.5)),
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
          return GestureDetector(
            onTap: () => _selectCategory(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: selected ? LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer]) : null,
                color: selected ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                category,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(ThemeData theme, MarketProduct product, int index) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.pushNamed(context, AppRoutes.marketProductDetail, arguments: product),
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
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                        ),
                      ),
                      errorWidget: (context, url, error) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image_rounded, size: 32, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${product.effectivePrice.toStringAsFixed(0)} ج.م',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
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

  Widget _buildProductCard(ThemeData theme, MarketProduct product, int index) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(context, AppRoutes.marketProductDetail, arguments: product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      if (product.isOnOffer)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [theme.colorScheme.error, theme.colorScheme.errorContainer]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('عرض', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.category,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                product.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Text(
                    '${product.effectivePrice.toStringAsFixed(0)} ج.م',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.favorite_border_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 40).ms).fade(duration: 400.ms).scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 3),
            const SizedBox(height: 20),
            Text('جاري تحميل المنتجات...', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 20),
            Text('تعذر تحميل المنتجات', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'تأكد من الاتصال بالإنترنت', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _loadProducts, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
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
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text('لا توجد منتجات حالياً', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('كن أول من يضيف منتجاً في السوق', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            if (isSeller) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, AppRoutes.marketAdd), icon: const Icon(Icons.add_rounded), label: const Text('إضافة منتج')),
            ],
          ],
        ),
      ),
    );
  }
}