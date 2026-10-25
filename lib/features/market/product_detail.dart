import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/comment_style.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/launch_link.dart';
import '../../core/utils/role_style.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/favorites_service.dart';
import '../../services/market_service.dart';
import '../../services/moderation_service.dart';
import '../../services/product_interaction_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/facebook_comment_tile.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/full_fit_image.dart';
import '../../widgets/image_gallery_wrap.dart';
import '../../widgets/owner_actions.dart';
import '../../widgets/qurity_app_bar.dart';
import 'add_product.dart';

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
  bool _isAdmin = false;
  String? _replyToCommentId;
  String? _replyToAuthorName;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
  }

  Future<void> _checkAdminStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final user = await UserService().getUser(uid);
      if (mounted && user != null) {
        setState(() => _isAdmin = user.isAdmin);
      }
    } catch (_) {}
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
        appBar: const QurityAppBar(title: 'المنتج'),
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
      appBar: QurityAppBar(
        title: product.name,
        actions: [
          FavoriteButton(
            item: FavoriteItem(
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
            ),
          ),
          IconButton(
            tooltip: 'مشاركة',
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareProduct,
          ),
          ModerationService.instance.buildMoreOptionsButton(
            context: context,
            targetType: 'product',
            targetId: product.id,
            authorId: product.sellerId ?? '',
            authorName: product.sellerName,
            contentSnippet: product.name,
            onBlocked: () => Navigator.pop(context),
          ),
        ],
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
                      if (product.hasActiveOffer) ...[
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
                      ] else if (product.isExpiredOffer) ...[
                        // السعر رجع لأصله: يُقال للسبب، لا صمتًا.
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text('انتهى العرض',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700)),
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
                            Icon(Icons.keyboard_arrow_down_rounded,
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
                    OwnerActions(
                      keyTag: 'product-detail',
                      ownerId: product.sellerId ?? '',
                      currentUserId: _currentUid(),
                      itemName: product.name,
                      editLabel: 'تعديل المنتج',
                      deleteLabel: 'حذف المنتج',
                      onEdit: () => _openEdit(product),
                      onDelete: () => _delete(product),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'التعليقات والتقييمات',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_reviews.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _openAddReviewSheet,
                          icon: const Icon(Icons.rate_review_rounded, size: 16),
                          label: const Text('أضف تقييماً'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: theme.colorScheme.primary,
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildReviewsSection(theme),
                    const SizedBox(height: 24),
                    _buildCommentsStreamSection(theme),
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

  /// معرّف الجلسة الحالي — فارغ بلا تسجيل دخول، فتُحجب أزرار المالك.
  String _currentUid() {
    try {
      return _auth.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  /// تعديل البائع لمنتجه: نفس صفحة الإضافة بـ`existing`، والنجاح يُغلق التفاصيل
  /// لأن المنتج عاد للمراجعة فلم يعد المعروض هو المنشور.
  Future<void> _openEdit(MarketProduct product) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => AddMarketProductScreen(existing: product)));
    if (saved == true && mounted) Navigator.pop(context);
  }

  Future<bool> _delete(MarketProduct product) async {
    try {
      await _marketService.deleteProduct(product.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
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
    final urls = product.imageUrls.isNotEmpty
        ? product.imageUrls
        : (product.imageUrl.isEmpty ? const <String>[] : [product.imageUrl]);
    if (urls.isEmpty) return const SizedBox.shrink();
    final current = urls[_currentPage.clamp(0, urls.length - 1)];

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
      // النسب تُقاس عبر محرك العرض المشترك، فيأخذ الشريط ارتفاع الصورة نفسها
      // وترسم `BoxFit.contain` — لا قصّ لمنتج صُوَّره بمقاسات مختلفة.
      FullFitImage.measure(current,
          onResult: (_) {
            if (mounted) setState(() {});
          });
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            height: FullFitImage.heightFor(current, width),
            child: PageView.builder(
              controller: _pageController,
              itemCount: urls.length,
              itemBuilder: (context, index) => FullFitImage(
                imageUrl: urls[index],
                width: width,
                radius: 0,
                fallback: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.black26, size: 40)),
              ),
              onPageChanged: (index) => setState(() => _currentPage = index),
            ),
          ),
          if (urls.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  urls.length,
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
    });
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
                      // قلب الإعجاب حبر لا أرضية: في الداكن يُرفع سطوع الأحمر
                      // الهادئ (2.5 خامًا) ليُقرأ، والتظليلات الباقية زخرفية.
                      color: AppColors.inkOn(AppColors.error, theme.brightness),
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
          PopupMenuItem(
              value: 'whatsapp',
              child: ListTile(
                  leading: Icon(Icons.chat_bubble_outline_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  title: const Text('واتساب'),
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
    await ShareService.shareContent(
      title: '🛒 ${_product!.name}',
      body: _product!.description,
      imageUrls: [
        if (_product!.imageUrl.isNotEmpty) _product!.imageUrl,
        ..._product!.imageUrls,
      ],
      details: {
        'السعر': '${_product!.effectivePrice.toStringAsFixed(0)} ج.م',
        'البائع': _product!.sellerName,
        'الهاتف': _product!.sellerPhone,
        'التصنيف': _product!.category,
        'الحالة': _product!.isInStock ? 'متوفر' : 'غير متوفر',
      },
    );
  }

  /// بلا بوّابة `canLaunchUrl`: الفحص القبلي كان يرجع false على أندرويد 11+ للحزم
  /// غير المصرّح برؤيتها، فالزر كان يصمت بلا كلمة. الفشل الحقيقي هو ما يُبلَّغ.
  void _shareToWhatsApp() async {
    final url =
        'https://wa.me/?text=${Uri.encodeComponent(_productShareText)}';
    final error = await launchContactUrl(url,
        unavailable: 'واتساب غير متاح على هذا الجهاز.',
        failed: 'تعذّر فتح المراسلة — تحقّق من الاتصال ثم أعد المحاولة.');
    if (error != null) AppHelpers.showToast(error, isError: true);
  }

  void _shareToFacebook() async {
    final url =
        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://abudshisha.web.app/market/${_product!.id}')}';
    final error = await launchContactUrl(url,
        unavailable: 'فيسبوك غير متاح على هذا الجهاز.',
        failed: 'تعذّر فتح المشاركة — تحقّق من الاتصال ثم أعد المحاولة.');
    if (error != null) AppHelpers.showToast(error, isError: true);
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

  void _openAddReviewSheet() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً لتتمكن من إضافة تقييم أو تعليق'),
        ),
      );
      return;
    }

    if (_product == null) return;

    // فحص ما إذا كان المستخدم قد قيّم هذا المنتج مسبقاً
    final alreadyReviewed = _reviews.any((r) => r.userId == user.uid);
    if (alreadyReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لقد قمت بتقييم هذا المنتج مسبقاً'),
        ),
      );
      return;
    }

    double selectedRating = 5.0;
    final textController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(context);
          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'تقييم وتعليق على المنتج',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // نجوم التقييم
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          iconSize: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: () {
                            setModalState(() => selectedRating = star.toDouble());
                          },
                          icon: Icon(
                            star <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFB300),
                          ),
                        );
                      }),
                    ),
                  ),
                  Center(
                    child: Text(
                      _ratingLabel(selectedRating),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'اكتب تجربتك أو رأيك في هذا المنتج بكل أمانة...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final commentText = textController.text.trim();
                            if (commentText.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('يرجى كتابة نص التعليق')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              String userName = user.displayName ?? '';
                              String? userPhoto = user.photoURL;
                              try {
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .get();
                                final data = userDoc.data();
                                if (data != null) {
                                  final n = (data['name'] as String? ?? '').trim();
                                  if (n.isNotEmpty) userName = n;
                                  final p = (data['photoUrl'] as String? ?? '').trim();
                                  if (p.isNotEmpty) userPhoto = p;
                                }
                              } catch (_) {}

                              if (userName.isEmpty) userName = 'مستخدم';

                              final review = ProductReview(
                                id: '',
                                productId: _product!.id,
                                userId: user.uid,
                                userName: userName,
                                userPhotoUrl: userPhoto,
                                rating: selectedRating,
                                comment: commentText,
                                createdAt: DateTime.now(),
                              );

                              await _marketService.addReview(review);
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadReviews();

                              final updatedProduct =
                                  await _marketService.getProductById(_product!.id);
                              if (mounted) {
                                setState(() {
                                  _product = updatedProduct;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('شكراً لك! تم نشر تقييمك بنجاح'),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('تعذر حفظ التقييم: $e')),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'نشر التقييم والتعليق',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating >= 5.0) return 'ممتاز جداً 🌟🌟🌟🌟🌟';
    if (rating >= 4.0) return 'جيد جداً ⭐⭐⭐⭐';
    if (rating >= 3.0) return 'جيد ⭐⭐⭐';
    if (rating >= 2.0) return 'مقبول ⭐⭐';
    return 'يحتاج إلى تحسين ⭐';
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
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 38,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'لا توجد تعليقات أو تقييمات بعد',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _openAddReviewSheet,
                icon: const Icon(Icons.star_outline_rounded, size: 16),
                label: const Text('كن أول من يقيّم هذا المنتج'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
                        radius: CommentStyle.avatarRadius,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: review.userPhotoUrl != null
                            ? CachedNetworkImageProvider(review.userPhotoUrl!)
                            : null,
                        child: review.userPhotoUrl == null
                            ? Icon(Icons.person,
                                size: 20, color: theme.colorScheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(review.userName,
                                style: CommentStyle.author(context)),
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
                  Text(review.comment, style: CommentStyle.body(context)),
                  if (review.images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ImageGalleryWrap(urls: review.images, tileWidth: 72, radius: 8, spacing: 8),
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

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول للتعليق على المنتج')),
      );
      return;
    }
    try {
      await _interactionService.addComment(
        productId: _product!.id,
        userName: user.displayName ?? 'مستخدم',
        text: text,
        parentId: _replyToCommentId,
        replyToUser: _replyToAuthorName,
      );
      if (!mounted) return;
      _commentController.clear();
      if (_replyToCommentId != null) {
        setState(() {
          _replyToCommentId = null;
          _replyToAuthorName = null;
        });
      }
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال تعليقك بنجاح')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال التعليق: $e')),
        );
      }
    }
  }

  Widget _buildCommentsStreamSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'استفسارات وتعليقات المشترين',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_replyToCommentId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'الرد على ${_replyToAuthorName ?? "تعليق"}',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _replyToCommentId = null;
                      _replyToAuthorName = null;
                    }),
                    child: const Icon(Icons.close_rounded, size: 16),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'اسأل البائع أو علّق على هذا المنتج...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: _submitComment,
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _interactionService.getCommentsStream(_product!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'لا توجد استفسارات بعد، كن أول من يسأل أو يعلق!',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final c = comments[index];
                  final commentId = c['id'] as String? ?? '';
                  final name = c['userName'] as String? ?? 'مستخدم';
                  final text = c['text'] as String? ?? '';
                  final photo = c['userPhotoUrl'] as String?;
                  final userId = c['userId'] as String? ?? '';
                  final ts = c['createdAt'];
                  DateTime? date;
                  if (ts is Timestamp) date = ts.toDate();
                  final up = c['updatedAt'];
                  DateTime? updatedDate;
                  if (up is Timestamp) updatedDate = up.toDate();
                  final likes = (c['likes'] as num?)?.toInt() ?? 0;
                  final likedBy = (c['likedBy'] as List?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      <String>[];
                  final parentId = c['parentId'] as String?;
                  final replyToUser = c['replyToUser'] as String?;

                  return FacebookCommentTile(
                    avatarRadius: CommentStyle.avatarRadius,
                    textStyle: CommentStyle.body(context),
                    commentId: commentId,
                    authorId: userId,
                    authorName: name,
                    authorPhotoUrl: photo ?? '',
                    text: text,
                    createdAt: date,
                    updatedAt: updatedDate,
                    likes: likes,
                    likedBy: likedBy,
                    parentId: parentId,
                    replyToUser: replyToUser,
                    currentUserId: _auth.currentUser?.uid ?? '',
                    isAdmin: _isAdmin,
                    onLike: () => _interactionService.toggleCommentLike(
                      productId: _product!.id,
                      commentId: commentId,
                      userId: _auth.currentUser?.uid ?? '',
                    ),
                    onReply: () {
                      setState(() {
                        _replyToCommentId = commentId;
                        _replyToAuthorName = name;
                      });
                    },
                    onEdit: (newText) => _interactionService.editComment(
                      productId: _product!.id,
                      commentId: commentId,
                      newText: newText,
                    ),
                    onDelete: () => _interactionService.deleteComment(
                      productId: _product!.id,
                      commentId: commentId,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
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
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('توفير ${savings.toStringAsFixed(0)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
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
      // أرضيات الشريط هنا ألوان ثابتة في السمتين بينما حبره الافتراضي يُقرأ من
      // `onInverseSurface` وهو في الداكن داكن ⇒ الحبر يُثبَّت (البياض على
      // الزمردي والأحمر الهادئ، والداكن على العنبري الذي لا يُقرأ عليه بياض).
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('تم الاشتراك في التنبيهات',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error));
    }
  }

  Future<void> _unsubscribeFromStockAlert() async {
    if (_product == null || _auth.currentUser == null) return;
    try {
      await _marketService.unsubscribeFromStockAlert(
          _auth.currentUser!.uid, _product!.id);
      if (!mounted) return;
      setState(() => _isSubscribedToStockAlert = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم إلغاء الاشتراك',
              style: TextStyle(color: AppColors.onWarning)),
          backgroundColor: AppColors.warning));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error));
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
