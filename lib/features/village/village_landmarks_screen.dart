import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/village_content_models.dart';
import '../../routes/app_routes.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kLandmarkColor = Color(0xFF1565C0);

/// «معالم القرية» — المساجد والمدارس والمرافق والأماكن التاريخية.
class VillageLandmarksScreen extends StatelessWidget {
  const VillageLandmarksScreen({super.key});

  static final VillageExtendedService _service = VillageExtendedService();

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageLandmark>(
      title: 'معالم القرية',
      subtitle: 'مساجد ومدارس ومرافق وأماكن تاريخية في أبودشيشة',
      accent: kLandmarkColor,
      icon: Icons.landscape_rounded,
      stream: _service.watchLandmarks(),
      searchHint: 'ابحث عن معلم…',
      searchText: (l) => '${l.name} ${l.description} ${l.location}',
      nameOf: (l) => l.name,
      subtitleOf: (l) => l.location,
      remove: (id) => _service.deleteLandmark(id),
      formBuilder: (ctx, editing) => LandmarkForm(editing: editing),
      topBuilder: (_) => OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.villageMap),
        icon: const Icon(Icons.map_rounded, size: 18),
        label: const Text('خريطة القرية',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      cardBuilder: (ctx, l, i) => VillageInfoCard(
        accent: kLandmarkColor,
        title: l.name,
        subtitle: l.location,
        imageUrl: l.currentImages.isNotEmpty
            ? l.currentImages.first
            : (l.historicalImages.isNotEmpty ? l.historicalImages.first : ''),
        index: i,
        body: [
          if (l.description.isNotEmpty) l.description,
          if (l.historicalInfo.isNotEmpty) 'تاريخه: ${l.historicalInfo}',
          if (l.story.isNotEmpty) 'حكايته: ${l.story}',
        ],
        footer: l.mapLocation.isNotEmpty
            ? OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(l.mapLocation),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.location_on_rounded, size: 16),
                label: const Text('الموقع على الخريطة',
                    style: TextStyle(fontSize: 11.5)),
              )
            : null,
      ),
    );
  }
}
