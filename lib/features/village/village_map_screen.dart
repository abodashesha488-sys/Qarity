import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import '../../widgets/village_ornament.dart';
import 'village_section_scaffold.dart';

const Color kMapColor = Color(0xFF1565C0);

/// «خريطة القرية» — المعالم ذات إحداثيات/روابط خرائط، مع زر فتح خارجي.
class VillageMapScreen extends StatelessWidget {
  const VillageMapScreen({super.key});

  static final VillageExtendedService _service = VillageExtendedService();

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageLandmark>(
      title: 'خريطة القرية',
      subtitle: 'معالم أبودشيشة على الخريطة — اضغط للفتح في خرائط جوجل',
      accent: kMapColor,
      icon: Icons.map_rounded,
      stream: _service.watchLandmarks().map((items) =>
          items.where((l) => l.mapLocation.isNotEmpty).toList(growable: false)),
      emptyText: 'لا توجد معالم مرتبطة بالخريطة بعد',
      searchHint: 'ابحث عن معلم…',
      searchText: (l) => '${l.name} ${l.location}',
      nameOf: (l) => l.name,
      subtitleOf: (l) => l.location,
      remove: (id) => _service.deleteLandmark(id),
      formBuilder: (ctx, editing) =>
          throw UnsupportedError('إدارة المعالم تتم من شاشة المعالم'),
      cardBuilder: (ctx, l, i) => VillageInfoCard(
        accent: kMapColor,
        title: l.name,
        subtitle: l.location,
        imageUrl: l.currentImages.isNotEmpty
            ? l.currentImages.first
            : (l.historicalImages.isNotEmpty ? l.historicalImages.first : ''),
        index: i,
        body: [if (l.description.isNotEmpty) l.description],
        footer: FilledButton.icon(
          onPressed: () => _open(l.mapLocation),
          style: FilledButton.styleFrom(backgroundColor: kMapColor),
          icon: const Icon(Icons.directions_rounded, size: 17),
          label:
              const Text('فتح في خرائط جوجل', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

/// مرجع سريع: عنوان شاشة الخريطة داخل الهيكل المشترك.
class VillageMapHeader extends StatelessWidget {
  const VillageMapHeader({super.key});

  @override
  Widget build(BuildContext context) => const VillageSectionHeader(
        accent: kMapColor,
        title: 'خريطة القرية',
        subtitle: 'مواقع معالم أبودشيشة',
        icon: Icons.map_rounded,
        height: 140,
      );
}
