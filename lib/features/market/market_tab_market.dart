part of 'market_tabs_screen.dart';

// ═══════════════════ Tab 1: السوق المطور بالمعايير العالمية ═══════════════════

enum _MarketQuickFilter {
  all('الكل', Icons.grid_view_rounded),
  offers('🔥 أقوى العروض', Icons.local_fire_department_rounded),
  trusted('⭐ بائعون موثوقون', Icons.verified_rounded),
  priceAsc('🏷️ الأقل سعراً', Icons.arrow_downward_rounded),
  priceDesc('💎 الأعلى سعراً', Icons.arrow_upward_rounded),
  topRated('★ الأعلى تقييماً', Icons.star_rounded);

  final String label;
  final IconData icon;
  const _MarketQuickFilter(this.label, this.icon);
}

class _MarketTab extends StatefulWidget {
  const _MarketTab();

  @override
  State<_MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<_MarketTab> {
  final MarketService _service = MarketService();
  final TextEditingController _search = TextEditingController();
  String _cat = 'الكل';
  _MarketQuickFilter _quickFilter = _MarketQuickFilter.all;

  // تدفّق واحد ثابت طوال عمر الشاشة: إعادة إنشائه مع كل ضغطة كتابة
  // كانت تعيد الاشتراك وتُعيد تركيب شجرة النتائج فيفقد مربع البحث تركيزه.
  late final Stream<List<MarketProduct>> _stream =
      _service.getProductsStream();
  late final Future<List<Map<String, dynamic>>?> _cacheFuture =
      CacheService.getProducts();

  // العرض ينتهي بوقت لا بتغيير في الوثيقة، فالستريم وحده لا يُعيد شيئًا عند
  // بلوغ `offerEndsAt`. نبض دقيقة واحدة يعيد الرسم فتختفي الشارة والخصم
  // تلقائيًا — بلا إعادة اشتراك وبلا قراءة جديدة.
  Timer? _offerTicker;

  static const _cats = ['الكل', ...kProductCategories];

  @override
  void initState() {
    super.initState();
    _offerTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _offerTicker?.cancel();
    _search.dispose();
    super.dispose();
  }

  List<MarketProduct> _filterAndSortProducts(List<MarketProduct> raw) {
    var products = raw.where((p) => p.isInStock).toList();

    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.sellerName.toLowerCase().contains(q))
          .toList();
    }

    if (_cat != 'الكل') {
      products = products.where((p) => p.category == _cat).toList();
    }

    switch (_quickFilter) {
      case _MarketQuickFilter.all:
        break;
      case _MarketQuickFilter.offers:
        products = products.where((p) => p.hasActiveOffer).toList();
        break;
      case _MarketQuickFilter.trusted:
        products = products.where((p) {
          final sType = RoleStyle.parseSellerType(p.sellerType);
          return sType != SellerType.regular;
        }).toList();
        break;
      case _MarketQuickFilter.priceAsc:
        products.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case _MarketQuickFilter.priceDesc:
        products.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case _MarketQuickFilter.topRated:
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OfflineStreamBuilder<List<MarketProduct>>(
      stream: _stream,
      onlineBuilder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _MarketSkeletonView();
        }
        final raw = snapshot.data ?? [];
        return _buildMarketContent(theme, raw);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: _cacheFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const _MarketSkeletonView();
          final raw = (snapshot.data ?? [])
              .map((j) => MarketProduct.fromJson(j, 'cache'))
              .toList();
          return _buildMarketContent(theme, raw);
        },
      ),
    );
  }

  Widget _buildMarketContent(ThemeData theme, List<MarketProduct> rawProducts) {
    final featuredDeals = rawProducts
        .where((p) => p.isInStock && (p.hasActiveOffer || p.isFeatured))
        .take(6)
        .toList();

    final filteredProducts = _filterAndSortProducts(rawProducts);

    final showHeroCarousel = _search.text.isEmpty &&
        _cat == 'الكل' &&
        _quickFilter == _MarketQuickFilter.all &&
        featuredDeals.isNotEmpty;

    return CustomScrollView(
      slivers: [
        // 1. شريط البحث العصري بنمط المتاجر العالمية
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج، سلعة، أو بائع في القرية...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'مسح البحث',
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),

        // 2. سلايدر البانر الترويجي الفاخر (Hero Deals Carousel)
        if (showHeroCarousel)
          SliverToBoxAdapter(
            child: _FeaturedDealsCarousel(products: featuredDeals),
          ),

        // 3. شريط الفلاتر السريعة (عروض، موثوقين، فرز أسعار)
        SliverToBoxAdapter(
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _MarketQuickFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filter = _MarketQuickFilter.values[i];
                final isSelected = filter == _quickFilter;
                return InkWell(
                  onTap: () => setState(() => _quickFilter = filter),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter.icon,
                          size: 15,
                          color: isSelected ? Colors.white : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          filter.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // 4. شريط التصنيفات البصرية بالأيقونات العصرية
        SliverToBoxAdapter(
          child: SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _cats[i];
                final isSelected = cat == _cat;
                final icon = getProductCategoryIcon(cat);
                return InkWell(
                  onTap: () => setState(() => _cat = cat),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 5. شريط عدد المنتجات والتصفية
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Row(
              children: [
                Text(
                  _cat == 'الكل' ? 'جميع المنتجات' : _cat,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filteredProducts.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                if (_cat != 'الكل' || _quickFilter != _MarketQuickFilter.all || _search.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _search.clear();
                      setState(() {
                        _cat = 'الكل';
                        _quickFilter = _MarketQuickFilter.all;
                      });
                    },
                    child: Text(
                      'إعادة تعيين الفلاتر',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 6. شبكة المنتجات
        if (filteredProducts.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _TabEmpty(
              icon: Icons.store_rounded,
              message: 'لا توجد منتجات مطابقة لخيارات البحث الحالية',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.58,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ModernProductCard(product: filteredProducts[i]),
                childCount: filteredProducts.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _FeaturedDealsCarousel extends StatefulWidget {
  const _FeaturedDealsCarousel({required this.products});
  final List<MarketProduct> products;

  @override
  State<_FeaturedDealsCarousel> createState() => _FeaturedDealsCarouselState();
}

class _FeaturedDealsCarouselState extends State<_FeaturedDealsCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    if (widget.products.length > 1) {
      _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_currentIndex + 1) % widget.products.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.products.length;
    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) {
              final p = widget.products[i];
              final img = p.imageUrls.isNotEmpty ? p.imageUrls.first : p.imageUrl;
              final isOffer = p.hasActiveOffer;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.marketProductDetail,
                      arguments: p,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // الصورة الخلفية
                        if (img.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primaryContainer,
                                ],
                              ),
                            ),
                          ),

                        // تدرج التعتيم الفاخر
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.5),
                                Colors.black.withValues(alpha: 0.88),
                              ],
                            ),
                          ),
                        ),

                        // الشارة العلوية
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isOffer
                                    ? [const Color(0xFFD32F2F), const Color(0xFFF57C00)]
                                    : [const Color(0xFFD4AF37), const Color(0xFFB8860B)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOffer ? Icons.local_fire_department_rounded : Icons.star_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOffer
                                      ? 'خصم ${p.discountPercent.round()}%'
                                      : 'منتج مميز',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // المحتوى السفلي
                        Positioned(
                          bottom: 12,
                          left: 14,
                          right: 14,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.category,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          '${p.effectivePrice.toStringAsFixed(0)} ج.م',
                                          style: const TextStyle(
                                            color: Color(0xFFFFD54F),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        if (isOffer) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '${p.price.toStringAsFixed(0)} ج.م',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              decoration: TextDecoration.lineThrough,
                                              decorationColor: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'عرض',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (index) {
              final isCurrent = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                width: isCurrent ? 18 : 6,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

typedef _MiniProductCard = _ModernProductCard;

class _ModernProductCard extends StatelessWidget {
  const _ModernProductCard({required this.product});
  final MarketProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = product.effectivePrice;
    final accent = RoleStyle.sellerNameColor(
        RoleStyle.parseSellerType(product.sellerType));
    final isOffer = product.hasActiveOffer;
    final imgUrl = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : product.imageUrl;

    return Card(
      elevation: accent != null ? 2 : 0.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          width: accent != null ? 1.6 : 1,
          color: accent?.withValues(alpha: 0.75) ??
              theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.marketProductDetail,
          arguments: product,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج مع الشارات وزر المفضلة
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _net(imgUrl, theme),

                  // شارة الخصم أو المنتج المميز
                  if (isOffer)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '-${product.discountPercent.round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    )
                  else if (product.isFeatured)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8860B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⭐ مميز',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                  // زر المفضلة السريع
                  Positioned(
                    top: 5,
                    left: 5,
                    child: _QuickFavoriteButton(productId: product.id),
                  ),
                ],
              ),
            ),

            // تفاصيل المنتج
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // التصنيف
                  Row(
                    children: [
                      Icon(
                        getProductCategoryIcon(product.category),
                        size: 11,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (product.rating > 0) ...[
                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB300)),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  // اسم المنتج
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // السعر والخصم
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${price.toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      if (isOffer) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${product.price.toStringAsFixed(0)} ج.م',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 10.5,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  // اسم البائع ورتبته
                  RoleNameText(
                    name: product.sellerName,
                    role: 'seller',
                    sellerType: product.sellerType,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                    iconSize: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (product.hashCode % 15 * 20).ms).fadeIn(duration: 250.ms);
  }
}

class _QuickFavoriteButton extends StatefulWidget {
  const _QuickFavoriteButton({required this.productId});
  final String productId;

  @override
  State<_QuickFavoriteButton> createState() => _QuickFavoriteButtonState();
}

class _QuickFavoriteButtonState extends State<_QuickFavoriteButton> {
  bool _isLiked = false;
  final ProductInteractionService _interactionService = ProductInteractionService();
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _sub = _interactionService
          .hasUserLikedStream(productId: widget.productId, userId: uid)
          .listen((liked) {
        if (mounted) setState(() => _isLiked = liked);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول لحفظ المنتجات في المفضلة'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLiked = !_isLiked);
    try {
      await _interactionService.toggleLike(
        productId: widget.productId,
        userId: user.uid,
      );
    } catch (_) {
      if (mounted) setState(() => _isLiked = !_isLiked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 15,
            color: _isLiked ? const Color(0xFFE53935) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MarketSkeletonView extends StatelessWidget {
  const _MarketSkeletonView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, __) => Container(
                width: 90,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.58,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1200.ms);
  }
}


