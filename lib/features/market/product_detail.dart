import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';
import '../../services/product_interaction_service.dart';
import '../../widgets/common_appbar_actions.dart';
import 'cart.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  MarketProduct? _product;
  bool _loading = true;
  final TextEditingController _commentController = TextEditingController();
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final ProductInteractionService _interactionService = ProductInteractionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MarketService _marketService = MarketService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
  }

  Future<void> _loadProduct() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is MarketProduct) {
      setState(() {
        _product = args;
        _loading = false;
      });
      return;
    }
    if (args is String) {
      try {
        final product = await _marketService.getProductById(args);
        if (!mounted) return;
        setState(() {
          _product = product;
          _loading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في تحميل المنتج: $e')));
      }
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
    }
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المنتج')),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('المنتج غير موجود أو غير متوفر', style: theme.textTheme.titleMedium),
        ])),
      );
    }

    final product = _product!;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildImageCarousel(theme, product),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(product.name, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2))),
                  child: Text(product.category, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withValues(alpha: 0.25))),
                  child: Text('${product.effectivePrice.toStringAsFixed(0)} ج.م', style: theme.textTheme.titleLarge?.copyWith(color: Colors.green, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('4.5', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(' (120 مشتريات)', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ]),
              const SizedBox(height: 16),
              _buildInfoRow(theme, Icons.store_rounded, product.sellerName),
              const SizedBox(height: 8),
              _buildInfoRow(theme, Icons.phone_rounded, product.sellerPhone, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('الوصف', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(product.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
              const SizedBox(height: 20),
              _buildQuantityCard(theme),
              const SizedBox(height: 20),
              Row(children: [_buildLikeButton(theme), const SizedBox(width: 12), _buildShareButton(theme), const SizedBox(width: 12), _buildReviewsBadge(theme)]),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('التعليقات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), Text('${product.reviewCount} تعليق', style: theme.textTheme.bodySmall)]),
              const SizedBox(height: 12),
              _buildCommentsSection(theme, product),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String text, {Color? color}) {
    return Row(children: [
      Icon(icon, size: 18, color: color ?? theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
    ]);
  }

  Widget _buildImageCarousel(ThemeData theme, MarketProduct product) {
    final hasImages = product.imageUrls.isNotEmpty || product.imageUrl.isNotEmpty;
    if (!hasImages) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: product.imageUrls.isNotEmpty ? product.imageUrls.length : 1,
            itemBuilder: (context, index) {
              final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls[index] : product.imageUrl;
              return CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, width: double.infinity);
            },
            onPageChanged: (index) => setState(() => _currentPage = index),
          ),
        ),
        if ((product.imageUrls.isNotEmpty ? product.imageUrls.length : 1) > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                product.imageUrls.isNotEmpty ? product.imageUrls.length : 1,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الكمية', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(onPressed: () { if (_quantity > 1) setState(() => _quantity--); }, icon: const Icon(Icons.remove_rounded), color: theme.colorScheme.primary),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('$_quantity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                ),
                IconButton(onPressed: () { setState(() => _quantity++); }, icon: const Icon(Icons.add_rounded), color: theme.colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton(ThemeData theme) {
    return StreamBuilder<bool>(
      stream: _auth.currentUser != null ? _interactionService.hasUserLikedStream(productId: _product!.id, userId: _auth.currentUser!.uid) : null,
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;
        return Expanded(
          child: InkWell(
            onTap: _auth.currentUser != null ? _toggleLike : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isLiked ? Colors.red.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isLiked ? Colors.red.withValues(alpha: 0.3) : theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 6),
                  StreamBuilder<int>(stream: _interactionService.getLikeCountStream(_product!.id), builder: (context, countSnapshot) {
                    final count = countSnapshot.data ?? _product!.likes;
                    return Text('$count', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800));
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareButton(ThemeData theme) {
    return Expanded(
      child: InkWell(
        onTap: _shareProduct,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 6),
              Text('مشاركة', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
        const SizedBox(width: 6),
        Text('${_product!.reviewCount} تقييم', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildCommentsSection(ThemeData theme, MarketProduct product) {
    return SizedBox(
      height: 220,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _interactionService.getCommentsStream(product.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          final comments = snapshot.data ?? [];
          if (comments.isEmpty) return Center(child: Text('لا توجد تعليقات بعد', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)));
          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5), radius: 18, child: Icon(Icons.person, size: 16, color: theme.colorScheme.primary)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(comment['userName'] as String? ?? 'زائر', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(comment['text'] as String? ?? '', style: theme.textTheme.bodySmall),
                      ]),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))]),
      child: Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.marketCart),
          icon: Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.primary),
          label: Text('السلة (${Cart.instance.distinctItemCount})', style: TextStyle(color: theme.colorScheme.primary)),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('أضف إلى السلة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  void _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _interactionService.toggleLike(productId: _product!.id, userId: user.uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الإعجاب: $e')));
      }
    }
  }

  void _shareProduct() async {
    final text = Uri.encodeComponent('${_product!.name}\n${_product!.description}\n${_product!.effectivePrice.toStringAsFixed(0)} ج.م');
    await launchUrl(Uri.parse('https://t.me/share/url?url=$text'));
  }

  void _addToCart() {
    if (_product == null) return;
    try {
      final existingIndex = Cart.instance.items.indexWhere((c) => c.product.id == _product!.id);
      if (existingIndex >= 0) {
        Cart.instance.updateQuantity(_product!, Cart.instance.items[existingIndex].quantity + _quantity);
      } else {
        Cart.instance.add(_product!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingIndex >= 0 ? 'تم تحديث الكمية في السلة' : 'تمت الإضافة إلى السلة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إضافة للسلة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}