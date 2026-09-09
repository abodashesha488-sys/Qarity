import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/role_style.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';
import '../../widgets/common_appbar_actions.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final MarketService _marketService = MarketService();
  SellerProfile? _sellerProfile;
  List<MarketProduct> _sellerProducts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final profile = await _marketService.getSellerProfile(widget.sellerId);
      final products =
          await _marketService.getProductsBySeller(widget.sellerId);

      if (!mounted) return;
      setState(() {
        _sellerProfile = profile;
        _sellerProducts = products.where((p) => p.isApproved).toList();
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

  Future<void> _makePhoneCall(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final url = 'https://wa.me/2$cleanedPhone'; // Egypt country code
    final Uri launchUri = Uri.parse(url);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ملف البائع')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _sellerProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ملف البائع')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('تعذر تحميل ملف البائع', style: theme.textTheme.titleLarge),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadSellerData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _sellerProfile!;
    final approvedProducts =
        _sellerProducts.where((p) => p.isApproved).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
        centerTitle: true,
        elevation: 0,
        actions: CommonAppBarActions.actions(context),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSellerData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildProfileHeader(theme, profile),
            ),
            SliverToBoxAdapter(
              child: _buildStatsRow(theme, profile, approvedProducts.length),
            ),
            if (profile.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildCategoriesChips(theme, profile.categories),
              ),
            if (profile.bio != null && profile.bio!.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildBio(theme, profile.bio!),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'منتجات البائع (${approvedProducts.length})',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: approvedProducts.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text('لا توجد منتجات معتمدة بعد',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('سيظهر منتجات البائع هنا بعد موافقة الإدارة',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildProductCard(
                            theme, approvedProducts[index], index),
                        childCount: approvedProducts.length,
                      ),
                    ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, SellerProfile profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: profile.imageUrl != null
                    ? CachedNetworkImageProvider(profile.imageUrl!)
                    : null,
                child: profile.imageUrl == null
                    ? Text(
                        profile.name.isNotEmpty ? profile.name[0] : 'ب',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              if (profile.isVerified)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: theme.colorScheme.surface, width: 3),
                  ),
                  child: Icon(Icons.verified_rounded,
                      size: 16, color: theme.colorScheme.onPrimary),
                ),
            ],
          ),
          const SizedBox(height: 16),
          RoleNameText(
            name: profile.name,
            role: 'seller',
            sellerType: profile.sellerType,
            maxLines: 2,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (profile.address != null && profile.address!.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(profile.address!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildContactButton(
                theme,
                icon: Icons.phone_rounded,
                label: 'اتصال',
                color: theme.colorScheme.primary,
                onTap: () => _makePhoneCall(profile.phone),
              ),
              const SizedBox(width: 12),
              _buildContactButton(
                theme,
                icon: Icons.chat_bubble_outline_rounded,
                label: 'واتساب',
                color: Colors.green,
                onTap: () => _openWhatsApp(profile.phone),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                profile.rating.toStringAsFixed(1),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Text(
                '(${profile.reviewCount} تقييم)',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('بائع موثوق',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(ThemeData theme,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      ThemeData theme, SellerProfile profile, int approvedCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
              child: _buildStatItem(theme, 'المنتجات', approvedCount.toString(),
                  Icons.inventory_2_rounded)),
          Container(
              width: 1, height: 40, color: theme.colorScheme.outlineVariant),
          Expanded(
              child: _buildStatItem(theme, 'إجمالي المنتجات',
                  profile.totalProducts.toString(), Icons.storefront_rounded)),
          Container(
              width: 1, height: 40, color: theme.colorScheme.outlineVariant),
          Expanded(
                  child: _buildStatItem(theme, 'المبيعات',
                      profile.totalSales.toString(), Icons.trending_up_rounded)),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildCategoriesChips(ThemeData theme, List<String> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories
            .map((cat) => Chip(
                  label: Text(cat,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBio(ThemeData theme, String bio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نبذة عن البائع',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(bio, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildProductCard(ThemeData theme, MarketProduct product, int index) {
    final price = product.effectivePrice;

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
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
                      imageUrl: product.imageUrls.isNotEmpty
                          ? product.imageUrls.first
                          : product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image_rounded,
                            size: 32,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  if (product.isOnOffer)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('عرض',
                            style: TextStyle(
                                color: theme.colorScheme.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  if (product.isFeatured)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('مميز',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800))
                            ]),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(product.category,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    Text(product.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${price.toStringAsFixed(0)} ج.م',
                            style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        if (product.rating > 0)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(product.rating.toStringAsFixed(1),
                                style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant))
                          ]),
                      ],
                    ),
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
}
