import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';

class MarketSellersScreen extends StatefulWidget {
  const MarketSellersScreen({super.key});

  @override
  State<MarketSellersScreen> createState() => _MarketSellersScreenState();
}

class _MarketSellersScreenState extends State<MarketSellersScreen>
    with AutomaticKeepAliveClientMixin {
  final MarketService _marketService = MarketService();
  List<SellerProfile> _sellers = [];
  List<SellerProfile> _filteredSellers = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'الأعلى تقييماً';

  static const List<String> _sortOptions = [
    'الأعلى تقييماً',
    'الأكثر منتجات',
    'الأحدث',
    'الأكثر مبيعاً'
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSellers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSellers({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Get all approved products, then group by seller
      final products =
          await _marketService.getProductsList(forceRefresh: forceRefresh);
      final sellerMap = <String, SellerProfile>{};

      for (final product in products) {
        final sellerId = product.sellerId;
        if (sellerId == null || sellerId.isEmpty) continue;

        if (sellerMap.containsKey(sellerId)) {
          final existing = sellerMap[sellerId]!;
          sellerMap[sellerId] = SellerProfile(
            id: existing.id,
            userId: existing.userId,
            name: existing.name,
            bio: existing.bio,
            imageUrl: existing.imageUrl,
            phone: existing.phone,
            address: existing.address,
            rating: existing.rating,
            reviewCount: existing.reviewCount,
            totalProducts: existing.totalProducts + 1,
            totalSales: existing.totalSales,
            isVerified: existing.isVerified,
            categories: {...existing.categories, product.category}.toList(),
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
          );
        } else {
          // Try to get existing profile or create new one
          final profile = await _marketService.getSellerProfile(sellerId);
          if (profile != null) {
            sellerMap[sellerId] = SellerProfile(
              id: profile.id,
              userId: profile.userId,
              name: profile.name,
              bio: profile.bio,
              imageUrl: profile.imageUrl,
              phone: profile.phone,
              address: profile.address,
              rating: profile.rating,
              reviewCount: profile.reviewCount,
              totalProducts: profile.totalProducts + 1,
              totalSales: profile.totalSales,
              isVerified: profile.isVerified,
              categories: {...profile.categories, product.category}.toList(),
              createdAt: profile.createdAt,
              updatedAt: DateTime.now(),
            );
          } else {
            // Create basic profile from product data
            sellerMap[sellerId] = SellerProfile(
              id: sellerId,
              userId: sellerId,
              name: product.sellerName,
              phone: product.sellerPhone,
              totalProducts: 1,
              categories: [product.category],
              createdAt: DateTime.now(),
            );
          }
        }
      }

      var sellers = sellerMap.values.toList();

      // Apply sorting
      sellers = _applySort(sellers);

      if (!mounted) return;
      setState(() {
        _sellers = sellers;
        _filteredSellers = sellers;
        _isLoading = false;
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

  List<SellerProfile> _applySort(List<SellerProfile> sellers) {
    switch (_sortBy) {
      case 'الأعلى تقييماً':
        sellers.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'الأكثر منتجات':
        sellers.sort((a, b) => b.totalProducts.compareTo(a.totalProducts));
        break;
      case 'الأحدث':
        sellers.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        break;
      case 'الأكثر مبيعاً':
        sellers.sort((a, b) => b.totalSales.compareTo(a.totalSales));
        break;
    }
    return sellers;
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredSellers = _sellers);
    } else {
      final filtered = _sellers.where((seller) {
        return seller.name.toLowerCase().contains(query) ||
            seller.categories.any((cat) => cat.toLowerCase().contains(query)) ||
            (seller.address?.toLowerCase().contains(query) ?? false);
      }).toList();
      setState(() => _filteredSellers = filtered);
    }
  }

  void _selectSort(String sort) {
    setState(() {
      _sortBy = sort;
      _filteredSellers = _applySort(List.from(_filteredSellers));
    });
  }

  Future<void> _refreshSellers() async {
    await _loadSellers(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('محلات القرية'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          PopupMenuButton<String>(
            onSelected: _selectSort,
            itemBuilder: (context) => _sortOptions
                .map((option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          if (_sortBy == option)
                            Icon(Icons.check_rounded,
                                size: 18, color: theme.colorScheme.primary),
                          if (_sortBy == option) const SizedBox(width: 8),
                          Text(option),
                        ],
                      ),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort_rounded,
                      color: theme.colorScheme.onSurface, size: 20),
                  const SizedBox(width: 4),
                  Text(_sortBy,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSellers,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) return _buildLoadingState(theme);
    if (_hasError) return _buildErrorState(theme);
    if (_sellers.isEmpty) return _buildEmptyState(theme);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن محل أو فئة...',
              hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6)),
              prefixIcon:
                  Icon(Icons.search_rounded, color: theme.colorScheme.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
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
                borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ),
        // Sellers count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'محلات (${_filteredSellers.length})',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Sellers grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: _filteredSellers.length,
            itemBuilder: (context, index) =>
                _buildSellerCard(theme, _filteredSellers[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerCard(ThemeData theme, SellerProfile seller, int index) {
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
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.marketSellerProfile,
            arguments: seller.id,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image/avatar section
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    seller.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: seller.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) =>
                                _buildPlaceholder(theme),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholder(theme),
                          )
                        : _buildPlaceholder(theme),
                    if (seller.isVerified)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Icon(Icons.verified_rounded,
                              size: 14, color: theme.colorScheme.onPrimary),
                        ),
                      ),
                  ],
                ),
              ),
              // Info section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (seller.address != null && seller.address!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              seller.address!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (seller.rating > 0) ...[
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            seller.rating.toStringAsFixed(1),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${seller.reviewCount})',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${seller.totalProducts} منتج',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (seller.categories.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: seller.categories
                            .take(2)
                            .map((cat) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    cat,
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(fontSize: 10),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (index * 50).ms)
        .fade(duration: 400.ms)
        .scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.storefront_rounded,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
      ).animate(delay: (index * 80).ms).fade(duration: 400.ms),
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
              child: Icon(Icons.wifi_off_rounded,
                  size: 48, color: theme.colorScheme.error),
            ),
            const SizedBox(height: 24),
            Text('تعذر تحميل المحلات',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
                onPressed: _refreshSellers,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle),
              child: Icon(Icons.storefront_outlined,
                  size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('لا توجد محلات بعد',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('ستظهر المحلات هنا عند إضافة البائعين لمنتجاتهم',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
