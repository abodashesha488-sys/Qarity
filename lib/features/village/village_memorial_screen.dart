import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kMemorialColor = Color(0xFF5D4037);

/// «سجل الراحلين» — تكريم رجال القرية ونسائها الراحلين.
class VillageMemorialScreen extends StatelessWidget {
  const VillageMemorialScreen({super.key});

  static final VillageExtendedService _service = VillageExtendedService();

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageMemorialPerson>(
      title: 'سجل الراحلين',
      subtitle: 'رحمهم الله — رجال ونساء من أهل أبودشيشة',
      accent: kMemorialColor,
      icon: Icons.church_rounded,
      stream: _service.watchMemorialPeople(),
      searchHint: 'ابحث بالاسم…',
      searchText: (p) => '${p.fullName} ${p.field} ${p.biography}',
      nameOf: (p) => p.fullName,
      subtitleOf: (p) => p.field,
      remove: (id) => _service.deleteMemorialPerson(id),
      formBuilder: (ctx, editing) => MemorialPersonForm(editing: editing),
      cardBuilder: (ctx, p, i) => VillageInfoCard(
        accent: kMemorialColor,
        title: p.fullName,
        subtitle: p.field,
        imageUrl: p.photoUrl.isNotEmpty
            ? p.photoUrl
            : (p.images.isNotEmpty ? p.images.first : ''),
        index: i,
        body: [
          if (p.biography.isNotEmpty) p.biography,
          if (p.relationshipToVillage.isNotEmpty)
            'صلته بالقرية: ${p.relationshipToVillage}',
          if (p.causeOfDeath.isNotEmpty) 'سبب الوفاة: ${p.causeOfDeath}',
        ],
      ),
    );
  }
}
