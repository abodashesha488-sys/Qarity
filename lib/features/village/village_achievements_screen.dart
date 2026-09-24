import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kAchievementColor = Color(0xFFAD1457);

/// «إنجازات القرية» — بطاقات الإنجازات (التاريخ، الوصف، أصحاب الإنجاز).
class VillageAchievementsScreen extends StatelessWidget {
  const VillageAchievementsScreen({super.key});

  static final VillageExtendedService _service = VillageExtendedService();

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageAchievement>(
      title: 'إنجازات القرية',
      subtitle: 'إنجازات وأمجاد أبودشيشة التي يفتخر بها أهلها',
      accent: kAchievementColor,
      icon: Icons.emoji_events_rounded,
      stream: _service.watchAchievements(),
      searchHint: 'ابحث في الإنجازات…',
      searchText: (a) =>
          '${a.title} ${a.description} ${a.relatedPeople.join(' ')}',
      nameOf: (a) => a.title,
      subtitleOf: (a) => a.date,
      remove: (id) => _service.deleteAchievement(id),
      formBuilder: (ctx, editing) => AchievementForm(editing: editing),
      cardBuilder: (ctx, a, i) => VillageInfoCard(
        accent: kAchievementColor,
        title: a.title,
        subtitle: a.date,
        imageUrl: a.image,
        index: i,
        body: [
          if (a.description.isNotEmpty) a.description,
          if (a.relatedPeople.isNotEmpty)
            'أصحاب الإنجاز: ${a.relatedPeople.join('، ')}',
          if (a.source.isNotEmpty) 'المصدر: ${a.source}',
        ],
      ),
    );
  }
}
