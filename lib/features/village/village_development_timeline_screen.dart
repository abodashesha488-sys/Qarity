import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kDevelopmentColor = Color(0xFF0277BD);

/// «الخط الزمني للتطوير» — محطات تطوّر القرية (تاريخ، مشروع، صور قبل/بعد).
class VillageDevelopmentTimelineScreen extends StatelessWidget {
  const VillageDevelopmentTimelineScreen({super.key});

  static final VillageExtendedService _service = VillageExtendedService();

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageDevelopmentTimeline>(
      title: 'الخط الزمني للتطوير',
      subtitle: 'محطات تطوّر أبودشيشة: مشاريع ومرافق وتغيّرات',
      accent: kDevelopmentColor,
      icon: Icons.timeline_rounded,
      stream: _service.watchDevelopmentTimeline(),
      searchHint: 'ابحث في المحطات…',
      searchText: (d) => '${d.title} ${d.description} ${d.relatedProject}',
      nameOf: (d) => d.title,
      subtitleOf: (d) => d.date,
      remove: (id) => _service.deleteDevelopmentTimeline(id),
      formBuilder: (ctx, editing) => DevelopmentTimelineForm(editing: editing),
      cardBuilder: (ctx, d, i) => _DevNode(item: d, index: i),
    );
  }
}

/// عقدة الخط الزمني: شارة التاريخ + بطاقة المحطة.
class _DevNode extends StatelessWidget {
  const _DevNode({required this.item, required this.index});

  final VillageDevelopmentTimeline item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: kDevelopmentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(item.date,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: kDevelopmentColor.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 16),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: kDevelopmentColor)),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(item.description,
                            style:
                                const TextStyle(fontSize: 11.5, height: 1.8)),
                      ],
                      if (item.relatedProject.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('المشروع: ${item.relatedProject}',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                      if (item.beforeImage.isNotEmpty ||
                          item.afterImage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (item.beforeImage.isNotEmpty)
                              Expanded(
                                  child: _MiniImage(
                                      url: item.beforeImage, label: 'قبل')),
                            if (item.beforeImage.isNotEmpty &&
                                item.afterImage.isNotEmpty)
                              const SizedBox(width: 6),
                            if (item.afterImage.isNotEmpty)
                              Expanded(
                                  child: _MiniImage(
                                      url: item.afterImage, label: 'بعد')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms, delay: (40 * index).ms);
  }
}

class _MiniImage extends StatelessWidget {
  const _MiniImage({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 100,
              color: kDevelopmentColor.withValues(alpha: 0.08),
              child: Icon(Icons.broken_image_outlined,
                  color: kDevelopmentColor.withValues(alpha: 0.4)),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
