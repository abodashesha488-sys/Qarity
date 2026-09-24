import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kNotableColor = Color(0xFF6A1B9A);

/// «شخصيات بارزة» — سير الشخصيات التي تركت أثراً في القرية.
class VillageNotablePeopleScreen extends StatelessWidget {
  const VillageNotablePeopleScreen({super.key});

  static final VillageExtendedService _service = VillageExtendedService();

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageNotablePerson>(
      title: 'شخصيات بارزة',
      subtitle: 'رموز أبودشيشة ورجالها ونساؤها المؤثرون',
      accent: kNotableColor,
      icon: Icons.workspace_premium_rounded,
      stream: _service.watchNotablePeople(),
      searchHint: 'ابحث عن شخصية…',
      searchText: (p) => '${p.fullName} ${p.field} ${p.biography}',
      nameOf: (p) => p.fullName,
      subtitleOf: (p) => p.field,
      remove: (id) => _service.deleteNotablePerson(id),
      formBuilder: (ctx, editing) => NotablePersonForm(editing: editing),
      cardBuilder: (ctx, p, i) => _PersonCard(item: p, index: i),
    );
  }
}

/// بطاقة شخصية مع صورة دائرية وتفاصيل السيرة (تفاصيل كاملة بنقرة).
class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.item, required this.index});

  final VillageNotablePerson item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return VillageInfoCard(
      accent: kNotableColor,
      title: item.fullName,
      subtitle: item.field,
      imageUrl: item.photoUrl.isNotEmpty
          ? item.photoUrl
          : (item.images.isNotEmpty ? item.images.first : ''),
      index: index,
      body: [
        if (item.biography.isNotEmpty) item.biography,
        if (item.achievements.isNotEmpty)
          'الإنجازات: ${item.achievements.join('، ')}',
        if (item.relationshipToVillage.isNotEmpty)
          'صلته بالقرية: ${item.relationshipToVillage}',
      ],
    );
  }
}
