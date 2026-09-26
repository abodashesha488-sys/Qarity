import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';
import '../../services/review_service.dart';
import '../../widgets/qurity_app_bar.dart';

class SellerDetailScreen extends StatefulWidget {
  const SellerDetailScreen({super.key});

  @override
  State<SellerDetailScreen> createState() => _SellerDetailScreenState();
}

class _SellerDetailScreenState extends State<SellerDetailScreen> {
  final ReviewService _reviewService = ReviewService();
  final MarketService _marketService = MarketService();
  double _avgRating = 0.0;
  int _reviewCount = 0;
  List<MarketProduct> _products = [];
  bool _productsLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSellerData());
  }

  Map<String, String> _readArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is Map<String, String> ? args : {'name': 'بائع محلي', 'phone': '', 'sellerId': ''};
  }

  Future<void> _loadSellerData() async {
    final seller = _readArgs();
    final sellerKey = seller['phone']?.isNotEmpty == true ? seller['phone']! : seller['name']!;
    final sellerId = seller['sellerId'] ?? '';

    final avg = await _reviewService.getSellerAverageRating(sellerKey);
    final count = await _reviewService.getReviewCount(sellerKey);

    List<MarketProduct> products = [];
    if (sellerId.isNotEmpty) {
      products = await _marketService.getProductsBySeller(sellerId);
    }

    if (!mounted) return;
    setState(() {
      _avgRating = avg;
      _reviewCount = count;
      _products = products;
      _productsLoading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() => _productsLoading = true);
    await _loadSellerData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seller = _readArgs();
    final name = seller['name'] ?? 'بائع محلي';
    final phone = seller['phone'] ?? '';
    final sellerId = seller['sellerId'] ?? '';

    return Scaffold(
      appBar: QurityAppBar(title: name),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: theme.colorScheme.primary,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                          child: Text(
                            name.isNotEmpty ? name[0] : 'ب',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.phone_rounded, size: 14, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(phone, style: theme.textTheme.bodyMedium)),
                                ],
                              ),
                              if (_reviewCount > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_avgRating',
                                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '($_reviewCount مراجعة)',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.photo_library_rounded,
                            label: 'المعرض',
                            color: theme.colorScheme.primary,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.marketSellerGallery,
                              arguments: {'name': name, 'sellerId': sellerId},
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.reviews_rounded,
                            label: 'المراجعات',
                            color: theme.colorScheme.secondary,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.marketSellerReviews,
                              arguments: {'name': name, 'phone': phone},
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildContactButton(
                      context,
                      icon: Icons.call_rounded,
                      label: 'اتصال',
                      color: const Color(0xFF6F4E37),
                      onTap: () async {
                        final uri = Uri(scheme: 'tel', path: phone);
                        try {
                          await launchUrl(uri);
                        } catch (_) {}
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildContactButton(
                      context,
                      icon: Icons.message_rounded,
                      label: 'رسالة',
                      color: Colors.blue,
                      onTap: () async {
                        final uri = Uri(scheme: 'sms', path: phone);
                        try {
                          await launchUrl(uri);
                        } catch (_) {}
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildContactButton(
                context,
                icon: Icons.copy_rounded,
                label: 'نسخ الرقم',
                color: theme.colorScheme.primaryContainer,
                textColor: theme.colorScheme.primary,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم نسخ الرقم'),
                      backgroundColor: theme.colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('منتجات البائع', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (!_productsLoading) Text('${_products.length}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            _buildProductsSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(ThemeData theme) {
    if (_productsLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.storefront_outlined, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text('لا توجد منتجات للبائع بعد', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) => _buildProductCard(theme, _products[index]),
    );
  }

  Widget _buildProductCard(ThemeData theme, MarketProduct product) {
    final price = product.effectivePrice;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
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
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.broken_image_rounded, size: 32, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                if (product.hasActiveOffer)
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
                        style: TextStyle(color: theme.colorScheme.onError, fontSize: 10, fontWeight: FontWeight.w800),
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
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${price.toStringAsFixed(0)} ج.م',
                    style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(BuildContext context, {required IconData icon, required String label, required Color color, Color? textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor ?? color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor ?? color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
