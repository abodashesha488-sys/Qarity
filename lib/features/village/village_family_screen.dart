import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kFamilyColor = Color(0xFF6F4E37);

/// «عائلات القرية» — أصول العائلات وفروعها وأماكن إقامتها.
class VillageFamilyScreen extends StatelessWidget {
  const VillageFamilyScreen({super.key});

  static final VillageExtendedService _service = VillageExtendedService();

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageFamily>(
      title: 'عائلات القرية',
      subtitle: 'أصول عائلات أبودشيشة وفروعها وتاريخها',
      accent: kFamilyColor,
      icon: Icons.family_restroom_rounded,
      stream: _service.watchFamilies(),
      searchHint: 'ابحث عن عائلة…',
      searchText: (f) =>
          '${f.name} ${f.originHistory} ${f.branches.join(' ')} ${f.residenceArea}',
      nameOf: (f) => f.name,
      subtitleOf: (f) => FamilyCategory.label(f.category),
      remove: (id) => _service.deleteFamily(id),
      formBuilder: (ctx, editing) => FamilyForm(editing: editing),
      cardBuilder: (ctx, f, i) => VillageInfoCard(
        accent: kFamilyColor,
        title: 'عائلة ${f.name}',
        subtitle: FamilyCategory.label(f.category),
        imageUrl: f.imageUrls.isNotEmpty ? f.imageUrls.first : '',
        index: i,
        body: [
          if (f.originHistory.isNotEmpty) 'الأصل: ${f.originHistory}',
          if (f.branches.isNotEmpty) 'أبرز الفروع: ${f.branches.join('، ')}',
          if (f.residenceArea.isNotEmpty) 'منطقة السكن: ${f.residenceArea}',
          if (f.historicalInfo.isNotEmpty) f.historicalInfo,
          if (f.description.isNotEmpty) f.description,
        ],
      ),
    );
  }
}
