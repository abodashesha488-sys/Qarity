import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kBeforeAfterColor = Color(0xFF6A1B9A);

/// «قبل وبعد» — مقارنة صور الأماكن القديمة بالحديثة جنباً إلى جنب.
class VillageBeforeAfterScreen extends StatelessWidget {
  const VillageBeforeAfterScreen({super.key});

  static final VillageExtendedService _service = VillageExtendedService();

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageBeforeAfter>(
      title: 'قبل وبعد',
      subtitle: 'أماكن القرية: كيف كانت وكيف أصبحت',
      accent: kBeforeAfterColor,
      icon: Icons.compare_rounded,
      stream: _service.watchBeforeAfter(),
      searchHint: 'ابحث عن مكان…',
      searchText: (b) => '${b.location} ${b.description}',
      nameOf: (b) => b.location,
      subtitleOf: (b) => b.historicalDate,
      remove: (id) => _service.deleteBeforeAfter(id),
      formBuilder: (ctx, editing) => BeforeAfterForm(editing: editing),
      cardBuilder: (ctx, b, i) => _BeforeAfterCard(item: b, index: i),
    );
  }
}

class _BeforeAfterCard extends StatelessWidget {
  const _BeforeAfterCard({required this.item, required this.index});

  final VillageBeforeAfter item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shadowColor: kBeforeAfterColor.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: kBeforeAfterColor.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SideImage(
                    url: item.historicalImage,
                    label: 'قبل · ${item.historicalDate}'),
                const SizedBox(width: 8),
                _SideImage(
                    url: item.currentImage, label: 'بعد · ${item.currentDate}'),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.location,
                style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: kBeforeAfterColor)),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.description,
                  style: const TextStyle(fontSize: 12, height: 1.8)),
            ],
            if (item.source.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('المصدر: ${item.source}',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (40 * index).ms);
  }
}

class _SideImage extends StatelessWidget {
  const _SideImage({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _NoImage(),
                  )
                : const _NoImage(),
          ),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _NoImage extends StatelessWidget {
  const _NoImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      color: kBeforeAfterColor.withValues(alpha: 0.08),
      child: Icon(Icons.image_not_supported_outlined,
          color: kBeforeAfterColor.withValues(alpha: 0.4)),
    );
  }
}
