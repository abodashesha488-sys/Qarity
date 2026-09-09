part of 'market_tabs_screen.dart';

// ═══════════════════ Tab 2: المحلات ═══════════════════
class _ShopsTab extends StatelessWidget {
  const _ShopsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ShopService();
    return OfflineStreamBuilder<List<Shop>>(
      stream: service.getShopsStream(),
      onlineBuilder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final shops = snapshot.data ?? [];
        if (shops.isEmpty) {
          return const _TabEmpty(
            icon: Icons.storefront_rounded,
            message: 'لا توجد محلات بعد',
          );
        }
        return _buildShopsList(theme, shops);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getShops(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final shops = (snapshot.data ?? []).map((j) => Shop.fromJson(j, 'cache')).toList();
          if (shops.isEmpty) {
            return const _TabEmpty(icon: Icons.storefront_rounded, message: 'لا توجد محلات مخزنة');
          }
          return _buildShopsList(theme, shops);
        },
      ),
    );
  }

  Widget _buildShopsList(ThemeData theme, List<Shop> shops) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: shops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
            final s = shops[i];
            final accent = RoleStyle.contentAccent(s.ownerRole, s.ownerSellerType);
            return Card(
              elevation: accent != null ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                    width: accent != null ? 1.5 : 1,
                    color: accent?.withValues(alpha: 0.7) ??
                        theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => _ShopDetailScreen(shop: s))),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                            width: 60,
                            height: 60,
                            child: _net(s.imageUrl, theme)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RoleNameText(
                                name: s.name,
                                role: s.ownerRole,
                                sellerType: s.ownerSellerType,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 15),
                                iconSize: 14),
                            const SizedBox(height: 3),
                            Text(s.category,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700)),
                            if (s.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(s.description,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left_rounded,
                          color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
             ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.06);
          },
    );
  }
}

class _ShopDetailScreen extends StatelessWidget {
  const _ShopDetailScreen({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == shop.ownerUid;
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
        centerTitle: true,
        actions: [
          if (shop.whatsapp.isNotEmpty)
            IconButton(
              tooltip: 'تواصل واتساب',
              icon: const Icon(Icons.chat_rounded),
              onPressed: () async {
                final uri = Uri.parse(
                    'https://wa.me/2${shop.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<List<MarketProduct>>(
        stream: MarketService().getSellerProductsStream(shop.ownerUid),
        builder: (context, snapshot) {
          final products = (snapshot.data ?? [])
              .where((p) => p.isApproved && p.isInStock)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                    height: 150,
                    child: _net(shop.coverUrl ?? shop.imageUrl, theme)),
              ),
              const SizedBox(height: 16),
              Text(shop.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('${shop.category} • يديره ${shop.ownerName}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              if (shop.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(shop.description, style: const TextStyle(height: 1.5)),
              ],
              if (shop.imageUrls.length > 1) ...[
                const SizedBox(height: 12),
                const Text('صور المحل',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: shop.imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                          width: 100,
                          height: 80,
                          child: _net(shop.imageUrls[i], theme)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('منتجات المحل (${products.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 12),
              if (products.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد منتجات في هذا المحل بعد'),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62),
                  itemCount: products.length,
                  itemBuilder: (context, i) =>
                      _MiniProductCard(product: products[i]),
                ),
            ],
          );
        },
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              heroTag: 'shop_add',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.marketAdd),
              icon: const Icon(Icons.add_rounded),
              label: const Text('أضف منتجاً لمحلي'),
            )
          : null,
    );
  }
}

