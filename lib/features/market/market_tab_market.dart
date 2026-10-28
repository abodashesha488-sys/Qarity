part of 'market_tabs_screen.dart';

// ═══════════════════ Tab 1: السوق المطور بالمعايير العالمية ═══════════════════

enum _MarketQuickFilter {
  all('الافتراضي', Icons.sort_rounded),
  offers('🔥 العروض فقط', Icons.local_fire_department_rounded),
  trusted('⭐ بائعون موثوقون', Icons.verified_rounded),
  priceAsc('🏷️ الأقل سعراً', Icons.arrow_downward_rounded),
  priceDesc('💎 الأعلى سعراً', Icons.arrow_upward_rounded),
  topRated('★ الأعلى تقييماً', Icons.star_rounded);

  final String label;
  final IconData icon;
  const _MarketQuickFilter(this.label, this.icon);
}

class _MarketTab extends StatefulWidget {
  const _MarketTab({this.onSelectTab});
  final ValueChanged<int>? onSelectTab;

  @override
  State<_MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<_MarketTab> {
  final MarketService _service = MarketService();
  final TextEditingController _search = TextEditingController();
  String _cat = 'الكل';
  _MarketQuickFilter _quickFilter = _MarketQuickFilter.all;
  bool _isGridView = true;

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

  static const _cats = ['الكل', '🔥 العروض', ...kProductCategories];

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
      if (_cat == '🔥 العروض') {
        products = products.where((p) => p.hasActiveOffer).toList();
      } else {
        products = products.where((p) => p.category == _cat).toList();
      }
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

    final isDefaultBrowse = _search.text.isEmpty &&
        _cat == 'الكل' &&
        _quickFilter == _MarketQuickFilter.all;

    return CustomScrollView(
      slivers: [
        // 1. شريط البحث العصري بنمط المتاجر العالمية بحدود واضحة ومحددة
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
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
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
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.8,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2. سلايدر البانر الترويجي الفاخر أو بانر الترحيب التفاعلي
        if (isDefaultBrowse)
          SliverToBoxAdapter(
            child: featuredDeals.isNotEmpty
                ? _FeaturedDealsCarousel(products: featuredDeals)
                : _MarketWelcomeHeroBanner(
                    onExploreShops: widget.onSelectTab != null
                        ? () => widget.onSelectTab!(1)
                        : null,
                  ),
          ),

        // 3. شريط التصنيفات البصرية النظيف بالأيقونات
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
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
                  final isOfferCat = cat == '🔥 العروض';
                  final icon = isOfferCat
                      ? Icons.local_fire_department_rounded
                      : getProductCategoryIcon(cat);

                  final activeColor = isOfferCat
                      ? const Color(0xFFE53935)
                      : theme.colorScheme.primary;
                  final activeContainer = isOfferCat
                      ? const Color(0xFFFFEBEE)
                      : theme.colorScheme.primaryContainer;
                  final activeText = isOfferCat
                      ? const Color(0xFFC62828)
                      : theme.colorScheme.onPrimaryContainer;

                  return InkWell(
                    onTap: () => setState(() => _cat = cat),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeContainer
                            : (isOfferCat
                                ? const Color(0xFFFFF3E0).withValues(alpha: 0.6)
                                : theme.colorScheme.surface),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? activeColor
                              : (isOfferCat
                                  ? const Color(0xFFFF9800).withValues(alpha: 0.5)
                                  : theme.colorScheme.outline.withValues(alpha: 0.35)),
                          width: isSelected ? 1.6 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.2),
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
                                ? activeText
                                : (isOfferCat
                                    ? const Color(0xFFE53935)
                                    : theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? activeText
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
        ),

        // 4. سطر الترتيب والتصفية وعدد المنتجات ونمط العرض
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Text(
                  _cat == 'الكل' ? 'جميع المنتجات' : _cat,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () {
                        _search.clear();
                        setState(() {
                          _cat = 'الكل';
                          _quickFilter = _MarketQuickFilter.all;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, size: 12, color: theme.colorScheme.error),
                            const SizedBox(width: 2),
                            Text(
                              'إعادة ضبط',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // زر الترتيب والتصفية المدمج
                PopupMenuButton<_MarketQuickFilter>(
                  initialValue: _quickFilter,
                  onSelected: (filter) => setState(() => _quickFilter = filter),
                  tooltip: 'ترتيب وتصفية المنتجات',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: _quickFilter != _MarketQuickFilter.all
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _quickFilter != _MarketQuickFilter.all
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _quickFilter.icon,
                          size: 14,
                          color: _quickFilter != _MarketQuickFilter.all
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _quickFilter == _MarketQuickFilter.all ? 'الترتيب' : _quickFilter.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _quickFilter != _MarketQuickFilter.all
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: _quickFilter != _MarketQuickFilter.all
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => _MarketQuickFilter.values.map((f) {
                    final isCur = f == _quickFilter;
                    return PopupMenuItem<_MarketQuickFilter>(
                      value: f,
                      child: Row(
                        children: [
                          Icon(f.icon, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            f.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isCur ? FontWeight.w800 : FontWeight.w500,
                              color: isCur ? theme.colorScheme.primary : null,
                            ),
                          ),
                          if (isCur) ...[
                            const Spacer(),
                            Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.primary),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 8),
                // نمط العرض (شبكة / قائمة)
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ViewModeButton(
                        icon: Icons.grid_view_rounded,
                        isSelected: _isGridView,
                        onTap: () => setState(() => _isGridView = true),
                        tooltip: 'عرض الشبكة',
                      ),
                      _ViewModeButton(
                        icon: Icons.view_agenda_rounded,
                        isSelected: !_isGridView,
                        onTap: () => setState(() => _isGridView = false),
                        tooltip: 'عرض القائمة',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 7. المنتجات (شبكة أو قائمة حسب اختيار المستخدم)
        if (filteredProducts.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _TabEmpty(
              icon: Icons.store_rounded,
              message: 'لا توجد منتجات مطابقة لخيارات البحث الحالية',
            ),
          )
        else if (_isGridView)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.54,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ModernProductCard(product: filteredProducts[i]),
                childCount: filteredProducts.length,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList.separated(
              itemCount: filteredProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _ModernProductListCard(product: filteredProducts[i]),
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
                    child: _QuickFavoriteButton(product: product),
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

                  // اسم البائع والتواصل السريع
                  Row(
                    children: [
                      Expanded(
                        child: RoleNameText(
                          name: product.sellerName,
                          role: 'seller',
                          sellerType: product.sellerType,
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                          iconSize: 11,
                        ),
                      ),
                      if (product.sellerPhone.trim().isNotEmpty) ...[
                        _QuickContactActions(
                          phone: product.sellerPhone,
                          productName: product.name,
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
    ).animate(delay: (product.hashCode % 15 * 20).ms).fadeIn(duration: 250.ms);
  }
}

class _QuickFavoriteButton extends StatelessWidget {
  const _QuickFavoriteButton({required this.product});
  final MarketProduct product;

  Future<void> _toggle(BuildContext context) async {
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

    final item = FavoriteItem(
      id: 'product_${product.id}',
      targetId: product.id,
      collection: 'products',
      title: product.name,
      subtitle: '${product.effectivePrice.toStringAsFixed(0)} ج.م • ${product.sellerName}',
      imageUrl: product.imageUrl.isNotEmpty
          ? product.imageUrl
          : (product.imageUrls.isNotEmpty ? product.imageUrls.first : ''),
      route: AppRoutes.marketProductDetail,
      arguments: {'id': product.id},
      createdAt: DateTime.now(),
    );

    await FavoritesService.instance.toggleFavorite(item);
    try {
      await ProductInteractionService().toggleLike(
        productId: product.id,
        userId: user.uid,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<FavoriteItem>>(
      valueListenable: FavoritesService.instance.favoritesNotifier,
      builder: (context, _, __) {
        final isFav = FavoritesService.instance.isFavorite(product.id, 'products');
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggle(context),
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isFav
                      ? const Color(0xFFE53935).withValues(alpha: 0.45)
                      : Colors.black12,
                  width: 1.1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 17,
                color: isFav ? const Color(0xFFE53935) : const Color(0xFF333333),
              ),
            ),
          ),
        );
      },
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

// ═══════════════════ بطاقة المنتج بنمط القائمة العريضة ═══════════════════

class _ModernProductListCard extends StatelessWidget {
  const _ModernProductListCard({required this.product});
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
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          width: accent != null ? 1.5 : 1,
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
        child: SizedBox(
          height: 124,
          child: Row(
            children: [
              // صورة المنتج مع الشارات
              SizedBox(
                width: 120,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _net(imgUrl, theme),
                    if (isOffer)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${product.discountPercent.round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                    else if (product.isFeatured)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB8860B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '⭐ مميز',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: _QuickFavoriteButton(product: product),
                    ),
                  ],
                ),
              ),

              // تفاصيل المنتج
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // التصنيف والتقييم
                      Row(
                        children: [
                          Icon(
                            getProductCategoryIcon(product.category),
                            size: 12,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (product.rating > 0) ...[
                            const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB300)),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ],
                      ),

                      // اسم المنتج
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),

                      // اسم البائع
                      RoleNameText(
                        name: product.sellerName,
                        role: 'seller',
                        sellerType: product.sellerType,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                        iconSize: 12,
                      ),

                      // السعر وأزرار التواصل
                      Row(
                        children: [
                          Text(
                            '${price.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                            ),
                          ),
                          if (isOffer) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${product.price.toStringAsFixed(0)} ج.م',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (product.sellerPhone.trim().isNotEmpty) ...[
                            _QuickContactActions(
                              phone: product.sellerPhone,
                              productName: product.name,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (product.hashCode % 15 * 20).ms).fadeIn(duration: 250.ms);
  }
}

// ═══════════════════ أزرار التواصل المباشر ═══════════════════

class _QuickContactActions extends StatelessWidget {
  const _QuickContactActions({required this.phone, required this.productName});
  final String phone;
  final String productName;

  @override
  Widget build(BuildContext context) {
    final cleanPhone = phone.trim();
    if (cleanPhone.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // زر واتساب مباشر
        Tooltip(
          message: 'تواصل عبر واتساب',
          child: InkWell(
            onTap: () {
              final waUrl = egyptianWhatsAppUrl(cleanPhone);
              if (waUrl != null) {
                final msg = Uri.encodeComponent(
                    'السلام عليكم، بخصوص معروض: $productName على تطبيق قرية أبوديشيشة');
                launchWhatsAppUrl('$waUrl?text=$msg');
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble_rounded, size: 13, color: Color(0xFF25D366)),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // زر اتصال هاتفي مباشر
        Tooltip(
          message: 'اتصال هاتفي',
          child: InkWell(
            onTap: () => launchPhoneCall(cleanPhone),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.phone_rounded,
                  size: 13, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════ زر تبديل طريقة العرض (شبكة / قائمة) ═══════════════════

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════ بانر الترحيب التفاعلي بالسوق ═══════════════════

class _MarketWelcomeHeroBanner extends StatelessWidget {
  const _MarketWelcomeHeroBanner({this.onExploreShops});
  final VoidCallback? onExploreShops;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.84),
              theme.colorScheme.secondary.withValues(alpha: 0.88),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'سوق أبوديشيشة الرقمي',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'تسوق واطلب مباشرة من أهالي قريتك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'منتجات طازجة، محلات وورش، وسلع محلية بكل أمان وثقة وبلا وسيط.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.marketAdd),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                        label: const Text('أضف منتجك مجاناً',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      if (onExploreShops != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onExploreShops,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: const Text('المحلات 🏪',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


