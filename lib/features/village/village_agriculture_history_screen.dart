import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kAgricultureColor = Color(0xFF558B2F);

/// «تاريخ الزراعة» — المحاصيل والزراعة التقليدية والأدوات وحكايات الفلاحين.
class VillageAgricultureHistoryScreen extends StatelessWidget {
  const VillageAgricultureHistoryScreen({super.key});

  static final VillageExtendedService _service = VillageExtendedService();

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageAgricultureHistory>(
      title: 'تاريخ الزراعة',
      subtitle: 'المحاصيل والزراعة التقليدية في أبودشيشة عبر الزمن',
      accent: kAgricultureColor,
      icon: Icons.agriculture_rounded,
      stream: _service.watchAgricultureHistory(),
      searchHint: 'ابحث عن محصول…',
      searchText: (a) =>
          '${a.crop} ${a.traditionalFarming} ${a.farmerStory} ${a.historicalTools}',
      nameOf: (a) => a.crop,
      subtitleOf: (a) => a.agriculturalArea,
      remove: (id) => _service.deleteAgricultureHistory(id),
      formBuilder: (ctx, editing) => AgricultureHistoryForm(editing: editing),
      cardBuilder: (ctx, a, i) => VillageInfoCard(
        accent: kAgricultureColor,
        title: a.crop,
        subtitle: a.agriculturalArea,
        imageUrl: a.images.isNotEmpty ? a.images.first : '',
        index: i,
        body: [
          if (a.traditionalFarming.isNotEmpty)
            'الزراعة التقليدية: ${a.traditionalFarming}',
          if (a.historicalTools.isNotEmpty)
            'الأدوات القديمة: ${a.historicalTools}',
          if (a.farmerStory.isNotEmpty) 'حكاية الفلاح: ${a.farmerStory}',
          if (a.changesOverTime.isNotEmpty)
            'تغيّرات عبر الزمن: ${a.changesOverTime}',
          if (a.sources.isNotEmpty) 'المصادر: ${a.sources.join('، ')}',
        ],
      ),
    );
  }
}
