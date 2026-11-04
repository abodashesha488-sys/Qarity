import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import '../../widgets/village_video_card.dart';
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

  /// مواد هذه الفئة. `approvedOnly` للعرض العام؛ ولوحة الإدارة ترى كل الحالات
  /// حتى تُراجع مساهمة معلّقة أو تحذفها من نفس الشاشة.
  Stream<List<VillageArchiveItem>> _items({bool approvedOnly = false}) =>
      _service.watchArchiveItems().map((all) => all
          .where((i) =>
              i.category == category &&
              (!approvedOnly || i.approvalStatus == 'approved'))
          .toList(growable: false));

  @override
  Widget build(BuildContext context) {
    final color = ArchiveItemCategory.color(category);
    final label = ArchiveItemCategory.label(category);
    return VillageSectionScaffold<VillageArchiveItem>(
      title: label,
      subtitle: 'مواد «$label» الموثّقة من ذاكرة أبودشيشة',
      accent: color,
      icon: ArchiveItemCategory.icon(category),
      streamFactory: () => _items(approvedOnly: true),
      manageStreamFactory: _items,
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
        footer: item.videoUrl.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => VillageVideoHelper.playInApp(
                      ctx,
                      item.videoUrl,
                      title: item.title,
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                    label: const Text('مشاهدة الفيديو داخل التطبيق',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
