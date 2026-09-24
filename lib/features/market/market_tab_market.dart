part of 'market_tabs_screen.dart';

// ═══════════════════ Tab 1: السوق ═══════════════════
class _MarketTab extends StatefulWidget {
  const _MarketTab();

  @override
  State<_MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<_MarketTab> {
  final MarketService _service = MarketService();
  final TextEditingController _search = TextEditingController();
  String _cat = 'الكل';
  // تدفّق واحد ثابت طوال عمر الشاشة: إعادة إنشائه مع كل ضغطة كتابة
  // كانت تعيد الاشتراك وتُعيد تركيب شجرة النتائج فيفقد مربع البحث تركيزه.
  late final Stream<List<MarketProduct>> _stream =
      _service.getProductsStream();
  late final Future<List<Map<String, dynamic>>?> _cacheFuture =
      CacheService.getProducts();

  static const _cats = ['الكل', ...kProductCategories];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OfflineStreamBuilder<List<MarketProduct>>(
      stream: _stream,
      onlineBuilder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var products = (snapshot.data ?? []).where((p) => p.isInStock).toList();
        final q = _search.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          products = products
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q))
              .toList();
        }
        if (_cat != 'الكل') {
          products = products.where((p) => p.category == _cat).toList();
        }
        return _buildMarketContent(theme, products);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: _cacheFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var products = (snapshot.data ?? []).map((j) => MarketProduct.fromJson(j, 'cache')).where((p) => p.isInStock).toList();
          final q = _search.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            products = products.where((p) => p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q)).toList();
          }
          if (_cat != 'الكل') {
            products = products.where((p) => p.category == _cat).toList();
          }
          return _buildMarketContent(theme, products);
        },
      ),
    );
  }

  Widget _buildMarketContent(ThemeData theme, List<MarketProduct> products) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث في السوق...',
                hintStyle: TextStyle(
                    color:
                        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.search_rounded,
                    color: theme.colorScheme.primary),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text(_cats[i]),
                selected: _cats[i] == _cat,
                onSelected: (_) => setState(() => _cat = _cats[i]),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                    color: _cats[i] == _cat
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        if (products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _TabEmpty(
                icon: Icons.store_rounded,
                message: 'لا توجد منتجات حالياً'),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _MiniProductCard(product: products[i]),
                childCount: products.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniProductCard extends StatelessWidget {
  const _MiniProductCard({required this.product});
  final MarketProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = product.effectivePrice;
    final accent = RoleStyle.sellerNameColor(
        RoleStyle.parseSellerType(product.sellerType));
    return Card(
      elevation: accent != null ? 2 : 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            width: accent != null ? 1.6 : 1,
            color: accent?.withValues(alpha: 0.7) ??
                theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.marketProductDetail,
            arguments: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _net(
                      product.imageUrls.isNotEmpty
                          ? product.imageUrls.first
                          : product.imageUrl,
                      theme),
                  if (product.isOnOffer)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('-${product.discountPercent.round()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category,
                      style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text('${price.toStringAsFixed(0)} ج.م',
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  RoleNameText(
                    name: product.sellerName,
                    role: 'seller',
                    sellerType: product.sellerType,
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700),
                    iconSize: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (product.hashCode % 20 * 15).ms).fadeIn(duration: 300.ms);
  }
}

