import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

export '../../models/village_content_models.dart' show ArchiveItemCategory;

/// شاشة قائمة عامة لعناصر «ذاكرة القرية / الأرشيف» مقفلة على فئة واحدة
/// (صور، حكايات، وثائق، فيديوهات، صوتيات، صحف، خرائط).
/// تتصفح من مركز «ذاكرة القرية» مع تمرير الفئة كمعامل للمسار.
class VillageArchiveListScreen extends StatelessWidget {
  const VillageArchiveListScreen({super.key, required this.category});

  final String category;

  static final VillageExtendedService _service = VillageExtendedService();

  @override
  Widget build(BuildContext context) {
    final color = ArchiveItemCategory.color(category);
    final label = ArchiveItemCategory.label(category);
    return VillageSectionScaffold<VillageArchiveItem>(
      title: label,
      subtitle: 'مواد «$label» الموثّقة من ذاكرة أبودشيشة',
      accent: color,
      icon: ArchiveItemCategory.icon(category),
      stream: _service.watchApprovedArchiveItems().map((items) =>
          items.where((i) => i.category == category).toList(growable: false)),
      emptyText: 'لا يوجد محتوى في «$label» بعد',
      searchHint: 'ابحث في «$label»…',
      searchText: (i) =>
          '${i.title} ${i.description} ${i.contributor} ${i.location} ${i.people} ${i.period}',
      nameOf: (i) => i.title,
      subtitleOf: (i) => i.year,
      remove: (id) => _service.deleteArchiveItem(id),
      manageTitle: 'إدارة $label',
      formBuilder: (ctx, editing) =>
          ArchiveItemForm(item: editing, fixedCategory: category),
      cardBuilder: (ctx, item, i) => VillageInfoCard(
        accent: color,
        title: item.title,
        subtitle:
            [item.year, item.location].where((s) => s.isNotEmpty).join(' · '),
        imageUrl: item.imageUrl,
        index: i,
        body: [
          if (item.description.isNotEmpty) item.description,
          if (item.contributor.isNotEmpty)
            'المساهم/الراوي: ${item.contributor}',
          if (item.people.isNotEmpty) 'الأشخاص: ${item.people}',
        ],
      ),
    );
  }
}
