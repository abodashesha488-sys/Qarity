import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/role_style.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';
import '../../services/product_interaction_service.dart';
import '../../services/share_service.dart';
import '../../widgets/common_appbar_actions.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  MarketProduct? _product;
  bool _loading = true;
  final TextEditingController _commentController = TextEditingController();
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final ProductInteractionService _interactionService =
      ProductInteractionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MarketService _marketService = MarketService();

  // New features
  List<ProductReview> _reviews = [];
  List<MarketProduct> _similarProducts = [];
  bool _loadingReviews = false;
  bool _loadingSimilar = false;
  bool _isSubscribedToStockAlert = false;

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
      await _loadAdditionalData();
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
        await _loadAdditionalData();
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في تحميل المنتج: $e')));
      }
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAdditionalData() async {
    if (_product == null) return;
    await Future.wait([
      _loadReviews(),
      _loadSimilarProducts(),
      _checkStockAlertSubscription(),
    ]);
  }

  Future<void> _loadReviews() async {
    if (_product == null) return;
    setState(() => _loadingReviews = true);
    try {
      final reviews = await _marketService.getProductReviews(_product!.id);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _loadingReviews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _loadSimilarProducts() async {
    if (_product == null) return;
    setState(() => _loadingSimilar = true);
    try {
      final similar = await _marketService.findSimilarProducts(
          _product!.name, _product!.category,
          excludeSellerId: _product!.sellerId);
      if (!mounted) return;
      setState(() {
        _similarProducts = similar;
        _loadingSimilar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSimilar = false);
    }
  }

  Future<void> _checkStockAlertSubscription() async {
    if (_product == null || _auth.currentUser == null) return;
    try {
      final subscribed = await _marketService.isSubscribedToStockAlert(
          _auth.currentUser!.uid, _product!.id);
      if (!mounted) return;
      setState(() => _isSubscribedToStockAlert = subscribed);
    } catch (_) {}
  }

  Future<void> _refreshProduct() async {
    if (_product == null) {
      await _loadProduct();
      return;
    }
    try {
      final fresh = await _marketService.getProductById(_product!.id);
      if (!mounted) return;
      setState(() => _product = fresh);
      await _loadAdditionalData();
    } catch (_) {
      // keep showing the cached product on refresh failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
          body: Center(
              child:
                  CircularProgressIndicator(color: theme.colorScheme.primary)));
    }
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المنتج')),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline_rounded,
              size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('المنتج غير موجود أو غير متوفر',
              style: theme.textTheme.titleMedium),
        ])),
      );
    }

    final product = _product!;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProduct,
        color: theme.colorScheme.primary,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            _buildImageCarousel(theme, product),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(product.name,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w900))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.2))),
                            child: Text(product.category,
                                style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.25))),
                        child: Text(
                            '${product.effectivePrice.toStringAsFixed(0)} ج.م',
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w900)),
                      ),
                      if (product.isOnOffer && product.discountPercent > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: theme.colorScheme.error
                                      .withValues(alpha: 0.25))),
                          child: Text('خصم ${product.discountPercent.toInt()}%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(product.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(' (${product.reviewCount} تقييم)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _openSeller(),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              child: Icon(Icons.store_rounded,
                                  size: 20, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RoleNameText(
                                      name: product.sellerName,
                                      role: 'seller',
                                      sellerType: product.sellerType,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  Text(product.sellerPhone,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color:
                                                  theme.colorScheme.primary)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_left_rounded,
                                color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('الوصف',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(product.description,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                    const SizedBox(height: 20),
                    Row(children: [
                      _buildLikeButton(theme),
                      const SizedBox(width: 12),
                      _buildShareButton(theme),
                      const SizedBox(width: 12),
                      _buildReviewsBadge(theme)
                    ]),
                    const SizedBox(height: 20),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('التعليقات',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text('${_reviews.length} تعليق',
                              style: theme.textTheme.bodySmall)
                        ]),
                    const SizedBox(height: 12),
                    _buildReviewsSection(theme),
                    if (_similarProducts.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('منتجات مشابهة (مقارنة الأسعار)',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            TextButton(
                                onPressed: () {}, child: const Text('عرض الكل'))
                          ]),
                      const SizedBox(height: 12),
                      _buildSimilarProductsSection(theme),
                    ],
                    if (!_product!.isInStock) ...[
                      const SizedBox(height: 24),
                      _buildStockAlertButton(theme),
                    ],
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  void _openSeller() {
    if (_product == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.marketSellerDetail,
      arguments: {
        'name': _product!.sellerName,
        'phone': _product!.sellerPhone,
        'sellerId': _product!.sellerId ?? '',
      },
    );
  }

  Widget _buildImageCarousel(ThemeData theme, MarketProduct product) {
    final hasImages =
        product.imageUrls.isNotEmpty || product.imageUrl.isNotEmpty;
    if (!hasImages) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount:
                product.imageUrls.isNotEmpty ? product.imageUrls.length : 1,
            itemBuilder: (context, index) {
              final imageUrl = product.imageUrls.isNotEmpty
                  ? product.imageUrls[index]
                  : product.imageUrl;
              return CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity);
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
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLikeButton(ThemeData theme) {
    return StreamBuilder<bool>(
      stream: _auth.currentUser != null
          ? _interactionService.hasUserLikedStream(
              productId: _product!.id, userId: _auth.currentUser!.uid)
          : null,
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;
        return Expanded(
          child: InkWell(
            onTap: _auth.currentUser != null ? _toggleLike : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isLiked
                    ? Colors.red.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isLiked
                        ? Colors.red.withValues(alpha: 0.3)
                        : theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: Colors.red,
                      size: 20),
                  const SizedBox(width: 6),
                  StreamBuilder<int>(
                      stream:
                          _interactionService.getLikeCountStream(_product!.id),
                      builder: (context, countSnapshot) {
                        final count = countSnapshot.data ?? _product!.likes;
                        return Text('$count',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w800));
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
      child: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'share':
              _shareProduct();
              break;
            case 'whatsapp':
              _shareToWhatsApp();
              break;
            case 'facebook':
              _shareToFacebook();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
              value: 'share',
              child: ListTile(
                  leading: Icon(Icons.share_rounded),
                  title: Text('مشاركة عامة'),
                  dense: true)),
          const PopupMenuItem(
              value: 'whatsapp',
              child: ListTile(
                  leading: Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.green),
                  title: Text('واتساب'),
                  dense: true)),
          const PopupMenuItem(
              value: 'facebook',
              child: ListTile(
                  leading: Icon(Icons.facebook_rounded, color: Colors.blue),
                  title: Text('فيسبوك'),
                  dense: true)),
        ],
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share_rounded,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 6),
                Text('مشاركة',
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down_rounded,
                    color: theme.colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _productShareText =>
      'تحقق من هذا المنتج: ${_product!.name}\n${_product!.description}\n'
      'السعر: ${_product!.effectivePrice.toStringAsFixed(0)} ج.م\n'
      'بائع: ${_product!.sellerName}\n\n'
      '${ShareService.appSignature}';

  void _shareProduct() async {
    await SharePlus.instance.share(
        ShareParams(text: _productShareText, subject: _product!.name));
  }

  void _shareToWhatsApp() async {
    final url =
        'https://wa.me/?text=${Uri.encodeComponent(_productShareText)}';
    final Uri launchUri = Uri.parse(url);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareToFacebook() async {
    final url =
        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://abudshisha.web.app/market/${_product!.id}')}';
    final Uri launchUri = Uri.parse(url);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildReviewsBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
        const SizedBox(width: 6),
        Text('${_product!.reviewCount} تقييم',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }

  void _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _interactionService.toggleLike(
          productId: _product!.id, userId: user.uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في الإعجاب: $e')));
      }
    }
  }

  Widget _buildReviewsSection(ThemeData theme) {
    if (_loadingReviews) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_reviews.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('لا توجد تقييمات بعد',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant))));
    }
    return Column(
      children: [
        // Rating summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(_product!.rating.toStringAsFixed(1),
                      style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                              i < _product!.rating.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 20))),
                  const SizedBox(height: 4),
                  Text('${_reviews.length} تقييم',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((stars) {
                    final count =
                        _reviews.where((r) => r.rating.round() == stars).length;
                    final percentage =
                        _reviews.isEmpty ? 0.0 : count / _reviews.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$stars', style: theme.textTheme.labelSmall),
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                              child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  color: Colors.amber,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 8),
                          Text('$count', style: theme.textTheme.labelSmall),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Reviews list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final review = _reviews[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: review.userPhotoUrl != null
                            ? CachedNetworkImageProvider(review.userPhotoUrl!)
                            : null,
                        child: review.userPhotoUrl == null
                            ? Icon(Icons.person,
                                size: 16, color: theme.colorScheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(review.userName,
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            Text(_formatDate(review.createdAt),
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (review.isVerifiedPurchase)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.verified_rounded,
                                size: 10, color: theme.colorScheme.primary),
                            const SizedBox(width: 2),
                            Text('شراء موثق',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600))
                          ]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                              i < review.rating.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 16))),
                  const SizedBox(height: 8),
                  Text(review.comment,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                  if (review.images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: review.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                              imageUrl: review.images[i],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 30) return '${diff.inDays ~/ 30} شهر';
    if (diff.inDays > 0) return '${diff.inDays} يوم';
    if (diff.inHours > 0) return '${diff.inHours} ساعة';
    return '${diff.inMinutes} دقيقة';
  }

  Widget _buildSimilarProductsSection(ThemeData theme) {
    if (_loadingSimilar) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_similarProducts.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _similarProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = _similarProducts[index];
          final savings = _product!.effectivePrice - product.effectivePrice;
          return Container(
            width: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : product.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2))),
                    errorWidget: (context, url, error) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image_rounded,
                            size: 32,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      RoleNameText(
                          name: product.sellerName,
                          role: 'seller',
                          sellerType: product.sellerType,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          iconSize: 12),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                              '${product.effectivePrice.toStringAsFixed(0)} ج.م',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800)),
                          const Spacer(),
                          if (savings > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('توفير ${savings.toStringAsFixed(0)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockAlertButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Text('المنتج غير متوفر حالياً',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.error)),
            ],
          ),
          const SizedBox(height: 8),
          Text('سنخبرك فور توفره مرة أخرى',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isSubscribedToStockAlert ? null : _subscribeToStockAlert,
                  icon: Icon(
                      _isSubscribedToStockAlert
                          ? Icons.check_rounded
                          : Icons.notifications_none_rounded,
                      color: theme.colorScheme.error),
                  label: Text(
                      _isSubscribedToStockAlert
                          ? 'مُشترك'
                          : 'أعلمني عند التوفر',
                      style: TextStyle(color: theme.colorScheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_isSubscribedToStockAlert) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _unsubscribeFromStockAlert,
                    icon: Icon(Icons.notifications_off_rounded,
                        color: theme.colorScheme.onSurfaceVariant),
                    label: Text('إلغاء الاشتراك',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                    style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _subscribeToStockAlert() async {
    if (_product == null || _auth.currentUser == null) return;
    try {
      await _marketService.subscribeToStockAlert(
          _auth.currentUser!.uid, _product!.id);
      if (!mounted) return;
      setState(() => _isSubscribedToStockAlert = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم الاشتراك في التنبيهات'),
          backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _unsubscribeFromStockAlert() async {
    if (_product == null || _auth.currentUser == null) return;
    try {
      await _marketService.unsubscribeFromStockAlert(
          _auth.currentUser!.uid, _product!.id);
      if (!mounted) return;
      setState(() => _isSubscribedToStockAlert = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم إلغاء الاشتراك'), backgroundColor: Colors.orange));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
