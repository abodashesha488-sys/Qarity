import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/promo_placements.dart';
import '../core/utils/helpers.dart';
import '../core/utils/launch_link.dart';
import '../models/promo_model.dart';
import '../services/promo_service.dart';

/// مساحة إعلانات زراعية داخل تبويبي الأسمدة والمبيدات.
/// الإعلانات تُدار من مجموعة promos وتنتقل تلقائيًا كل خمس ثوانٍ.
class AgriculturePromoBanner extends StatefulWidget {
  const AgriculturePromoBanner({super.key, required this.placement});

  final String placement;

  @override
  State<AgriculturePromoBanner> createState() => _AgriculturePromoBannerState();
}

class _AgriculturePromoBannerState extends State<AgriculturePromoBanner> {
  final PromoService _service = PromoService();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Promo>>(
      stream: _service.watchAll(),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final promos = (snapshot.data ?? const <Promo>[])
            .where((promo) =>
                promo.isVisibleAt(now) &&
                (promo.placement == widget.placement ||
                    promo.placement == 'agri_both'))
            .toList();
        if (promos.isEmpty) return const SizedBox.shrink();
        final safeIndex = _index < promos.length ? _index : 0;
        final promo = promos[safeIndex];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openPromo(context, promo),
              child: Container(
                height: 112,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.35)),
                ),
                child: CachedNetworkImage(
                  imageUrl: promo.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported_outlined)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPromo(BuildContext context, Promo promo) async {
    if (promo.linkType == 'none' || promo.linkValue.isEmpty) return;
    if (promo.linkType == 'app') {
      final decoded = PromoInternalLink.decode(promo.linkValue);
      if (context.mounted) {
        await Navigator.pushNamed(context, decoded.$1, arguments: decoded.$2);
      }
      return;
    }
    final url = buildExternalUrl(promo.linkType, promo.linkValue);
    if (url == null) return;
    // رابط الإعلان قد يكون محادثة واتساب — تجربة مباشرة والفشل يُبلَّغ.
    final error = await launchContactUrl(url,
        unavailable: 'لا يمكن فتح رابط الإعلان على هذا الجهاز.',
        failed: 'تعذّر فتح الرابط — تحقّق من الاتصال ثم أعد المحاولة.');
    if (error != null) AppHelpers.showToast(error, isError: true);
  }
}
