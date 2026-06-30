import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';
import '../../widgets/common_appbar_actions.dart';

class MarketProductsScreen extends StatefulWidget {
  const MarketProductsScreen({super.key});

  @override
  State<MarketProductsScreen> createState() => _MarketProductsScreenState();
}

class _MarketProductsScreenState extends State<MarketProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  List<MarketProduct> _allProducts = [];
  List<MarketProduct> _filteredProducts = [];
  bool _isLoading = true;
  bool _hasError = false;
  final MarketService _marketService = MarketService();

  static const List<String> _categories = ['الكل', 'مواد غذائية', 'خضار وفواكه', 'لحوم وطيور وأسماك', 'ألبان وخير البلد', 'حلويات ومخبوزات', 'مشروبات ومقاهي', 'أدوات منزلية ومنظفات', 'إلكترونيات وهواتف', 'أثاث ومفروشات', 'ملابس وأحذية', 'مستلزمات زراعة وأعلاف', 'سوق المستعمل'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_updateSearchResults);
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final products = await _marketService.getProductsList();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
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
    final offerProducts = _allProducts.where((p) => p.isOnOffer).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('سوق القرية'), actions: CommonAppBarActions.actions(context)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'market-add',
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.marketAdd),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
                ? _buildErrorState()
                : _allProducts.isEmpty
                    ? _buildEmptyState()
                    : _buildProductList(offerProducts),
      ),
    );
  }

  Widget _buildProductList(List<MarketProduct> offerProducts) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSearchField(),
              const SizedBox(height: 16),
              _buildCategoryChips(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (offerProducts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('عروض اليوم', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${offerProducts.length} عرض', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: offerProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _buildOfferCard(offerProducts[index], index),
                  ),
                ),
              ],
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المنتجات (${_displayedProducts.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (_selectedCategory != 'الكل')
                  Text(_selectedCategory, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.75),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = _displayedProducts[index];
              return _buildProductCard(product).animate(delay: (index * 50).ms).fade(duration: 300.ms);
            },
            childCount: _displayedProducts.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج أو فئة...',
          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
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

  Widget _buildOfferCard(MarketProduct product, int index) {
    return SizedBox(
      width: 130,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, AppRoutes.marketProductDetail, arguments: product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      width: double.infinity,
                      height: 90,
                      child: CachedNetworkImage(imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : product.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                      child: const Text('عرض', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${product.offerPrice?.toStringAsFixed(0) ?? product.price.toStringAsFixed(0)} ج.م', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Expanded(child: Text('${product.price.toStringAsFixed(0)} ج.م', style: TextStyle(color: Colors.grey[500], fontSize: 10, decoration: TextDecoration.lineThrough))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).fade(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildProductCard(MarketProduct product) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, AppRoutes.marketProductDetail, arguments: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: CachedNetworkImage(imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : product.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                if (product.isOnOffer)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(10)),
                      child: const Text('عرض', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)), child: Text(product.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary))),
                  const SizedBox(height: 6),
                  Text(product.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${product.price.toStringAsFixed(0)} ج.م', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fade(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: double.infinity, height: 180, color: Colors.grey[300], child: const Center(child: CircularProgressIndicator())),
              const SizedBox(height: 12),
              Row(children: [
                Container(width: 80, height: 20, color: Colors.grey[300]),
                const Spacer(),
                Container(width: 60, height: 16, color: Colors.grey[200]),
              ]),
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
        Text('خطأ في تحميل المنتجات', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextButton(onPressed: _refreshProducts, child: const Text('حاول مرة أخرى')),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('لا توجد منتجات بعد', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('كن أول من يضيف منتجات إلى السوق', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.marketAdd), child: const Text('إضافة منتج')),
        ],
      ),
    );
  }
}