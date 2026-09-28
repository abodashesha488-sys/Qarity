import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../models/medical_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';
import '../../services/medical_service.dart';
import '../../services/share_service.dart';
import '../market/add_product.dart';
import 'clinic_detail_screen.dart';

/// ألوان قسم النظارات — مصدر واحد تستعمله البوابة والتبويب وشاشة التفاصيل.
const Color kOpticalAccent = Color(0xFF3949AB);
const Color kOpticalAccentDark = Color(0xFF1A237E);
const Color kOpticalGold = Color(0xFFB8860B);

/// شاشة تفاصيل محل نظارات طبية — بيانات المحل + منتجات صاحبة المعروضة في
/// السوق (نفس مسار «أضف منتجاً لمحلي» المتبع في التطبيق) + تجديد العرض المميز.
class OpticalShopDetailScreen extends StatefulWidget {
  const OpticalShopDetailScreen({super.key});

  @override
  State<OpticalShopDetailScreen> createState() => _OpticalShopDetailScreenState();
}

class _OpticalShopDetailScreenState extends State<OpticalShopDetailScreen> {

  final OpticalShopService _service = OpticalShopService();
  final MarketService _market = MarketService();
  Stream<List<MarketProduct>>? _productsStream;
  bool _renewing = false;

  String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Stream<List<MarketProduct>> _productsFor(String? sellerId) {
    final id = sellerId;
    if (id == null || id.isEmpty) return Stream<List<MarketProduct>>.value(const []);
    return _productsStream ??= _market.getSellerProductsStream(id);
  }

  Future<void> _renew(OpticalShop shop) async {
    final days = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          OpticalRenewSheet(shopName: shop.name, featured: shop.isFeaturedAd),
    );
    if (days == null || !mounted) return;
    setState(() => _renewing = true);
    try {
      await _service.setFeaturedWindow(shop.id, days);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم تفعيل العرض المميز لمدة $days يومًا'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذّر التجديد — تحقق من الصلاحيات'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _renewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shop = ModalRoute.of(context)?.settings.arguments is OpticalShop
        ? ModalRoute.of(context)!.settings.arguments as OpticalShop
        : const OpticalShop(id: '', name: '');
    final uid = _uid;
    final isOwner = uid != null && shop.submittedBy == uid;
    final now = DateTime.now();
    final live = shop.adLiveAt(now);
    final expired = shop.isFeaturedAd && !live;

    return Scaffold(
      body: StreamBuilder<List<MarketProduct>>(
        stream: _productsFor(shop.submittedBy),
        builder: (context, snapshot) {
          final products = (snapshot.data ?? [])
              .where((p) => p.isApproved && p.isInStock)
              .toList();
          return CustomScrollView(
            slivers: [
              MedDetailHeader(
                title: shop.name,
                accent: kOpticalAccent,
                accentDark: kOpticalAccentDark,
                imageUrl: shop.imageUrl,
                icon: Icons.remove_red_eye_rounded,
                onShare: () => ShareService.shareText(
                    title: '👓 ${shop.name}',
                    body: [
                      if (shop.categories.isNotEmpty)
                        'التخصصات: ${shop.categories.join('، ')}',
                      if (shop.ownerName.isNotEmpty) 'المسؤول: ${shop.ownerName}',
                      if (shop.workingHours.isNotEmpty)
                        'المواعيد: ${shop.workingHours}',
                      if (shop.address.isNotEmpty) 'العنوان: ${shop.address}',
                      if (shop.phone.isNotEmpty) 'هاتف: ${shop.phone}',
                    ].where((e) => e.isNotEmpty).join('\n')),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(shop.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900)),
                          ),
                          if (live)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                  color: kOpticalGold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: kOpticalGold.withValues(alpha: 0.4))),
                              child: Text(
                                  'مميز حتى ${AppHelpers.formatDate(shop.featuredUntil!)}',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: kOpticalGold)),
                            ),
                        ],
                      ),
                      if (shop.categories.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: shop.categories
                              .map((c) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: kOpticalAccent.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text(c,
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: kOpticalAccent)),
                                  ))
                              .toList(),
                        ),
                      ],
                      if (expired) ...[
                        const SizedBox(height: 14),
                        const _NoticeBanner(
                          text: 'انتهت مدة العرض المميز، لذلك اختفى المحل من '
                              'دليل النظارات. يمكن لصاحبه تجديده ليعود ظاهرًا.',
                          accent: kOpticalGold,
                        ),
                      ],
                      if (!shop.isApproved) ...[
                        const SizedBox(height: 14),
                        const _NoticeBanner(
                          text: 'هذا المحل قيد مراجعة الإدارة ولن يظهر في الدليل '
                              'قبل الموافقة عليه.',
                          accent: kOpticalAccent,
                        ),
                      ],
                      const SizedBox(height: 16),
                      MedSection(
                        title: 'بيانات المحل',
                        accent: kOpticalAccent,
                        child: Column(
                          children: [
                            if (shop.ownerName.isNotEmpty)
                              MedInfoRow(
                                  icon: Icons.person_rounded,
                                  label: 'صاحب المحل',
                                  value: shop.ownerName,
                                  accent: kOpticalAccent),
                            if (shop.phone.isNotEmpty)
                              MedInfoRow(
                                  icon: Icons.phone_rounded,
                                  label: 'الهاتف',
                                  value: shop.phone,
                                  accent: kOpticalAccent),
                            if (shop.workingHours.isNotEmpty)
                              MedInfoRow(
                                  icon: Icons.access_time_rounded,
                                  label: 'مواعيد العمل',
                                  value: shop.workingHours,
                                  accent: kOpticalAccent),
                            if (shop.address.isNotEmpty)
                              MedInfoRow(
                                  icon: Icons.location_on_rounded,
                                  label: 'العنوان',
                                  value: shop.address,
                                  accent: kOpticalAccent),
                          ],
                        ),
                      ),
                      if (shop.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MedSection(
                          title: 'عن المحل',
                          accent: kOpticalAccent,
                          child: Text(shop.description,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(height: 1.6)),
                        ),
                      ],
                      if (shop.imageUrls.length > 1) ...[
                        const SizedBox(height: 16),
                        MedSection(
                          title: 'صور المحل',
                          accent: kOpticalAccent,
                          child: SizedBox(
                            height: 130,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: shop.imageUrls.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, i) => ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CachedNetworkImage(
                                    imageUrl: shop.imageUrls[i],
                                    width: 180,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                        width: 180,
                                        color: theme
                                            .colorScheme.surfaceContainerHighest,
                                        child: const Icon(
                                            Icons.broken_image_rounded))),
                              ),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                              isOwner
                                  ? 'لم تُضف أي منتجات بعد — استخدم زر «أضف منتجاً لمحلي» أدناه.'
                                  : 'لا توجد منتجات معروضة في هذا المحل بعد.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(height: 1.5)),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.62),
                          itemCount: products.length,
                          itemBuilder: (context, i) =>
                              _ProductTile(product: products[i]),
                        ),
                      const SizedBox(height: 18),
                      if (shop.phone.isNotEmpty)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: kOpticalAccent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: () async {
                            final uri = Uri(scheme: 'tel', path: shop.phone);
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          icon: const Icon(Icons.call_rounded),
                          label: const Text('اتصال بالمحل',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      if (isOwner) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: kOpticalGold)),
                          onPressed:
                              _renewing ? null : () => _renew(shop),
                          icon: _renewing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.star_rounded, color: kOpticalGold),
                          label: Text(
                              shop.isFeaturedAd
                                  ? 'تجديد العرض المميز'
                                  : 'تحويل الإعلان إلى عرض مميز',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              heroTag: 'optical_add_product',
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.marketAdd,
                arguments: <String, dynamic>{
                  kCategoryOptionsArgKey: kOpticalCategories,
                },
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('أضف منتجاً لمحلي'),
            )
          : null,
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.text, required this.accent});
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.3))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class OpticalRenewSheet extends StatefulWidget {
  const OpticalRenewSheet(
      {super.key, required this.shopName, this.featured = true});
  final String shopName;

  /// محل مميز بالفعل ⇒ «تجديد»؛ وغير المميز ⇒ «تفعيل».
  final bool featured;

  @override
  State<OpticalRenewSheet> createState() => _OpticalRenewSheetState();
}

class _OpticalRenewSheetState extends State<OpticalRenewSheet> {
  int _days = kOpticalFeaturedDayOptions[1];

  @override
  Widget build(BuildContext context) {
    final until = DateTime.now().add(Duration(days: _days));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.featured ? 'تجديد العرض المميز' : 'تفعيل العرض المميز',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 6),
          Text(
              '«${widget.shopName}» يظهر بإطار ذهبي في مقدمة الدليل طوال المدة، '
              'ويختفي منها بعدها حتى تجديده مرة أخرى.',
              style: const TextStyle(fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kOpticalFeaturedDayOptions.map((d) {
              final selected = d == _days;
              return ChoiceChip(
                label: Text('$d يوم'),
                selected: selected,
                onSelected: (_) => setState(() => _days = d),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('ينتهي ${AppHelpers.formatDate(until)}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB8860B),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => Navigator.pop(context, _days),
            child: Text(
                widget.featured ? 'تجديد الآن' : 'تفعيل العرض المميز',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});
  final MarketProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.marketProductDetail,
            arguments: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: product.imageUrl.isEmpty
                  ? ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.remove_red_eye_rounded,
                          size: 32))
                  : CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_rounded))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12.5)),
                  const SizedBox(height: 4),
                  Text(
                      product.hasActiveOffer
                          ? '${product.effectivePrice.toStringAsFixed(0)} ج'
                          : '${product.price.toStringAsFixed(0)} ج',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          color: kOpticalAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
